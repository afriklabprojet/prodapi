import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'delivery.freezed.dart';
part 'delivery.g.dart';

@freezed
abstract class Delivery with _$Delivery {
  const factory Delivery({
    @JsonKey(fromJson: safeInt) required int id,
    @JsonKey(name: 'order_id', fromJson: safeIntOrNull) int? orderId,
    required String reference,
    @JsonKey(name: 'pharmacy_name') required String pharmacyName,
    @JsonKey(name: 'pharmacy_address') required String pharmacyAddress,
    @JsonKey(name: 'pharmacy_phone') String? pharmacyPhone,
    @JsonKey(name: 'customer_name') required String customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'delivery_address') required String deliveryAddress,
    @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull)
    double? pharmacyLat,
    @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull)
    double? pharmacyLng,
    @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull)
    double? deliveryLat,
    @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull)
    double? deliveryLng,
    @JsonKey(name: 'total_amount', fromJson: safeDouble)
    required double totalAmount,
    @JsonKey(name: 'delivery_fee', fromJson: safeDoubleOrNull)
    double? deliveryFee,
    @JsonKey(name: 'commission', fromJson: safeDoubleOrNull) double? commission,
    @JsonKey(name: 'estimated_earnings', fromJson: safeDoubleOrNull)
    double? estimatedEarnings,
    @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull)
    double? distanceKm,
    @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull)
    int? estimatedDuration,
    required String status,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    String? notes,
  }) = _Delivery;

  factory Delivery.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFromJson(json);
}
