// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchased_subject.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchasedSubjectAdapter extends TypeAdapter<PurchasedSubject> {
  @override
  final int typeId = 10;

  @override
  PurchasedSubject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchasedSubject(
      subjectId: fields[0] as String,
      expiresAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PurchasedSubject obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.subjectId)
      ..writeByte(1)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchasedSubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
