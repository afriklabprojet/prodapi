// GENERATED CODE — HAND-PATCHED for safe type conversions.
// DO NOT run build_runner on this file — it would regenerate unsafe casts.

part of 'user_model.dart';

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] is int
      ? json['id']
      : int.tryParse(json['id']?.toString() ?? '') ?? 0,
  name: json['name']?.toString() ?? '',
  email: json['email']?.toString() ?? '',
  phone: json['phone']?.toString() ?? '',
  role: json['role']?.toString(),
  avatar: json['avatar']?.toString(),
  pharmacies: (json['pharmacies'] as List<dynamic>?)
      ?.map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'role': instance.role,
  'avatar': instance.avatar,
  'pharmacies': instance.pharmacies,
};
