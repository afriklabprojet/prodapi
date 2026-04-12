import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'courier_profile.freezed.dart';
part 'courier_profile.g.dart';

@freezed
abstract class CourierProfile with _$CourierProfile {
  const factory CourierProfile({
    @JsonKey(fromJson: safeInt) required int id,
    required String name,
    required String email,
    String? avatar,
    required String status,
    @JsonKey(name: 'vehicle_type') required String vehicleType,
    @JsonKey(name: 'plate_number', defaultValue: '')
    required String plateNumber,
    @JsonKey(fromJson: safeDouble) required double rating,
    @JsonKey(name: 'completed_deliveries', fromJson: safeInt)
    required int completedDeliveries,
    @JsonKey(fromJson: safeDouble) required double earnings,
    @JsonKey(name: 'kyc_status', defaultValue: 'unknown')
    required String kycStatus,
    @Default([]) List<ProfileBadge> badges,
    @JsonKey(name: 'active_challenges')
    @Default([])
    List<ProfileChallenge> activeChallenges,
  }) = _CourierProfile;

  factory CourierProfile.fromJson(Map<String, dynamic> json) =>
      _$CourierProfileFromJson(json);
}

/// Badge rattaché au profil (challenge complété)
@freezed
abstract class ProfileBadge with _$ProfileBadge {
  const factory ProfileBadge({
    @JsonKey(fromJson: safeInt) required int id,
    required String name,
    @Default('') String description,
    @Default('star') String icon,
    @Default('bronze') String color,
    @JsonKey(name: 'earned_at') String? earnedAt,
  }) = _ProfileBadge;

  factory ProfileBadge.fromJson(Map<String, dynamic> json) =>
      _$ProfileBadgeFromJson(json);
}

/// Challenge actif (en cours) rattaché au profil
@freezed
abstract class ProfileChallenge with _$ProfileChallenge {
  const factory ProfileChallenge({
    @JsonKey(fromJson: safeInt) required int id,
    required String title,
    @Default('') String description,
    @JsonKey(name: 'target_value', fromJson: safeInt) required int targetValue,
    @JsonKey(name: 'current_value', fromJson: safeInt)
    required int currentValue,
    @JsonKey(name: 'xp_reward', fromJson: safeInt) @Default(0) int xpReward,
    @JsonKey(name: 'bonus_reward', fromJson: safeIntOrNull) int? bonusReward,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @Default('easy') String difficulty,
  }) = _ProfileChallenge;

  factory ProfileChallenge.fromJson(Map<String, dynamic> json) =>
      _$ProfileChallengeFromJson(json);
}
