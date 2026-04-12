import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/data/models/delivery_filters.dart';

void main() {
  group('HistoryFiltersNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is empty filters', () {
      final filters = container.read(historyFiltersProvider);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('setDateRange updates dates', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 1, 31);
      notifier.setDateRange(from, to);

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, from);
      expect(filters.dateTo, to);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('setStatus updates status', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setStatus('delivered');

      final filters = container.read(historyFiltersProvider);
      expect(filters.status, 'delivered');
      expect(filters.hasActiveFilters, isTrue);
    });

    test('setPharmacy updates pharmacy', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPharmacy('1', 'Pharmacie X');

      final filters = container.read(historyFiltersProvider);
      expect(filters.pharmacyId, '1');
      expect(filters.pharmacyName, 'Pharmacie X');
    });

    test('setSortBy updates sort', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setSortBy(SortBy.amount);

      final filters = container.read(historyFiltersProvider);
      expect(filters.sortBy, SortBy.amount);
    });

    test('setSortOrder updates order', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setSortOrder(SortOrder.asc);

      final filters = container.read(historyFiltersProvider);
      expect(filters.sortOrder, SortOrder.asc);
    });

    test('setAmountRange updates amounts', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setAmountRange(1000, 5000);

      final filters = container.read(historyFiltersProvider);
      expect(filters.minAmount, 1000);
      expect(filters.maxAmount, 5000);
    });

    test('setPreset today', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPreset('today');

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateTo, isNotNull);
    });

    test('setPreset week', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPreset('week');

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
    });

    test('setPreset month', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPreset('month');

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
    });

    test('setPreset unknown resets to empty', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPreset('today'); // set something first
      notifier.setPreset('unknown');

      final filters = container.read(historyFiltersProvider);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('clearFilters resets everything', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setStatus('delivered');
      notifier.setSortBy(SortBy.amount);
      notifier.clearFilters();

      final filters = container.read(historyFiltersProvider);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('clearDateRange clears dates only', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setDateRange(DateTime(2024, 1, 1), DateTime(2024, 1, 31));
      notifier.setStatus('delivered');
      notifier.clearDateRange();

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.status, 'delivered'); // preserved
    });

    test('clearStatus clears status only', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setStatus('delivered');
      notifier.clearStatus();

      final filters = container.read(historyFiltersProvider);
      expect(filters.status, isNull);
    });

    test('clearPharmacy clears pharmacy only', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPharmacy('1', 'Pharma');
      notifier.clearPharmacy();

      final filters = container.read(historyFiltersProvider);
      expect(filters.pharmacyId, isNull);
      expect(filters.pharmacyName, isNull);
    });

    test('setDateRange with null values keeps existing dates', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 1, 31);
      notifier.setDateRange(from, to);
      // Passing null keeps existing values due to ?? operator in copyWith
      notifier.setDateRange(null, null);

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, from);
      expect(filters.dateTo, to);
    });

    test('partial date update keeps other date', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 1, 31);
      notifier.setDateRange(from, to);
      // Update only 'from', 'to' stays
      final newFrom = DateTime(2024, 2, 1);
      notifier.setDateRange(newFrom, null);

      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, newFrom);
      expect(filters.dateTo, to);
    });

    test('setStatus with null keeps existing status', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setStatus('delivered');
      notifier.setStatus(null);

      // null falls back to existing value via ??
      final filters = container.read(historyFiltersProvider);
      expect(filters.status, 'delivered');
    });

    test('setPharmacy with null values keeps existing pharmacy', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setPharmacy('1', 'Pharma');
      notifier.setPharmacy(null, null);

      // Null values keep existing via ??
      final filters = container.read(historyFiltersProvider);
      expect(filters.pharmacyId, '1');
      expect(filters.pharmacyName, 'Pharma');
    });

    test('setAmountRange with null values keeps existing amounts', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setAmountRange(100, 500);
      notifier.setAmountRange(null, null);

      // Null values keep existing via ??
      final filters = container.read(historyFiltersProvider);
      expect(filters.minAmount, 100);
      expect(filters.maxAmount, 500);
    });

    test('setAmountRange with min only', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setAmountRange(100, null);

      final filters = container.read(historyFiltersProvider);
      expect(filters.minAmount, 100);
      expect(filters.maxAmount, isNull);
    });

    test('setAmountRange with max only', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setAmountRange(null, 500);

      final filters = container.read(historyFiltersProvider);
      expect(filters.minAmount, isNull);
      expect(filters.maxAmount, 500);
    });

    test('multiple filters can be combined', () {
      final notifier = container.read(historyFiltersProvider.notifier);
      notifier.setStatus('delivered');
      notifier.setSortBy(SortBy.amount);
      notifier.setSortOrder(SortOrder.desc);
      notifier.setAmountRange(100, 1000);

      final filters = container.read(historyFiltersProvider);
      expect(filters.status, 'delivered');
      expect(filters.sortBy, SortBy.amount);
      expect(filters.sortOrder, SortOrder.desc);
      expect(filters.minAmount, 100);
      expect(filters.maxAmount, 1000);
      expect(filters.hasActiveFilters, isTrue);
    });
  });

  group('PharmacyOption', () {
    test('creates instance with id and name', () {
      const option = PharmacyOption(id: '123', name: 'Pharmacie ABC');
      expect(option.id, '123');
      expect(option.name, 'Pharmacie ABC');
    });

    test('supports empty values', () {
      const option = PharmacyOption(id: '', name: '');
      expect(option.id, '');
      expect(option.name, '');
    });

    test('handles special characters in name', () {
      const option = PharmacyOption(id: '1', name: "Pharmacie de l'Étoile");
      expect(option.name, "Pharmacie de l'Étoile");
    });
  });

  group('HistoryStats', () {
    test('creates instance with all values', () {
      const stats = HistoryStats(
        totalDeliveries: 100,
        delivered: 80,
        cancelled: 20,
        totalEarnings: 15000.0,
      );
      expect(stats.totalDeliveries, 100);
      expect(stats.delivered, 80);
      expect(stats.cancelled, 20);
      expect(stats.totalEarnings, 15000.0);
    });

    test('successRate calculates percentage correctly', () {
      const stats = HistoryStats(
        totalDeliveries: 100,
        delivered: 80,
        cancelled: 20,
        totalEarnings: 15000.0,
      );
      expect(stats.successRate, 80.0);
    });

    test('successRate returns 0 when totalDeliveries is 0', () {
      const stats = HistoryStats(
        totalDeliveries: 0,
        delivered: 0,
        cancelled: 0,
        totalEarnings: 0.0,
      );
      expect(stats.successRate, 0.0);
    });

    test('successRate with 100% success', () {
      const stats = HistoryStats(
        totalDeliveries: 50,
        delivered: 50,
        cancelled: 0,
        totalEarnings: 5000.0,
      );
      expect(stats.successRate, 100.0);
    });

    test('successRate with 0% success', () {
      const stats = HistoryStats(
        totalDeliveries: 50,
        delivered: 0,
        cancelled: 50,
        totalEarnings: 0.0,
      );
      expect(stats.successRate, 0.0);
    });

    test('successRate with fractional percentage', () {
      const stats = HistoryStats(
        totalDeliveries: 3,
        delivered: 1,
        cancelled: 2,
        totalEarnings: 500.0,
      );
      expect(stats.successRate, closeTo(33.33, 0.01));
    });

    test('handles large numbers', () {
      const stats = HistoryStats(
        totalDeliveries: 1000000,
        delivered: 950000,
        cancelled: 50000,
        totalEarnings: 150000000.0,
      );
      expect(stats.successRate, 95.0);
      expect(stats.totalEarnings, 150000000.0);
    });

    test('handles zero earnings with deliveries', () {
      const stats = HistoryStats(
        totalDeliveries: 10,
        delivered: 8,
        cancelled: 2,
        totalEarnings: 0.0,
      );
      expect(stats.successRate, 80.0);
      expect(stats.totalEarnings, 0.0);
    });
  });
}
