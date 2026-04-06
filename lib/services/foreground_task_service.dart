import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'activity_counter.dart';

// Entry point do isolate do serviço — DEVE ser top-level.
@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_MonitorTaskHandler());
}

/// Handler mínimo: só precisa existir para manter o serviço vivo.
class _MonitorTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// Serviço de foreground persistente.
/// Mantém o processo Flutter vivo para que os monitores de SMS e
/// notificações continuem funcionando mesmo com o app fechado.
class ForegroundTaskService {
  ForegroundTaskService._();

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'antigolpeia_monitor',
        channelName: 'AntiGolpeia Monitor',
        channelDescription:
            'Monitoramento ativo contra golpes em SMS e notificações',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: false,
      ),
    );
  }

  static Future<void> start() async {
    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'AntiGolpeia ativo',
      notificationText: 'Monitorando mensagens em tempo real',
      callback: _foregroundTaskCallback,
    );

    if (result is ServiceRequestSuccess) {
      debugPrint('[ForegroundTask] Serviço iniciado.');
      ActivityCounter().stats.addListener(_onCountChanged);
    } else {
      debugPrint('[ForegroundTask] Falha ao iniciar: $result');
    }
  }

  static void _onCountChanged() {
    final s = ActivityCounter().stats.value;
    final n = s == null ? 0 : s.smsTotal + s.waTotal + s.gmailTotal + s.manualTotal;
    FlutterForegroundTask.updateService(
      notificationTitle: 'AntiGolpeia ativo',
      notificationText: n == 0
          ? 'Monitorando mensagens em tempo real'
          : '$n ${n == 1 ? 'mensagem verificada' : 'mensagens verificadas'} no total',
    );
  }

  static Future<void> stop() async {
    ActivityCounter().stats.removeListener(_onCountChanged);
    await FlutterForegroundTask.stopService();
  }
}
