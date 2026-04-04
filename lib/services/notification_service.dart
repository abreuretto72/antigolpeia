import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'api_service.dart';
import '../main.dart';
import '../pages/result_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _apiService = ApiService();
  bool _isListening = false;
  StreamSubscription? _notifSubscription;

  // Deduplicação por notificationId
  final Set<String> _seenIds = {};

  bool _isDuplicate(String pkg, int? notifId) {
    if (notifId == null) return false;
    final key = '$pkg:$notifId';
    if (_seenIds.contains(key)) return true;
    _seenIds.add(key);
    if (_seenIds.length > 200) _seenIds.clear();
    return false;
  }

  Future<void> init() async {
    final bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) return;
    if (_isListening) return;

    _notifSubscription = NotificationListenerService.notificationsStream.listen(
      _processNotification,
      onError: (e) => debugPrint('[NotificationService] Stream error: $e'),
      cancelOnError: false,
    );
    _isListening = true;
  }

  void dispose() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
    _isListening = false;
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

    if (packageName == null || content == null) return;

    final isWhatsApp = packageName.contains('com.whatsapp');
    final isGmail = packageName.contains('com.google.android.gm');

    if (!isWhatsApp && !isGmail) return;
    if (content.length <= 5) return;
    if (_isDuplicate(packageName, event.id)) return;

    // Log apenas em debug — nunca expõe conteúdo em release
    if (kDebugMode) {
      debugPrint('[NOTIF] pkg=$packageName analisando (${content.length} chars)');
    }

    _analyzeInBackground(
      content,
      isWhatsApp ? 'whatsapp' : 'email',
      title,
    );
  }

  Future<void> _analyzeInBackground(
    String content,
    String inputType,
    String? sender,
  ) async {
    try {
      final raw = await _apiService.analyzeContent(inputType, content);

      final result = Map<String, dynamic>.from(raw)
        ..['_content'] = content
        ..['_input_type'] = inputType
        ..['_sender'] = sender
        ..['_created_at'] = DateTime.now().toIso8601String();

      if ((result['risco'] as num? ?? 0) > 50) {
        _handleHighRiskResult(result);
      }
    } catch (e) {
      debugPrint('[NOTIF] Erro na análise: $e');
    }
  }

  void _handleHighRiskResult(Map<String, dynamic> result) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ALERTA: ${result['tipo_golpe'] ?? 'Golpe detectado'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'VER',
            textColor: Colors.white,
            onPressed: () {
              final ctx = navigatorKey.currentContext;
              if (ctx == null || !ctx.mounted) return;
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => ResultPage(result: result)),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NOTIF] Erro ao exibir alerta: $e');
    }
  }
}
