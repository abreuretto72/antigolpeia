import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import '../main.dart';
import '../pages/result_page.dart';
import 'api_service.dart';
import '../features/antigolpe/services/twilio_service.dart';

// Chamado em background pelo plugin — deve ser função top-level
@pragma('vm:entry-point')
void _onBackgroundSms(SmsMessage message) {
  SmsMonitorService()._process(message);
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
  final _twilioService = TwilioService();
  bool _isListening = false;

  Future<bool> get isPermissionGranted async {
    return await _telephony.requestSmsPermissions ?? false;
  }

  Future<bool> requestPermission() async {
    return await _telephony.requestSmsPermissions ?? false;
  }

  void startListening() {
    if (_isListening) return;
    _telephony.listenIncomingSms(
      onNewMessage: _process,
      onBackgroundMessage: _onBackgroundSms,
      listenInBackground: true,
    );
    _isListening = true;
    debugPrint('[SmsMonitor] Escutando SMS.');
  }

  Future<void> _process(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';
    if (sender.isEmpty || body.isEmpty) return;

    // Ignora short codes bancários conhecidos
    final normalized = sender.replaceAll(RegExp(r'\D'), '');
    if (_bankShortCodes.contains(normalized)) {
      debugPrint('[SmsMonitor] Short code bancário ignorado: $sender');
      return;
    }

    final hasLink = _hasSuspiciousLink(body);

    // Análise de conteúdo via Claude (privacidade: só o texto, não o número)
    Map<String, dynamic>? contentResult;
    try {
      contentResult = await _apiService.analyzeContent('sms', body, skipSave: false);
    } catch (e) {
      debugPrint('[SmsMonitor] Erro na análise de conteúdo: $e');
    }

    final contentRisk = (contentResult?['risco'] as num?)?.toInt() ?? 0;

    // Eleva risco automaticamente se link suspeito detectado localmente
    final effectiveRisk = hasLink && contentRisk < 70 ? 75 : contentRisk;

    if (effectiveRisk < 50) return;

    // Verificação do remetente via Twilio apenas se for número E2 (não short code)
    if (sender.startsWith('+') || sender.length > 6) {
      try {
        final simResult = await _twilioService.checkSimSwap(sender);
        if (simResult['isSwapped'] == true) {
          _showAlert({
            'risco': 95,
            'classificacao': 'golpe',
            'tipo_golpe': 'SIM Swap + SMS Suspeito',
            'explicacao': 'O número $sender trocou de chip recentemente e enviou um SMS suspeito. '
                'Golpistas usam chips clonados para enganar vítimas.',
            'sinais_alerta': [
              'Chip do remetente trocado recentemente',
              if (hasLink) 'Contém link encurtado suspeito',
              'Risco alto confirmado pela análise de conteúdo',
            ],
            'acao_imediata': 'Não clique em nenhum link. Bloqueie o número imediatamente.',
            'nivel_urgencia': 'extremo',
            'confianca': 90,
            'golpe_conhecido': true,
          });
          return;
        }
      } catch (e) {
        debugPrint('[SmsMonitor] Twilio check error: $e');
      }
    }

    if (contentResult != null) {
      _showAlert(contentResult);
    }
  }

  bool _hasSuspiciousLink(String text) {
    final urlRegex = RegExp(r'https?://([^\s/]+)', caseSensitive: false);
    return urlRegex.allMatches(text).any(
      (m) => _suspiciousHosts.any((host) => (m.group(1) ?? '').contains(host)),
    );
  }

  void _showAlert(Map<String, dynamic> result) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('📱 SMS SUSPEITO: ${result['tipo_golpe'] ?? 'Golpe detectado'}'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => ResultPage(result: result)),
          ),
        ),
      ),
    );
  }
}
