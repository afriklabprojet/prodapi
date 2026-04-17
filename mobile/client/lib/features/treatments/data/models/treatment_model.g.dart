// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentModelAdapter extends TypeAdapter<TreatmentModel> {
  @override
  final int typeId = 10;

  @override
  TreatmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreatmentModel(
      id: fields[0] as String,
      productId: fields[1] as int,
      productName: fields[2] as String,
      productImage: fields[3] as String?,
      dosage: fields[4] as String?,
      frequency: fields[5] as String?,
      quantityPerRenewal: fields[6] as int?,
      renewalPeriodDays: fields[7] as int,
      nextRenewalDate: fields[8] as DateTime?,
      lastOrderedAt: fields[9] as DateTime?,
      reminderEnabled: fields[10] as bool,
      reminderDaysBefore: fields[11] as int,
      notes: fields[12] as String?,
      isActive: fields[13] as bool,
      createdAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TreatmentModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.productImage)
      ..writeByte(4)
      ..write(obj.dosage)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.quantityPerRenewal)
      ..writeByte(7)
      ..write(obj.renewalPeriodDays)
      ..writeByte(8)
      ..write(obj.nextRenewalDate)
      ..writeByte(9)
      ..write(obj.lastOrderedAt)
      ..writeByte(10)
      ..write(obj.reminderEnabled)
      ..writeByte(11)
      ..write(obj.reminderDaysBefore)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
