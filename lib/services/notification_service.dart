import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'api_service.dart';
import '../main.dart';
import '../pages/result_page.dart';
import '../pages/history_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _apiService = ApiService();
  bool _isListening = false;

  // Deduplicação por notificationId: evita analisar update/remove do mesmo evento
  final Set<String> _seenIds = {};

  bool _isDuplicate(String pkg, int? notifId) {
    if (notifId == null) return false;
    final key = '$pkg:$notifId';
    if (_seenIds.contains(key)) return true;
    _seenIds.add(key);
    // Evita crescimento ilimitado — mantém só os últimos 200
    if (_seenIds.length > 200) _seenIds.clear();
    return false;
  }

  Future<void> init() async {
    final bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      debugPrint("Permissão para NotificationListener não concedida.");
      return;
    }

    if (_isListening) return;

    NotificationListenerService.notificationsStream.listen((ServiceNotificationEvent event) {
      _processNotification(event);
    });
    
    _isListening = true;
    debugPrint("NotificationListener iniciado.");
  }

  Future<void> requestPermission() async {
    try {
      await NotificationListenerService.requestPermission();
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }
  }

  void _processNotification(ServiceNotificationEvent event) {
    final String? packageName = event.packageName;
    final String? content = event.content;
    final String? title = event.title;

    debugPrint('[NOTIF] pkg=$packageName id=${event.id} content=$content');

    if (packageName == null || content == null) {
      debugPrint('[NOTIF] Ignorado: packageName ou content nulo');
      return;
    }

    final isWhatsApp = packageName.contains('com.whatsapp');
    final isGmail = packageName.contains('com.google.android.gm');

    if (!isWhatsApp && !isGmail) {
      debugPrint('[NOTIF] Ignorado: app não monitorado ($packageName)');
      return;
    }

    if (content.length <= 5) {
      debugPrint('[NOTIF] Ignorado: conteúdo muito curto (${content.length} chars)');
      return;
    }

    if (_isDuplicate(packageName, event.id)) {
      debugPrint('[NOTIF] Ignorado: duplicata pkg=$packageName id=${event.id}');
      return;
    }

    debugPrint('[NOTIF] Analisando: $content');
    _analyzeInBackground(content, title ?? "Mensagem", isWhatsApp ? 'whatsapp' : 'email', title);
  }

  Future<void> _analyzeInBackground(String content, String title, String inputType, String? sender) async {
    try {
      debugPrint('[NOTIF] Chamando API... inputType=$inputType');
      final raw = await _apiService.analyzeContent(inputType, content);
      debugPrint('[NOTIF] API respondeu: risco=${raw['risco']}');

      // Injeta metadados para exibição na ResultPage
      final result = Map<String, dynamic>.from(raw);
      result['_content'] = content;
      result['_input_type'] = inputType;
      result['_sender'] = sender;
      result['_created_at'] = DateTime.now().toIso8601String();

      if (result['risco'] > 50) {
        _handleHighRiskResult(result);
      }
    } catch (e) {
      debugPrint('[NOTIF] Erro na análise: $e');
    }
  }

  void _handleHighRiskResult(Map<String, dynamic> result) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⚠️ ALERTA DE GOLPE: ${result['tipo_golpe']}"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: "VER",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ResultPage(result: result)),
            );
          },
        ),
      ),
    );

    // Abre o histórico para o usuário ver todas as ameaças detectadas
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }
}
