// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courier_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourierProfile {

@JsonKey(fromJson: safeInt) int get id; String get name; String get email; String? get avatar; String get status;@JsonKey(name: 'vehicle_type') String get vehicleType;@JsonKey(name: 'plate_number', defaultValue: '') String get plateNumber;@JsonKey(fromJson: safeDouble) double get rating;@JsonKey(name: 'completed_deliveries', fromJson: safeInt) int get completedDeliveries;@JsonKey(fromJson: safeDouble) double get earnings;@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String get kycStatus; List<ProfileBadge> get badges;@JsonKey(name: 'active_challenges') List<ProfileChallenge> get activeChallenges;
/// Create a copy of CourierProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierProfileCopyWith<CourierProfile> get copyWith => _$CourierProfileCopyWithImpl<CourierProfile>(this as CourierProfile, _$identity);

  /// Serializes this CourierProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries)&&(identical(other.earnings, earnings) || other.earnings == earnings)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&const DeepCollectionEquality().equals(other.badges, badges)&&const DeepCollectionEquality().equals(other.activeChallenges, activeChallenges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,avatar,status,vehicleType,plateNumber,rating,completedDeliveries,earnings,kycStatus,const DeepCollectionEquality().hash(badges),const DeepCollectionEquality().hash(activeChallenges));

@override
String toString() {
  return 'CourierProfile(id: $id, name: $name, email: $email, avatar: $avatar, status: $status, vehicleType: $vehicleType, plateNumber: $plateNumber, rating: $rating, completedDeliveries: $completedDeliveries, earnings: $earnings, kycStatus: $kycStatus, badges: $badges, activeChallenges: $activeChallenges)';
}


}

/// @nodoc
abstract mixin class $CourierProfileCopyWith<$Res>  {
  factory $CourierProfileCopyWith(CourierProfile value, $Res Function(CourierProfile) _then) = _$CourierProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String name, String email, String? avatar, String status,@JsonKey(name: 'vehicle_type') String vehicleType,@JsonKey(name: 'plate_number', defaultValue: '') String plateNumber,@JsonKey(fromJson: safeDouble) double rating,@JsonKey(name: 'completed_deliveries', fromJson: safeInt) int completedDeliveries,@JsonKey(fromJson: safeDouble) double earnings,@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String kycStatus, List<ProfileBadge> badges,@JsonKey(name: 'active_challenges') List<ProfileChallenge> activeChallenges
});




}
/// @nodoc
class _$CourierProfileCopyWithImpl<$Res>
    implements $CourierProfileCopyWith<$Res> {
  _$CourierProfileCopyWithImpl(this._self, this._then);

  final CourierProfile _self;
  final $Res Function(CourierProfile) _then;

/// Create a copy of CourierProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? avatar = freezed,Object? status = null,Object? vehicleType = null,Object? plateNumber = null,Object? rating = null,Object? completedDeliveries = null,Object? earnings = null,Object? kycStatus = null,Object? badges = null,Object? activeChallenges = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<ProfileBadge>,activeChallenges: null == activeChallenges ? _self.activeChallenges : activeChallenges // ignore: cast_nullable_to_non_nullable
as List<ProfileChallenge>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourierProfile].
extension CourierProfilePatterns on CourierProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierProfile value)  $default,){
final _that = this;
switch (_that) {
case _CourierProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierProfile value)?  $default,){
final _that = this;
switch (_that) {
case _CourierProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String email,  String? avatar,  String status, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'plate_number', defaultValue: '')  String plateNumber, @JsonKey(fromJson: safeDouble)  double rating, @JsonKey(name: 'completed_deliveries', fromJson: safeInt)  int completedDeliveries, @JsonKey(fromJson: safeDouble)  double earnings, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String kycStatus,  List<ProfileBadge> badges, @JsonKey(name: 'active_challenges')  List<ProfileChallenge> activeChallenges)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierProfile() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.avatar,_that.status,_that.vehicleType,_that.plateNumber,_that.rating,_that.completedDeliveries,_that.earnings,_that.kycStatus,_that.badges,_that.activeChallenges);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String email,  String? avatar,  String status, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'plate_number', defaultValue: '')  String plateNumber, @JsonKey(fromJson: safeDouble)  double rating, @JsonKey(name: 'completed_deliveries', fromJson: safeInt)  int completedDeliveries, @JsonKey(fromJson: safeDouble)  double earnings, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String kycStatus,  List<ProfileBadge> badges, @JsonKey(name: 'active_challenges')  List<ProfileChallenge> activeChallenges)  $default,) {final _that = this;
switch (_that) {
case _CourierProfile():
return $default(_that.id,_that.name,_that.email,_that.avatar,_that.status,_that.vehicleType,_that.plateNumber,_that.rating,_that.completedDeliveries,_that.earnings,_that.kycStatus,_that.badges,_that.activeChallenges);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String email,  String? avatar,  String status, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'plate_number', defaultValue: '')  String plateNumber, @JsonKey(fromJson: safeDouble)  double rating, @JsonKey(name: 'completed_deliveries', fromJson: safeInt)  int completedDeliveries, @JsonKey(fromJson: safeDouble)  double earnings, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String kycStatus,  List<ProfileBadge> badges, @JsonKey(name: 'active_challenges')  List<ProfileChallenge> activeChallenges)?  $default,) {final _that = this;
switch (_that) {
case _CourierProfile() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.avatar,_that.status,_that.vehicleType,_that.plateNumber,_that.rating,_that.completedDeliveries,_that.earnings,_that.kycStatus,_that.badges,_that.activeChallenges);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourierProfile implements CourierProfile {
  const _CourierProfile({@JsonKey(fromJson: safeInt) required this.id, required this.name, required this.email, this.avatar, required this.status, @JsonKey(name: 'vehicle_type') required this.vehicleType, @JsonKey(name: 'plate_number', defaultValue: '') required this.plateNumber, @JsonKey(fromJson: safeDouble) required this.rating, @JsonKey(name: 'completed_deliveries', fromJson: safeInt) required this.completedDeliveries, @JsonKey(fromJson: safeDouble) required this.earnings, @JsonKey(name: 'kyc_status', defaultValue: 'unknown') required this.kycStatus, final  List<ProfileBadge> badges = const [], @JsonKey(name: 'active_challenges') final  List<ProfileChallenge> activeChallenges = const []}): _badges = badges,_activeChallenges = activeChallenges;
  factory _CourierProfile.fromJson(Map<String, dynamic> json) => _$CourierProfileFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override final  String name;
@override final  String email;
@override final  String? avatar;
@override final  String status;
@override@JsonKey(name: 'vehicle_type') final  String vehicleType;
@override@JsonKey(name: 'plate_number', defaultValue: '') final  String plateNumber;
@override@JsonKey(fromJson: safeDouble) final  double rating;
@override@JsonKey(name: 'completed_deliveries', fromJson: safeInt) final  int completedDeliveries;
@override@JsonKey(fromJson: safeDouble) final  double earnings;
@override@JsonKey(name: 'kyc_status', defaultValue: 'unknown') final  String kycStatus;
 final  List<ProfileBadge> _badges;
@override@JsonKey() List<ProfileBadge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

 final  List<ProfileChallenge> _activeChallenges;
@override@JsonKey(name: 'active_challenges') List<ProfileChallenge> get activeChallenges {
  if (_activeChallenges is EqualUnmodifiableListView) return _activeChallenges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeChallenges);
}


/// Create a copy of CourierProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierProfileCopyWith<_CourierProfile> get copyWith => __$CourierProfileCopyWithImpl<_CourierProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourierProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries)&&(identical(other.earnings, earnings) || other.earnings == earnings)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&const DeepCollectionEquality().equals(other._badges, _badges)&&const DeepCollectionEquality().equals(other._activeChallenges, _activeChallenges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,avatar,status,vehicleType,plateNumber,rating,completedDeliveries,earnings,kycStatus,const DeepCollectionEquality().hash(_badges),const DeepCollectionEquality().hash(_activeChallenges));

@override
String toString() {
  return 'CourierProfile(id: $id, name: $name, email: $email, avatar: $avatar, status: $status, vehicleType: $vehicleType, plateNumber: $plateNumber, rating: $rating, completedDeliveries: $completedDeliveries, earnings: $earnings, kycStatus: $kycStatus, badges: $badges, activeChallenges: $activeChallenges)';
}


}

/// @nodoc
abstract mixin class _$CourierProfileCopyWith<$Res> implements $CourierProfileCopyWith<$Res> {
  factory _$CourierProfileCopyWith(_CourierProfile value, $Res Function(_CourierProfile) _then) = __$CourierProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String name, String email, String? avatar, String status,@JsonKey(name: 'vehicle_type') String vehicleType,@JsonKey(name: 'plate_number', defaultValue: '') String plateNumber,@JsonKey(fromJson: safeDouble) double rating,@JsonKey(name: 'completed_deliveries', fromJson: safeInt) int completedDeliveries,@JsonKey(fromJson: safeDouble) double earnings,@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String kycStatus, List<ProfileBadge> badges,@JsonKey(name: 'active_challenges') List<ProfileChallenge> activeChallenges
});




}
/// @nodoc
class __$CourierProfileCopyWithImpl<$Res>
    implements _$CourierProfileCopyWith<$Res> {
  __$CourierProfileCopyWithImpl(this._self, this._then);

  final _CourierProfile _self;
  final $Res Function(_CourierProfile) _then;

/// Create a copy of CourierProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? avatar = freezed,Object? status = null,Object? vehicleType = null,Object? plateNumber = null,Object? rating = null,Object? completedDeliveries = null,Object? earnings = null,Object? kycStatus = null,Object? badges = null,Object? activeChallenges = null,}) {
  return _then(_CourierProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<ProfileBadge>,activeChallenges: null == activeChallenges ? _self._activeChallenges : activeChallenges // ignore: cast_nullable_to_non_nullable
as List<ProfileChallenge>,
  ));
}


}


/// @nodoc
mixin _$ProfileBadge {

@JsonKey(fromJson: safeInt) int get id; String get name; String get description; String get icon; String get color;@JsonKey(name: 'earned_at') String? get earnedAt;
/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileBadgeCopyWith<ProfileBadge> get copyWith => _$ProfileBadgeCopyWithImpl<ProfileBadge>(this as ProfileBadge, _$identity);

  /// Serializes this ProfileBadge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileBadge&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.earnedAt, earnedAt) || other.earnedAt == earnedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,earnedAt);

@override
String toString() {
  return 'ProfileBadge(id: $id, name: $name, description: $description, icon: $icon, color: $color, earnedAt: $earnedAt)';
}


}

/// @nodoc
abstract mixin class $ProfileBadgeCopyWith<$Res>  {
  factory $ProfileBadgeCopyWith(ProfileBadge value, $Res Function(ProfileBadge) _then) = _$ProfileBadgeCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String name, String description, String icon, String color,@JsonKey(name: 'earned_at') String? earnedAt
});




}
/// @nodoc
class _$ProfileBadgeCopyWithImpl<$Res>
    implements $ProfileBadgeCopyWith<$Res> {
  _$ProfileBadgeCopyWithImpl(this._self, this._then);

  final ProfileBadge _self;
  final $Res Function(ProfileBadge) _then;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? earnedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,earnedAt: freezed == earnedAt ? _self.earnedAt : earnedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileBadge].
extension ProfileBadgePatterns on ProfileBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileBadge value)  $default,){
final _that = this;
switch (_that) {
case _ProfileBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileBadge value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String description,  String icon,  String color, @JsonKey(name: 'earned_at')  String? earnedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.earnedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String description,  String icon,  String color, @JsonKey(name: 'earned_at')  String? earnedAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileBadge():
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.earnedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id,  String name,  String description,  String icon,  String color, @JsonKey(name: 'earned_at')  String? earnedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.earnedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileBadge implements ProfileBadge {
  const _ProfileBadge({@JsonKey(fromJson: safeInt) required this.id, required this.name, this.description = '', this.icon = 'star', this.color = 'bronze', @JsonKey(name: 'earned_at') this.earnedAt});
  factory _ProfileBadge.fromJson(Map<String, dynamic> json) => _$ProfileBadgeFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey(name: 'earned_at') final  String? earnedAt;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileBadgeCopyWith<_ProfileBadge> get copyWith => __$ProfileBadgeCopyWithImpl<_ProfileBadge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileBadgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileBadge&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.earnedAt, earnedAt) || other.earnedAt == earnedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,earnedAt);

@override
String toString() {
  return 'ProfileBadge(id: $id, name: $name, description: $description, icon: $icon, color: $color, earnedAt: $earnedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileBadgeCopyWith<$Res> implements $ProfileBadgeCopyWith<$Res> {
  factory _$ProfileBadgeCopyWith(_ProfileBadge value, $Res Function(_ProfileBadge) _then) = __$ProfileBadgeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String name, String description, String icon, String color,@JsonKey(name: 'earned_at') String? earnedAt
});




}
/// @nodoc
class __$ProfileBadgeCopyWithImpl<$Res>
    implements _$ProfileBadgeCopyWith<$Res> {
  __$ProfileBadgeCopyWithImpl(this._self, this._then);

  final _ProfileBadge _self;
  final $Res Function(_ProfileBadge) _then;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? color = null,Object? earnedAt = freezed,}) {
  return _then(_ProfileBadge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,earnedAt: freezed == earnedAt ? _self.earnedAt : earnedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProfileChallenge {

@JsonKey(fromJson: safeInt) int get id; String get title; String get description;@JsonKey(name: 'target_value', fromJson: safeInt) int get targetValue;@JsonKey(name: 'current_value', fromJson: safeInt) int get currentValue;@JsonKey(name: 'xp_reward', fromJson: safeInt) int get xpReward;@JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) int? get bonusReward;@JsonKey(name: 'expires_at') String? get expiresAt; String get difficulty;
/// Create a copy of ProfileChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileChallengeCopyWith<ProfileChallenge> get copyWith => _$ProfileChallengeCopyWithImpl<ProfileChallenge>(this as ProfileChallenge, _$identity);

  /// Serializes this ProfileChallenge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileChallenge&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetValue, targetValue) || other.targetValue == targetValue)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.bonusReward, bonusReward) || other.bonusReward == bonusReward)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,targetValue,currentValue,xpReward,bonusReward,expiresAt,difficulty);

@override
String toString() {
  return 'ProfileChallenge(id: $id, title: $title, description: $description, targetValue: $targetValue, currentValue: $currentValue, xpReward: $xpReward, bonusReward: $bonusReward, expiresAt: $expiresAt, difficulty: $difficulty)';
}


}

/// @nodoc
abstract mixin class $ProfileChallengeCopyWith<$Res>  {
  factory $ProfileChallengeCopyWith(ProfileChallenge value, $Res Function(ProfileChallenge) _then) = _$ProfileChallengeCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String title, String description,@JsonKey(name: 'target_value', fromJson: safeInt) int targetValue,@JsonKey(name: 'current_value', fromJson: safeInt) int currentValue,@JsonKey(name: 'xp_reward', fromJson: safeInt) int xpReward,@JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) int? bonusReward,@JsonKey(name: 'expires_at') String? expiresAt, String difficulty
});




}
/// @nodoc
class _$ProfileChallengeCopyWithImpl<$Res>
    implements $ProfileChallengeCopyWith<$Res> {
  _$ProfileChallengeCopyWithImpl(this._self, this._then);

  final ProfileChallenge _self;
  final $Res Function(ProfileChallenge) _then;

/// Create a copy of ProfileChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? targetValue = null,Object? currentValue = null,Object? xpReward = null,Object? bonusReward = freezed,Object? expiresAt = freezed,Object? difficulty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetValue: null == targetValue ? _self.targetValue : targetValue // ignore: cast_nullable_to_non_nullable
as int,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,bonusReward: freezed == bonusReward ? _self.bonusReward : bonusReward // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileChallenge].
extension ProfileChallengePatterns on ProfileChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileChallenge value)  $default,){
final _that = this;
switch (_that) {
case _ProfileChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String title,  String description, @JsonKey(name: 'target_value', fromJson: safeInt)  int targetValue, @JsonKey(name: 'current_value', fromJson: safeInt)  int currentValue, @JsonKey(name: 'xp_reward', fromJson: safeInt)  int xpReward, @JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull)  int? bonusReward, @JsonKey(name: 'expires_at')  String? expiresAt,  String difficulty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileChallenge() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.targetValue,_that.currentValue,_that.xpReward,_that.bonusReward,_that.expiresAt,_that.difficulty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id,  String title,  String description, @JsonKey(name: 'target_value', fromJson: safeInt)  int targetValue, @JsonKey(name: 'current_value', fromJson: safeInt)  int currentValue, @JsonKey(name: 'xp_reward', fromJson: safeInt)  int xpReward, @JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull)  int? bonusReward, @JsonKey(name: 'expires_at')  String? expiresAt,  String difficulty)  $default,) {final _that = this;
switch (_that) {
case _ProfileChallenge():
return $default(_that.id,_that.title,_that.description,_that.targetValue,_that.currentValue,_that.xpReward,_that.bonusReward,_that.expiresAt,_that.difficulty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id,  String title,  String description, @JsonKey(name: 'target_value', fromJson: safeInt)  int targetValue, @JsonKey(name: 'current_value', fromJson: safeInt)  int currentValue, @JsonKey(name: 'xp_reward', fromJson: safeInt)  int xpReward, @JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull)  int? bonusReward, @JsonKey(name: 'expires_at')  String? expiresAt,  String difficulty)?  $default,) {final _that = this;
switch (_that) {
case _ProfileChallenge() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.targetValue,_that.currentValue,_that.xpReward,_that.bonusReward,_that.expiresAt,_that.difficulty);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileChallenge implements ProfileChallenge {
  const _ProfileChallenge({@JsonKey(fromJson: safeInt) required this.id, required this.title, this.description = '', @JsonKey(name: 'target_value', fromJson: safeInt) required this.targetValue, @JsonKey(name: 'current_value', fromJson: safeInt) required this.currentValue, @JsonKey(name: 'xp_reward', fromJson: safeInt) this.xpReward = 0, @JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) this.bonusReward, @JsonKey(name: 'expires_at') this.expiresAt, this.difficulty = 'easy'});
  factory _ProfileChallenge.fromJson(Map<String, dynamic> json) => _$ProfileChallengeFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'target_value', fromJson: safeInt) final  int targetValue;
@override@JsonKey(name: 'current_value', fromJson: safeInt) final  int currentValue;
@override@JsonKey(name: 'xp_reward', fromJson: safeInt) final  int xpReward;
@override@JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) final  int? bonusReward;
@override@JsonKey(name: 'expires_at') final  String? expiresAt;
@override@JsonKey() final  String difficulty;

/// Create a copy of ProfileChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileChallengeCopyWith<_ProfileChallenge> get copyWith => __$ProfileChallengeCopyWithImpl<_ProfileChallenge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileChallengeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileChallenge&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetValue, targetValue) || other.targetValue == targetValue)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.bonusReward, bonusReward) || other.bonusReward == bonusReward)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,targetValue,currentValue,xpReward,bonusReward,expiresAt,difficulty);

@override
String toString() {
  return 'ProfileChallenge(id: $id, title: $title, description: $description, targetValue: $targetValue, currentValue: $currentValue, xpReward: $xpReward, bonusReward: $bonusReward, expiresAt: $expiresAt, difficulty: $difficulty)';
}


}

/// @nodoc
abstract mixin class _$ProfileChallengeCopyWith<$Res> implements $ProfileChallengeCopyWith<$Res> {
  factory _$ProfileChallengeCopyWith(_ProfileChallenge value, $Res Function(_ProfileChallenge) _then) = __$ProfileChallengeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id, String title, String description,@JsonKey(name: 'target_value', fromJson: safeInt) int targetValue,@JsonKey(name: 'current_value', fromJson: safeInt) int currentValue,@JsonKey(name: 'xp_reward', fromJson: safeInt) int xpReward,@JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) int? bonusReward,@JsonKey(name: 'expires_at') String? expiresAt, String difficulty
});




}
/// @nodoc
class __$ProfileChallengeCopyWithImpl<$Res>
    implements _$ProfileChallengeCopyWith<$Res> {
  __$ProfileChallengeCopyWithImpl(this._self, this._then);

  final _ProfileChallenge _self;
  final $Res Function(_ProfileChallenge) _then;

/// Create a copy of ProfileChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? targetValue = null,Object? currentValue = null,Object? xpReward = null,Object? bonusReward = freezed,Object? expiresAt = freezed,Object? difficulty = null,}) {
  return _then(_ProfileChallenge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,targetValue: null == targetValue ? _self.targetValue : targetValue // ignore: cast_nullable_to_non_nullable
as int,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,bonusReward: freezed == bonusReward ? _self.bonusReward : bonusReward // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
