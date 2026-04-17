// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courier_shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourierShift {

@JsonKey(fromJson: safeInt) int get id; String get date;@JsonKey(name: 'start_time') String get startTime;@JsonKey(name: 'end_time') String get endTime;@JsonKey(name: 'zone_id') String? get zoneId; String get status;@JsonKey(name: 'guaranteed_bonus', fromJson: safeInt) int get guaranteedBonus;@JsonKey(name: 'earned_bonus', fromJson: safeInt) int get earnedBonus;@JsonKey(name: 'deliveries_completed', fromJson: safeInt) int get deliveriesCompleted;@JsonKey(name: 'violations_count', fromJson: safeInt) int get violationsCount;@JsonKey(name: 'actual_start_time') String? get actualStartTime;@JsonKey(name: 'actual_end_time') String? get actualEndTime;@JsonKey(name: 'started_at') String? get startedAt;@JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull) int? get remainingMinutes;@JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull) int? get calculatedBonus;@JsonKey(name: 'shift_type') String? get shiftType;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of CourierShift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierShiftCopyWith<CourierShift> get copyWith => _$CourierShiftCopyWithImpl<CourierShift>(this as CourierShift, _$identity);

  /// Serializes this CourierShift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierShift&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.status, status) || other.status == status)&&(identical(other.guaranteedBonus, guaranteedBonus) || other.guaranteedBonus == guaranteedBonus)&&(identical(other.earnedBonus, earnedBonus) || other.earnedBonus == earnedBonus)&&(identical(other.deliveriesCompleted, deliveriesCompleted) || other.deliveriesCompleted == deliveriesCompleted)&&(identical(other.violationsCount, violationsCount) || other.violationsCount == violationsCount)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&(identical(other.actualEndTime, actualEndTime) || other.actualEndTime == actualEndTime)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.calculatedBonus, calculatedBonus) || other.calculatedBonus == calculatedBonus)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,startTime,endTime,zoneId,status,guaranteedBonus,earnedBonus,deliveriesCompleted,violationsCount,actualStartTime,actualEndTime,startedAt,remainingMinutes,calculatedBonus,shiftType,createdAt);

@override
String toString() {
  return 'CourierShift(id: $id, date: $date, startTime: $startTime, endTime: $endTime, zoneId: $zoneId, status: $status, guaranteedBonus: $guaranteedBonus, earnedBonus: $earnedBonus, deliveriesCompleted: $deliveriesCompleted, violationsCount: $violationsCount, actualStartTime: $actualStartTime, actualEndTime: $actualEndTime, startedAt: $startedAt, remainingMinutes: $remainingMinutes, calculatedBonus: $calculatedBonus, shiftType: $shiftType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CourierShiftCopyWith<$Res>  {
  factory $CourierShiftCopyWith(CourierShift value, $Res Function(CourierShift) _then) = _$CourierShiftCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String date,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(name: 'zone_id') String? zoneId, String status,@JsonKey(name: 'guaranteed_bonus', fromJson: safeInt) int guaranteedBonus,@JsonKey(name: 'earned_bonus', fromJson: safeInt) int earnedBonus,@JsonKey(name: 'deliveries_completed', fromJson: safeInt) int deliveriesCompleted,@JsonKey(name: 'violations_count', fromJson: safeInt) int violationsCount,@JsonKey(name: 'actual_start_time') String? actualStartTime,@JsonKey(name: 'actual_end_time') String? actualEndTime,@JsonKey(name: 'started_at') String? startedAt,@JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull) int? remainingMinutes,@JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull) int? calculatedBonus,@JsonKey(name: 'shift_type') String? shiftType,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$CourierShiftCopyWithImpl<$Res>
    implements $CourierShiftCopyWith<$Res> {
  _$CourierShiftCopyWithImpl(this._self, this._then);

  final CourierShift _self;
  final $Res Function(CourierShift) _then;

/// Create a copy of CourierShift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? startTime = null,Object? endTime = null,Object? zoneId = freezed,Object? status = null,Object? guaranteedBonus = null,Object? earnedBonus = null,Object? deliveriesCompleted = null,Object? violationsCount = null,Object? actualStartTime = freezed,Object? actualEndTime = freezed,Object? startedAt = freezed,Object? remainingMinutes = freezed,Object? calculatedBonus = freezed,Object? shiftType = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,guaranteedBonus: null == guaranteedBonus ? _self.guaranteedBonus : guaranteedBonus // ignore: cast_nullable_to_non_nullable
as int,earnedBonus: null == earnedBonus ? _self.earnedBonus : earnedBonus // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,violationsCount: null == violationsCount ? _self.violationsCount : violationsCount // ignore: cast_nullable_to_non_nullable
as int,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualEndTime: freezed == actualEndTime ? _self.actualEndTime : actualEndTime // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,remainingMinutes: freezed == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int?,calculatedBonus: freezed == calculatedBonus ? _self.calculatedBonus : calculatedBonus // ignore: cast_nullable_to_non_nullable
as int?,shiftType: freezed == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CourierShift].
extension CourierShiftPatterns on CourierShift {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierShift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierShift() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierShift value)  $default,){
final _that = this;
switch (_that) {
case _CourierShift():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierShift value)?  $default,){
final _that = this;
switch (_that) {
case _CourierShift() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String date, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'zone_id')  String? zoneId,  String status, @JsonKey(name: 'guaranteed_bonus', fromJson: safeInt)  int guaranteedBonus, @JsonKey(name: 'earned_bonus', fromJson: safeInt)  int earnedBonus, @JsonKey(name: 'deliveries_completed', fromJson: safeInt)  int deliveriesCompleted, @JsonKey(name: 'violations_count', fromJson: safeInt)  int violationsCount, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'actual_end_time')  String? actualEndTime, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull)  int? remainingMinutes, @JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull)  int? calculatedBonus, @JsonKey(name: 'shift_type')  String? shiftType, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierShift() when $default != null:
return $default(_that.id,_that.date,_that.startTime,_that.endTime,_that.zoneId,_that.status,_that.guaranteedBonus,_that.earnedBonus,_that.deliveriesCompleted,_that.violationsCount,_that.actualStartTime,_that.actualEndTime,_that.startedAt,_that.remainingMinutes,_that.calculatedBonus,_that.shiftType,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String date, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'zone_id')  String? zoneId,  String status, @JsonKey(name: 'guaranteed_bonus', fromJson: safeInt)  int guaranteedBonus, @JsonKey(name: 'earned_bonus', fromJson: safeInt)  int earnedBonus, @JsonKey(name: 'deliveries_completed', fromJson: safeInt)  int deliveriesCompleted, @JsonKey(name: 'violations_count', fromJson: safeInt)  int violationsCount, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'actual_end_time')  String? actualEndTime, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull)  int? remainingMinutes, @JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull)  int? calculatedBonus, @JsonKey(name: 'shift_type')  String? shiftType, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CourierShift():
return $default(_that.id,_that.date,_that.startTime,_that.endTime,_that.zoneId,_that.status,_that.guaranteedBonus,_that.earnedBonus,_that.deliveriesCompleted,_that.violationsCount,_that.actualStartTime,_that.actualEndTime,_that.startedAt,_that.remainingMinutes,_that.calculatedBonus,_that.shiftType,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id,  String date, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(name: 'zone_id')  String? zoneId,  String status, @JsonKey(name: 'guaranteed_bonus', fromJson: safeInt)  int guaranteedBonus, @JsonKey(name: 'earned_bonus', fromJson: safeInt)  int earnedBonus, @JsonKey(name: 'deliveries_completed', fromJson: safeInt)  int deliveriesCompleted, @JsonKey(name: 'violations_count', fromJson: safeInt)  int violationsCount, @JsonKey(name: 'actual_start_time')  String? actualStartTime, @JsonKey(name: 'actual_end_time')  String? actualEndTime, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull)  int? remainingMinutes, @JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull)  int? calculatedBonus, @JsonKey(name: 'shift_type')  String? shiftType, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CourierShift() when $default != null:
return $default(_that.id,_that.date,_that.startTime,_that.endTime,_that.zoneId,_that.status,_that.guaranteedBonus,_that.earnedBonus,_that.deliveriesCompleted,_that.violationsCount,_that.actualStartTime,_that.actualEndTime,_that.startedAt,_that.remainingMinutes,_that.calculatedBonus,_that.shiftType,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourierShift implements CourierShift {
  const _CourierShift({@JsonKey(fromJson: safeInt) required this.id, required this.date, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') required this.endTime, @JsonKey(name: 'zone_id') this.zoneId, required this.status, @JsonKey(name: 'guaranteed_bonus', fromJson: safeInt) required this.guaranteedBonus, @JsonKey(name: 'earned_bonus', fromJson: safeInt) this.earnedBonus = 0, @JsonKey(name: 'deliveries_completed', fromJson: safeInt) this.deliveriesCompleted = 0, @JsonKey(name: 'violations_count', fromJson: safeInt) this.violationsCount = 0, @JsonKey(name: 'actual_start_time') this.actualStartTime, @JsonKey(name: 'actual_end_time') this.actualEndTime, @JsonKey(name: 'started_at') this.startedAt, @JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull) this.remainingMinutes, @JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull) this.calculatedBonus, @JsonKey(name: 'shift_type') this.shiftType, @JsonKey(name: 'created_at') this.createdAt});
  factory _CourierShift.fromJson(Map<String, dynamic> json) => _$CourierShiftFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override final  String date;
@override@JsonKey(name: 'start_time') final  String startTime;
@override@JsonKey(name: 'end_time') final  String endTime;
@override@JsonKey(name: 'zone_id') final  String? zoneId;
@override final  String status;
@override@JsonKey(name: 'guaranteed_bonus', fromJson: safeInt) final  int guaranteedBonus;
@override@JsonKey(name: 'earned_bonus', fromJson: safeInt) final  int earnedBonus;
@override@JsonKey(name: 'deliveries_completed', fromJson: safeInt) final  int deliveriesCompleted;
@override@JsonKey(name: 'violations_count', fromJson: safeInt) final  int violationsCount;
@override@JsonKey(name: 'actual_start_time') final  String? actualStartTime;
@override@JsonKey(name: 'actual_end_time') final  String? actualEndTime;
@override@JsonKey(name: 'started_at') final  String? startedAt;
@override@JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull) final  int? remainingMinutes;
@override@JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull) final  int? calculatedBonus;
@override@JsonKey(name: 'shift_type') final  String? shiftType;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of CourierShift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierShiftCopyWith<_CourierShift> get copyWith => __$CourierShiftCopyWithImpl<_CourierShift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourierShiftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierShift&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.zoneId, zoneId) || other.zoneId == zoneId)&&(identical(other.status, status) || other.status == status)&&(identical(other.guaranteedBonus, guaranteedBonus) || other.guaranteedBonus == guaranteedBonus)&&(identical(other.earnedBonus, earnedBonus) || other.earnedBonus == earnedBonus)&&(identical(other.deliveriesCompleted, deliveriesCompleted) || other.deliveriesCompleted == deliveriesCompleted)&&(identical(other.violationsCount, violationsCount) || other.violationsCount == violationsCount)&&(identical(other.actualStartTime, actualStartTime) || other.actualStartTime == actualStartTime)&&(identical(other.actualEndTime, actualEndTime) || other.actualEndTime == actualEndTime)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.calculatedBonus, calculatedBonus) || other.calculatedBonus == calculatedBonus)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,startTime,endTime,zoneId,status,guaranteedBonus,earnedBonus,deliveriesCompleted,violationsCount,actualStartTime,actualEndTime,startedAt,remainingMinutes,calculatedBonus,shiftType,createdAt);

@override
String toString() {
  return 'CourierShift(id: $id, date: $date, startTime: $startTime, endTime: $endTime, zoneId: $zoneId, status: $status, guaranteedBonus: $guaranteedBonus, earnedBonus: $earnedBonus, deliveriesCompleted: $deliveriesCompleted, violationsCount: $violationsCount, actualStartTime: $actualStartTime, actualEndTime: $actualEndTime, startedAt: $startedAt, remainingMinutes: $remainingMinutes, calculatedBonus: $calculatedBonus, shiftType: $shiftType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CourierShiftCopyWith<$Res> implements $CourierShiftCopyWith<$Res> {
  factory _$CourierShiftCopyWith(_CourierShift value, $Res Function(_CourierShift) _then) = __$CourierShiftCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String date,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(name: 'zone_id') String? zoneId, String status,@JsonKey(name: 'guaranteed_bonus', fromJson: safeInt) int guaranteedBonus,@JsonKey(name: 'earned_bonus', fromJson: safeInt) int earnedBonus,@JsonKey(name: 'deliveries_completed', fromJson: safeInt) int deliveriesCompleted,@JsonKey(name: 'violations_count', fromJson: safeInt) int violationsCount,@JsonKey(name: 'actual_start_time') String? actualStartTime,@JsonKey(name: 'actual_end_time') String? actualEndTime,@JsonKey(name: 'started_at') String? startedAt,@JsonKey(name: 'remaining_minutes', fromJson: safeIntOrNull) int? remainingMinutes,@JsonKey(name: 'calculated_bonus', fromJson: safeIntOrNull) int? calculatedBonus,@JsonKey(name: 'shift_type') String? shiftType,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$CourierShiftCopyWithImpl<$Res>
    implements _$CourierShiftCopyWith<$Res> {
  __$CourierShiftCopyWithImpl(this._self, this._then);

  final _CourierShift _self;
  final $Res Function(_CourierShift) _then;

/// Create a copy of CourierShift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? startTime = null,Object? endTime = null,Object? zoneId = freezed,Object? status = null,Object? guaranteedBonus = null,Object? earnedBonus = null,Object? deliveriesCompleted = null,Object? violationsCount = null,Object? actualStartTime = freezed,Object? actualEndTime = freezed,Object? startedAt = freezed,Object? remainingMinutes = freezed,Object? calculatedBonus = freezed,Object? shiftType = freezed,Object? createdAt = freezed,}) {
  return _then(_CourierShift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,zoneId: freezed == zoneId ? _self.zoneId : zoneId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,guaranteedBonus: null == guaranteedBonus ? _self.guaranteedBonus : guaranteedBonus // ignore: cast_nullable_to_non_nullable
as int,earnedBonus: null == earnedBonus ? _self.earnedBonus : earnedBonus // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,violationsCount: null == violationsCount ? _self.violationsCount : violationsCount // ignore: cast_nullable_to_non_nullable
as int,actualStartTime: freezed == actualStartTime ? _self.actualStartTime : actualStartTime // ignore: cast_nullable_to_non_nullable
as String?,actualEndTime: freezed == actualEndTime ? _self.actualEndTime : actualEndTime // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,remainingMinutes: freezed == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int?,calculatedBonus: freezed == calculatedBonus ? _self.calculatedBonus : calculatedBonus // ignore: cast_nullable_to_non_nullable
as int?,shiftType: freezed == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ShiftSlot {

@JsonKey(fromJson: safeInt) int get id;@JsonKey(name: 'shift_type') String get shiftType;@JsonKey(name: 'shift_label') String get shiftLabel;@JsonKey(name: 'start_time') String get startTime;@JsonKey(name: 'end_time') String get endTime;@JsonKey(fromJson: safeInt) int get capacity;@JsonKey(name: 'booked_count', fromJson: safeInt) int get bookedCount;@JsonKey(name: 'spots_remaining', fromJson: safeInt) int get spotsRemaining;@JsonKey(name: 'bonus_amount', fromJson: safeInt) int get bonusAmount; String get status;
/// Create a copy of ShiftSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftSlotCopyWith<ShiftSlot> get copyWith => _$ShiftSlotCopyWithImpl<ShiftSlot>(this as ShiftSlot, _$identity);

  /// Serializes this ShiftSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.shiftLabel, shiftLabel) || other.shiftLabel == shiftLabel)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.bookedCount, bookedCount) || other.bookedCount == bookedCount)&&(identical(other.spotsRemaining, spotsRemaining) || other.spotsRemaining == spotsRemaining)&&(identical(other.bonusAmount, bonusAmount) || other.bonusAmount == bonusAmount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shiftType,shiftLabel,startTime,endTime,capacity,bookedCount,spotsRemaining,bonusAmount,status);

@override
String toString() {
  return 'ShiftSlot(id: $id, shiftType: $shiftType, shiftLabel: $shiftLabel, startTime: $startTime, endTime: $endTime, capacity: $capacity, bookedCount: $bookedCount, spotsRemaining: $spotsRemaining, bonusAmount: $bonusAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class $ShiftSlotCopyWith<$Res>  {
  factory $ShiftSlotCopyWith(ShiftSlot value, $Res Function(ShiftSlot) _then) = _$ShiftSlotCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id,@JsonKey(name: 'shift_type') String shiftType,@JsonKey(name: 'shift_label') String shiftLabel,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(fromJson: safeInt) int capacity,@JsonKey(name: 'booked_count', fromJson: safeInt) int bookedCount,@JsonKey(name: 'spots_remaining', fromJson: safeInt) int spotsRemaining,@JsonKey(name: 'bonus_amount', fromJson: safeInt) int bonusAmount, String status
});




}
/// @nodoc
class _$ShiftSlotCopyWithImpl<$Res>
    implements $ShiftSlotCopyWith<$Res> {
  _$ShiftSlotCopyWithImpl(this._self, this._then);

  final ShiftSlot _self;
  final $Res Function(ShiftSlot) _then;

/// Create a copy of ShiftSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shiftType = null,Object? shiftLabel = null,Object? startTime = null,Object? endTime = null,Object? capacity = null,Object? bookedCount = null,Object? spotsRemaining = null,Object? bonusAmount = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shiftType: null == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as String,shiftLabel: null == shiftLabel ? _self.shiftLabel : shiftLabel // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,bookedCount: null == bookedCount ? _self.bookedCount : bookedCount // ignore: cast_nullable_to_non_nullable
as int,spotsRemaining: null == spotsRemaining ? _self.spotsRemaining : spotsRemaining // ignore: cast_nullable_to_non_nullable
as int,bonusAmount: null == bonusAmount ? _self.bonusAmount : bonusAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftSlot].
extension ShiftSlotPatterns on ShiftSlot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftSlot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftSlot value)  $default,){
final _that = this;
switch (_that) {
case _ShiftSlot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftSlot value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftSlot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'shift_type')  String shiftType, @JsonKey(name: 'shift_label')  String shiftLabel, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(fromJson: safeInt)  int capacity, @JsonKey(name: 'booked_count', fromJson: safeInt)  int bookedCount, @JsonKey(name: 'spots_remaining', fromJson: safeInt)  int spotsRemaining, @JsonKey(name: 'bonus_amount', fromJson: safeInt)  int bonusAmount,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftSlot() when $default != null:
return $default(_that.id,_that.shiftType,_that.shiftLabel,_that.startTime,_that.endTime,_that.capacity,_that.bookedCount,_that.spotsRemaining,_that.bonusAmount,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'shift_type')  String shiftType, @JsonKey(name: 'shift_label')  String shiftLabel, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(fromJson: safeInt)  int capacity, @JsonKey(name: 'booked_count', fromJson: safeInt)  int bookedCount, @JsonKey(name: 'spots_remaining', fromJson: safeInt)  int spotsRemaining, @JsonKey(name: 'bonus_amount', fromJson: safeInt)  int bonusAmount,  String status)  $default,) {final _that = this;
switch (_that) {
case _ShiftSlot():
return $default(_that.id,_that.shiftType,_that.shiftLabel,_that.startTime,_that.endTime,_that.capacity,_that.bookedCount,_that.spotsRemaining,_that.bonusAmount,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'shift_type')  String shiftType, @JsonKey(name: 'shift_label')  String shiftLabel, @JsonKey(name: 'start_time')  String startTime, @JsonKey(name: 'end_time')  String endTime, @JsonKey(fromJson: safeInt)  int capacity, @JsonKey(name: 'booked_count', fromJson: safeInt)  int bookedCount, @JsonKey(name: 'spots_remaining', fromJson: safeInt)  int spotsRemaining, @JsonKey(name: 'bonus_amount', fromJson: safeInt)  int bonusAmount,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ShiftSlot() when $default != null:
return $default(_that.id,_that.shiftType,_that.shiftLabel,_that.startTime,_that.endTime,_that.capacity,_that.bookedCount,_that.spotsRemaining,_that.bonusAmount,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftSlot implements ShiftSlot {
  const _ShiftSlot({@JsonKey(fromJson: safeInt) required this.id, @JsonKey(name: 'shift_type') required this.shiftType, @JsonKey(name: 'shift_label') required this.shiftLabel, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') required this.endTime, @JsonKey(fromJson: safeInt) required this.capacity, @JsonKey(name: 'booked_count', fromJson: safeInt) this.bookedCount = 0, @JsonKey(name: 'spots_remaining', fromJson: safeInt) this.spotsRemaining = 0, @JsonKey(name: 'bonus_amount', fromJson: safeInt) this.bonusAmount = 0, required this.status});
  factory _ShiftSlot.fromJson(Map<String, dynamic> json) => _$ShiftSlotFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override@JsonKey(name: 'shift_type') final  String shiftType;
@override@JsonKey(name: 'shift_label') final  String shiftLabel;
@override@JsonKey(name: 'start_time') final  String startTime;
@override@JsonKey(name: 'end_time') final  String endTime;
@override@JsonKey(fromJson: safeInt) final  int capacity;
@override@JsonKey(name: 'booked_count', fromJson: safeInt) final  int bookedCount;
@override@JsonKey(name: 'spots_remaining', fromJson: safeInt) final  int spotsRemaining;
@override@JsonKey(name: 'bonus_amount', fromJson: safeInt) final  int bonusAmount;
@override final  String status;

/// Create a copy of ShiftSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftSlotCopyWith<_ShiftSlot> get copyWith => __$ShiftSlotCopyWithImpl<_ShiftSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.shiftLabel, shiftLabel) || other.shiftLabel == shiftLabel)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.bookedCount, bookedCount) || other.bookedCount == bookedCount)&&(identical(other.spotsRemaining, spotsRemaining) || other.spotsRemaining == spotsRemaining)&&(identical(other.bonusAmount, bonusAmount) || other.bonusAmount == bonusAmount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shiftType,shiftLabel,startTime,endTime,capacity,bookedCount,spotsRemaining,bonusAmount,status);

@override
String toString() {
  return 'ShiftSlot(id: $id, shiftType: $shiftType, shiftLabel: $shiftLabel, startTime: $startTime, endTime: $endTime, capacity: $capacity, bookedCount: $bookedCount, spotsRemaining: $spotsRemaining, bonusAmount: $bonusAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ShiftSlotCopyWith<$Res> implements $ShiftSlotCopyWith<$Res> {
  factory _$ShiftSlotCopyWith(_ShiftSlot value, $Res Function(_ShiftSlot) _then) = __$ShiftSlotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id,@JsonKey(name: 'shift_type') String shiftType,@JsonKey(name: 'shift_label') String shiftLabel,@JsonKey(name: 'start_time') String startTime,@JsonKey(name: 'end_time') String endTime,@JsonKey(fromJson: safeInt) int capacity,@JsonKey(name: 'booked_count', fromJson: safeInt) int bookedCount,@JsonKey(name: 'spots_remaining', fromJson: safeInt) int spotsRemaining,@JsonKey(name: 'bonus_amount', fromJson: safeInt) int bonusAmount, String status
});




}
/// @nodoc
class __$ShiftSlotCopyWithImpl<$Res>
    implements _$ShiftSlotCopyWith<$Res> {
  __$ShiftSlotCopyWithImpl(this._self, this._then);

  final _ShiftSlot _self;
  final $Res Function(_ShiftSlot) _then;

/// Create a copy of ShiftSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shiftType = null,Object? shiftLabel = null,Object? startTime = null,Object? endTime = null,Object? capacity = null,Object? bookedCount = null,Object? spotsRemaining = null,Object? bonusAmount = null,Object? status = null,}) {
  return _then(_ShiftSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shiftType: null == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as String,shiftLabel: null == shiftLabel ? _self.shiftLabel : shiftLabel // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,bookedCount: null == bookedCount ? _self.bookedCount : bookedCount // ignore: cast_nullable_to_non_nullable
as int,spotsRemaining: null == spotsRemaining ? _self.spotsRemaining : spotsRemaining // ignore: cast_nullable_to_non_nullable
as int,bonusAmount: null == bonusAmount ? _self.bonusAmount : bonusAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DaySlots {

 String get date; List<ShiftSlot> get slots;
/// Create a copy of DaySlots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DaySlotsCopyWith<DaySlots> get copyWith => _$DaySlotsCopyWithImpl<DaySlots>(this as DaySlots, _$identity);

  /// Serializes this DaySlots to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DaySlots&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.slots, slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(slots));

@override
String toString() {
  return 'DaySlots(date: $date, slots: $slots)';
}


}

/// @nodoc
abstract mixin class $DaySlotsCopyWith<$Res>  {
  factory $DaySlotsCopyWith(DaySlots value, $Res Function(DaySlots) _then) = _$DaySlotsCopyWithImpl;
@useResult
$Res call({
 String date, List<ShiftSlot> slots
});




}
/// @nodoc
class _$DaySlotsCopyWithImpl<$Res>
    implements $DaySlotsCopyWith<$Res> {
  _$DaySlotsCopyWithImpl(this._self, this._then);

  final DaySlots _self;
  final $Res Function(DaySlots) _then;

/// Create a copy of DaySlots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? slots = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<ShiftSlot>,
  ));
}

}


/// Adds pattern-matching-related methods to [DaySlots].
extension DaySlotsPatterns on DaySlots {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DaySlots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DaySlots() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DaySlots value)  $default,){
final _that = this;
switch (_that) {
case _DaySlots():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DaySlots value)?  $default,){
final _that = this;
switch (_that) {
case _DaySlots() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  List<ShiftSlot> slots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DaySlots() when $default != null:
return $default(_that.date,_that.slots);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  List<ShiftSlot> slots)  $default,) {final _that = this;
switch (_that) {
case _DaySlots():
return $default(_that.date,_that.slots);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  List<ShiftSlot> slots)?  $default,) {final _that = this;
switch (_that) {
case _DaySlots() when $default != null:
return $default(_that.date,_that.slots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DaySlots implements DaySlots {
  const _DaySlots({required this.date, required final  List<ShiftSlot> slots}): _slots = slots;
  factory _DaySlots.fromJson(Map<String, dynamic> json) => _$DaySlotsFromJson(json);

@override final  String date;
 final  List<ShiftSlot> _slots;
@override List<ShiftSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}


/// Create a copy of DaySlots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DaySlotsCopyWith<_DaySlots> get copyWith => __$DaySlotsCopyWithImpl<_DaySlots>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DaySlotsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DaySlots&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._slots, _slots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_slots));

@override
String toString() {
  return 'DaySlots(date: $date, slots: $slots)';
}


}

/// @nodoc
abstract mixin class _$DaySlotsCopyWith<$Res> implements $DaySlotsCopyWith<$Res> {
  factory _$DaySlotsCopyWith(_DaySlots value, $Res Function(_DaySlots) _then) = __$DaySlotsCopyWithImpl;
@override @useResult
$Res call({
 String date, List<ShiftSlot> slots
});




}
/// @nodoc
class __$DaySlotsCopyWithImpl<$Res>
    implements _$DaySlotsCopyWith<$Res> {
  __$DaySlotsCopyWithImpl(this._self, this._then);

  final _DaySlots _self;
  final $Res Function(_DaySlots) _then;

/// Create a copy of DaySlots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? slots = null,}) {
  return _then(_DaySlots(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<ShiftSlot>,
  ));
}


}

// dart format on
