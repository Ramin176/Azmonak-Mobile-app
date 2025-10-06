// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionPlanAdapter extends TypeAdapter<SubscriptionPlan> {
  @override
  final int typeId = 11;

  @override
  SubscriptionPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionPlan(
      duration: fields[0] as String,
      price: fields[1] as String,
      planKey: fields[2] as String,
      name: fields[3] as String,
      description: fields[4] as String,
      subjectIds: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionPlan obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.duration)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.planKey)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.subjectIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 8;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      paymentInstructions: fields[0] as String,
      telegramLink: fields[1] as String,
      accountNumber: fields[2] as String,
      subscriptionPlans: (fields[3] as List).cast<SubscriptionPlan>(),
      aboutUsText: fields[4] as String,
      deactivatedUserMessage: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.paymentInstructions)
      ..writeByte(1)
      ..write(obj.telegramLink)
      ..writeByte(2)
      ..write(obj.accountNumber)
      ..writeByte(3)
      ..write(obj.subscriptionPlans)
      ..writeByte(4)
      ..write(obj.aboutUsText)
      ..writeByte(5)
      ..write(obj.deactivatedUserMessage);
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
