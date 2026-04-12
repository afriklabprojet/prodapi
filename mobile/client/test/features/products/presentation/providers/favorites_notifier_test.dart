import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/products/presentation/providers/favorites_provider.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart'
    as products_pharmacy;

products_pharmacy.PharmacyEntity _makePharmacy() =>
    const products_pharmacy.PharmacyEntity(
      id: 1,
      name: 'Pharmacie du Centre',
      address: 'Rue 1',
      phone: '+22507',
      status: 'active',
      isOpen: true,
    );

ProductEntity _makeProduct({int id = 1, String name = 'Paracétamol'}) =>
    ProductEntity(
      id: id,
      name: name,
      price: 500.0,
      stockQuantity: 10,
      requiresPrescription: false,
      pharmacy: _makePharmacy(),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

FavoritesNotifier _make() => FavoritesNotifier();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────
  // Initial state
  // ──────────────────────────────────────────────────────
  group('initial state', () {
    test('empty when no prefs', () async {
      final notifier = _make();
      // Wait for _loadFavorites() to complete
      await Future.delayed(Duration.zero);
      expect(notifier.state.favoriteIds, isEmpty);
      expect(notifier.state.favoriteProducts, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────
  // FavoritesState
  // ──────────────────────────────────────────────────────
  group('FavoritesState', () {
    test('isFavorite — false for unknown id', () {
      const s = FavoritesState();
      expect(s.isFavorite(99), isFalse);
    });

    test('isFavorite — true when id is in set', () {
      final s = FavoritesState(favoriteIds: {1, 2});
      expect(s.isFavorite(1), isTrue);
      expect(s.isFavorite(3), isFalse);
    });

    test('copyWith — updates favoriteIds', () {
      const s = FavoritesState();
      final next = s.copyWith(favoriteIds: {5});
      expect(next.favoriteIds, {5});
    });

    test('copyWith — updates isLoading', () {
      const s = FavoritesState();
      expect(s.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('copyWith — preserves unset fields', () {
      const s = FavoritesState(isLoading: true);
      final next = s.copyWith(favoriteIds: {3});
      expect(next.isLoading, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // toggleFavorite
  // ──────────────────────────────────────────────────────
  group('toggleFavorite', () {
    test('adds product if not in favorites', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p = _makeProduct();
      await notifier.toggleFavorite(p);

      expect(notifier.state.favoriteIds, contains(1));
      expect(notifier.state.favoriteProducts.any((x) => x.id == 1), isTrue);
    });

    test('removes product if already in favorites', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p = _makeProduct();
      await notifier.toggleFavorite(p); // add
      await notifier.toggleFavorite(p); // remove

      expect(notifier.state.favoriteIds, isNot(contains(1)));
      expect(notifier.state.favoriteProducts.any((x) => x.id == 1), isFalse);
    });

    test('first product added appears at index 0', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p1 = _makeProduct(id: 1);
      final p2 = _makeProduct(id: 2, name: 'Ibuprofène');
      await notifier.toggleFavorite(p1);
      await notifier.toggleFavorite(p2);

      expect(notifier.state.favoriteProducts.first.id, 2); // most recent first
    });
  });

  // ──────────────────────────────────────────────────────
  // addFavorite
  // ──────────────────────────────────────────────────────
  group('addFavorite', () {
    test('adds new product', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p = _makeProduct();
      await notifier.addFavorite(p);

      expect(notifier.state.favoriteIds, contains(1));
    });

    test('skips if already a favorite', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p = _makeProduct();
      await notifier.addFavorite(p);
      final countBefore = notifier.state.favoriteIds.length;
      await notifier.addFavorite(p); // duplicate
      expect(notifier.state.favoriteIds.length, countBefore);
    });
  });

  // ──────────────────────────────────────────────────────
  // removeFavorite
  // ──────────────────────────────────────────────────────
  group('removeFavorite', () {
    test('removes existing product', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final p = _makeProduct();
      await notifier.addFavorite(p);
      await notifier.removeFavorite(1);

      expect(notifier.state.favoriteIds, isNot(contains(1)));
    });

    test('no-op if product not in favorites', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      final before = notifier.state.favoriteIds.length;
      await notifier.removeFavorite(999);
      expect(notifier.state.favoriteIds.length, before);
    });
  });

  // ──────────────────────────────────────────────────────
  // clearAll
  // ──────────────────────────────────────────────────────
  group('clearAll', () {
    test('empties both lists', () async {
      final notifier = _make();
      await Future.delayed(Duration.zero);

      await notifier.addFavorite(_makeProduct(id: 1));
      await notifier.addFavorite(_makeProduct(id: 2, name: 'Ibuprofène'));
      await notifier.clearAll();

      expect(notifier.state.favoriteIds, isEmpty);
      expect(notifier.state.favoriteProducts, isEmpty);
    });
  });
}
