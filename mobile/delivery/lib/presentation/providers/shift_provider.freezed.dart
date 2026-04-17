// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShiftState {

 List<CourierShift> get myShifts; List<DaySlots> get availableSlots; CourierShift? get activeShift; bool get isLoading; bool get isSlotsLoading; bool get isBooking; String? get error; int? get bookingSlotId;
/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftStateCopyWith<ShiftState> get copyWith => _$ShiftStateCopyWithImpl<ShiftState>(this as ShiftState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftState&&const DeepCollectionEquality().equals(other.myShifts, myShifts)&&const DeepCollectionEquality().equals(other.availableSlots, availableSlots)&&(identical(other.activeShift, activeShift) || other.activeShift == activeShift)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSlotsLoading, isSlotsLoading) || other.isSlotsLoading == isSlotsLoading)&&(identical(other.isBooking, isBooking) || other.isBooking == isBooking)&&(identical(other.error, error) || other.error == error)&&(identical(other.bookingSlotId, bookingSlotId) || other.bookingSlotId == bookingSlotId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(myShifts),const DeepCollectionEquality().hash(availableSlots),activeShift,isLoading,isSlotsLoading,isBooking,error,bookingSlotId);

@override
String toString() {
  return 'ShiftState(myShifts: $myShifts, availableSlots: $availableSlots, activeShift: $activeShift, isLoading: $isLoading, isSlotsLoading: $isSlotsLoading, isBooking: $isBooking, error: $error, bookingSlotId: $bookingSlotId)';
}


}

/// @nodoc
abstract mixin class $ShiftStateCopyWith<$Res>  {
  factory $ShiftStateCopyWith(ShiftState value, $Res Function(ShiftState) _then) = _$ShiftStateCopyWithImpl;
@useResult
$Res call({
 List<CourierShift> myShifts, List<DaySlots> availableSlots, CourierShift? activeShift, bool isLoading, bool isSlotsLoading, bool isBooking, String? error, int? bookingSlotId
});


$CourierShiftCopyWith<$Res>? get activeShift;

}
/// @nodoc
class _$ShiftStateCopyWithImpl<$Res>
    implements $ShiftStateCopyWith<$Res> {
  _$ShiftStateCopyWithImpl(this._self, this._then);

  final ShiftState _self;
  final $Res Function(ShiftState) _then;

/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? myShifts = null,Object? availableSlots = null,Object? activeShift = freezed,Object? isLoading = null,Object? isSlotsLoading = null,Object? isBooking = null,Object? error = freezed,Object? bookingSlotId = freezed,}) {
  return _then(_self.copyWith(
myShifts: null == myShifts ? _self.myShifts : myShifts // ignore: cast_nullable_to_non_nullable
as List<CourierShift>,availableSlots: null == availableSlots ? _self.availableSlots : availableSlots // ignore: cast_nullable_to_non_nullable
as List<DaySlots>,activeShift: freezed == activeShift ? _self.activeShift : activeShift // ignore: cast_nullable_to_non_nullable
as CourierShift?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSlotsLoading: null == isSlotsLoading ? _self.isSlotsLoading : isSlotsLoading // ignore: cast_nullable_to_non_nullable
as bool,isBooking: null == isBooking ? _self.isBooking : isBooking // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,bookingSlotId: freezed == bookingSlotId ? _self.bookingSlotId : bookingSlotId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourierShiftCopyWith<$Res>? get activeShift {
    if (_self.activeShift == null) {
    return null;
  }

  return $CourierShiftCopyWith<$Res>(_self.activeShift!, (value) {
    return _then(_self.copyWith(activeShift: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShiftState].
extension ShiftStatePatterns on ShiftState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftState value)  $default,){
final _that = this;
switch (_that) {
case _ShiftState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftState value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CourierShift> myShifts,  List<DaySlots> availableSlots,  CourierShift? activeShift,  bool isLoading,  bool isSlotsLoading,  bool isBooking,  String? error,  int? bookingSlotId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftState() when $default != null:
return $default(_that.myShifts,_that.availableSlots,_that.activeShift,_that.isLoading,_that.isSlotsLoading,_that.isBooking,_that.error,_that.bookingSlotId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CourierShift> myShifts,  List<DaySlots> availableSlots,  CourierShift? activeShift,  bool isLoading,  bool isSlotsLoading,  bool isBooking,  String? error,  int? bookingSlotId)  $default,) {final _that = this;
switch (_that) {
case _ShiftState():
return $default(_that.myShifts,_that.availableSlots,_that.activeShift,_that.isLoading,_that.isSlotsLoading,_that.isBooking,_that.error,_that.bookingSlotId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CourierShift> myShifts,  List<DaySlots> availableSlots,  CourierShift? activeShift,  bool isLoading,  bool isSlotsLoading,  bool isBooking,  String? error,  int? bookingSlotId)?  $default,) {final _that = this;
switch (_that) {
case _ShiftState() when $default != null:
return $default(_that.myShifts,_that.availableSlots,_that.activeShift,_that.isLoading,_that.isSlotsLoading,_that.isBooking,_that.error,_that.bookingSlotId);case _:
  return null;

}
}

}

/// @nodoc


class _ShiftState implements ShiftState {
  const _ShiftState({final  List<CourierShift> myShifts = const [], final  List<DaySlots> availableSlots = const [], this.activeShift, this.isLoading = false, this.isSlotsLoading = false, this.isBooking = false, this.error, this.bookingSlotId}): _myShifts = myShifts,_availableSlots = availableSlots;
  

 final  List<CourierShift> _myShifts;
@override@JsonKey() List<CourierShift> get myShifts {
  if (_myShifts is EqualUnmodifiableListView) return _myShifts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_myShifts);
}

 final  List<DaySlots> _availableSlots;
@override@JsonKey() List<DaySlots> get availableSlots {
  if (_availableSlots is EqualUnmodifiableListView) return _availableSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableSlots);
}

@override final  CourierShift? activeShift;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSlotsLoading;
@override@JsonKey() final  bool isBooking;
@override final  String? error;
@override final  int? bookingSlotId;

/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftStateCopyWith<_ShiftState> get copyWith => __$ShiftStateCopyWithImpl<_ShiftState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftState&&const DeepCollectionEquality().equals(other._myShifts, _myShifts)&&const DeepCollectionEquality().equals(other._availableSlots, _availableSlots)&&(identical(other.activeShift, activeShift) || other.activeShift == activeShift)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSlotsLoading, isSlotsLoading) || other.isSlotsLoading == isSlotsLoading)&&(identical(other.isBooking, isBooking) || other.isBooking == isBooking)&&(identical(other.error, error) || other.error == error)&&(identical(other.bookingSlotId, bookingSlotId) || other.bookingSlotId == bookingSlotId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_myShifts),const DeepCollectionEquality().hash(_availableSlots),activeShift,isLoading,isSlotsLoading,isBooking,error,bookingSlotId);

@override
String toString() {
  return 'ShiftState(myShifts: $myShifts, availableSlots: $availableSlots, activeShift: $activeShift, isLoading: $isLoading, isSlotsLoading: $isSlotsLoading, isBooking: $isBooking, error: $error, bookingSlotId: $bookingSlotId)';
}


}

/// @nodoc
abstract mixin class _$ShiftStateCopyWith<$Res> implements $ShiftStateCopyWith<$Res> {
  factory _$ShiftStateCopyWith(_ShiftState value, $Res Function(_ShiftState) _then) = __$ShiftStateCopyWithImpl;
@override @useResult
$Res call({
 List<CourierShift> myShifts, List<DaySlots> availableSlots, CourierShift? activeShift, bool isLoading, bool isSlotsLoading, bool isBooking, String? error, int? bookingSlotId
});


@override $CourierShiftCopyWith<$Res>? get activeShift;

}
/// @nodoc
class __$ShiftStateCopyWithImpl<$Res>
    implements _$ShiftStateCopyWith<$Res> {
  __$ShiftStateCopyWithImpl(this._self, this._then);

  final _ShiftState _self;
  final $Res Function(_ShiftState) _then;

/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? myShifts = null,Object? availableSlots = null,Object? activeShift = freezed,Object? isLoading = null,Object? isSlotsLoading = null,Object? isBooking = null,Object? error = freezed,Object? bookingSlotId = freezed,}) {
  return _then(_ShiftState(
myShifts: null == myShifts ? _self._myShifts : myShifts // ignore: cast_nullable_to_non_nullable
as List<CourierShift>,availableSlots: null == availableSlots ? _self._availableSlots : availableSlots // ignore: cast_nullable_to_non_nullable
as List<DaySlots>,activeShift: freezed == activeShift ? _self.activeShift : activeShift // ignore: cast_nullable_to_non_nullable
as CourierShift?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSlotsLoading: null == isSlotsLoading ? _self.isSlotsLoading : isSlotsLoading // ignore: cast_nullable_to_non_nullable
as bool,isBooking: null == isBooking ? _self.isBooking : isBooking // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,bookingSlotId: freezed == bookingSlotId ? _self.bookingSlotId : bookingSlotId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ShiftState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourierShiftCopyWith<$Res>? get activeShift {
    if (_self.activeShift == null) {
    return null;
  }

  return $CourierShiftCopyWith<$Res>(_self.activeShift!, (value) {
    return _then(_self.copyWith(activeShift: value));
  });
}
}

// dart format on
