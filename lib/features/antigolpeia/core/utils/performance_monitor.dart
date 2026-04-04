import 'dart:developer' as dev;

/// Monitor de performance para auditar o custo computacional da IA no SM A256E.
/// Usa [Timeline] do dart:developer — visível no DevTools sem overhead de prod.
class PerformanceMonitor {
  // Limite de tempo por mensagem antes de recomendar Isolate.
  static const int _warnThresholdMs = 100;
  static const int _criticalThresholdMs = 200;

  final String _label;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceMonitor(this._label);

  /// Inicia a medição.
  void start() {
    _stopwatch.reset();
    _stopwatch.start();
    dev.Timeline.startSync(_label);
  }

  /// Encerra a medição e loga o resultado.
  /// Retorna `true` se dentro do threshold seguro para a UI thread.
  bool stop() {
    _stopwatch.stop();
    dev.Timeline.finishSync();

    final ms = _stopwatch.elapsedMilliseconds;
    final status = _classify(ms);

    dev.log(
      '[$_label] ${ms}ms — $status',
      name: 'AntiGolpeia.Perf',
      level: ms >= _criticalThresholdMs ? 900 : (ms >= _warnThresholdMs ? 800 : 500),
    );

    return ms < _warnThresholdMs;
  }

  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  String _classify(int ms) {
    if (ms < _warnThresholdMs) return 'OK';
    if (ms < _criticalThresholdMs) return 'WARN — considerar Isolate';
    return 'CRITICAL — mover para Isolate';
  }

  /// Mede o tempo de execução de [fn] e retorna o resultado + duração.
  static Future<(T result, int elapsedMs)> measure<T>(
    String label,
    Future<T> Function() fn,
  ) async {
    final monitor = PerformanceMonitor(label);
    monitor.start();
    final result = await fn();
    monitor.stop();
    return (result, monitor.elapsedMs);
  }
}
