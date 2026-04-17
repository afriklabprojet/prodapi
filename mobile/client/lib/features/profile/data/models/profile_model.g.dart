// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      defaultAddress: json['default_address'] as String?,
      createdAt: json['created_at'] as String,
      totalOrders: (json['total_orders'] as num?)?.toInt(),
      completedOrders: (json['completed_orders'] as num?)?.toInt(),
      totalSpent: json['total_spent'],
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'avatar': instance.avatar,
      'default_address': instance.defaultAddress,
      'created_at': instance.createdAt,
      'total_orders': instance.totalOrders,
      'completed_orders': instance.completedOrders,
      'total_spent': instance.totalSpent,
    };
