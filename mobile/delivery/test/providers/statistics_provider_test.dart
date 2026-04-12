import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/statistics_repository.dart';
import 'package:courier/data/models/statistics.dart';
import 'package:courier/presentation/providers/statistics_provider.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  group('statisticsProvider', () {
    late MockStatisticsRepository mockRepo;

    setUp(() {
      mockRepo = MockStatisticsRepository();
    });

    test('returns Statistics for a given period', () async {
      when(
        () => mockRepo.getStatistics(period: 'week'),
      ).thenAnswer((_) async => _testStats);

      final container = ProviderContainer(
        overrides: [statisticsRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(statisticsProvider('week').future);
      expect(result, isA<Statistics>());
      expect(result.period, 'week');
      verify(() => mockRepo.getStatistics(period: 'week')).called(1);
    });

    test('returns Statistics for month period', () async {
      when(
        () => mockRepo.getStatistics(period: 'month'),
      ).thenAnswer((_) async => _testStats);

      final container = ProviderContainer(
        overrides: [statisticsRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(statisticsProvider('month').future);
      expect(result, isA<Statistics>());
    });

    test('calls repository with correct period argument', () async {
      when(
        () => mockRepo.getStatistics(period: 'day'),
      ).thenAnswer((_) async => _testStats);

      final container = ProviderContainer(
        overrides: [statisticsRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      await container.read(statisticsProvider('day').future);
      verify(() => mockRepo.getStatistics(period: 'day')).called(1);
    });
  });
}

final _testStats = Statistics.fromJson(const {
  'period': 'week',
  'start_date': '2024-01-08',
  'end_date': '2024-01-14',
  'overview': {
    'total_deliveries': 10,
    'completed_deliveries': 9,
    'cancelled_deliveries': 1,
    'total_earnings': 5000,
    'average_delivery_time': 25,
  },
  'performance': {
    'acceptance_rate': 95.0,
    'completion_rate': 90.0,
    'on_time_rate': 85.0,
    'average_rating': 4.8,
    'total_distance': 45.5,
  },
});
