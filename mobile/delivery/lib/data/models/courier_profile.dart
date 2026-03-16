import 'package:freezed_annotation/freezed_annotation.dart';

part 'courier_profile.freezed.dart';
part 'courier_profile.g.dart';

@freezed
abstract class CourierProfile with _$CourierProfile {
  const factory CourierProfile({
    required int id,
    required String name,
    required String email,
    String? avatar,
    required String status,
    @JsonKey(name: 'vehicle_type') required String vehicleType,
    @JsonKey(name: 'plate_number', defaultValue: '')
    required String plateNumber,
    required double rating,
    @JsonKey(name: 'completed_deliveries') required int completedDeliveries,
    required double earnings,
  }) = _CourierProfile;

  factory CourierProfile.fromJson(Map<String, dynamic> json) =>
      _$CourierProfileFromJson(json);
}
