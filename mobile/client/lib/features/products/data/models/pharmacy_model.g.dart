// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pharmacy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PharmacyModel _$PharmacyModelFromJson(Map<String, dynamic> json) =>
    PharmacyModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status'] as String? ?? 'active',
      isOpen: json['is_open'] as bool? ?? false,
    );

Map<String, dynamic> _$PharmacyModelToJson(PharmacyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'status': instance.status,
      'is_open': instance.isOpen,
    };
