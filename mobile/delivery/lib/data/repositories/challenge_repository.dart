import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(ref.read(dioProvider));
});

class ChallengeRepository {
  final Dio _dio;

  ChallengeRepository(this._dio);



  /// Récupérer les challenges et bonus actifs
  Future<Map<String, dynamic>> getChallenges() async {
    try {
      final response = await _dio.get(ApiConstants.challenges);
      final data = SafeJsonUtils.safeData(response.data)['data'];
      // L'API peut retourner un Map ou un List (ancien format)
      if (data is Map<String, dynamic>) return data;
      // Si c'est un List ou null, retourner une structure vide
      return _emptyChallengesResponse();
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];
        
        if (statusCode == 403 || statusCode == 404) {
          throw Exception(message ?? 'Profil coursier non trouvé.');
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Le serveur rencontre un problème. Réessayez dans quelques instants.');
        } else if (message != null) {
          throw Exception(message);
        }
      }
      throw Exception('Impossible de charger les défis. Vérifiez votre connexion.');
    }
  }

  static Map<String, dynamic> _emptyChallengesResponse() => {
    'challenges': {
      'in_progress': <Map<String, dynamic>>[],
      'completed': <Map<String, dynamic>>[],
      'rewarded': <Map<String, dynamic>>[],
    },
    'active_bonuses': <Map<String, dynamic>>[],
    'stats': {
      'in_progress_count': 0,
      'can_claim_count': 0,
      'rewarded_count': 0,
    },
  };

  /// Réclamer la récompense d'un défi complété
  Future<Map<String, dynamic>> claimReward(int challengeId) async {
    try {
      final response = await _dio.post(ApiConstants.claimChallenge(challengeId));
      return (SafeJsonUtils.safeData(response.data)['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];

        if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Le serveur rencontre un problème. Réessayez dans quelques instants.');
        }
        throw Exception(message ?? 'Erreur lors de la réclamation.');
      }
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de réclamer la récompense.'));
    }
  }

  /// Récupérer les bonus actifs
  Future<List<Map<String, dynamic>>> getActiveBonuses() async {
    try {
      final response = await _dio.get(ApiConstants.bonuses);
      return (SafeJsonUtils.safeData(response.data)['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de charger les bonus.'));
    }
  }

  /// Calculer le bonus potentiel pour une livraison
  Future<Map<String, dynamic>> calculateBonus(double baseEarnings) async {
    try {
      final response = await _dio.post(
        ApiConstants.calculateBonus,
        data: {'base_earnings': baseEarnings},
      );
      return SafeJsonUtils.safeData(response.data)['data'] ?? {};
    } catch (e) {
      throw Exception(ErrorHandler.getReadableMessage(e, defaultMessage: 'Impossible de calculer le bonus.'));
    }
  }
}
