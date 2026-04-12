import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_service.dart';
import '../../core/utils/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/courier_profile.dart';
import '../models/delivery.dart';
import '../models/chat_message.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.read(dioProvider));
});

class DeliveryRepository {
  final Dio _dio;

  DeliveryRepository(this._dio);

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
          if (kDebugMode) {
            debugPrint('⚠️ [Cache] Impossible de mettre en cache: $e');
          }
        }
      }

      return deliveries;
    } catch (e) {
      // 403 INCOMPLETE_KYC — retourner liste vide (KycBanner gère l'affichage)
      if (e is DioException && e.response?.statusCode == 403) {
        final errorCode = SafeJsonUtils.safeData(
          e.response?.data,
        )['error_code'];
        if (errorCode == 'INCOMPLETE_KYC') {
          return [];
        }
      }
      // En cas d'erreur réseau, tenter de récupérer depuis le cache
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError)) {
        if (kDebugMode) {
          debugPrint('📴 [Offline] Connexion perdue, utilisation du cache');
        }
        final cached = await OfflineService.instance
            .getCachedActiveDeliveries();
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
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];

        if (statusCode == 400) {
          throw Exception(
            message ??
                'Cette livraison ne peut pas être récupérée actuellement.',
          );
        } else if (statusCode == 403) {
          throw Exception(
            message ?? 'Vous n\'êtes pas autorisé à récupérer cette livraison.',
          );
        } else if (statusCode == 404) {
          throw Exception('Livraison introuvable.');
        }
      }
      throw Exception(
        'Impossible de confirmer la récupération. Vérifiez votre connexion.',
      );
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
      } catch (e) {
        // L'invalidation du cache ne doit pas faire échouer la complétion
        if (kDebugMode) debugPrint('⚠️ Cache invalidation failed: $e');
      }
    } catch (e) {
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }

  /// Update courier profile (name, phone, vehicle_type, vehicle_number)
  Future<void> updateCourierProfile({
    String? name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      if (vehicleType != null && vehicleType.isNotEmpty) {
        data['vehicle_type'] = vehicleType;
      }
      if (vehicleNumber != null) data['vehicle_number'] = vehicleNumber;

      if (data.isEmpty) return;

      await _dio.post(ApiConstants.updateCourierProfile, data: data);
      await CacheService.instance.invalidateProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final body = SafeJsonUtils.safeMap(e.response?.data);
        if (body.containsKey('message')) {
          throw Exception(body['message']);
        }
        if (body.containsKey('errors')) {
          final errors = body['errors'] as Map;
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            throw Exception(first.first);
          }
        }
      }
      throw Exception('Erreur lors de la mise à jour du profil');
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Erreur lors de la mise à jour du profil',
        ),
      );
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
      // Invalider le cache profil pour éviter que le re-fetch ne renvoie l'ancien statut
      await CacheService.instance.invalidateProfile();
      return response.data?['data']?['status'] == 'available';
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];
        final errorCode = SafeJsonUtils.safeData(
          e.response?.data,
        )['error_code'];

        if (statusCode == 403) {
          if (errorCode == 'COURIER_PROFILE_NOT_FOUND') {
            throw Exception(
              'Votre compte n\'est pas configuré comme coursier. Veuillez vous déconnecter et utiliser un compte coursier.',
            );
          }
          if (errorCode == 'INCOMPLETE_KYC') {
            final reason = SafeJsonUtils.safeData(
              e.response?.data,
            )['rejection_reason'];
            throw IncompleteKycException(
              rejectionReason: reason is String ? reason : null,
            );
          }
          throw Exception(
            message ?? 'Accès refusé. Veuillez vous reconnecter.',
          );
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        }
      }
      throw Exception(
        'Impossible de changer le statut. Vérifiez votre connexion.',
      );
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _dio.post(
        ApiConstants.location,
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de mettre à jour la position.',
        ),
      );
    }
  }

  Future<CourierProfile> getProfile() async {
    // Toujours appeler l'API pour avoir le profil à jour (notamment kyc_status).
    // Le cache sert uniquement de fallback en cas d'erreur réseau.
    try {
      final response = await _dio.get(ApiConstants.profile);
      final data = response.data['data'];
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Profil coursier introuvable.');
      }

      // Sauvegarder dans le cache (non-bloquant)
      try {
        await CacheService.instance.cacheCourierProfile(data);
      } catch (_) {}

      final profile = CourierProfile.fromJson(data);

      // Vérifier le statut du coursier même sur une réponse 200
      final status = profile.status;
      if (status == 'suspended') {
        throw PendingApprovalException(
          userMessage: 'Votre compte a été suspendu.',
          code: 'SUSPENDED',
          status: status,
        );
      }
      if (status == 'rejected') {
        throw PendingApprovalException(
          userMessage: 'Votre demande a été refusée.',
          code: 'REJECTED',
          status: status,
        );
      }

      return profile;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = SafeJsonUtils.safeData(e.response?.data);
      final message = responseData['message'] as String?;
      final errorCode = responseData['error_code'] as String?;

      if (kDebugMode) {
        debugPrint(
          '❌ [Profile] API error: status=$statusCode, code=$errorCode, message=$message',
        );
      }

      // 401 - Non authentifié
      if (statusCode == 401 || errorCode == 'UNAUTHENTICATED') {
        throw const SessionExpiredException();
      }

      // 403 - Erreurs de profil/statut coursier
      if (statusCode == 403) {
        if (errorCode == 'COURIER_PROFILE_NOT_FOUND' ||
            errorCode == 'COURIER_PROFILE_MISSING') {
          throw const ForbiddenException(
            message: 'Courier profile not found',
            userMessage: 'Ce compte n\'est pas un compte livreur.',
            code: 'COURIER_PROFILE_NOT_FOUND',
          );
        }
        if (errorCode == 'PENDING_APPROVAL' ||
            (message != null && message.contains('attente'))) {
          throw PendingApprovalException(
            userMessage:
                message ?? 'Votre compte est en attente d\'approbation.',
            status: 'pending_approval',
          );
        }
        if (errorCode == 'SUSPENDED' ||
            (message != null && message.contains('suspendu'))) {
          throw PendingApprovalException(
            userMessage: message ?? 'Votre compte a été suspendu.',
            code: 'SUSPENDED',
            status: 'suspended',
          );
        }
        if (errorCode == 'REJECTED' ||
            (message != null && message.contains('refusé'))) {
          throw PendingApprovalException(
            userMessage: message ?? 'Votre demande a été refusée.',
            code: 'REJECTED',
            status: 'rejected',
          );
        }
        if (errorCode == 'INCOMPLETE_KYC') {
          // Retourner un profil minimal pour que le dashboard charge
          // Le KycBanner et KycGuard gèrent les restrictions
          return CourierProfile(
            id: 0,
            name: '',
            email: '',
            status: 'inactive',
            vehicleType: '',
            plateNumber: '',
            rating: 0.0,
            completedDeliveries: 0,
            earnings: 0.0,
            kycStatus: 'incomplete',
          );
        }
        // Passer le vrai message serveur pour les 403 non reconnus
        throw ForbiddenException(userMessage: message ?? 'Accès refusé.');
      }

      // Erreur réseau explicite — tenter le cache en fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        try {
          final cached = await CacheService.instance
              .getCachedCourierProfile()
              .timeout(const Duration(seconds: 2));
          if (cached != null) {
            if (kDebugMode) {
              debugPrint('📦 [Profile] Fallback cache (erreur réseau)');
            }
            return CourierProfile.fromJson(cached);
          }
        } catch (_) {}
        throw const NetworkException();
      }

      // Autres erreurs serveur (500, etc.) - propager le message serveur
      if (statusCode != null && statusCode >= 500) {
        throw ServerException(
          userMessage: 'Erreur serveur ($statusCode). Réessayez plus tard.',
        );
      }

      throw ApiException(
        message: 'API error $statusCode',
        userMessage: message ?? 'Erreur de communication avec le serveur.',
        statusCode: statusCode,
      );
    } catch (e) {
      // Re-throw si c'est déjà une AppException typée
      if (e is AppException) rethrow;
      if (kDebugMode) debugPrint('❌ [Profile] Unexpected error: $e');
      throw Exception('Impossible de charger le profil: $e');
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

  Future<ChatMessage> sendMessage(
    int orderId,
    String content,
    String target,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.messages(orderId),
        data: {'content': content, 'target': target},
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
  Future<Map<String, dynamic>> batchAcceptDeliveries(
    List<int> deliveryIds,
  ) async {
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
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de calculer l\'itinéraire.',
        ),
      );
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
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible d\'enregistrer la notation.',
        ),
      );
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
