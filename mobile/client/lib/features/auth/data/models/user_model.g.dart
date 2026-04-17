// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String?,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      totalSpent: json['total_spent'] ?? 0.0,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'address': instance.address,
      'avatar': instance.avatar,
      'email_verified_at': instance.emailVerifiedAt,
      'phone_verified_at': instance.phoneVerifiedAt,
      'created_at': instance.createdAt,
      'total_orders': instance.totalOrders,
      'completed_orders': instance.completedOrders,
      'total_spent': instance.totalSpent,
    };
