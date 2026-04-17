import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_state.dart';

PharmacyEntity _makePharmacy({
  int id = 1,
  String name = 'Pharmacie du Centre',
  bool isOpen = true,
}) => PharmacyEntity(
  id: id,
  name: name,
  address: 'Rue des Pharmaciens',
  phone: '+2250700000001',
  status: 'active',
  isOpen: isOpen,
);

void main() {
  group('PharmaciesState — defaults', () {
    test('status is initial by default', () {
      const s = PharmaciesState();
      expect(s.status, PharmaciesStatus.initial);
    });

    test('all lists are empty by default', () {
      const s = PharmaciesState();
      expect(s.pharmacies, isEmpty);
      expect(s.nearbyPharmacies, isEmpty);
      expect(s.onDutyPharmacies, isEmpty);
      expect(s.featuredPharmacies, isEmpty);
    });

    test('selectedPharmacy is null by default', () {
      const s = PharmaciesState();
      expect(s.selectedPharmacy, isNull);
    });

    test('errorMessage is null by default', () {
      const s = PharmaciesState();
      expect(s.errorMessage, isNull);
    });

    test('hasReachedMax is false by default', () {
      const s = PharmaciesState();
      expect(s.hasReachedMax, isFalse);
    });

    test('currentPage is 1 by default', () {
      const s = PharmaciesState();
      expect(s.currentPage, 1);
    });

    test('isFeaturedLoading is false by default', () {
      const s = PharmaciesState();
      expect(s.isFeaturedLoading, isFalse);
    });

    test('isFeaturedLoaded is false by default', () {
      const s = PharmaciesState();
      expect(s.isFeaturedLoaded, isFalse);
    });
  });

  group('PharmaciesState — copyWith', () {
    test('updates status', () {
      const s = PharmaciesState();
      expect(
        s.copyWith(status: PharmaciesStatus.loading).status,
        PharmaciesStatus.loading,
      );
    });

    test('updates pharmacies list', () {
      const s = PharmaciesState();
      final p = _makePharmacy();
      expect(s.copyWith(pharmacies: [p]).pharmacies.length, 1);
    });

    test('clearError removes errorMessage', () {
      const s = PharmaciesState(errorMessage: 'Erreur réseau');
      final copy = s.copyWith(clearError: true);
      expect(copy.errorMessage, isNull);
    });

    test('errorMessage preserved when not cleared', () {
      const s = PharmaciesState(errorMessage: 'Erreur');
      final copy = s.copyWith(status: PharmaciesStatus.success);
      expect(copy.errorMessage, 'Erreur');
    });

    test('clearSelectedPharmacy removes selectedPharmacy', () {
      final p = _makePharmacy();
      final s = PharmaciesState(selectedPharmacy: p);
      final copy = s.copyWith(clearSelectedPharmacy: true);
      expect(copy.selectedPharmacy, isNull);
    });

    test('selectedPharmacy can be set', () {
      const s = PharmaciesState();
      final p = _makePharmacy(id: 42);
      expect(s.copyWith(selectedPharmacy: p).selectedPharmacy!.id, 42);
    });

    test('hasReachedMax can be updated', () {
      const s = PharmaciesState();
      expect(s.copyWith(hasReachedMax: true).hasReachedMax, isTrue);
    });

    test('currentPage can be incremented', () {
      const s = PharmaciesState(currentPage: 1);
      expect(s.copyWith(currentPage: 2).currentPage, 2);
    });

    test('isFeaturedLoading can be toggled', () {
      const s = PharmaciesState();
      expect(s.copyWith(isFeaturedLoading: true).isFeaturedLoading, isTrue);
    });
  });

  group('PharmaciesState — props equality', () {
    test('two default states are equal', () {
      const a = PharmaciesState();
      const b = PharmaciesState();
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = PharmaciesState(status: PharmaciesStatus.loading);
      const b = PharmaciesState(status: PharmaciesStatus.success);
      expect(a, isNot(equals(b)));
    });
  });
}
