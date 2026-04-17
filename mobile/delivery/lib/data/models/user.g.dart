// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: _forceInt(json['id']),
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String?,
  avatar: json['avatar'] as String?,
  courier: json['courier'] == null
      ? null
      : CourierInfo.fromJson(json['courier'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'role': instance.role,
  'avatar': instance.avatar,
  'courier': instance.courier,
};

_CourierInfo _$CourierInfoFromJson(Map<String, dynamic> json) => _CourierInfo(
  id: _forceInt(json['id']),
  status: json['status'] as String,
  vehicleType: json['vehicle_type'] as String?,
  vehicleNumber: json['vehicle_number'] as String?,
  rating: _stringToDouble(json['rating']),
  completedDeliveries: _stringToInt(json['completed_deliveries']),
  kycStatus: json['kyc_status'] as String? ?? 'unknown',
);

Map<String, dynamic> _$CourierInfoToJson(_CourierInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'vehicle_type': instance.vehicleType,
      'vehicle_number': instance.vehicleNumber,
      'rating': instance.rating,
      'completed_deliveries': instance.completedDeliveries,
      'kyc_status': instance.kycStatus,
    };
