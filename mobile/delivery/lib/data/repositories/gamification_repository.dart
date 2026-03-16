import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/gamification.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(dioProvider));
});

/// Provider pour les données de gamification
final gamificationProvider = FutureProvider.autoDispose<GamificationData>((ref) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getGamificationData();
});

/// Provider pour le leaderboard seul
final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, period) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getLeaderboard(period: period);
});

/// Provider pour les défis quotidiens
final dailyChallengesProvider = FutureProvider.autoDispose<DailyChallengesData>((ref) async {
  final repo = ref.read(gamificationRepositoryProvider);
  return repo.getDailyChallenges();
});

class GamificationRepository {
  final Dio _dio;

  GamificationRepository(this._dio);

  /// Parse sécurisé des réponses API
  static Map<String, dynamic> _safeData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  /// Récupérer toutes les données de gamification
  Future<GamificationData> getGamificationData() async {
    try {
      final response = await _dio.get('/api/courier/gamification');
      return GamificationData.fromJson(_safeData(response.data)['data'] ?? _safeData(response.data));
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de charger la gamification';
      throw Exception(message);
    }
  }

  /// Récupérer le leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({String period = 'week'}) async {
    try {
      final response = await _dio.get('/api/courier/leaderboard', queryParameters: {'period': period});
      final list = _safeData(response.data)['data'] as List? ?? [];
      return list.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de charger le classement';
      throw Exception(message);
    }
  }

  /// Récupérer les badges
  Future<List<GamificationBadge>> getBadges() async {
    try {
      final response = await _dio.get('/api/courier/badges');
      final list = _safeData(response.data)['data'] as List? ?? [];
      return list.map((e) => GamificationBadge.fromJson(e)).toList();
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de charger les badges';
      throw Exception(message);
    }
  }

  /// Récupérer le niveau
  Future<CourierLevel> getLevel() async {
    try {
      final response = await _dio.get('/api/courier/level');
      final data = _safeData(response.data);
      return CourierLevel.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de charger le niveau';
      throw Exception(message);
    }
  }

  /// Récupérer les défis quotidiens
  Future<DailyChallengesData> getDailyChallenges() async {
    try {
      final response = await _dio.get('/api/courier/challenges');
      final data = _safeData(response.data);
      return DailyChallengesData.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de charger les défis';
      throw Exception(message);
    }
  }

  /// Réclamer la récompense d'un défi
  Future<bool> claimChallengeReward(String challengeId) async {
    try {
      await _dio.post('/api/courier/challenges/$challengeId/claim');
      return true;
    } on DioException catch (e) {
      final message = _safeData(e.response?.data)['message'] ?? 'Impossible de réclamer la récompense';
      throw Exception(message);
    }
  }
}
