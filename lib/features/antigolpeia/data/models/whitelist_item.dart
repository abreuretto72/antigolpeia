import 'package:hive_flutter/hive_flutter.dart';

/// Contato confiável na Whitelist — nunca enviado à base de IA (privacidade).
/// typeId: 3 — IMUTÁVEL. Alterar quebra compatibilidade do Hive box.
class WhitelistItem extends HiveObject {
  final String phoneNumber;
  final String name;
  final DateTime addedAt;

  WhitelistItem({
    required this.phoneNumber,
    required this.name,
    required this.addedAt,
  });
}

class WhitelistItemAdapter extends TypeAdapter<WhitelistItem> {
  @override
  final int typeId = 3;

  @override
  WhitelistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WhitelistItem(
      phoneNumber: fields[0] as String,
      name: fields[1] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
    );
  }

  @override
  void write(BinaryWriter writer, WhitelistItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.phoneNumber)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.addedAt.millisecondsSinceEpoch);
  }
}
