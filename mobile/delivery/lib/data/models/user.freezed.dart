// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

@JsonKey(fromJson: _forceInt) int get id; String get name; String get email; String? get phone; String? get role; String? get avatar; CourierInfo? get courier;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.courier, courier) || other.courier == courier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,role,avatar,courier);

@override
String toString() {
  return 'User(id: $id, name: $name, email: $email, phone: $phone, role: $role, avatar: $avatar, courier: $courier)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _forceInt) int id, String name, String email, String? phone, String? role, String? avatar, CourierInfo? courier
});


$CourierInfoCopyWith<$Res>? get courier;

}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = freezed,Object? role = freezed,Object? avatar = freezed,Object? courier = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,courier: freezed == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as CourierInfo?,
  ));
}
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourierInfoCopyWith<$Res>? get courier {
    if (_self.courier == null) {
    return null;
  }

  return $CourierInfoCopyWith<$Res>(_self.courier!, (value) {
    return _then(_self.copyWith(courier: value));
  });
}
}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _forceInt)  int id,  String name,  String email,  String? phone,  String? role,  String? avatar,  CourierInfo? courier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.role,_that.avatar,_that.courier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _forceInt)  int id,  String name,  String email,  String? phone,  String? role,  String? avatar,  CourierInfo? courier)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.name,_that.email,_that.phone,_that.role,_that.avatar,_that.courier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _forceInt)  int id,  String name,  String email,  String? phone,  String? role,  String? avatar,  CourierInfo? courier)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.role,_that.avatar,_that.courier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({@JsonKey(fromJson: _forceInt) required this.id, required this.name, required this.email, this.phone, this.role, this.avatar, this.courier});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override@JsonKey(fromJson: _forceInt) final  int id;
@override final  String name;
@override final  String email;
@override final  String? phone;
@override final  String? role;
@override final  String? avatar;
@override final  CourierInfo? courier;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.courier, courier) || other.courier == courier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,role,avatar,courier);

@override
String toString() {
  return 'User(id: $id, name: $name, email: $email, phone: $phone, role: $role, avatar: $avatar, courier: $courier)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _forceInt) int id, String name, String email, String? phone, String? role, String? avatar, CourierInfo? courier
});


@override $CourierInfoCopyWith<$Res>? get courier;

}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = freezed,Object? role = freezed,Object? avatar = freezed,Object? courier = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,courier: freezed == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as CourierInfo?,
  ));
}

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourierInfoCopyWith<$Res>? get courier {
    if (_self.courier == null) {
    return null;
  }

  return $CourierInfoCopyWith<$Res>(_self.courier!, (value) {
    return _then(_self.copyWith(courier: value));
  });
}
}


/// @nodoc
mixin _$CourierInfo {

@JsonKey(fromJson: _forceInt) int get id; String get status;@JsonKey(name: 'vehicle_type') String? get vehicleType;@JsonKey(name: 'vehicle_number') String? get vehicleNumber;@JsonKey(fromJson: _stringToDouble) double? get rating;@JsonKey(name: 'completed_deliveries', fromJson: _stringToInt) int? get completedDeliveries;@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String? get kycStatus;
/// Create a copy of CourierInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierInfoCopyWith<CourierInfo> get copyWith => _$CourierInfoCopyWithImpl<CourierInfo>(this as CourierInfo, _$identity);

  /// Serializes this CourierInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,vehicleType,vehicleNumber,rating,completedDeliveries,kycStatus);

@override
String toString() {
  return 'CourierInfo(id: $id, status: $status, vehicleType: $vehicleType, vehicleNumber: $vehicleNumber, rating: $rating, completedDeliveries: $completedDeliveries, kycStatus: $kycStatus)';
}


}

/// @nodoc
abstract mixin class $CourierInfoCopyWith<$Res>  {
  factory $CourierInfoCopyWith(CourierInfo value, $Res Function(CourierInfo) _then) = _$CourierInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _forceInt) int id, String status,@JsonKey(name: 'vehicle_type') String? vehicleType,@JsonKey(name: 'vehicle_number') String? vehicleNumber,@JsonKey(fromJson: _stringToDouble) double? rating,@JsonKey(name: 'completed_deliveries', fromJson: _stringToInt) int? completedDeliveries,@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String? kycStatus
});




}
/// @nodoc
class _$CourierInfoCopyWithImpl<$Res>
    implements $CourierInfoCopyWith<$Res> {
  _$CourierInfoCopyWithImpl(this._self, this._then);

  final CourierInfo _self;
  final $Res Function(CourierInfo) _then;

/// Create a copy of CourierInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? vehicleType = freezed,Object? vehicleNumber = freezed,Object? rating = freezed,Object? completedDeliveries = freezed,Object? kycStatus = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,vehicleNumber: freezed == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,completedDeliveries: freezed == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CourierInfo].
extension CourierInfoPatterns on CourierInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierInfo value)  $default,){
final _that = this;
switch (_that) {
case _CourierInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierInfo value)?  $default,){
final _that = this;
switch (_that) {
case _CourierInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _forceInt)  int id,  String status, @JsonKey(name: 'vehicle_type')  String? vehicleType, @JsonKey(name: 'vehicle_number')  String? vehicleNumber, @JsonKey(fromJson: _stringToDouble)  double? rating, @JsonKey(name: 'completed_deliveries', fromJson: _stringToInt)  int? completedDeliveries, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String? kycStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierInfo() when $default != null:
return $default(_that.id,_that.status,_that.vehicleType,_that.vehicleNumber,_that.rating,_that.completedDeliveries,_that.kycStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _forceInt)  int id,  String status, @JsonKey(name: 'vehicle_type')  String? vehicleType, @JsonKey(name: 'vehicle_number')  String? vehicleNumber, @JsonKey(fromJson: _stringToDouble)  double? rating, @JsonKey(name: 'completed_deliveries', fromJson: _stringToInt)  int? completedDeliveries, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String? kycStatus)  $default,) {final _that = this;
switch (_that) {
case _CourierInfo():
return $default(_that.id,_that.status,_that.vehicleType,_that.vehicleNumber,_that.rating,_that.completedDeliveries,_that.kycStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _forceInt)  int id,  String status, @JsonKey(name: 'vehicle_type')  String? vehicleType, @JsonKey(name: 'vehicle_number')  String? vehicleNumber, @JsonKey(fromJson: _stringToDouble)  double? rating, @JsonKey(name: 'completed_deliveries', fromJson: _stringToInt)  int? completedDeliveries, @JsonKey(name: 'kyc_status', defaultValue: 'unknown')  String? kycStatus)?  $default,) {final _that = this;
switch (_that) {
case _CourierInfo() when $default != null:
return $default(_that.id,_that.status,_that.vehicleType,_that.vehicleNumber,_that.rating,_that.completedDeliveries,_that.kycStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourierInfo implements CourierInfo {
  const _CourierInfo({@JsonKey(fromJson: _forceInt) required this.id, required this.status, @JsonKey(name: 'vehicle_type') this.vehicleType, @JsonKey(name: 'vehicle_number') this.vehicleNumber, @JsonKey(fromJson: _stringToDouble) this.rating, @JsonKey(name: 'completed_deliveries', fromJson: _stringToInt) this.completedDeliveries, @JsonKey(name: 'kyc_status', defaultValue: 'unknown') this.kycStatus});
  factory _CourierInfo.fromJson(Map<String, dynamic> json) => _$CourierInfoFromJson(json);

@override@JsonKey(fromJson: _forceInt) final  int id;
@override final  String status;
@override@JsonKey(name: 'vehicle_type') final  String? vehicleType;
@override@JsonKey(name: 'vehicle_number') final  String? vehicleNumber;
@override@JsonKey(fromJson: _stringToDouble) final  double? rating;
@override@JsonKey(name: 'completed_deliveries', fromJson: _stringToInt) final  int? completedDeliveries;
@override@JsonKey(name: 'kyc_status', defaultValue: 'unknown') final  String? kycStatus;

/// Create a copy of CourierInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierInfoCopyWith<_CourierInfo> get copyWith => __$CourierInfoCopyWithImpl<_CourierInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourierInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehicleNumber, vehicleNumber) || other.vehicleNumber == vehicleNumber)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,vehicleType,vehicleNumber,rating,completedDeliveries,kycStatus);

@override
String toString() {
  return 'CourierInfo(id: $id, status: $status, vehicleType: $vehicleType, vehicleNumber: $vehicleNumber, rating: $rating, completedDeliveries: $completedDeliveries, kycStatus: $kycStatus)';
}


}

/// @nodoc
abstract mixin class _$CourierInfoCopyWith<$Res> implements $CourierInfoCopyWith<$Res> {
  factory _$CourierInfoCopyWith(_CourierInfo value, $Res Function(_CourierInfo) _then) = __$CourierInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _forceInt) int id, String status,@JsonKey(name: 'vehicle_type') String? vehicleType,@JsonKey(name: 'vehicle_number') String? vehicleNumber,@JsonKey(fromJson: _stringToDouble) double? rating,@JsonKey(name: 'completed_deliveries', fromJson: _stringToInt) int? completedDeliveries,@JsonKey(name: 'kyc_status', defaultValue: 'unknown') String? kycStatus
});




}
/// @nodoc
class __$CourierInfoCopyWithImpl<$Res>
    implements _$CourierInfoCopyWith<$Res> {
  __$CourierInfoCopyWithImpl(this._self, this._then);

  final _CourierInfo _self;
  final $Res Function(_CourierInfo) _then;

/// Create a copy of CourierInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? vehicleType = freezed,Object? vehicleNumber = freezed,Object? rating = freezed,Object? completedDeliveries = freezed,Object? kycStatus = freezed,}) {
  return _then(_CourierInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,vehicleNumber: freezed == vehicleNumber ? _self.vehicleNumber : vehicleNumber // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,completedDeliveries: freezed == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
