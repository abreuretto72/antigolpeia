import 'package:hive_flutter/hive_flutter.dart';

/// Cache local de padrões de golpe confirmados pela comunidade.
/// typeId: 2 — IMUTÁVEL. Alterar quebra compatibilidade do Hive box.
class FraudPatternModel extends HiveObject {
  final String patternHash;
  final String sanitizedContent;
  final int fraudScore;
  final String classification;
  final DateTime detectedAt;
  final bool userConfirmed;

  FraudPatternModel({
    required this.patternHash,
    required this.sanitizedContent,
    required this.fraudScore,
    required this.classification,
    required this.detectedAt,
    required this.userConfirmed,
  });
}

class FraudPatternModelAdapter extends TypeAdapter<FraudPatternModel> {
  @override
  final int typeId = 2;

  @override
  FraudPatternModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FraudPatternModel(
      patternHash: fields[0] as String,
      sanitizedContent: fields[1] as String,
      fraudScore: fields[2] as int,
      classification: fields[3] as String,
      detectedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      userConfirmed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FraudPatternModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.patternHash)
      ..writeByte(1)
      ..write(obj.sanitizedContent)
      ..writeByte(2)
      ..write(obj.fraudScore)
      ..writeByte(3)
      ..write(obj.classification)
      ..writeByte(4)
      ..write(obj.detectedAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.userConfirmed);
  }
}
