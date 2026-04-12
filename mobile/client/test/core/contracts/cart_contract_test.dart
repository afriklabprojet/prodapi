import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/contracts/cart_contract.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';

ProductEntity _makeProduct({
  int id = 1,
  double price = 10.0,
  int stock = 5,
  bool requiresPrescription = false,
}) {
  return ProductEntity(
    id: id,
    name: 'Product $id',
    price: price,
    stockQuantity: stock,
    requiresPrescription: requiresPrescription,
    pharmacy: const PharmacyEntity(
      id: 1,
      name: 'Pharmacy',
      address: '1 Rue Test',
      phone: '+225',
      status: 'active',
      isOpen: true,
    ),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

CartItemEntity _makeItem({
  int productId = 1,
  int quantity = 2,
  bool rx = false,
}) {
  return CartItemEntity(
    product: _makeProduct(id: productId, requiresPrescription: rx),
    quantity: quantity,
  );
}

void main() {
  // ── CartData.empty ────────────────────────────────────
  group('CartData.empty', () {
    test('creates empty cart with no items', () {
      final cart = CartData.empty();
      expect(cart.items, isEmpty);
      expect(cart.pharmacyId, isNull);
      expect(cart.source, CartSource.local);
    });
  });

  // ── CartData computed properties ──────────────────────
  group('CartData computed properties', () {
    test('totalItems sums all quantities', () {
      final cart = CartData(
        items: [
          _makeItem(productId: 1, quantity: 3),
          _makeItem(productId: 2, quantity: 2),
        ],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.totalItems, 5);
    });

    test('uniqueItemCount returns item count', () {
      final cart = CartData(
        items: [_makeItem(productId: 1), _makeItem(productId: 2)],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.uniqueItemCount, 2);
    });

    test('subtotal sums totalPrice of all items', () {
      final cart = CartData(
        items: [
          CartItemEntity(product: _makeProduct(price: 10.0), quantity: 2), // 20
          CartItemEntity(
            product: _makeProduct(id: 2, price: 5.0),
            quantity: 3,
          ), // 15
        ],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.subtotal, closeTo(35.0, 0.01));
    });

    test('isEmpty true for empty cart', () {
      expect(CartData.empty().isEmpty, true);
      expect(CartData.empty().isNotEmpty, false);
    });

    test('isNotEmpty true when items present', () {
      final cart = CartData(
        items: [_makeItem()],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.isNotEmpty, true);
      expect(cart.isEmpty, false);
    });

    test('hasPrescriptionRequired false when no rx items', () {
      final cart = CartData(
        items: [_makeItem(rx: false)],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.hasPrescriptionRequired, false);
    });

    test('hasPrescriptionRequired true when rx item present', () {
      final cart = CartData(
        items: [_makeItem(rx: true)],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.hasPrescriptionRequired, true);
    });

    test('prescriptionItems returns only rx items', () {
      final cart = CartData(
        items: [
          _makeItem(productId: 1, rx: false),
          _makeItem(productId: 2, rx: true),
        ],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      expect(cart.prescriptionItems.length, 1);
      expect(cart.prescriptionItems.first.product.id, 2);
    });
  });

  // ── CartData.getItem / containsProduct ────────────────
  group('CartData.getItem', () {
    late CartData cart;

    setUp(() {
      cart = CartData(
        items: [
          _makeItem(productId: 10, quantity: 1),
          _makeItem(productId: 20, quantity: 2),
        ],
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
    });

    test('getItem returns item for known productId', () {
      expect(cart.getItem(10), isNotNull);
      expect(cart.getItem(10)!.product.id, 10);
    });

    test('getItem returns null for unknown productId', () {
      expect(cart.getItem(999), isNull);
    });

    test('containsProduct true for existing productId', () {
      expect(cart.containsProduct(20), true);
    });

    test('containsProduct false for unknown productId', () {
      expect(cart.containsProduct(999), false);
    });
  });

  // ── CartData.copyWith ─────────────────────────────────
  group('CartData.copyWith', () {
    test('preserves unchanged fields', () {
      final original = CartData(
        items: [_makeItem()],
        pharmacyId: 5,
        pharmacyName: 'Pouvoir',
        lastModified: DateTime(2024, 6, 1),
        source: CartSource.server,
      );
      final copy = original.copyWith();
      expect(copy.pharmacyId, 5);
      expect(copy.pharmacyName, 'Pouvoir');
      expect(copy.source, CartSource.server);
    });

    test('clearPharmacy sets pharmacyId and name to null', () {
      final original = CartData(
        items: [],
        pharmacyId: 5,
        pharmacyName: 'Test',
        lastModified: DateTime.now(),
        source: CartSource.local,
      );
      final copy = original.copyWith(clearPharmacy: true);
      expect(copy.pharmacyId, isNull);
      expect(copy.pharmacyName, isNull);
    });

    test('overrides source', () {
      final original = CartData.empty();
      final copy = original.copyWith(source: CartSource.merged);
      expect(copy.source, CartSource.merged);
    });
  });

  // ── CartData.toJson ───────────────────────────────────
  group('CartData.toJson', () {
    test('produces correct JSON structure', () {
      final cart = CartData(
        items: [_makeItem(productId: 7, quantity: 3)],
        pharmacyId: 2,
        pharmacyName: 'Pharmacie Test',
        lastModified: DateTime(2024, 3, 1),
        source: CartSource.local,
      );
      final json = cart.toJson();
      expect(json['pharmacy_id'], 2);
      expect(json['pharmacy_name'], 'Pharmacie Test');
      expect(json['source'], 'local');
      expect((json['items'] as List).first['product_id'], 7);
    });
  });

  // ── CartData.toString ─────────────────────────────────
  group('CartData.toString', () {
    test('includes item count and source', () {
      final cart = CartData(
        items: [_makeItem()],
        pharmacyId: 3,
        lastModified: DateTime.now(),
        source: CartSource.server,
      );
      expect(cart.toString(), contains('server'));
      expect(cart.toString(), contains('3'));
    });
  });

  // ── PendingCartOperation ──────────────────────────────
  group('PendingCartOperation', () {
    test('incrementRetry increases retryCount by 1', () {
      final op = PendingCartOperation(
        type: CartOperationType.add,
        productId: 1,
        quantity: 2,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        retryCount: 2,
      );
      final incremented = op.incrementRetry();
      expect(incremented.retryCount, 3);
    });

    test('toJson produces correct keys', () {
      final op = PendingCartOperation(
        type: CartOperationType.remove,
        productId: 5,
        createdAt: DateTime(2024, 1, 15),
        retryCount: 1,
      );
      final json = op.toJson();
      expect(json['type'], 'remove');
      expect(json['product_id'], 5);
      expect(json['retry_count'], 1);
    });

    test('fromJson round-trip', () {
      final original = PendingCartOperation(
        type: CartOperationType.updateQuantity,
        productId: 3,
        quantity: 4,
        createdAt: DateTime(2024, 2, 20),
        retryCount: 0,
      );
      final json = original.toJson();
      final restored = PendingCartOperation.fromJson(json);
      expect(restored.type, CartOperationType.updateQuantity);
      expect(restored.productId, 3);
      expect(restored.quantity, 4);
      expect(restored.retryCount, 0);
    });

    test('fromJson with unknown type defaults to add', () {
      final json = {
        'type': 'unknown_type',
        'product_id': 1,
        'created_at': DateTime(2024, 1, 1).toIso8601String(),
        'retry_count': 0,
      };
      final op = PendingCartOperation.fromJson(json);
      expect(op.type, CartOperationType.add);
    });
  });
}
