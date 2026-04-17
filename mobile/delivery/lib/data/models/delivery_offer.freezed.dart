// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeliveryOffer {

@JsonKey(fromJson: safeInt) int get id;@JsonKey(name: 'order_id', fromJson: safeIntOrNull) int? get orderId; String get status;@JsonKey(name: 'broadcast_level', fromJson: safeInt) int get broadcastLevel;@JsonKey(name: 'base_fee', fromJson: safeDouble) double get baseFee;@JsonKey(name: 'bonus_fee', fromJson: safeDouble) double get bonusFee;@JsonKey(name: 'expires_at') String get expiresAt;@JsonKey(name: 'accepted_at') String? get acceptedAt;@JsonKey(name: 'pharmacy_name') String? get pharmacyName;@JsonKey(name: 'pharmacy_address') String? get pharmacyAddress;@JsonKey(name: 'pharmacy_phone') String? get pharmacyPhone;@JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull) double? get pharmacyLat;@JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull) double? get pharmacyLng;@JsonKey(name: 'customer_name') String? get customerName;@JsonKey(name: 'delivery_address') String? get deliveryAddress;@JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull) double? get deliveryLat;@JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull) double? get deliveryLng;@JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull) double? get distanceKm;@JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull) int? get estimatedDuration;@JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull) double? get totalAmount;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryOfferCopyWith<DeliveryOffer> get copyWith => _$DeliveryOfferCopyWithImpl<DeliveryOffer>(this as DeliveryOffer, _$identity);

  /// Serializes this DeliveryOffer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.broadcastLevel, broadcastLevel) || other.broadcastLevel == broadcastLevel)&&(identical(other.baseFee, baseFee) || other.baseFee == baseFee)&&(identical(other.bonusFee, bonusFee) || other.bonusFee == bonusFee)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.pharmacyName, pharmacyName) || other.pharmacyName == pharmacyName)&&(identical(other.pharmacyAddress, pharmacyAddress) || other.pharmacyAddress == pharmacyAddress)&&(identical(other.pharmacyPhone, pharmacyPhone) || other.pharmacyPhone == pharmacyPhone)&&(identical(other.pharmacyLat, pharmacyLat) || other.pharmacyLat == pharmacyLat)&&(identical(other.pharmacyLng, pharmacyLng) || other.pharmacyLng == pharmacyLng)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,status,broadcastLevel,baseFee,bonusFee,expiresAt,acceptedAt,pharmacyName,pharmacyAddress,pharmacyPhone,pharmacyLat,pharmacyLng,customerName,deliveryAddress,deliveryLat,deliveryLng,distanceKm,estimatedDuration,totalAmount,createdAt]);

@override
String toString() {
  return 'DeliveryOffer(id: $id, orderId: $orderId, status: $status, broadcastLevel: $broadcastLevel, baseFee: $baseFee, bonusFee: $bonusFee, expiresAt: $expiresAt, acceptedAt: $acceptedAt, pharmacyName: $pharmacyName, pharmacyAddress: $pharmacyAddress, pharmacyPhone: $pharmacyPhone, pharmacyLat: $pharmacyLat, pharmacyLng: $pharmacyLng, customerName: $customerName, deliveryAddress: $deliveryAddress, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, distanceKm: $distanceKm, estimatedDuration: $estimatedDuration, totalAmount: $totalAmount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DeliveryOfferCopyWith<$Res>  {
  factory $DeliveryOfferCopyWith(DeliveryOffer value, $Res Function(DeliveryOffer) _then) = _$DeliveryOfferCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeInt) int id,@JsonKey(name: 'order_id', fromJson: safeIntOrNull) int? orderId, String status,@JsonKey(name: 'broadcast_level', fromJson: safeInt) int broadcastLevel,@JsonKey(name: 'base_fee', fromJson: safeDouble) double baseFee,@JsonKey(name: 'bonus_fee', fromJson: safeDouble) double bonusFee,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'accepted_at') String? acceptedAt,@JsonKey(name: 'pharmacy_name') String? pharmacyName,@JsonKey(name: 'pharmacy_address') String? pharmacyAddress,@JsonKey(name: 'pharmacy_phone') String? pharmacyPhone,@JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull) double? pharmacyLat,@JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull) double? pharmacyLng,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'delivery_address') String? deliveryAddress,@JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull) double? deliveryLat,@JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull) double? deliveryLng,@JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull) double? distanceKm,@JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull) int? estimatedDuration,@JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull) double? totalAmount,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$DeliveryOfferCopyWithImpl<$Res>
    implements $DeliveryOfferCopyWith<$Res> {
  _$DeliveryOfferCopyWithImpl(this._self, this._then);

  final DeliveryOffer _self;
  final $Res Function(DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = freezed,Object? status = null,Object? broadcastLevel = null,Object? baseFee = null,Object? bonusFee = null,Object? expiresAt = null,Object? acceptedAt = freezed,Object? pharmacyName = freezed,Object? pharmacyAddress = freezed,Object? pharmacyPhone = freezed,Object? pharmacyLat = freezed,Object? pharmacyLng = freezed,Object? customerName = freezed,Object? deliveryAddress = freezed,Object? deliveryLat = freezed,Object? deliveryLng = freezed,Object? distanceKm = freezed,Object? estimatedDuration = freezed,Object? totalAmount = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,broadcastLevel: null == broadcastLevel ? _self.broadcastLevel : broadcastLevel // ignore: cast_nullable_to_non_nullable
as int,baseFee: null == baseFee ? _self.baseFee : baseFee // ignore: cast_nullable_to_non_nullable
as double,bonusFee: null == bonusFee ? _self.bonusFee : bonusFee // ignore: cast_nullable_to_non_nullable
as double,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,pharmacyName: freezed == pharmacyName ? _self.pharmacyName : pharmacyName // ignore: cast_nullable_to_non_nullable
as String?,pharmacyAddress: freezed == pharmacyAddress ? _self.pharmacyAddress : pharmacyAddress // ignore: cast_nullable_to_non_nullable
as String?,pharmacyPhone: freezed == pharmacyPhone ? _self.pharmacyPhone : pharmacyPhone // ignore: cast_nullable_to_non_nullable
as String?,pharmacyLat: freezed == pharmacyLat ? _self.pharmacyLat : pharmacyLat // ignore: cast_nullable_to_non_nullable
as double?,pharmacyLng: freezed == pharmacyLng ? _self.pharmacyLng : pharmacyLng // ignore: cast_nullable_to_non_nullable
as double?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: freezed == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as double?,deliveryLng: freezed == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as int?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryOffer].
extension DeliveryOfferPatterns on DeliveryOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryOffer value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryOffer value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'order_id', fromJson: safeIntOrNull)  int? orderId,  String status, @JsonKey(name: 'broadcast_level', fromJson: safeInt)  int broadcastLevel, @JsonKey(name: 'base_fee', fromJson: safeDouble)  double baseFee, @JsonKey(name: 'bonus_fee', fromJson: safeDouble)  double bonusFee, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'pharmacy_name')  String? pharmacyName, @JsonKey(name: 'pharmacy_address')  String? pharmacyAddress, @JsonKey(name: 'pharmacy_phone')  String? pharmacyPhone, @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull)  double? pharmacyLat, @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull)  double? pharmacyLng, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'delivery_address')  String? deliveryAddress, @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull)  double? deliveryLat, @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull)  double? deliveryLng, @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull)  double? distanceKm, @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull)  int? estimatedDuration, @JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull)  double? totalAmount, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.status,_that.broadcastLevel,_that.baseFee,_that.bonusFee,_that.expiresAt,_that.acceptedAt,_that.pharmacyName,_that.pharmacyAddress,_that.pharmacyPhone,_that.pharmacyLat,_that.pharmacyLng,_that.customerName,_that.deliveryAddress,_that.deliveryLat,_that.deliveryLng,_that.distanceKm,_that.estimatedDuration,_that.totalAmount,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'order_id', fromJson: safeIntOrNull)  int? orderId,  String status, @JsonKey(name: 'broadcast_level', fromJson: safeInt)  int broadcastLevel, @JsonKey(name: 'base_fee', fromJson: safeDouble)  double baseFee, @JsonKey(name: 'bonus_fee', fromJson: safeDouble)  double bonusFee, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'pharmacy_name')  String? pharmacyName, @JsonKey(name: 'pharmacy_address')  String? pharmacyAddress, @JsonKey(name: 'pharmacy_phone')  String? pharmacyPhone, @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull)  double? pharmacyLat, @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull)  double? pharmacyLng, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'delivery_address')  String? deliveryAddress, @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull)  double? deliveryLat, @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull)  double? deliveryLng, @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull)  double? distanceKm, @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull)  int? estimatedDuration, @JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull)  double? totalAmount, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer():
return $default(_that.id,_that.orderId,_that.status,_that.broadcastLevel,_that.baseFee,_that.bonusFee,_that.expiresAt,_that.acceptedAt,_that.pharmacyName,_that.pharmacyAddress,_that.pharmacyPhone,_that.pharmacyLat,_that.pharmacyLng,_that.customerName,_that.deliveryAddress,_that.deliveryLat,_that.deliveryLng,_that.distanceKm,_that.estimatedDuration,_that.totalAmount,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeInt)  int id, @JsonKey(name: 'order_id', fromJson: safeIntOrNull)  int? orderId,  String status, @JsonKey(name: 'broadcast_level', fromJson: safeInt)  int broadcastLevel, @JsonKey(name: 'base_fee', fromJson: safeDouble)  double baseFee, @JsonKey(name: 'bonus_fee', fromJson: safeDouble)  double bonusFee, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'pharmacy_name')  String? pharmacyName, @JsonKey(name: 'pharmacy_address')  String? pharmacyAddress, @JsonKey(name: 'pharmacy_phone')  String? pharmacyPhone, @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull)  double? pharmacyLat, @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull)  double? pharmacyLng, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'delivery_address')  String? deliveryAddress, @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull)  double? deliveryLat, @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull)  double? deliveryLng, @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull)  double? distanceKm, @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull)  int? estimatedDuration, @JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull)  double? totalAmount, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.status,_that.broadcastLevel,_that.baseFee,_that.bonusFee,_that.expiresAt,_that.acceptedAt,_that.pharmacyName,_that.pharmacyAddress,_that.pharmacyPhone,_that.pharmacyLat,_that.pharmacyLng,_that.customerName,_that.deliveryAddress,_that.deliveryLat,_that.deliveryLng,_that.distanceKm,_that.estimatedDuration,_that.totalAmount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryOffer implements DeliveryOffer {
  const _DeliveryOffer({@JsonKey(fromJson: safeInt) required this.id, @JsonKey(name: 'order_id', fromJson: safeIntOrNull) this.orderId, required this.status, @JsonKey(name: 'broadcast_level', fromJson: safeInt) required this.broadcastLevel, @JsonKey(name: 'base_fee', fromJson: safeDouble) required this.baseFee, @JsonKey(name: 'bonus_fee', fromJson: safeDouble) required this.bonusFee, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'accepted_at') this.acceptedAt, @JsonKey(name: 'pharmacy_name') this.pharmacyName, @JsonKey(name: 'pharmacy_address') this.pharmacyAddress, @JsonKey(name: 'pharmacy_phone') this.pharmacyPhone, @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull) this.pharmacyLat, @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull) this.pharmacyLng, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'delivery_address') this.deliveryAddress, @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull) this.deliveryLat, @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull) this.deliveryLng, @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull) this.distanceKm, @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull) this.estimatedDuration, @JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull) this.totalAmount, @JsonKey(name: 'created_at') this.createdAt});
  factory _DeliveryOffer.fromJson(Map<String, dynamic> json) => _$DeliveryOfferFromJson(json);

@override@JsonKey(fromJson: safeInt) final  int id;
@override@JsonKey(name: 'order_id', fromJson: safeIntOrNull) final  int? orderId;
@override final  String status;
@override@JsonKey(name: 'broadcast_level', fromJson: safeInt) final  int broadcastLevel;
@override@JsonKey(name: 'base_fee', fromJson: safeDouble) final  double baseFee;
@override@JsonKey(name: 'bonus_fee', fromJson: safeDouble) final  double bonusFee;
@override@JsonKey(name: 'expires_at') final  String expiresAt;
@override@JsonKey(name: 'accepted_at') final  String? acceptedAt;
@override@JsonKey(name: 'pharmacy_name') final  String? pharmacyName;
@override@JsonKey(name: 'pharmacy_address') final  String? pharmacyAddress;
@override@JsonKey(name: 'pharmacy_phone') final  String? pharmacyPhone;
@override@JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull) final  double? pharmacyLat;
@override@JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull) final  double? pharmacyLng;
@override@JsonKey(name: 'customer_name') final  String? customerName;
@override@JsonKey(name: 'delivery_address') final  String? deliveryAddress;
@override@JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull) final  double? deliveryLat;
@override@JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull) final  double? deliveryLng;
@override@JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull) final  double? distanceKm;
@override@JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull) final  int? estimatedDuration;
@override@JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull) final  double? totalAmount;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryOfferCopyWith<_DeliveryOffer> get copyWith => __$DeliveryOfferCopyWithImpl<_DeliveryOffer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryOfferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.broadcastLevel, broadcastLevel) || other.broadcastLevel == broadcastLevel)&&(identical(other.baseFee, baseFee) || other.baseFee == baseFee)&&(identical(other.bonusFee, bonusFee) || other.bonusFee == bonusFee)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.pharmacyName, pharmacyName) || other.pharmacyName == pharmacyName)&&(identical(other.pharmacyAddress, pharmacyAddress) || other.pharmacyAddress == pharmacyAddress)&&(identical(other.pharmacyPhone, pharmacyPhone) || other.pharmacyPhone == pharmacyPhone)&&(identical(other.pharmacyLat, pharmacyLat) || other.pharmacyLat == pharmacyLat)&&(identical(other.pharmacyLng, pharmacyLng) || other.pharmacyLng == pharmacyLng)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.estimatedDuration, estimatedDuration) || other.estimatedDuration == estimatedDuration)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,status,broadcastLevel,baseFee,bonusFee,expiresAt,acceptedAt,pharmacyName,pharmacyAddress,pharmacyPhone,pharmacyLat,pharmacyLng,customerName,deliveryAddress,deliveryLat,deliveryLng,distanceKm,estimatedDuration,totalAmount,createdAt]);

@override
String toString() {
  return 'DeliveryOffer(id: $id, orderId: $orderId, status: $status, broadcastLevel: $broadcastLevel, baseFee: $baseFee, bonusFee: $bonusFee, expiresAt: $expiresAt, acceptedAt: $acceptedAt, pharmacyName: $pharmacyName, pharmacyAddress: $pharmacyAddress, pharmacyPhone: $pharmacyPhone, pharmacyLat: $pharmacyLat, pharmacyLng: $pharmacyLng, customerName: $customerName, deliveryAddress: $deliveryAddress, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, distanceKm: $distanceKm, estimatedDuration: $estimatedDuration, totalAmount: $totalAmount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DeliveryOfferCopyWith<$Res> implements $DeliveryOfferCopyWith<$Res> {
  factory _$DeliveryOfferCopyWith(_DeliveryOffer value, $Res Function(_DeliveryOffer) _then) = __$DeliveryOfferCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeInt) int id,@JsonKey(name: 'order_id', fromJson: safeIntOrNull) int? orderId, String status,@JsonKey(name: 'broadcast_level', fromJson: safeInt) int broadcastLevel,@JsonKey(name: 'base_fee', fromJson: safeDouble) double baseFee,@JsonKey(name: 'bonus_fee', fromJson: safeDouble) double bonusFee,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'accepted_at') String? acceptedAt,@JsonKey(name: 'pharmacy_name') String? pharmacyName,@JsonKey(name: 'pharmacy_address') String? pharmacyAddress,@JsonKey(name: 'pharmacy_phone') String? pharmacyPhone,@JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull) double? pharmacyLat,@JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull) double? pharmacyLng,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'delivery_address') String? deliveryAddress,@JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull) double? deliveryLat,@JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull) double? deliveryLng,@JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull) double? distanceKm,@JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull) int? estimatedDuration,@JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull) double? totalAmount,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$DeliveryOfferCopyWithImpl<$Res>
    implements _$DeliveryOfferCopyWith<$Res> {
  __$DeliveryOfferCopyWithImpl(this._self, this._then);

  final _DeliveryOffer _self;
  final $Res Function(_DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = freezed,Object? status = null,Object? broadcastLevel = null,Object? baseFee = null,Object? bonusFee = null,Object? expiresAt = null,Object? acceptedAt = freezed,Object? pharmacyName = freezed,Object? pharmacyAddress = freezed,Object? pharmacyPhone = freezed,Object? pharmacyLat = freezed,Object? pharmacyLng = freezed,Object? customerName = freezed,Object? deliveryAddress = freezed,Object? deliveryLat = freezed,Object? deliveryLng = freezed,Object? distanceKm = freezed,Object? estimatedDuration = freezed,Object? totalAmount = freezed,Object? createdAt = freezed,}) {
  return _then(_DeliveryOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,broadcastLevel: null == broadcastLevel ? _self.broadcastLevel : broadcastLevel // ignore: cast_nullable_to_non_nullable
as int,baseFee: null == baseFee ? _self.baseFee : baseFee // ignore: cast_nullable_to_non_nullable
as double,bonusFee: null == bonusFee ? _self.bonusFee : bonusFee // ignore: cast_nullable_to_non_nullable
as double,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,pharmacyName: freezed == pharmacyName ? _self.pharmacyName : pharmacyName // ignore: cast_nullable_to_non_nullable
as String?,pharmacyAddress: freezed == pharmacyAddress ? _self.pharmacyAddress : pharmacyAddress // ignore: cast_nullable_to_non_nullable
as String?,pharmacyPhone: freezed == pharmacyPhone ? _self.pharmacyPhone : pharmacyPhone // ignore: cast_nullable_to_non_nullable
as String?,pharmacyLat: freezed == pharmacyLat ? _self.pharmacyLat : pharmacyLat // ignore: cast_nullable_to_non_nullable
as double?,pharmacyLng: freezed == pharmacyLng ? _self.pharmacyLng : pharmacyLng // ignore: cast_nullable_to_non_nullable
as double?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: freezed == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as double?,deliveryLng: freezed == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,estimatedDuration: freezed == estimatedDuration ? _self.estimatedDuration : estimatedDuration // ignore: cast_nullable_to_non_nullable
as int?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
