import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/statistics_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/core/services/cache_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late StatisticsRepository repo;

  setUp(() async {
    mockDio = MockDio();
    repo = StatisticsRepository(mockDio);
    await setupTestDependencies();
  });

  final statsJson = {
    'period': 'week',
    'start_date': '2026-02-06',
    'end_date': '2026-02-13',
    'overview': {
      'total_deliveries': 25,
      'total_earnings': 62500.0,
      'total_distance_km': 87.3,
      'total_duration_minutes': 540,
      'average_rating': 4.8,
    },
    'performance': {
      'total_assigned': 30,
      'total_accepted': 28,
      'total_delivered': 25,
      'total_cancelled': 2,
      'acceptance_rate': 93.3,
      'completion_rate': 89.3,
    },
    'daily_breakdown': [],
    'peak_hours': [],
  };

  group('getStatistics', () {
    test('returns Statistics from API', () async {
      when(() => mockDio.get(ApiConstants.statistics,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({'data': statsJson}));

      final stats = await repo.getStatistics(period: 'week');
      expect(stats.period, 'week');
      expect(stats.overview.totalDeliveries, 25);
      expect(stats.overview.totalEarnings, 62500.0);
      expect(stats.performance.acceptanceRate, 93.3);
    });

    test('serves from cache when available', () async {
      await CacheService.instance.cacheStatistics('week', statsJson);

      final stats = await repo.getStatistics(period: 'week');
      expect(stats.overview.totalDeliveries, 25);
      verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    test('caches data after successful API call', () async {
      when(() => mockDio.get(ApiConstants.statistics,
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({'data': statsJson}));

      await repo.getStatistics(period: 'month');

      // Second call should come from cache
      final stats = await repo.getStatistics(period: 'month');
      expect(stats.period, 'week'); // Same mock data
      verify(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('throws on 403 COURIER_PROFILE_NOT_FOUND', () async {
      when(() => mockDio.get(ApiConstants.statistics,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(
        statusCode: 403,
        data: {
          'error_code': 'COURIER_PROFILE_NOT_FOUND',
          'message': 'Profil non trouvé',
        },
      ));

      expect(
        () => repo.getStatistics(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('livreur'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.statistics,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.getStatistics(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('Session expirée'),
        )),
      );
    });

    test('throws generic on unknown error', () async {
      when(() => mockDio.get(ApiConstants.statistics,
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.getStatistics(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'msg',
          contains('statistiques'),
        )),
      );
    });
  });
}
