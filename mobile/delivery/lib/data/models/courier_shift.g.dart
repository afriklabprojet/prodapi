// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourierShift _$CourierShiftFromJson(Map<String, dynamic> json) =>
    _CourierShift(
      id: safeInt(json['id']),
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      zoneId: json['zone_id'] as String?,
      status: json['status'] as String,
      guaranteedBonus: safeInt(json['guaranteed_bonus']),
      earnedBonus: json['earned_bonus'] == null
          ? 0
          : safeInt(json['earned_bonus']),
      deliveriesCompleted: json['deliveries_completed'] == null
          ? 0
          : safeInt(json['deliveries_completed']),
      violationsCount: json['violations_count'] == null
          ? 0
          : safeInt(json['violations_count']),
      actualStartTime: json['actual_start_time'] as String?,
      actualEndTime: json['actual_end_time'] as String?,
      startedAt: json['started_at'] as String?,
      remainingMinutes: safeIntOrNull(json['remaining_minutes']),
      calculatedBonus: safeIntOrNull(json['calculated_bonus']),
      shiftType: json['shift_type'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$CourierShiftToJson(_CourierShift instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'zone_id': instance.zoneId,
      'status': instance.status,
      'guaranteed_bonus': instance.guaranteedBonus,
      'earned_bonus': instance.earnedBonus,
      'deliveries_completed': instance.deliveriesCompleted,
      'violations_count': instance.violationsCount,
      'actual_start_time': instance.actualStartTime,
      'actual_end_time': instance.actualEndTime,
      'started_at': instance.startedAt,
      'remaining_minutes': instance.remainingMinutes,
      'calculated_bonus': instance.calculatedBonus,
      'shift_type': instance.shiftType,
      'created_at': instance.createdAt,
    };

_ShiftSlot _$ShiftSlotFromJson(Map<String, dynamic> json) => _ShiftSlot(
  id: safeInt(json['id']),
  shiftType: json['shift_type'] as String,
  shiftLabel: json['shift_label'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  capacity: safeInt(json['capacity']),
  bookedCount: json['booked_count'] == null ? 0 : safeInt(json['booked_count']),
  spotsRemaining: json['spots_remaining'] == null
      ? 0
      : safeInt(json['spots_remaining']),
  bonusAmount: json['bonus_amount'] == null ? 0 : safeInt(json['bonus_amount']),
  status: json['status'] as String,
);

Map<String, dynamic> _$ShiftSlotToJson(_ShiftSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shift_type': instance.shiftType,
      'shift_label': instance.shiftLabel,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'capacity': instance.capacity,
      'booked_count': instance.bookedCount,
      'spots_remaining': instance.spotsRemaining,
      'bonus_amount': instance.bonusAmount,
      'status': instance.status,
    };

_DaySlots _$DaySlotsFromJson(Map<String, dynamic> json) => _DaySlots(
  date: json['date'] as String,
  slots: (json['slots'] as List<dynamic>)
      .map((e) => ShiftSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DaySlotsToJson(_DaySlots instance) => <String, dynamic>{
  'date': instance.date,
  'slots': instance.slots,
};
