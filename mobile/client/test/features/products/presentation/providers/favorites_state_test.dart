import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/products/presentation/providers/favorites_provider.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart'
    as products_pharmacy;
import 'package:drpharma_client/features/products/domain/entities/category_entity.dart';

products_pharmacy.PharmacyEntity _makePharmacy() =>
    const products_pharmacy.PharmacyEntity(
      id: 1,
      name: 'Pharmacie du Centre',
      address: 'Rue 1',
      phone: '+22507',
      status: 'active',
      isOpen: true,
    );

CategoryEntity _makeCategory() =>
    const CategoryEntity(id: 1, name: 'Médicaments');

ProductEntity _makeProduct({int id = 1, String name = 'Paracétamol'}) =>
    ProductEntity(
      id: id,
      name: name,
      price: 500.0,
      stockQuantity: 10,
      requiresPrescription: false,
      pharmacy: _makePharmacy(),
      category: _makeCategory(),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  group('FavoritesState — defaults', () {
    test('favoriteIds is empty', () {
      const s = FavoritesState();
      expect(s.favoriteIds, isEmpty);
    });

    test('favoriteProducts is empty', () {
      const s = FavoritesState();
      expect(s.favoriteProducts, isEmpty);
    });

    test('isLoading is false', () {
      const s = FavoritesState();
      expect(s.isLoading, isFalse);
    });
  });

  group('FavoritesState — isFavorite', () {
    test('returns false for unknown id', () {
      const s = FavoritesState(favoriteIds: {1, 2, 3});
      expect(s.isFavorite(99), isFalse);
    });

    test('returns true for known id', () {
      const s = FavoritesState(favoriteIds: {1, 2, 3});
      expect(s.isFavorite(2), isTrue);
    });

    test('returns false on empty set', () {
      const s = FavoritesState();
      expect(s.isFavorite(1), isFalse);
    });
  });

  group('FavoritesState — copyWith', () {
    test('updates favoriteIds', () {
      const s = FavoritesState();
      final copy = s.copyWith(favoriteIds: {5, 10});
      expect(copy.favoriteIds, containsAll([5, 10]));
    });

    test('updates favoriteProducts', () {
      const s = FavoritesState();
      final p = _makeProduct();
      final copy = s.copyWith(favoriteProducts: [p]);
      expect(copy.favoriteProducts.length, 1);
    });

    test('updates isLoading', () {
      const s = FavoritesState();
      expect(s.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('preserves favoritesIds when not specified', () {
      const s = FavoritesState(favoriteIds: {1, 2});
      final copy = s.copyWith(isLoading: true);
      expect(copy.favoriteIds, containsAll([1, 2]));
    });
  });

  group('FavoritesState — equality', () {
    test('two empty states are equal', () {
      const a = FavoritesState();
      const b = FavoritesState();
      // FavoritesState doesn't extend Equatable — uses default identity
      // Just verify the data is consistent
      expect(a.favoriteIds, equals(b.favoriteIds));
      expect(a.favoriteProducts, equals(b.favoriteProducts));
      expect(a.isLoading, equals(b.isLoading));
    });

    test('copied state has same values', () {
      const s = FavoritesState(favoriteIds: {1, 2}, isLoading: false);
      final copy = s.copyWith();
      expect(copy.favoriteIds, containsAll([1, 2]));
      expect(copy.isLoading, isFalse);
    });
  });
}
