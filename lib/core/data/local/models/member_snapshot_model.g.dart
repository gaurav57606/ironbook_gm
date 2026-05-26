// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_snapshot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberSnapshotAdapter extends TypeAdapter<MemberSnapshot> {
  @override
  final int typeId = 11;

  @override
  MemberSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberSnapshot(
      memberId: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      joinDate: fields[3] as DateTime,
      planId: fields[4] as String?,
      planName: fields[5] as String?,
      expiryDate: fields[6] as DateTime?,
      totalPaid: fields[7] as int,
      paymentIds: (fields[8] as List?)?.cast<String>(),
      joinDateHistory: (fields[9] as List?)?.cast<JoinDateChange>(),
      archived: fields[10] as bool,
      lastUpdated: fields[11] as DateTime?,
      gender: fields[12] as String?,
      age: fields[13] as int?,
      checkInPin: fields[14] as String?,
      lastCheckIn: fields[15] as DateTime?,
      lastCheckInDevice: fields[16] as String?,
      hmacSignature: fields[17] as String?,
      photoPath: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MemberSnapshot obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.joinDate)
      ..writeByte(4)
      ..write(obj.planId)
      ..writeByte(5)
      ..write(obj.planName)
      ..writeByte(6)
      ..write(obj.expiryDate)
      ..writeByte(7)
      ..write(obj.totalPaid)
      ..writeByte(8)
      ..write(obj.paymentIds)
      ..writeByte(9)
      ..write(obj.joinDateHistory)
      ..writeByte(10)
      ..write(obj.archived)
      ..writeByte(11)
      ..write(obj.lastUpdated)
      ..writeByte(12)
      ..write(obj.gender)
      ..writeByte(13)
      ..write(obj.age)
      ..writeByte(14)
      ..write(obj.checkInPin)
      ..writeByte(15)
      ..write(obj.lastCheckIn)
      ..writeByte(16)
      ..write(obj.lastCheckInDevice)
      ..writeByte(17)
      ..write(obj.hmacSignature)
      ..writeByte(18)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
