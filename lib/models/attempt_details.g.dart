// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_details.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttemptDetailsAdapter extends TypeAdapter<AttemptDetails> {
  @override
  final int typeId = 5;

  @override
  AttemptDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttemptDetails(
      attemptId: fields[0] as String,
      questions: (fields[1] as List).cast<Question>(),
      userAnswers: (fields[2] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, AttemptDetails obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.attemptId)
      ..writeByte(1)
      ..write(obj.questions)
      ..writeByte(2)
      ..write(obj.userAnswers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
