import 'package:hive/hive.dart';

class AuthorityReportModel extends HiveObject {
  String offenderPhone;
  String cleanedMessage;
  int ipqsScore;
  int timestampMs;
  String victimId;

  AuthorityReportModel({
    required this.offenderPhone,
    required this.cleanedMessage,
    required this.ipqsScore,
    required this.timestampMs,
    required this.victimId,
  });

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);
}

class AuthorityReportModelAdapter extends TypeAdapter<AuthorityReportModel> {
  @override
  final int typeId = 6;

  @override
  AuthorityReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthorityReportModel(
      offenderPhone: fields[0] as String,
      cleanedMessage: fields[1] as String,
      ipqsScore: fields[2] as int,
      timestampMs: fields[3] as int,
      victimId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuthorityReportModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.offenderPhone)
      ..writeByte(1)
      ..write(obj.cleanedMessage)
      ..writeByte(2)
      ..write(obj.ipqsScore)
      ..writeByte(3)
      ..write(obj.timestampMs)
      ..writeByte(4)
      ..write(obj.victimId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorityReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
