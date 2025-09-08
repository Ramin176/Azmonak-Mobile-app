// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttemptQuestionAdapter extends TypeAdapter<AttemptQuestion> {
  @override
  final int typeId = 6;

  @override
  AttemptQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttemptQuestion(
      id: fields[0] as String,
      text: fields[1] as String,
      options: (fields[2] as List).cast<String>(),
      correctAnswerIndex: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttemptQuestion obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctAnswerIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
