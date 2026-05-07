// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      gstRate: fields[0] as double,
      expiryReminderDays: fields[1] as int,
      whatsappReminders: fields[2] as bool,
      biometricEnabled: fields[3] as bool,
      useBiometrics: fields[5] as bool,
      businessType: fields[4] as String,
      lastBackupAt: fields[6] as DateTime?,
      hmacSignature: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.gstRate)
      ..writeByte(1)
      ..write(obj.expiryReminderDays)
      ..writeByte(2)
      ..write(obj.whatsappReminders)
      ..writeByte(3)
      ..write(obj.biometricEnabled)
      ..writeByte(5)
      ..write(obj.useBiometrics)
      ..writeByte(4)
      ..write(obj.businessType)
      ..writeByte(6)
      ..write(obj.lastBackupAt)
      ..writeByte(7)
      ..write(obj.hmacSignature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
