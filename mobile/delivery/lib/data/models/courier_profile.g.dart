// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourierProfile _$CourierProfileFromJson(Map<String, dynamic> json) =>
    _CourierProfile(
      id: safeInt(json['id']),
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      status: json['status'] as String,
      vehicleType: json['vehicle_type'] as String,
      plateNumber: json['plate_number'] as String? ?? '',
      rating: safeDouble(json['rating']),
      completedDeliveries: safeInt(json['completed_deliveries']),
      earnings: safeDouble(json['earnings']),
      kycStatus: json['kyc_status'] as String? ?? 'unknown',
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => ProfileBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeChallenges:
          (json['active_challenges'] as List<dynamic>?)
              ?.map((e) => ProfileChallenge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CourierProfileToJson(_CourierProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'status': instance.status,
      'vehicle_type': instance.vehicleType,
      'plate_number': instance.plateNumber,
      'rating': instance.rating,
      'completed_deliveries': instance.completedDeliveries,
      'earnings': instance.earnings,
      'kyc_status': instance.kycStatus,
      'badges': instance.badges,
      'active_challenges': instance.activeChallenges,
    };

_ProfileBadge _$ProfileBadgeFromJson(Map<String, dynamic> json) =>
    _ProfileBadge(
      id: safeInt(json['id']),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
      color: json['color'] as String? ?? 'bronze',
      earnedAt: json['earned_at'] as String?,
    );

Map<String, dynamic> _$ProfileBadgeToJson(_ProfileBadge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'color': instance.color,
      'earned_at': instance.earnedAt,
    };

_ProfileChallenge _$ProfileChallengeFromJson(Map<String, dynamic> json) =>
    _ProfileChallenge(
      id: safeInt(json['id']),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      targetValue: safeInt(json['target_value']),
      currentValue: safeInt(json['current_value']),
      xpReward: json['xp_reward'] == null ? 0 : safeInt(json['xp_reward']),
      bonusReward: safeIntOrNull(json['bonus_reward']),
      expiresAt: json['expires_at'] as String?,
      difficulty: json['difficulty'] as String? ?? 'easy',
    );

Map<String, dynamic> _$ProfileChallengeToJson(_ProfileChallenge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'target_value': instance.targetValue,
      'current_value': instance.currentValue,
      'xp_reward': instance.xpReward,
      'bonus_reward': instance.bonusReward,
      'expires_at': instance.expiresAt,
      'difficulty': instance.difficulty,
    };
