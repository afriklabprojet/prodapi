import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/orders/data/datasources/cart_local_datasource.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';

// ─── Helpers ──────────────────────────────────────────────

PharmacyEntity _makePharmacy({int id = 1}) => PharmacyEntity(
  id: id,
  name: 'Pharmacie Test',
  address: '123 Rue Test',
  phone: '+24100000000',
  status: 'active',
  isOpen: true,
);

ProductEntity _makeProduct({int id = 1, PharmacyEntity? pharmacy}) =>
    ProductEntity(
      id: id,
      name: 'Paracetamol 500mg',
      price: 750.0,
      stockQuantity: 20,
      requiresPrescription: false,
      pharmacy: pharmacy ?? _makePharmacy(),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

CartItemEntity _makeItem({int id = 1, int quantity = 2}) => CartItemEntity(
  product: _makeProduct(id: id),
  quantity: quantity,
);

void main() {
  late CartLocalDataSourceImpl datasource;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = CartLocalDataSourceImpl(sharedPreferences: prefs);
  });

  // ── loadCart ───────────────────────────────────────────
  group('loadCart', () {
    test('returns empty when no data stored', () async {
      final result = await datasource.loadCart();
      expect(result.items, isEmpty);
      expect(result.pharmacyId, isNull);
    });

    test('round-trips items and pharmacyId through save/load', () async {
      final item1 = _makeItem(id: 1, quantity: 2);
      final item2 = _makeItem(id: 2, quantity: 3);
      await datasource.saveCart([item1, item2], pharmacyId: 42);

      final loaded = await datasource.loadCart();
      expect(loaded.items.length, 2);
      expect(loaded.items[0].quantity, 2);
      expect(loaded.items[1].quantity, 3);
      expect(loaded.pharmacyId, 42);
    });

    test('preserves pharmacyId when present', () async {
      await datasource.saveCart([_makeItem()], pharmacyId: 7);
      final result = await datasource.loadCart();
      expect(result.pharmacyId, 7);
    });

    test('pharmacyId is null when not stored', () async {
      await datasource.saveCart([_makeItem()]);
      final result = await datasource.loadCart();
      expect(result.pharmacyId, isNull);
    });

    test('discards data with old cart version', () async {
      // Manually store v1 data
      await prefs.setString(
        'shopping_cart',
        jsonEncode({'version': 1, 'items': [], 'pharmacy_id': null}),
      );

      final result = await datasource.loadCart();
      expect(result.items, isEmpty);
      expect(result.pharmacyId, isNull);
    });

    test('returns empty when items list is null in stored data', () async {
      await prefs.setString(
        'shopping_cart',
        jsonEncode({'version': 2, 'items': null, 'pharmacy_id': null}),
      );

      final result = await datasource.loadCart();
      expect(result.items, isEmpty);
    });

    test('returns empty on corrupt JSON', () async {
      await prefs.setString('shopping_cart', 'not-valid-json!!!');

      final result = await datasource.loadCart();
      expect(result.items, isEmpty);
      expect(result.pharmacyId, isNull);
    });
  });

  // ── saveCart ────────────────────────────────────────────
  group('saveCart', () {
    test('saves empty list without error', () async {
      await expectLater(datasource.saveCart([]), completes);
    });

    test('overwrites previous data on save', () async {
      await datasource.saveCart([_makeItem(id: 1, quantity: 1)], pharmacyId: 1);
      await datasource.saveCart([_makeItem(id: 2, quantity: 5)], pharmacyId: 2);

      final result = await datasource.loadCart();
      expect(result.items.length, 1);
      expect(result.items[0].product.id, 2);
      expect(result.pharmacyId, 2);
    });
  });

  // ── clearCart ───────────────────────────────────────────
  group('clearCart', () {
    test('removes stored data', () async {
      await datasource.saveCart([_makeItem()], pharmacyId: 5);
      await datasource.clearCart();

      final result = await datasource.loadCart();
      expect(result.items, isEmpty);
      expect(result.pharmacyId, isNull);
    });

    test('is idempotent when nothing stored', () async {
      await expectLater(datasource.clearCart(), completes);
    });
  });
}
