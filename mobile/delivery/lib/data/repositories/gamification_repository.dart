import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/gamification.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(dioProvider));
});

/// Provider pour les données de gamification
final gamificationProvider = FutureProvider.autoDispose<GamificationData>((
  ref,
) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getGamificationData();
});

/// Provider pour le leaderboard seul
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, String>((ref, period) async {
      final repo = ref.read(gamificationRepositoryProvider);
      return repo.getLeaderboard(period: period);
    });

/// Provider pour les défis quotidiens
final dailyChallengesProvider = FutureProvider.autoDispose<DailyChallengesData>(
  (ref) async {
    final repo = ref.read(gamificationRepositoryProvider);
    return repo.getDailyChallenges();
  },
);

class GamificationRepository {
  final Dio _dio;

  GamificationRepository(this._dio);

  /// Récupérer toutes les données de gamification
  Future<GamificationData> getGamificationData() async {
    try {
      final response = await _dio.get('/courier/gamification');
      return GamificationData.fromJson(
        SafeJsonUtils.safeData(response.data)['data'] ??
            SafeJsonUtils.safeData(response.data),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorCode = SafeJsonUtils.safeData(e.response?.data)['error_code'];
      if (statusCode == 403 && errorCode == 'INCOMPLETE_KYC' ||
          statusCode == 404) {
        return const GamificationData(
          level: CourierLevel(
            level: 1,
            title: 'Débutant',
            currentXP: 0,
            requiredXP: 100,
            totalXP: 0,
            color: Color(0xFFCD7F32),
          ),
          badges: [],
          recentBadges: [],
          leaderboard: [],
        );
      }
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible de charger la gamification';
      throw Exception(message);
    }
  }

  /// Récupérer le leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    String period = 'week',
  }) async {
    try {
      final response = await _dio.get(
        '/courier/leaderboard',
        queryParameters: {'period': period},
      );
      final list = SafeJsonUtils.safeData(response.data)['data'] as List? ?? [];
      return list.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorCode = SafeJsonUtils.safeData(e.response?.data)['error_code'];
      if (statusCode == 403 && errorCode == 'INCOMPLETE_KYC' ||
          statusCode == 404) {
        return [];
      }
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible de charger le classement';
      throw Exception(message);
    }
  }

  /// Récupérer les badges
  Future<List<GamificationBadge>> getBadges() async {
    try {
      final response = await _dio.get('/courier/badges');
      final list = SafeJsonUtils.safeData(response.data)['data'] as List? ?? [];
      return list.map((e) => GamificationBadge.fromJson(e)).toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorCode = SafeJsonUtils.safeData(e.response?.data)['error_code'];
      if (statusCode == 403 && errorCode == 'INCOMPLETE_KYC' ||
          statusCode == 404) {
        return [];
      }
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible de charger les badges';
      throw Exception(message);
    }
  }

  /// Récupérer le niveau
  Future<CourierLevel> getLevel() async {
    try {
      final response = await _dio.get('/courier/level');
      final data = SafeJsonUtils.safeData(response.data);
      return CourierLevel.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorCode = SafeJsonUtils.safeData(e.response?.data)['error_code'];
      if (statusCode == 403 && errorCode == 'INCOMPLETE_KYC' ||
          statusCode == 404) {
        return const CourierLevel(
          level: 1,
          title: 'Débutant',
          currentXP: 0,
          requiredXP: 100,
          totalXP: 0,
          color: Color(0xFFCD7F32),
        );
      }
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible de charger le niveau';
      throw Exception(message);
    }
  }

  /// Récupérer les défis quotidiens
  Future<DailyChallengesData> getDailyChallenges() async {
    try {
      final response = await _dio.get('/courier/challenges');
      final data = SafeJsonUtils.safeData(response.data);
      return DailyChallengesData.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = SafeJsonUtils.safeData(e.response?.data)['message'];
      final errorCode = SafeJsonUtils.safeData(e.response?.data)['error_code'];

      if (statusCode == 403 && errorCode == 'INCOMPLETE_KYC' ||
          statusCode == 404) {
        return const DailyChallengesData(challenges: []);
      }
      if (statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (statusCode != null && statusCode >= 500) {
        throw Exception(
          'Le serveur rencontre un problème. Réessayez dans quelques instants.',
        );
      }
      throw Exception(message ?? 'Impossible de charger les défis.');
    }
  }

  /// Réclamer la récompense d'un défi
  Future<bool> claimChallengeReward(String challengeId) async {
    try {
      await _dio.post('/courier/challenges/$challengeId/claim');
      return true;
    } on DioException catch (e) {
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible de réclamer la récompense';
      throw Exception(message);
    }
  }
}
