import 'package:flutter_test/flutter_test.dart';
import 'package:courier/features/history/advanced_history_screen.dart';

void main() {
  group('HistoryPeriod', () {
    test('should have all expected values', () {
      expect(HistoryPeriod.values.length, 6);
      expect(HistoryPeriod.today.index, 0);
      expect(HistoryPeriod.week.index, 1);
      expect(HistoryPeriod.month.index, 2);
      expect(HistoryPeriod.quarter.index, 3);
      expect(HistoryPeriod.year.index, 4);
      expect(HistoryPeriod.custom.index, 5);
    });
  });

  group('ChartType', () {
    test('should have all expected values', () {
      expect(ChartType.values.length, 4);
      expect(ChartType.earnings.index, 0);
      expect(ChartType.deliveries.index, 1);
      expect(ChartType.distance.index, 2);
      expect(ChartType.rating.index, 3);
    });
  });

  group('HistoryFilter', () {
    test('should create with default values', () {
      const filter = HistoryFilter();

      expect(filter.period, HistoryPeriod.month);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.statuses, isEmpty);
      expect(filter.minAmount, isNull);
      expect(filter.maxAmount, isNull);
      expect(filter.pharmacyId, isNull);
      expect(filter.searchQuery, isNull);
      expect(filter.sortDescending, true);
      expect(filter.sortBy, 'date');
    });

    test('copyWith should update specified fields', () {
      const filter = HistoryFilter();

      final updated = filter.copyWith(
        period: HistoryPeriod.week,
        minAmount: 1000,
        maxAmount: 5000,
        sortBy: 'amount',
      );

      expect(updated.period, HistoryPeriod.week);
      expect(updated.minAmount, 1000);
      expect(updated.maxAmount, 5000);
      expect(updated.sortBy, 'amount');
      // Others should remain unchanged
      expect(updated.sortDescending, true);
      expect(updated.statuses, isEmpty);
    });

    test('should support status filtering', () {
      final filter = const HistoryFilter().copyWith(
        statuses: ['delivered', 'cancelled'],
      );

      expect(filter.statuses.length, 2);
      expect(filter.statuses, contains('delivered'));
      expect(filter.statuses, contains('cancelled'));
    });

    test('should support search query', () {
      final filter = const HistoryFilter().copyWith(
        searchQuery: 'Pharmacie du Centre',
      );

      expect(filter.searchQuery, 'Pharmacie du Centre');
    });

    test('dateRange should return today range', () {
      const filter = HistoryFilter(period: HistoryPeriod.today);
      final range = filter.dateRange;
      final today = DateTime.now();

      expect(range.start.year, today.year);
      expect(range.start.month, today.month);
      expect(range.start.day, today.day);
      expect(range.end.day, today.day);
    });

    test('dateRange should return week range', () {
      const filter = HistoryFilter(period: HistoryPeriod.week);
      final range = filter.dateRange;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      expect(range.start.day, weekAgo.day);
      expect(range.end.day, now.day);
    });

    test('dateRange should return month range', () {
      const filter = HistoryFilter(period: HistoryPeriod.month);
      final range = filter.dateRange;
      final now = DateTime.now();

      expect(range.end.day, now.day);
      // Start should be roughly 30 days ago
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(28));
      expect(diff.inDays, lessThanOrEqualTo(31));
    });

    test('dateRange should return quarter range', () {
      const filter = HistoryFilter(period: HistoryPeriod.quarter);
      final range = filter.dateRange;
      final now = DateTime.now();

      expect(range.end.day, now.day);
      // Start should be roughly 90 days ago
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(89));
      expect(diff.inDays, lessThanOrEqualTo(92));
    });

    test('dateRange should return year range', () {
      const filter = HistoryFilter(period: HistoryPeriod.year);
      final range = filter.dateRange;
      final now = DateTime.now();

      expect(range.end.day, now.day);
      // Start should be roughly 365 days ago
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(364));
      expect(diff.inDays, lessThanOrEqualTo(366));
    });

    test('dateRange should use custom dates when set', () {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 2, 28);

      final filter = HistoryFilter(
        period: HistoryPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      );
      final range = filter.dateRange;

      expect(range.start, startDate);
      expect(range.end, endDate);
    });

    test('sort ascending', () {
      final filter = const HistoryFilter().copyWith(
        sortDescending: false,
      );

      expect(filter.sortDescending, false);
    });

    test('sort by different fields', () {
      final byDate = const HistoryFilter().copyWith(sortBy: 'date');
      expect(byDate.sortBy, 'date');

      final byAmount = const HistoryFilter().copyWith(sortBy: 'amount');
      expect(byAmount.sortBy, 'amount');

      final byDistance = const HistoryFilter().copyWith(sortBy: 'distance');
      expect(byDistance.sortBy, 'distance');
    });

    test('filter by pharmacy', () {
      final filter = const HistoryFilter().copyWith(
        pharmacyId: 'pharmacy_001',
      );

      expect(filter.pharmacyId, 'pharmacy_001');
    });
  });
}
