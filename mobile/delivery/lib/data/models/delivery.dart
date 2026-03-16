import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery.freezed.dart';
part 'delivery.g.dart';

@freezed
abstract class Delivery with _$Delivery {
  const factory Delivery({
    required int id,
    @JsonKey(name: 'order_id') int? orderId,
    required String reference,
    @JsonKey(name: 'pharmacy_name') required String pharmacyName,
    @JsonKey(name: 'pharmacy_address') required String pharmacyAddress,
    @JsonKey(name: 'pharmacy_phone') String? pharmacyPhone,
    @JsonKey(name: 'customer_name') required String customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'delivery_address') required String deliveryAddress,
    @JsonKey(name: 'pharmacy_latitude') double? pharmacyLat,
    @JsonKey(name: 'pharmacy_longitude') double? pharmacyLng,
    @JsonKey(name: 'delivery_latitude') double? deliveryLat,
    @JsonKey(name: 'delivery_longitude') double? deliveryLng,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'delivery_fee') double? deliveryFee,
    @JsonKey(name: 'commission') double? commission,
    @JsonKey(name: 'estimated_earnings') double? estimatedEarnings,
    @JsonKey(name: 'distance_km') double? distanceKm,
    required String status,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Delivery;

  factory Delivery.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFromJson(json);
}
