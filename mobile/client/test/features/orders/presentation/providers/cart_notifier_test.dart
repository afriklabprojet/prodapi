import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/features/orders/data/datasources/cart_local_datasource.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';

@GenerateMocks([CartLocalDataSource])
import 'cart_notifier_test.mocks.dart';

// ────────────────────────────────────────────────────────────────────────────
// Test helpers
// ────────────────────────────────────────────────────────────────────────────
const _pharmacy = PharmacyEntity(
  id: 1,
  name: 'Pharmacie du Centre',
  address: 'Plateau, Abidjan',
  phone: '+2250700000001',
  status: 'active',
  isOpen: true,
);

const _pharmacy2 = PharmacyEntity(
  id: 2,
  name: 'Pharmacie Cocody',
  address: 'Cocody, Abidjan',
  phone: '+2250700000002',
  status: 'active',
  isOpen: true,
);

ProductEntity _product({
  int id = 1,
  String name = 'Doliprane 500mg',
  double price = 1500,
  int stock = 20,
  bool requiresPrescription = false,
  PharmacyEntity? pharmacy,
}) => ProductEntity(
  id: id,
  name: name,
  price: price,
  stockQuantity: stock,
  requiresPrescription: requiresPrescription,
  pharmacy: pharmacy ?? _pharmacy,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  late MockCartLocalDataSource mockDataSource;
  late CartNotifier notifier;

  // Stub save/load/clear by default
  setUp(() {
    mockDataSource = MockCartLocalDataSource();
    when(
      mockDataSource.loadCart(),
    ).thenAnswer((_) async => (items: <CartItemEntity>[], pharmacyId: null));
    when(
      mockDataSource.saveCart(any, pharmacyId: anyNamed('pharmacyId')),
    ).thenAnswer((_) async {});
    when(mockDataSource.clearCart()).thenAnswer((_) async {});
    notifier = CartNotifier(mockDataSource);
  });

  group('CartNotifier initial state', () {
    test('starts with initial status and empty items', () {
      expect(notifier.state.status, CartStatus.initial);
      expect(notifier.state.items, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // addItem
  // ────────────────────────────────────────────────────────────────────────────
  group('addItem', () {
    test('adds a product to empty cart', () async {
      final product = _product();
      final added = await notifier.addItem(product);

      expect(added, isTrue);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.product.id, product.id);
      expect(notifier.state.items.first.quantity, 1);
      expect(notifier.state.selectedPharmacyId, 1);
      expect(notifier.state.status, CartStatus.loaded);
    });

    test('increases quantity for existing product', () async {
      final product = _product();
      await notifier.addItem(product);
      await notifier.addItem(product, quantity: 2);

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 3);
    });

    test('returns false for quantity <= 0', () async {
      final product = _product();
      final added = await notifier.addItem(product, quantity: 0);
      expect(added, isFalse);
      expect(notifier.state.items, isEmpty);
    });

    test('returns false when product is out of stock', () async {
      final product = _product(stock: 0);
      final added = await notifier.addItem(product);
      expect(added, isFalse);
      expect(notifier.state.status, CartStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('returns false when requested quantity exceeds stock', () async {
      final product = _product(stock: 3);
      final added = await notifier.addItem(product, quantity: 5);
      expect(added, isFalse);
      expect(notifier.state.status, CartStatus.error);
    });

    test('returns false when adding product from different pharmacy', () async {
      await notifier.addItem(_product(pharmacy: _pharmacy));
      final different = _product(id: 2, pharmacy: _pharmacy2);
      final added = await notifier.addItem(different);

      expect(added, isFalse);
      expect(notifier.state.status, CartStatus.error);
      expect(notifier.state.errorMessage, contains('pharmacie'));
    });

    test('can add multiple products from same pharmacy', () async {
      await notifier.addItem(_product(id: 1));
      await notifier.addItem(_product(id: 2, name: 'Aspirine'));

      expect(notifier.state.items.length, 2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // removeItem
  // ────────────────────────────────────────────────────────────────────────────
  group('removeItem', () {
    test('removes existing item', () async {
      await notifier.addItem(_product());
      await notifier.removeItem(1);

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.selectedPharmacyId, isNull);
    });

    test('removes only the target item when multiple in cart', () async {
      await notifier.addItem(_product(id: 1));
      await notifier.addItem(_product(id: 2, name: 'Aspirine'));
      await notifier.removeItem(1);

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.product.id, 2);
    });

    test('no-op when removing non-existent item', () async {
      await notifier.addItem(_product(id: 1));
      await notifier.removeItem(999);

      expect(notifier.state.items.length, 1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // updateQuantity
  // ────────────────────────────────────────────────────────────────────────────
  group('updateQuantity', () {
    test('updates quantity for existing item', () async {
      await notifier.addItem(_product());
      await notifier.updateQuantity(1, 5);

      expect(notifier.state.items.first.quantity, 5);
    });

    test('removes item when quantity set to 0', () async {
      await notifier.addItem(_product());
      await notifier.updateQuantity(1, 0);

      expect(notifier.state.items, isEmpty);
    });

    test('sets error when quantity exceeds stock', () async {
      await notifier.addItem(_product(stock: 5));
      await notifier.updateQuantity(1, 10);

      expect(notifier.state.status, CartStatus.error);
      expect(notifier.state.errorMessage, contains('Stock'));
    });

    test('no-op when product not in cart', () async {
      await notifier.updateQuantity(999, 3);
      expect(notifier.state.items, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // clearCart
  // ────────────────────────────────────────────────────────────────────────────
  group('clearCart', () {
    test('clears all items and resets to initial state', () async {
      await notifier.addItem(_product());
      await notifier.clearCart();

      expect(notifier.state.status, CartStatus.initial);
      expect(notifier.state.items, isEmpty);
      verify(mockDataSource.clearCart()).called(1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // clearError
  // ────────────────────────────────────────────────────────────────────────────
  group('clearError', () {
    test('clears error message when it exists', () async {
      await notifier.addItem(_product(stock: 0)); // should set error
      expect(notifier.state.errorMessage, isNotNull);

      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });

    test('no-op when no error exists', () {
      notifier.clearError(); // should not throw
      expect(notifier.state.errorMessage, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // updateDeliveryFee / clearDeliveryFee
  // ────────────────────────────────────────────────────────────────────────────
  group('updateDeliveryFee', () {
    test('stores delivery fee and distance', () {
      notifier.updateDeliveryFee(deliveryFee: 1500, distanceKm: 7.5);

      expect(notifier.state.calculatedDeliveryFee, 1500);
      expect(notifier.state.deliveryDistanceKm, 7.5);
    });
  });

  group('clearDeliveryFee', () {
    test('resets delivery fee', () {
      notifier.updateDeliveryFee(deliveryFee: 1500);
      notifier.clearDeliveryFee();

      expect(notifier.state.calculatedDeliveryFee, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // updatePaymentMode
  // ────────────────────────────────────────────────────────────────────────────
  group('updatePaymentMode', () {
    test('changes the payment mode', () {
      notifier.updatePaymentMode('wallet');
      expect(notifier.state.paymentMode, 'wallet');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CartState computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('CartState computed properties', () {
    test('totalItems sums all quantities', () async {
      await notifier.addItem(_product(id: 1), quantity: 2);
      await notifier.addItem(_product(id: 2, name: 'Aspirine'), quantity: 3);
      expect(notifier.state.totalItems, 5);
    });

    test('subtotal sums all item totals', () async {
      await notifier.addItem(_product(id: 1, price: 1500), quantity: 2);
      expect(notifier.state.subtotal, 3000.0);
    });

    test('isEmpty and isNotEmpty', () async {
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.isNotEmpty, isFalse);

      await notifier.addItem(_product());
      expect(notifier.state.isEmpty, isFalse);
      expect(notifier.state.isNotEmpty, isTrue);
    });

    test('hasPrescriptionRequiredItems', () async {
      await notifier.addItem(_product(requiresPrescription: true));
      expect(notifier.state.hasPrescriptionRequiredItems, isTrue);
    });

    test('prescriptionRequiredProductNames lists names', () async {
      await notifier.addItem(
        _product(id: 1, name: 'Amoxicilline', requiresPrescription: true),
      );
      expect(
        notifier.state.prescriptionRequiredProductNames,
        contains('Amoxicilline'),
      );
    });

    test('getItem returns item by product id', () async {
      await notifier.addItem(_product(id: 5));
      expect(notifier.state.getItem(5), isNotNull);
      expect(notifier.state.getItem(999), isNull);
    });
  });
}
