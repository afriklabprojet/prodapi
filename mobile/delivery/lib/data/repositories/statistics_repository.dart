import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/statistics.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.read(dioProvider));
});

class StatisticsRepository {
  final Dio _dio;

  StatisticsRepository(this._dio);

  Future<Statistics> getStatistics({String period = 'week'}) async {
    // Tenter de lire le cache d'abord
    final cache = CacheService.instance;
    final cached = await cache.getCachedStatistics(period);
    if (cached != null) {
      return Statistics.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        ApiConstants.statistics,
        queryParameters: {'period': period},
      );

      final rawData = response.data['data'];
      final data = rawData is Map<String, dynamic>
          ? rawData
          : SafeJsonUtils.safeData(rawData);

      // Sauvegarder dans le cache
      await cache.cacheStatistics(period, data);

      return Statistics.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];
        final errorCode = SafeJsonUtils.safeData(
          e.response?.data,
        )['error_code'];

        if (statusCode == 403) {
          if (errorCode == 'INCOMPLETE_KYC') {
            // Retourner des stats vides pour que l'écran charge normalement
            return const Statistics(
              period: 'week',
              startDate: '',
              endDate: '',
              overview: StatsOverview(),
              performance: StatsPerformance(),
            );
          }
          if (errorCode == 'COURIER_PROFILE_NOT_FOUND') {
            throw Exception(
              'Profil coursier non trouvé. Ce compte n\'est pas un compte livreur.',
            );
          }
          throw Exception(message ?? 'Accès refusé.');
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        }
      }
      throw Exception('Impossible de charger les statistiques.');
    }
  }
}
