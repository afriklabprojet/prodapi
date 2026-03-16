import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_service.dart';
import '../../core/utils/error_handler.dart';
import '../models/courier_profile.dart';
import '../models/delivery.dart';
import '../models/chat_message.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.read(dioProvider));
});

class DeliveryRepository {
  final Dio _dio;

  DeliveryRepository(this._dio);

  /// Parse sécurisé des réponses API (protège contre data qui n'est pas un Map)
  static Map<String, dynamic> _safeData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<List<Delivery>> getDeliveries({String status = 'pending'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.deliveries,
        queryParameters: {'status': status},
      );

      final data = response.data['data'];
      if (data is! List) return [];
      final deliveries = data.map((e) => Delivery.fromJson(e)).toList();
      
      // Cache les livraisons actives pour mode hors-ligne (non-bloquant)
      if (status == 'active' || status == 'assigned' || status == 'picked_up') {
        try {
          await OfflineService.instance.cacheActiveDeliveries(deliveries);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ [Cache] Impossible de mettre en cache: $e');
        }
      }
      
      return deliveries;
    } catch (e) {
      // En cas d'erreur réseau, tenter de récupérer depuis le cache
      if (e is DioException && 
          (e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.connectionError)) {
        if (kDebugMode) debugPrint('📴 [Offline] Connexion perdue, utilisation du cache');
        final cached = await OfflineService.instance.getCachedActiveDeliveries();
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Récupère une livraison par son ID
  Future<Delivery> getDeliveryById(int id) async {
    try {
      final response = await _dio.get(ApiConstants.deliveryShow(id));
      final data = response.data['data'];
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Livraison introuvable.');
      }
      return Delivery.fromJson(data);
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  Future<void> acceptDelivery(int id) async {
    try {
      await _dio.post(ApiConstants.acceptDelivery(id));
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  Future<void> pickupDelivery(int id) async {
    try {
      await _dio.post(ApiConstants.pickupDelivery(id));
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = _safeData(e.response?.data)['message'];
        
        if (statusCode == 400) {
          throw Exception(message ?? 'Cette livraison ne peut pas être récupérée actuellement.');
        } else if (statusCode == 403) {
          throw Exception(message ?? 'Vous n\'êtes pas autorisé à récupérer cette livraison.');
        } else if (statusCode == 404) {
          throw Exception('Livraison introuvable.');
        }
      }
      throw Exception('Impossible de confirmer la récupération. Vérifiez votre connexion.');
    }
  }

  Future<void> completeDelivery(int id, String code) async {
    try {
      await _dio.post(
        ApiConstants.completeDelivery(id),
        data: {'confirmation_code': code},
      );
      // Invalider wallet et stats après livraison complétée (non-bloquant)
      try {
        await CacheService.instance.invalidateWallet();
        await CacheService.instance.invalidateStatistics();
      } catch (_) {
        // L'invalidation du cache ne doit pas faire échouer la complétion
      }
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Toggle ou définit la disponibilité du coursier
  /// [desiredStatus] : 'available' pour en ligne, 'offline' pour hors ligne
  /// Si null, fait un toggle basé sur l'état actuel du serveur
  Future<bool> toggleAvailability({String? desiredStatus}) async {
    try {
      final response = await _dio.post(
        ApiConstants.availability,
        data: desiredStatus != null ? {'status': desiredStatus} : null,
      );
      return response.data?['data']?['status'] == 'available';
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = _safeData(e.response?.data)['message'];
        final errorCode = _safeData(e.response?.data)['error_code'];
        
        if (statusCode == 403) {
          if (errorCode == 'COURIER_PROFILE_NOT_FOUND') {
            throw Exception('Votre compte n\'est pas configuré comme coursier. Veuillez vous déconnecter et utiliser un compte coursier.');
          }
          throw Exception(message ?? 'Accès refusé. Veuillez vous reconnecter.');
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        }
      }
      throw Exception('Impossible de changer le statut. Vérifiez votre connexion.');
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _dio.post(
        ApiConstants.location,
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de mettre à jour la position.'));
    }
  }

  Future<CourierProfile> getProfile() async {
    // Tenter de lire le cache d'abord
    final cache = CacheService.instance;
    final cached = await cache.getCachedCourierProfile();
    if (cached != null) {
      return CourierProfile.fromJson(cached);
    }

    try {
      final response = await _dio.get(ApiConstants.profile);
      final data = response.data['data'];
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Profil coursier introuvable.');
      }

      // Sauvegarder dans le cache
      await cache.cacheCourierProfile(data);

      return CourierProfile.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = _safeData(e.response?.data)['message'];
        final errorCode = _safeData(e.response?.data)['error_code'];
        
        if (statusCode == 403) {
          if (errorCode == 'COURIER_PROFILE_NOT_FOUND') {
            throw Exception('Profil coursier non trouvé. Ce compte n\'est pas un compte livreur.');
          }
          throw Exception(message ?? 'Accès refusé.');
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        }
      }
      throw Exception('Impossible de charger le profil.');
    }
  }

  Future<List<ChatMessage>> getMessages(int orderId, String target) async {
    try {
      final response = await _dio.get(
        ApiConstants.messages(orderId),
        queryParameters: {'is_courier': 1, 'target': target},
      );
      final data = response.data['data'];
      if (data is! List) return [];
      return data.map((e) => ChatMessage.fromJson(e)).toList();
    } catch (e) {
      throw Exception(ErrorHandler.getChatErrorMessage(e));
    }
  }

  Future<ChatMessage> sendMessage(int orderId, String content, String target) async {
    try {
      final response = await _dio.post(
        ApiConstants.messages(orderId),
        data: {
          'content': content, 
          'target': target
        },
      );
      final msgData = response.data['data'];
      if (msgData == null || msgData is! Map<String, dynamic>) {
        throw Exception('Réponse inattendue lors de l\'envoi du message.');
      }
      return ChatMessage.fromJson(msgData);
    } catch (e) {
      throw Exception(ErrorHandler.getChatErrorMessage(e));
    }
  }

  /// Accepter plusieurs livraisons en batch (max 5)
  Future<Map<String, dynamic>> batchAcceptDeliveries(List<int> deliveryIds) async {
    try {
      final response = await _dio.post(
        ApiConstants.batchAcceptDeliveries,
        data: {'delivery_ids': deliveryIds},
      );
      return response.data['data'];
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Récupérer l'itinéraire optimisé pour les livraisons actives
  Future<Map<String, dynamic>> getOptimizedRoute() async {
    try {
      final response = await _dio.get(ApiConstants.deliveriesRoute);
      return response.data['data'];
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de calculer l\'itinéraire.'));
    }
  }

  /// Noter un client après une livraison
  Future<void> rateCustomer({
    required int deliveryId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    try {
      await _dio.post(
        ApiConstants.rateCustomer(deliveryId),
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
        },
      );
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible d\'enregistrer la notation.'));
    }
  }

  Future<void> rejectDelivery(int id) async {
    try {
      await _dio.post(ApiConstants.rejectDelivery(id));
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }
}
