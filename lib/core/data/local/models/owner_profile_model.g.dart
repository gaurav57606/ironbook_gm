// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OwnerProfileAdapter extends TypeAdapter<OwnerProfile> {
  @override
  final int typeId = 4;

  @override
  OwnerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnerProfile(
      gymName: fields[0] as String,
      ownerName: fields[1] as String,
      phone: fields[2] as String,
      address: fields[3] as String,
      gstin: fields[4] as String?,
      bankName: fields[5] as String?,
      accountNumber: fields[6] as String?,
      ifsc: fields[7] as String?,
      upiId: fields[8] as String?,
      logoPath: fields[9] as String?,
      hmacSignature: fields[10] as String?,
      level: fields[11] as int,
      exp: fields[12] as int,
      strength: fields[13] as double,
      endurance: fields[14] as double,
      dexterity: fields[15] as double,
      selectedCharacterId: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OwnerProfile obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.gymName)
      ..writeByte(1)
      ..write(obj.ownerName)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.gstin)
      ..writeByte(5)
      ..write(obj.bankName)
      ..writeByte(6)
      ..write(obj.accountNumber)
      ..writeByte(7)
      ..write(obj.ifsc)
      ..writeByte(8)
      ..write(obj.upiId)
      ..writeByte(9)
      ..write(obj.logoPath)
      ..writeByte(10)
      ..write(obj.hmacSignature)
      ..writeByte(11)
      ..write(obj.level)
      ..writeByte(12)
      ..write(obj.exp)
      ..writeByte(13)
      ..write(obj.strength)
      ..writeByte(14)
      ..write(obj.endurance)
      ..writeByte(15)
      ..write(obj.dexterity)
      ..writeByte(16)
      ..write(obj.selectedCharacterId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
