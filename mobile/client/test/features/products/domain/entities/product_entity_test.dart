import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/products/domain/entities/category_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(0);

  const testPharmacy = PharmacyEntity(
    id: 1,
    name: 'Pharmacie Centrale',
    address: 'Plateau, Abidjan',
    phone: '+2250700000000',
    status: 'active',
    isOpen: true,
  );

  ProductEntity makeProduct({
    double price = 1000,
    double? discountPrice,
    int stockQuantity = 10,
    int lowStockThreshold = 5,
    String? imageUrl,
    double? averageRating,
    bool requiresPrescription = false,
  }) {
    return ProductEntity(
      id: 1,
      name: 'Paracétamol 500mg',
      price: price,
      discountPrice: discountPrice,
      stockQuantity: stockQuantity,
      requiresPrescription: requiresPrescription,
      pharmacy: testPharmacy,
      imageUrl: imageUrl,
      averageRating: averageRating,
      createdAt: now,
      updatedAt: now,
      lowStockThreshold: lowStockThreshold,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PharmacyEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('PharmacyEntity', () {
    test('hasCoordinates true when both lat and lon set', () {
      const p = PharmacyEntity(
        id: 1,
        name: 'Test',
        address: 'Somewhere',
        phone: '00',
        status: 'active',
        isOpen: true,
        latitude: 5.35,
        longitude: -4.00,
      );
      expect(p.hasCoordinates, isTrue);
    });

    test('hasCoordinates false when latitude is null', () {
      expect(testPharmacy.hasCoordinates, isFalse);
    });

    test('hasCoordinates false when only one coord set', () {
      const p = PharmacyEntity(
        id: 1,
        name: 'Test',
        address: 'Somewhere',
        phone: '00',
        status: 'active',
        isOpen: true,
        latitude: 5.35,
      );
      expect(p.hasCoordinates, isFalse);
    });

    test('props equality', () {
      const a = PharmacyEntity(
        id: 1,
        name: 'Pharmacie Centrale',
        address: 'Plateau, Abidjan',
        phone: '+2250700000000',
        status: 'active',
        isOpen: true,
      );
      expect(a, equals(testPharmacy));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CategoryEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('CategoryEntity', () {
    test('props equality', () {
      const a = CategoryEntity(id: 1, name: 'Médicaments');
      const b = CategoryEntity(id: 1, name: 'Médicaments');
      expect(a, equals(b));
    });

    test('different id → not equal', () {
      const a = CategoryEntity(id: 1, name: 'A');
      const b = CategoryEntity(id: 2, name: 'A');
      expect(a, isNot(equals(b)));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductEntity — stock helpers
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductEntity — stock', () {
    test('isAvailable true when stockQuantity > 0', () {
      expect(makeProduct(stockQuantity: 1).isAvailable, isTrue);
    });

    test('isAvailable false when stockQuantity == 0', () {
      expect(makeProduct(stockQuantity: 0).isAvailable, isFalse);
    });

    test('isOutOfStock true when stockQuantity == 0', () {
      expect(makeProduct(stockQuantity: 0).isOutOfStock, isTrue);
    });

    test('isOutOfStock false when stockQuantity > 0', () {
      expect(makeProduct(stockQuantity: 5).isOutOfStock, isFalse);
    });

    test('isLowStock true when qty between 1 and threshold inclusive', () {
      expect(
        makeProduct(stockQuantity: 3, lowStockThreshold: 5).isLowStock,
        isTrue,
      );
    });

    test('isLowStock true when qty equals threshold', () {
      expect(
        makeProduct(stockQuantity: 5, lowStockThreshold: 5).isLowStock,
        isTrue,
      );
    });

    test('isLowStock false when qty > threshold', () {
      expect(
        makeProduct(stockQuantity: 10, lowStockThreshold: 5).isLowStock,
        isFalse,
      );
    });

    test('isLowStock false when out of stock', () {
      expect(
        makeProduct(stockQuantity: 0, lowStockThreshold: 5).isLowStock,
        isFalse,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductEntity — image
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductEntity — image', () {
    test('hasImage true when imageUrl is set', () {
      expect(
        makeProduct(imageUrl: 'https://img.example.com/p.jpg').hasImage,
        isTrue,
      );
    });

    test('hasImage false when imageUrl is null', () {
      expect(makeProduct().hasImage, isFalse);
    });

    test('hasImage false when imageUrl is empty string', () {
      expect(makeProduct(imageUrl: '').hasImage, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductEntity — discount
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductEntity — discount', () {
    test('hasDiscount true when discountPrice < price', () {
      expect(makeProduct(price: 1000, discountPrice: 800).hasDiscount, isTrue);
    });

    test('hasDiscount false when discountPrice is null', () {
      expect(makeProduct(price: 1000).hasDiscount, isFalse);
    });

    test('hasDiscount false when discountPrice == price', () {
      expect(
        makeProduct(price: 1000, discountPrice: 1000).hasDiscount,
        isFalse,
      );
    });

    test('hasDiscount false when discountPrice > price', () {
      expect(
        makeProduct(price: 1000, discountPrice: 1200).hasDiscount,
        isFalse,
      );
    });

    test('finalPrice returns discountPrice when hasDiscount', () {
      expect(makeProduct(price: 1000, discountPrice: 750).finalPrice, 750);
    });

    test('finalPrice returns price when no discount', () {
      expect(makeProduct(price: 1000).finalPrice, 1000);
    });

    test('discountPercentage calculates correctly (20% off)', () {
      final p = makeProduct(price: 1000, discountPrice: 800);
      expect(p.discountPercentage, 20);
    });

    test('discountPercentage is 0 when no discount', () {
      expect(makeProduct(price: 1000).discountPercentage, 0);
    });

    test('discountPercentage rounds correctly (33%)', () {
      final p = makeProduct(price: 900, discountPrice: 600);
      expect(p.discountPercentage, 33);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductEntity — rating
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductEntity — rating', () {
    test('hasRating true when averageRating > 0', () {
      expect(makeProduct(averageRating: 4.5).hasRating, isTrue);
    });

    test('hasRating false when averageRating is null', () {
      expect(makeProduct().hasRating, isFalse);
    });

    test('hasRating false when averageRating == 0', () {
      expect(makeProduct(averageRating: 0).hasRating, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProductEntity — props
  // ────────────────────────────────────────────────────────────────────────────
  group('ProductEntity — props', () {
    test('two products with same id/name/price/stock/pharmacyId are equal', () {
      final a = makeProduct();
      final b = makeProduct();
      expect(a, equals(b));
    });

    test('different id makes products unequal', () {
      final a = makeProduct();
      final b = ProductEntity(
        id: 999,
        name: a.name,
        price: a.price,
        stockQuantity: a.stockQuantity,
        requiresPrescription: false,
        pharmacy: testPharmacy,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
