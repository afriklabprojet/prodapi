import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/data/models/delivery_filters.dart';

void main() {
  group('HistoryFiltersNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty filters', () {
      final filters = container.read(historyFiltersProvider);
      expect(filters.status, isNull);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.pharmacyId, isNull);
      expect(filters.pharmacyName, isNull);
    });

    test('setDateRange updates from and to dates', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);
      container.read(historyFiltersProvider.notifier).setDateRange(from, to);
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, from);
      expect(filters.dateTo, to);
    });

    test('setStatus updates status filter', () {
      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      expect(container.read(historyFiltersProvider).status, 'delivered');
    });

    test('setPharmacy updates pharmacy id and name', () {
      container
          .read(historyFiltersProvider.notifier)
          .setPharmacy('42', 'Pharmacie Test');
      final filters = container.read(historyFiltersProvider);
      expect(filters.pharmacyId, '42');
      expect(filters.pharmacyName, 'Pharmacie Test');
    });

    test('setSortBy updates sort field', () {
      container.read(historyFiltersProvider.notifier).setSortBy(SortBy.amount);
      expect(container.read(historyFiltersProvider).sortBy, SortBy.amount);
    });

    test('setSortOrder updates sort order', () {
      container
          .read(historyFiltersProvider.notifier)
          .setSortOrder(SortOrder.asc);
      expect(container.read(historyFiltersProvider).sortOrder, SortOrder.asc);
    });

    test('setAmountRange updates min and max amounts', () {
      container.read(historyFiltersProvider.notifier).setAmountRange(100, 5000);
      final filters = container.read(historyFiltersProvider);
      expect(filters.minAmount, 100);
      expect(filters.maxAmount, 5000);
    });

    test('setPreset today sets date range for today', () {
      container.read(historyFiltersProvider.notifier).setPreset('today');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateTo, isNotNull);
    });

    test('setPreset week sets date range for this week', () {
      container.read(historyFiltersProvider.notifier).setPreset('week');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
    });

    test('setPreset month sets date range for this month', () {
      container.read(historyFiltersProvider.notifier).setPreset('month');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
    });

    test('setPreset unknown resets to empty', () {
      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      container.read(historyFiltersProvider.notifier).setPreset('all');
      final filters = container.read(historyFiltersProvider);
      expect(filters.status, isNull);
    });

    test('clearFilters resets to empty state', () {
      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      container.read(historyFiltersProvider.notifier).setPharmacy('1', 'Test');
      container.read(historyFiltersProvider.notifier).clearFilters();
      final filters = container.read(historyFiltersProvider);
      expect(filters.status, isNull);
      expect(filters.pharmacyId, isNull);
    });

    test('clearDateRange clears dates only', () {
      container
          .read(historyFiltersProvider.notifier)
          .setDateRange(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      container.read(historyFiltersProvider.notifier).clearDateRange();
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.status, 'delivered');
    });

    test('clearStatus clears status only', () {
      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      container.read(historyFiltersProvider.notifier).setPharmacy('1', 'P');
      container.read(historyFiltersProvider.notifier).clearStatus();
      final filters = container.read(historyFiltersProvider);
      expect(filters.status, isNull);
      expect(filters.pharmacyId, '1');
    });

    test('clearPharmacy clears pharmacy only', () {
      container.read(historyFiltersProvider.notifier).setPharmacy('1', 'P');
      container.read(historyFiltersProvider.notifier).setStatus('cancelled');
      container.read(historyFiltersProvider.notifier).clearPharmacy();
      final filters = container.read(historyFiltersProvider);
      expect(filters.pharmacyName, isNull);
      expect(filters.status, 'cancelled');
    });
  });

  group('PharmacyOption', () {
    test('constructor', () {
      const option = PharmacyOption(id: '1', name: 'Test Pharmacy');
      expect(option.id, '1');
      expect(option.name, 'Test Pharmacy');
    });
  });

  group('HistoryStats', () {
    test('constructor and properties', () {
      const stats = HistoryStats(
        totalDeliveries: 100,
        delivered: 80,
        cancelled: 20,
        totalEarnings: 50000,
      );
      expect(stats.totalDeliveries, 100);
      expect(stats.delivered, 80);
      expect(stats.cancelled, 20);
      expect(stats.totalEarnings, 50000);
    });

    test('successRate calculates correctly', () {
      const stats = HistoryStats(
        totalDeliveries: 100,
        delivered: 80,
        cancelled: 20,
        totalEarnings: 50000,
      );
      expect(stats.successRate, 80.0);
    });

    test('successRate returns 0 for empty history', () {
      const stats = HistoryStats(
        totalDeliveries: 0,
        delivered: 0,
        cancelled: 0,
        totalEarnings: 0,
      );
      expect(stats.successRate, 0);
    });
  });
}
