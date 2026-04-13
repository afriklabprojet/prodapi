import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'courier_shift.freezed.dart';
part 'courier_shift.g.dart';

/// Créneau de travail réservé par le livreur.
@freezed
abstract class CourierShift with _$CourierShift {
  const factory CourierShift({
    @JsonKey(fromJson: safeInt) required int id,
    required String date,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'zone_id') String? zoneId,
    required String status,
    @JsonKey(name: 'guaranteed_bonus', fromJson: safeInt)
    required int guaranteedBonus,
    @JsonKey(name: 'earned_bonus', fromJson: safeInt)
    @Default(0)
    int earnedBonus,
    @JsonKey(name: 'deliveries_completed', fromJson: safeInt)
    @Default(0)
    int deliveriesCompleted,
    @JsonKey(name: 'violations_count', fromJson: safeInt)
    @Default(0)
    int violationsCount,
    @JsonKey(name: 'actual_start_time') String? actualStartTime,
    @JsonKey(name: 'actual_end_time') String? actualEndTime,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull)
    int? remainingMinutes,
    @JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull)
    int? calculatedBonus,
    @JsonKey(name: 'shift_type') String? shiftType,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _CourierShift;

  factory CourierShift.fromJson(Map<String, dynamic> json) =>
      _$CourierShiftFromJson(json);
}

/// Créneau disponible à la réservation.
@freezed
abstract class ShiftSlot with _$ShiftSlot {
  const factory ShiftSlot({
    @JsonKey(fromJson: safeInt) required int id,
    @JsonKey(name: 'shift_type') required String shiftType,
    @JsonKey(name: 'shift_label') required String shiftLabel,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(fromJson: safeInt) required int capacity,
    @JsonKey(name: 'booked_count', fromJson: safeInt)
    @Default(0)
    int bookedCount,
    @JsonKey(name: 'spots_remaining', fromJson: safeInt)
    @Default(0)
    int spotsRemaining,
    @JsonKey(name: 'bonus_amount', fromJson: safeInt)
    @Default(0)
    int bonusAmount,
    required String status,
  }) = _ShiftSlot;

  factory ShiftSlot.fromJson(Map<String, dynamic> json) =>
      _$ShiftSlotFromJson(json);
}

/// Slots groupés par date (réponse API).
@freezed
abstract class DaySlots with _$DaySlots {
  const factory DaySlots({
    required String date,
    required List<ShiftSlot> slots,
  }) = _DaySlots;

  factory DaySlots.fromJson(Map<String, dynamic> json) =>
      _$DaySlotsFromJson(json);
}

/// Statuts d'un shift.
class ShiftStatus {
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';

  static String label(String status) => switch (status) {
    confirmed => 'Confirmé',
    inProgress => 'En cours',
    completed => 'Terminé',
    cancelled => 'Annulé',
    noShow => 'Absent',
    _ => status,
  };

  static bool isActive(String status) =>
      status == confirmed || status == inProgress;
}

/// Types de shift avec icônes et couleurs.
class ShiftType {
  static const Map<String, String> labels = {
    'morning': 'Matin',
    'lunch': 'Déjeuner',
    'afternoon': 'Après-midi',
    'dinner': 'Dîner',
    'night': 'Nuit',
  };

  static const Map<String, String> icons = {
    'morning': '🌅',
    'lunch': '☀️',
    'afternoon': '🌤️',
    'dinner': '🌆',
    'night': '🌙',
  };
}
