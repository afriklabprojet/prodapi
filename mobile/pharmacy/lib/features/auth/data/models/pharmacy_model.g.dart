// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pharmacy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PharmacyModel _$PharmacyModelFromJson(Map<String, dynamic> json) =>
    PharmacyModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String,
      licenseNumber: json['license_number'] as String?,
      licenseDocument: json['license_document'] as String?,
      idCardDocument: json['id_card_document'] as String?,
      dutyZoneId: (json['duty_zone_id'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PharmacyModelToJson(PharmacyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'phone': instance.phone,
      'email': instance.email,
      'status': instance.status,
      'license_number': instance.licenseNumber,
      'license_document': instance.licenseDocument,
      'id_card_document': instance.idCardDocument,
      'duty_zone_id': instance.dutyZoneId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
