import 'package:hive_flutter/hive_flutter.dart';

/// Totais de análises por canal, persistidos localmente no Hive.
/// typeId: 7 — IMUTÁVEL.
class AnalysisStats extends HiveObject {
  int smsTotal;
  int smsSuspicious;
  int waTotal;
  int waSuspicious;
  int gmailTotal;
  int gmailSuspicious;
  int manualTotal;
  int manualSuspicious;
  /// true após o backfill inicial do histórico Supabase — nunca repetir.
  bool historyLoaded;

  AnalysisStats({
    this.smsTotal = 0,
    this.smsSuspicious = 0,
    this.waTotal = 0,
    this.waSuspicious = 0,
    this.gmailTotal = 0,
    this.gmailSuspicious = 0,
    this.manualTotal = 0,
    this.manualSuspicious = 0,
    this.historyLoaded = false,
  });

  static const String boxName = 'analysis_stats';

  static AnalysisStats get current {
    final box = Hive.box<AnalysisStats>(boxName);
    if (box.isNotEmpty) return box.getAt(0)!;
    final stats = AnalysisStats();
    box.add(stats);
    return stats;
  }
}

class AnalysisStatsAdapter extends TypeAdapter<AnalysisStats> {
  @override
  final int typeId = 7;

  @override
  AnalysisStats read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return AnalysisStats(
      smsTotal:        (fields[0] as num?)?.toInt() ?? 0,
      smsSuspicious:   (fields[1] as num?)?.toInt() ?? 0,
      waTotal:         (fields[2] as num?)?.toInt() ?? 0,
      waSuspicious:    (fields[3] as num?)?.toInt() ?? 0,
      gmailTotal:      (fields[4] as num?)?.toInt() ?? 0,
      gmailSuspicious: (fields[5] as num?)?.toInt() ?? 0,
      manualTotal:     (fields[6] as num?)?.toInt() ?? 0,
      manualSuspicious:(fields[7] as num?)?.toInt() ?? 0,
      historyLoaded:   (fields[8] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AnalysisStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.smsTotal)
      ..writeByte(1)..write(obj.smsSuspicious)
      ..writeByte(2)..write(obj.waTotal)
      ..writeByte(3)..write(obj.waSuspicious)
      ..writeByte(4)..write(obj.gmailTotal)
      ..writeByte(5)..write(obj.gmailSuspicious)
      ..writeByte(6)..write(obj.manualTotal)
      ..writeByte(7)..write(obj.manualSuspicious)
      ..writeByte(8)..write(obj.historyLoaded);
  }
}
