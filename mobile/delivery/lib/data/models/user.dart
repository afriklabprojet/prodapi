import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(fromJson: _forceInt) required int id,
    required String name,
    required String email,
    String? phone,
    String? role,
    String? avatar,
    CourierInfo? courier,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class CourierInfo with _$CourierInfo {
  const factory CourierInfo({
    @JsonKey(fromJson: _forceInt) required int id,
    required String status,
    @JsonKey(name: 'vehicle_type') String? vehicleType,
    @JsonKey(name: 'vehicle_number') String? vehicleNumber,
    @JsonKey(fromJson: _stringToDouble) double? rating,
    @JsonKey(name: 'completed_deliveries', fromJson: _stringToInt)
    int? completedDeliveries,
    @JsonKey(name: 'kyc_status', defaultValue: 'unknown') String? kycStatus,
  }) = _CourierInfo;

  factory CourierInfo.fromJson(Map<String, dynamic> json) =>
      _$CourierInfoFromJson(json);
}

double? _stringToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _stringToInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int _forceInt(dynamic value) {
  if (value == null || value == 0) return 0;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Cannot parse ID from: $value (${value.runtimeType})');
}
