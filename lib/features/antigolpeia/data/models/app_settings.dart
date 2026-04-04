import 'package:hive_flutter/hive_flutter.dart';

/// Preferências do usuário persistidas localmente.
/// typeId: 5 — IMUTÁVEL.
class AppSettings extends HiveObject {
  bool enableCriticalSounds;
  bool enableHapticFeedback;

  AppSettings({
    this.enableCriticalSounds = true,
    this.enableHapticFeedback = true,
  });

  static AppSettings get current {
    final box = Hive.box<AppSettings>('app_settings');
    final existing = box.isEmpty ? null : box.getAt(0);
    if (existing != null) return existing;
    final defaults = AppSettings();
    box.add(defaults);
    return defaults;
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      enableCriticalSounds: fields[0] as bool,
      enableHapticFeedback: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.enableCriticalSounds)
      ..writeByte(1)
      ..write(obj.enableHapticFeedback);
  }
}
