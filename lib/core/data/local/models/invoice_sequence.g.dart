// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_sequence.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceSequenceAdapter extends TypeAdapter<InvoiceSequence> {
  @override
  final int typeId = 12;

  @override
  InvoiceSequence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceSequence(
      prefix: fields[0] as String,
      nextNumber: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceSequence obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.prefix)
      ..writeByte(1)
      ..write(obj.nextNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceSequenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
