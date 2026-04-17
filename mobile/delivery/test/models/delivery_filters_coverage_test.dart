import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery_filters.dart';

void main() {
  group('DeliveryFilters', () {
    test('empty factory creates default filters', () {
      final filters = DeliveryFilters.empty();
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.status, isNull);
      expect(filters.pharmacyId, isNull);
      expect(filters.pharmacyName, isNull);
      expect(filters.sortBy, SortBy.date);
      expect(filters.sortOrder, SortOrder.desc);
      expect(filters.minAmount, isNull);
      expect(filters.maxAmount, isNull);
    });

    test('today factory sets today date range', () {
      final filters = DeliveryFilters.today();
      final now = DateTime.now();
      expect(filters.dateFrom!.year, now.year);
      expect(filters.dateFrom!.month, now.month);
      expect(filters.dateFrom!.day, now.day);
      expect(filters.dateTo!.year, now.year);
      expect(filters.dateTo!.month, now.month);
      expect(filters.dateTo!.day, now.day);
    });

    test('thisWeek factory sets week date range', () {
      final filters = DeliveryFilters.thisWeek();
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateTo, isNotNull);
      // dateFrom should be Monday of current week
      expect(filters.dateFrom!.weekday, DateTime.monday);
    });

    test('thisMonth factory sets month date range', () {
      final filters = DeliveryFilters.thisMonth();
      final now = DateTime.now();
      expect(filters.dateFrom!.year, now.year);
      expect(filters.dateFrom!.month, now.month);
      expect(filters.dateFrom!.day, 1);
    });

    test('hasActiveFilters is false for empty', () {
      expect(DeliveryFilters.empty().hasActiveFilters, false);
    });

    test('hasActiveFilters is true with dateFrom', () {
      final f = DeliveryFilters(dateFrom: DateTime.now());
      expect(f.hasActiveFilters, true);
    });

    test('hasActiveFilters is true with status', () {
      const f = DeliveryFilters(status: 'delivered');
      expect(f.hasActiveFilters, true);
    });

    test('hasActiveFilters is false with status all', () {
      const f = DeliveryFilters(status: 'all');
      expect(f.hasActiveFilters, false);
    });

    test('hasActiveFilters is true with pharmacyId', () {
      const f = DeliveryFilters(pharmacyId: '1');
      expect(f.hasActiveFilters, true);
    });

    test('hasActiveFilters is true with minAmount', () {
      const f = DeliveryFilters(minAmount: 100);
      expect(f.hasActiveFilters, true);
    });

    test('hasActiveFilters is true with non-default sortBy', () {
      const f = DeliveryFilters(sortBy: SortBy.amount);
      expect(f.hasActiveFilters, true);
    });

    test('hasActiveFilters is true with non-default sortOrder', () {
      const f = DeliveryFilters(sortOrder: SortOrder.asc);
      expect(f.hasActiveFilters, true);
    });

    test('activeFilterCount counts correctly', () {
      const f = DeliveryFilters(
        dateFrom: null,
        dateTo: null,
        status: 'delivered',
        pharmacyId: '1',
        pharmacyName: 'Test',
        minAmount: 100,
        sortBy: SortBy.amount,
      );
      // status=1, pharmacy=1, amount=1, sortBy=1 = 4
      expect(f.activeFilterCount, 4);
    });

    test('activeFilterCount counts date as one filter', () {
      final f = DeliveryFilters(
        dateFrom: DateTime(2024, 1, 1),
        dateTo: DateTime(2024, 12, 31),
      );
      expect(f.activeFilterCount, 1);
    });

    test('activeFilterCount 0 for empty', () {
      expect(DeliveryFilters.empty().activeFilterCount, 0);
    });

    test('copyWith preserves values', () {
      const f = DeliveryFilters(status: 'delivered', sortBy: SortBy.amount);
      final copy = f.copyWith(pharmacyId: '1');
      expect(copy.status, 'delivered');
      expect(copy.sortBy, SortBy.amount);
      expect(copy.pharmacyId, '1');
    });

    test('copyWith with clearDateFrom', () {
      final f = DeliveryFilters(dateFrom: DateTime(2024, 1, 1));
      final copy = f.copyWith(clearDateFrom: true);
      expect(copy.dateFrom, isNull);
    });

    test('copyWith with clearStatus', () {
      const f = DeliveryFilters(status: 'delivered');
      final copy = f.copyWith(clearStatus: true);
      expect(copy.status, isNull);
    });

    test('copyWith with clearPharmacy', () {
      const f = DeliveryFilters(pharmacyId: '1', pharmacyName: 'Test');
      final copy = f.copyWith(clearPharmacy: true);
      expect(copy.pharmacyId, isNull);
      expect(copy.pharmacyName, isNull);
    });

    test('copyWith with clearAmount', () {
      const f = DeliveryFilters(minAmount: 100, maxAmount: 500);
      final copy = f.copyWith(clearAmount: true);
      expect(copy.minAmount, isNull);
      expect(copy.maxAmount, isNull);
    });

    test('equality', () {
      const a = DeliveryFilters(status: 'delivered');
      const b = DeliveryFilters(status: 'delivered');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality', () {
      const a = DeliveryFilters(status: 'delivered');
      const b = DeliveryFilters(status: 'cancelled');
      expect(a, isNot(equals(b)));
    });
  });

  group('SortBy', () {
    test('all values', () {
      expect(SortBy.values.length, 4);
      expect(SortBy.values, contains(SortBy.date));
      expect(SortBy.values, contains(SortBy.amount));
      expect(SortBy.values, contains(SortBy.pharmacyName));
      expect(SortBy.values, contains(SortBy.status));
    });
  });

  group('SortOrder', () {
    test('all values', () {
      expect(SortOrder.values.length, 2);
      expect(SortOrder.values, contains(SortOrder.asc));
      expect(SortOrder.values, contains(SortOrder.desc));
    });
  });
}
