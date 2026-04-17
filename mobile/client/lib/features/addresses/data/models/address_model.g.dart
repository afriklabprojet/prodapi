// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) => AddressModel(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      address: json['address'] as String,
      city: json['city'] as String?,
      district: json['district'] as String?,
      phone: json['phone'] as String?,
      instructions: json['instructions'] as String?,
      latitude: const StringToDoubleConverter().fromJson(json['latitude']),
      longitude: const StringToDoubleConverter().fromJson(json['longitude']),
      isDefault: json['is_default'] as bool? ?? false,
      fullAddress: json['full_address'] as String? ?? '',
      hasCoordinates: json['has_coordinates'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'address': instance.address,
      'city': instance.city,
      'district': instance.district,
      'phone': instance.phone,
      'instructions': instance.instructions,
      'latitude': const StringToDoubleConverter().toJson(instance.latitude),
      'longitude': const StringToDoubleConverter().toJson(instance.longitude),
      'is_default': instance.isDefault,
      'full_address': instance.fullAddress,
      'has_coordinates': instance.hasCoordinates,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
