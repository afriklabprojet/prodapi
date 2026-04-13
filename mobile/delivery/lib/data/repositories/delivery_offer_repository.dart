import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/delivery_offer.dart';

final deliveryOfferRepositoryProvider = Provider<DeliveryOfferRepository>((
  ref,
) {
  return DeliveryOfferRepository(ref.read(dioProvider));
});

class DeliveryOfferRepository {
  final Dio _dio;

  DeliveryOfferRepository(this._dio);

  /// Récupère les offres broadcast en attente pour ce livreur
  Future<List<DeliveryOffer>> getPendingOffers() async {
    try {
      final response = await _dio.get(
        ApiConstants.deliveryOffers,
        queryParameters: {'status': 'pending'},
      );

      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => DeliveryOffer.fromJson(_flattenOfferJson(e)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DeliveryOfferRepo] getPendingOffers error: $e');
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Accepter une offre de livraison broadcast
  Future<void> acceptOffer(int offerId) async {
    try {
      await _dio.post(ApiConstants.acceptOffer(offerId));
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];

        if (statusCode == 409) {
          throw Exception(
            message ?? 'Cette offre a déjà été acceptée par un autre livreur.',
          );
        }
        if (statusCode == 410) {
          throw Exception(message ?? 'Cette offre a expiré.');
        }
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Refuser une offre avec raison optionnelle
  Future<void> rejectOffer(int offerId, {String? reason}) async {
    try {
      await _dio.post(
        ApiConstants.rejectOffer(offerId),
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DeliveryOfferRepo] rejectOffer error: $e');
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Marquer l'offre comme vue (pour tracking analytics)
  Future<void> markOfferViewed(int offerId) async {
    try {
      await _dio.post(ApiConstants.viewOffer(offerId));
    } catch (e) {
      // Non-bloquant : le tracking ne doit pas empêcher l'UX
      if (kDebugMode) {
        debugPrint('⚠️ [DeliveryOfferRepo] markOfferViewed error: $e');
      }
    }
  }

  /// Aplatit la réponse API imbriquée (pickup/dropoff) en champs plats
  /// pour matcher le modèle Freezed DeliveryOffer.
  Map<String, dynamic> _flattenOfferJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    final pickup = json['pickup'] as Map<String, dynamic>?;
    final dropoff = json['dropoff'] as Map<String, dynamic>?;

    // Mapper les champs imbriqués vers les champs plats du modèle
    json['status'] = json['status'] ?? 'pending';
    json['base_fee'] = json['estimated_earnings'] ?? json['base_fee'] ?? 0;
    json['bonus_fee'] = json['bonus_fee'] ?? 0;
    json['total_amount'] =
        json['estimated_earnings'] ?? json['total_amount'] ?? 0;

    if (pickup != null) {
      json['pharmacy_name'] = pickup['name'];
      json['pharmacy_address'] = pickup['address'];
      json['pharmacy_phone'] = pickup['phone'];
      json['pharmacy_latitude'] = pickup['latitude'];
      json['pharmacy_longitude'] = pickup['longitude'];
    }

    if (dropoff != null) {
      json['delivery_address'] = dropoff['address'];
      json['delivery_latitude'] = dropoff['latitude'];
      json['delivery_longitude'] = dropoff['longitude'];
    }

    json['distance_km'] = json['estimated_distance_km'] ?? json['distance_km'];

    return json;
  }
}
