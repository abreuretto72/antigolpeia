import 'package:flutter/foundation.dart';
import '../features/antigolpeia/data/models/analysis_stats_model.dart';

enum AnalysisType { sms, whatsapp, gmail, manual }

/// Totais de análises em memória (espelho do Hive), atualizados em tempo real.
class ActivityCounter {
  static final ActivityCounter _instance = ActivityCounter._internal();
  factory ActivityCounter() => _instance;
  ActivityCounter._internal();

  /// Notifica a UI sempre que um total mudar.
  final ValueNotifier<AnalysisStats?> stats = ValueNotifier(null);

  /// Carrega os totais do Hive. Chamado uma vez no startup.
  void init() {
    stats.value = AnalysisStats.current;
  }

  /// Backfill único do histórico Supabase na primeira instalação.
  /// Cada row deve ter 'input_type' (whatsapp/email/sms/text) e 'risk' (0-100).
  /// Nunca é chamado novamente após historyLoaded = true.
  void backfillFromHistory(List<Map<String, dynamic>> rows) {
    final s = stats.value ?? AnalysisStats.current;
    if (s.historyLoaded) return;

    for (final row in rows) {
      final inputType = row['input_type'] as String? ?? '';
      final risk = (row['risk'] as num? ?? 0).toInt();
      final isSuspicious = risk >= 50;

      switch (inputType) {
        case 'whatsapp':
          s.waTotal++;
          if (isSuspicious) s.waSuspicious++;
        case 'email':
          s.gmailTotal++;
          if (isSuspicious) s.gmailSuspicious++;
        case 'sms':
          s.smsTotal++;
          if (isSuspicious) s.smsSuspicious++;
        default:
          s.manualTotal++;
          if (isSuspicious) s.manualSuspicious++;
      }
    }

    s.historyLoaded = true;
    s.save();
    stats.value = null;
    stats.value = s;
  }

  /// Registra uma análise e persiste imediatamente no Hive.
  void add(AnalysisType type, {bool wasSuspicious = false}) {
    final s = stats.value ?? AnalysisStats.current;

    switch (type) {
      case AnalysisType.sms:
        s.smsTotal++;
        if (wasSuspicious) s.smsSuspicious++;
      case AnalysisType.whatsapp:
        s.waTotal++;
        if (wasSuspicious) s.waSuspicious++;
      case AnalysisType.gmail:
        s.gmailTotal++;
        if (wasSuspicious) s.gmailSuspicious++;
      case AnalysisType.manual:
        s.manualTotal++;
        if (wasSuspicious) s.manualSuspicious++;
    }

    s.save(); // persiste no Hive
    // Força notificação reatribuindo — ValueNotifier só notifica em mudança de referência
    stats.value = null;
    stats.value = s;
  }
}
