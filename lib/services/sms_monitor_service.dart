import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telephony/telephony.dart';
import '../main.dart';
import '../pages/result_page.dart';
import 'api_service.dart';

// ── Background isolate ────────────────────────────────────────────────────
// Chamado pelo plugin telephony em um isolate separado.
// DEVE reinicializar todas as dependências — o isolate não compartilha estado.
@pragma('vm:entry-point')
void _onBackgroundSms(SmsMessage message) async {
  try {
    // 1. Inicializar Flutter bindings no isolate
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Carregar .env
    await dotenv.load(fileName: '.env');

    // 3. Inicializar Supabase (idempotente — seguro chamar múltiplas vezes)
    await Supabase.initialize(
      url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
    );

    // 4. Processar sem alertas visuais (sem contexto de UI no background)
    await SmsMonitorService()._processBackground(message);
  } catch (e) {
    // Não propaga — isolate de background não deve quebrar a app principal
    debugPrint('[SmsMonitor:background] Erro não tratado: $e');
  }
}

// Short codes oficiais de bancos brasileiros (whitelist local)
const _bankShortCodes = {
  '29000', // Bradesco
  '4422',  // Itaú
  '30080', // Santander
  '4040',  // Nubank
  '60476', // Caixa
  '47777', // C6 Bank
};

// Links encurtados comuns em golpes
const _suspiciousHosts = [
  'bit.ly', 't.me', 'rebrand.ly', 'tinyurl.com',
  'cutt.ly', 'ow.ly', 'tiny.cc', 'is.gd',
];

class SmsMonitorService {
  static final SmsMonitorService _instance = SmsMonitorService._internal();
  factory SmsMonitorService() => _instance;
  SmsMonitorService._internal();

  final _telephony = Telephony.instance;
  final _apiService = ApiService();
  bool _isListening = false;

  Future<bool> get isPermissionGranted async =>
      await _telephony.requestSmsPermissions ?? false;

  Future<bool> requestPermission() async =>
      await _telephony.requestSmsPermissions ?? false;

  void startListening() {
    if (_isListening) return;
    _telephony.listenIncomingSms(
      onNewMessage: _processForground,
      onBackgroundMessage: _onBackgroundSms,
      listenInBackground: true,
    );
    _isListening = true;
    debugPrint('[SmsMonitor] Escutando SMS.');
  }

  // ── Foreground: análise + alerta visual ──────────────────────────────────

  Future<void> _processForground(SmsMessage message) async {
    final result = await _analyze(message);
    if (result != null) _showAlert(result);
  }

  // ── Background: análise silenciosa (sem UI) ──────────────────────────────
  // Salva no histórico via ApiService — o usuário verá na próxima abertura.

  Future<void> _processBackground(SmsMessage message) async {
    await _analyze(message); // skipSave = false → salva no histórico
  }

  // ── Lógica compartilhada de análise ─────────────────────────────────────

  Future<Map<String, dynamic>?> _analyze(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';
    if (sender.isEmpty || body.isEmpty) return null;

    // Ignora short codes bancários conhecidos
    final normalized = sender.replaceAll(RegExp(r'\D'), '');
    if (_bankShortCodes.contains(normalized)) return null;

    final hasLink = _hasSuspiciousLink(body);

    Map<String, dynamic>? contentResult;
    try {
      contentResult = await _apiService.analyzeContent(
        'sms',
        body,
        skipSave: false,
      );
    } catch (e) {
      debugPrint('[SmsMonitor] Erro na análise: $e');
      return null;
    }

    final contentRisk = (contentResult['risco'] as num?)?.toInt() ?? 0;
    final effectiveRisk = hasLink && contentRisk < 70 ? 75 : contentRisk;

    if (effectiveRisk < 50) return null;

    // Verificação SIM Swap via Edge Function (não expõe credentials)
    if (sender.startsWith('+') || sender.length > 6) {
      try {
        final simRes = await Supabase.instance.client.functions.invoke(
          'check-sim-swap',
          body: {'phone': sender},
        );
        final simData = simRes.data as Map<String, dynamic>? ?? {};
        if (simData['isSwapped'] == true) {
          return {
            'risco': 95,
            'classificacao': 'golpe',
            'tipo_golpe': 'SIM Swap + SMS Suspeito',
            'explicacao':
                'O número $sender trocou de chip recentemente e enviou um SMS suspeito.',
            'sinais_alerta': [
              'Chip do remetente trocado recentemente',
              if (hasLink) 'Contém link encurtado suspeito',
              'Risco alto confirmado pela análise de conteúdo',
            ],
            'acao_imediata':
                'Não clique em nenhum link. Bloqueie o número imediatamente.',
            'nivel_urgencia': 'extremo',
            'confianca': 90,
            'golpe_conhecido': true,
          };
        }
      } catch (e) {
        debugPrint('[SmsMonitor] SIM Swap check error: $e');
      }
    }

    return contentResult;
  }

  bool _hasSuspiciousLink(String text) {
    final urlRegex = RegExp(r'https?://([^\s/]+)', caseSensitive: false);
    return urlRegex.allMatches(text).any(
      (m) => _suspiciousHosts.any((h) => (m.group(1) ?? '').contains(h)),
    );
  }

  void _showAlert(Map<String, dynamic> result) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
              '📱 SMS SUSPEITO: ${result['tipo_golpe'] ?? 'Golpe detectado'}'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'VER',
            textColor: Colors.white,
            onPressed: () {
              final navCtx = navigatorKey.currentContext;
              if (navCtx == null || !navCtx.mounted) return;
              Navigator.push(
                navCtx,
                MaterialPageRoute(builder: (_) => ResultPage(result: result)),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[SmsMonitor] Erro ao exibir alerta: $e');
    }
  }
}
