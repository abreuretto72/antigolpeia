import 'package:hive_flutter/hive_flutter.dart';

/// Número bloqueado pela análise da IA ou confirmação do usuário.
/// typeId: 4 — IMUTÁVEL.
class BlacklistItem extends HiveObject {
  final String phoneNumber;
  final String reason;
  final DateTime blockedAt;

  BlacklistItem({
    required this.phoneNumber,
    required this.reason,
    required this.blockedAt,
  });
}

class BlacklistItemAdapter extends TypeAdapter<BlacklistItem> {
  @override
  final int typeId = 4;

  @override
  BlacklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlacklistItem(
      phoneNumber: fields[0] as String,
      reason: fields[1] as String,
      blockedAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BlacklistItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.phoneNumber)
      ..writeByte(1)
      ..write(obj.reason)
      ..writeByte(2)
      ..write(obj.blockedAt.millisecondsSinceEpoch);
  }
}
