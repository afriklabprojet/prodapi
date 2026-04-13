import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/safe_json.dart';

part 'delivery_offer.freezed.dart';
part 'delivery_offer.g.dart';

/// Modèle représentant une offre de livraison broadcastée par le système de dispatch.
/// L'offre est envoyée à plusieurs livreurs simultanément avec un countdown.
@freezed
abstract class DeliveryOffer with _$DeliveryOffer {
  const factory DeliveryOffer({
    @JsonKey(fromJson: safeInt) required int id,
    @JsonKey(name: 'order_id', fromJson: safeIntOrNull) int? orderId,
    required String status,
    @JsonKey(name: 'broadcast_level', fromJson: safeInt)
    required int broadcastLevel,
    @JsonKey(name: 'base_fee', fromJson: safeDouble) required double baseFee,
    @JsonKey(name: 'bonus_fee', fromJson: safeDouble) required double bonusFee,
    @JsonKey(name: 'expires_at') required String expiresAt,
    @JsonKey(name: 'accepted_at') String? acceptedAt,
    @JsonKey(name: 'pharmacy_name') String? pharmacyName,
    @JsonKey(name: 'pharmacy_address') String? pharmacyAddress,
    @JsonKey(name: 'pharmacy_phone') String? pharmacyPhone,
    @JsonKey(name: 'pharmacy_latitude', fromJson: safeDoubleOrNull)
    double? pharmacyLat,
    @JsonKey(name: 'pharmacy_longitude', fromJson: safeDoubleOrNull)
    double? pharmacyLng,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    @JsonKey(name: 'delivery_latitude', fromJson: safeDoubleOrNull)
    double? deliveryLat,
    @JsonKey(name: 'delivery_longitude', fromJson: safeDoubleOrNull)
    double? deliveryLng,
    @JsonKey(name: 'distance_km', fromJson: safeDoubleOrNull)
    double? distanceKm,
    @JsonKey(name: 'estimated_duration', fromJson: safeIntOrNull)
    int? estimatedDuration,
    @JsonKey(name: 'total_amount', fromJson: safeDoubleOrNull)
    double? totalAmount,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _DeliveryOffer;

  factory DeliveryOffer.fromJson(Map<String, dynamic> json) =>
      _$DeliveryOfferFromJson(json);
}

/// Statuts possibles d'une offre côté livreur
class OfferStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String expired = 'expired';
  static const String noCourierFound = 'no_courier_found';
  static const String cancelled = 'cancelled';
}

/// Raisons de refus prédéfinies
class OfferRejectionReason {
  static const String tooFar = 'too_far';
  static const String lowFee = 'low_fee';
  static const String busy = 'busy';
  static const String badWeather = 'bad_weather';
  static const String vehicleIssue = 'vehicle_issue';
  static const String other = 'other';

  static const Map<String, String> labels = {
    tooFar: 'Trop loin',
    lowFee: 'Rémunération trop basse',
    busy: 'Déjà occupé',
    badWeather: 'Mauvaises conditions météo',
    vehicleIssue: 'Problème véhicule',
    other: 'Autre raison',
  };
}
