import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery_filters.dart';

void main() {
  group('DeliveryFilters', () {
    test('empty factory has no active filters', () {
      final f = DeliveryFilters.empty();
      expect(f.hasActiveFilters, isFalse);
      expect(f.activeFilterCount, 0);
    });

    test('today factory sets date range', () {
      final f = DeliveryFilters.today();
      expect(f.dateFrom, isNotNull);
      expect(f.dateTo, isNotNull);
      expect(f.hasActiveFilters, isTrue);
      expect(f.activeFilterCount, 1); // dateFrom+dateTo count as 1
    });

    test('thisWeek factory sets date range', () {
      final f = DeliveryFilters.thisWeek();
      expect(f.dateFrom, isNotNull);
      expect(f.dateTo, isNotNull);
      expect(f.hasActiveFilters, isTrue);
    });

    test('thisMonth factory sets date range', () {
      final f = DeliveryFilters.thisMonth();
      expect(f.dateFrom, isNotNull);
      expect(f.dateTo, isNotNull);
    });

    test('hasActiveFilters detects status', () {
      final f = DeliveryFilters.empty().copyWith(status: 'delivered');
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters ignores status=all', () {
      final f = DeliveryFilters.empty().copyWith(status: 'all');
      expect(f.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters detects pharmacyId', () {
      final f = DeliveryFilters.empty().copyWith(pharmacyId: '1');
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects minAmount', () {
      final f = DeliveryFilters.empty().copyWith(minAmount: 1000);
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects non-default sortBy', () {
      final f = DeliveryFilters.empty().copyWith(sortBy: SortBy.amount);
      expect(f.hasActiveFilters, isTrue);
    });

    test('activeFilterCount counts multiple', () {
      final f = DeliveryFilters(
        dateFrom: DateTime.now(),
        status: 'delivered',
        pharmacyId: '1',
        minAmount: 500,
        sortBy: SortBy.amount,
      );
      expect(f.activeFilterCount, 5);
    });

    test('copyWith clears fields', () {
      final f = DeliveryFilters(
        dateFrom: DateTime.now(),
        status: 'delivered',
        pharmacyId: '1',
        minAmount: 500,
      );
      final cleared = f.copyWith(
        clearDateFrom: true,
        clearStatus: true,
        clearPharmacy: true,
        clearAmount: true,
      );
      expect(cleared.dateFrom, isNull);
      expect(cleared.status, isNull);
      expect(cleared.pharmacyId, isNull);
      expect(cleared.minAmount, isNull);
    });

    test('equality works', () {
      final f1 = DeliveryFilters.empty();
      final f2 = DeliveryFilters.empty();
      expect(f1, equals(f2));
      expect(f1.hashCode, f2.hashCode);
    });

    test('equality detects differences', () {
      final f1 = DeliveryFilters.empty();
      final f2 = DeliveryFilters.empty().copyWith(status: 'cancelled');
      expect(f1, isNot(equals(f2)));
    });
  });

  group('SortBy extension', () {
    test('labels are correct', () {
      expect(SortBy.date.label, 'Date');
      expect(SortBy.amount.label, 'Montant');
      expect(SortBy.pharmacyName.label, 'Pharmacie');
      expect(SortBy.status.label, 'Statut');
    });
  });

  group('SortOrder extension', () {
    test('labels are correct', () {
      expect(SortOrder.asc.label, 'Croissant');
      expect(SortOrder.desc.label, 'Décroissant');
    });
  });

  group('DeliveryFilters - additional', () {
    test('hasActiveFilters detects maxAmount', () {
      final f = DeliveryFilters.empty().copyWith(maxAmount: 5000);
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects pharmacyName', () {
      final f = DeliveryFilters.empty().copyWith(pharmacyName: 'Pharma A');
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects dateTo without dateFrom', () {
      final f = DeliveryFilters.empty().copyWith(dateTo: DateTime(2025, 6, 1));
      expect(f.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects sortOrder asc', () {
      final f = DeliveryFilters.empty().copyWith(sortOrder: SortOrder.asc);
      expect(f.hasActiveFilters, isTrue);
    });

    test('activeFilterCount counts maxAmount with minAmount as one', () {
      final f = DeliveryFilters(minAmount: 100, maxAmount: 5000);
      // minAmount and maxAmount count as one filter
      expect(f.activeFilterCount, 1);
    });

    test('activeFilterCount counts maxAmount alone', () {
      final f = DeliveryFilters(maxAmount: 5000);
      expect(f.activeFilterCount, 1);
    });

    test('copyWith changes sortOrder', () {
      final f = DeliveryFilters.empty().copyWith(sortOrder: SortOrder.asc);
      expect(f.sortOrder, SortOrder.asc);
    });

    test('copyWith clearDateTo independent of clearDateFrom', () {
      final f = DeliveryFilters(
        dateFrom: DateTime(2025, 1, 1),
        dateTo: DateTime(2025, 6, 1),
      );
      final cleared = f.copyWith(clearDateTo: true);
      expect(cleared.dateFrom, isNotNull);
      expect(cleared.dateTo, isNull);
    });

    test('thisWeek dateFrom is Monday of current week', () {
      final f = DeliveryFilters.thisWeek();
      // dateFrom should be a Monday (weekday == 1)
      expect(f.dateFrom!.weekday, DateTime.monday);
    });

    test('thisMonth dateFrom is 1st of current month', () {
      final f = DeliveryFilters.thisMonth();
      expect(f.dateFrom!.day, 1);
      expect(f.dateFrom!.month, DateTime.now().month);
    });

    test('hashCode differs for different filters', () {
      final f1 = DeliveryFilters.empty();
      final f2 = DeliveryFilters.empty().copyWith(status: 'delivered');
      expect(f1.hashCode, isNot(equals(f2.hashCode)));
    });

    test('copyWith preserves existing values when not clearing', () {
      final f = DeliveryFilters(
        status: 'delivered',
        pharmacyId: '42',
        pharmacyName: 'Pharma X',
        sortBy: SortBy.amount,
      );
      final updated = f.copyWith(sortOrder: SortOrder.asc);
      expect(updated.status, 'delivered');
      expect(updated.pharmacyId, '42');
      expect(updated.pharmacyName, 'Pharma X');
      expect(updated.sortBy, SortBy.amount);
      expect(updated.sortOrder, SortOrder.asc);
    });

    test('today factory has correct day boundaries', () {
      final f = DeliveryFilters.today();
      final now = DateTime.now();
      expect(f.dateFrom!.hour, 0);
      expect(f.dateFrom!.minute, 0);
      expect(f.dateTo!.hour, 23);
      expect(f.dateTo!.minute, 59);
      expect(f.dateFrom!.day, now.day);
      expect(f.dateTo!.day, now.day);
    });

    test('SortBy values exist', () {
      expect(SortBy.values.length, 4);
      expect(SortBy.values, contains(SortBy.date));
      expect(SortBy.values, contains(SortBy.amount));
      expect(SortBy.values, contains(SortBy.pharmacyName));
      expect(SortBy.values, contains(SortBy.status));
    });

    test('SortOrder values exist', () {
      expect(SortOrder.values.length, 2);
      expect(SortOrder.values, contains(SortOrder.asc));
      expect(SortOrder.values, contains(SortOrder.desc));
    });
  });
}
