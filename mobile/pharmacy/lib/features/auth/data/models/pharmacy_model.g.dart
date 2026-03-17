// GENERATED CODE — HAND-PATCHED for safe type conversions.
// DO NOT run build_runner on this file — it would regenerate unsafe casts.

part of 'pharmacy_model.dart';

int _pmToInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _pmToIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _pmToDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

PharmacyModel _$PharmacyModelFromJson(Map<String, dynamic> json) =>
    PharmacyModel(
      id: _pmToInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      licenseNumber: json['license_number']?.toString(),
      licenseDocument: json['license_document']?.toString(),
      idCardDocument: json['id_card_document']?.toString(),
      dutyZoneId: _pmToIntNullable(json['duty_zone_id']),
      latitude: _pmToDoubleNullable(json['latitude']),
      longitude: _pmToDoubleNullable(json['longitude']),
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
