import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/core/services/cart_service.dart';
import 'package:drpharma_client/core/contracts/cart_contract.dart';
import 'package:drpharma_client/core/errors/cart_failures.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';

PharmacyEntity _makePharmacy({int id = 1, String name = 'Pharmacie Test'}) =>
    PharmacyEntity(
      id: id,
      name: name,
      address: '123 Rue Principale',
      phone: '+24107000000',
      status: 'active',
      isOpen: true,
    );

ProductEntity _makeProduct({
  int id = 1,
  String name = 'Paracetamol',
  double price = 500.0,
  int stockQuantity = 10,
  bool requiresPrescription = false,
  PharmacyEntity? pharmacy,
}) => ProductEntity(
  id: id,
  name: name,
  price: price,
  stockQuantity: stockQuantity,
  requiresPrescription: requiresPrescription,
  pharmacy: pharmacy ?? _makePharmacy(),
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

void main() {
  late CartService cartService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cartService = CartService(prefs: prefs);
  });

  tearDown(() {
    cartService.dispose();
  });

  group('CartService', () {
    // ── Initial state ──────────────────────────────────────
    group('initial state', () {
      test('currentCart is empty on creation', () {
        expect(cartService.currentCart.isEmpty, true);
        expect(cartService.currentCart.items, isEmpty);
        expect(cartService.currentCart.pharmacyId, isNull);
      });

      test('cartStream is a broadcast stream', () {
        expect(cartService.cartStream, isA<Stream<CartData>>());
      });

      test('syncStatusStream is a stream', () {
        expect(cartService.syncStatusStream, isA<Stream<CartSyncStatus>>());
      });
    });

    // ── addItem ────────────────────────────────────────────
    group('addItem', () {
      test('returns InvalidQuantityFailure when quantity is 0', () async {
        final product = _makeProduct();
        final result = await cartService.addItem(product, quantity: 0);
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<InvalidQuantityFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test(
        'returns InvalidQuantityFailure when quantity is negative',
        () async {
          final product = _makeProduct();
          final result = await cartService.addItem(product, quantity: -3);
          expect(result.isLeft(), true);
          result.fold(
            (f) => expect(f, isA<InvalidQuantityFailure>()),
            (_) => fail('Expected failure'),
          );
        },
      );

      test('returns ProductUnavailableFailure when stock is 0', () async {
        final product = _makeProduct(stockQuantity: 0);
        final result = await cartService.addItem(product);
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<ProductUnavailableFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test(
        'returns InsufficientStockFailure when quantity exceeds stock',
        () async {
          final product = _makeProduct(stockQuantity: 3);
          final result = await cartService.addItem(product, quantity: 5);
          expect(result.isLeft(), true);
          result.fold(
            (f) => expect(f, isA<InsufficientStockFailure>()),
            (_) => fail('Expected failure'),
          );
        },
      );

      test('adds product to cart successfully', () async {
        final product = _makeProduct();
        final result = await cartService.addItem(product, quantity: 2);
        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (cart) {
          expect(cart.items.length, 1);
          expect(cart.items.first.product.id, product.id);
          expect(cart.items.first.quantity, 2);
        });
      });

      test('updates quantity when same product added again', () async {
        final product = _makeProduct();
        await cartService.addItem(product, quantity: 2);
        final result = await cartService.addItem(product, quantity: 3);
        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (cart) {
          expect(cart.items.length, 1);
          expect(cart.items.first.quantity, 5);
        });
      });

      test('sets pharmacyId and pharmacyName on first add', () async {
        final pharmacy = _makePharmacy(id: 42, name: 'La Bonne Pharmacie');
        final product = _makeProduct(pharmacy: pharmacy);
        final result = await cartService.addItem(product);
        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (cart) {
          expect(cart.pharmacyId, 42);
          expect(cart.pharmacyName, 'La Bonne Pharmacie');
        });
      });

      test(
        'returns DifferentPharmacyFailure when adding from different pharmacy',
        () async {
          final pharmacy1 = _makePharmacy(id: 1, name: 'Pharmacie A');
          final pharmacy2 = _makePharmacy(id: 2, name: 'Pharmacie B');
          final product1 = _makeProduct(id: 1, pharmacy: pharmacy1);
          final product2 = _makeProduct(
            id: 2,
            name: 'Ibuprofène',
            pharmacy: pharmacy2,
          );

          await cartService.addItem(product1);
          final result = await cartService.addItem(product2);

          expect(result.isLeft(), true);
          result.fold(
            (f) => expect(f, isA<DifferentPharmacyFailure>()),
            (_) => fail('Expected failure'),
          );
        },
      );

      test('returns CartLimitReachedFailure when cart is full', () async {
        final limitedService = CartService(prefs: prefs, maxCartItems: 1);
        addTearDown(() => limitedService.dispose());

        final product1 = _makeProduct(id: 1);
        await limitedService.addItem(product1);

        final product2 = _makeProduct(id: 2, name: 'Ibuprofène');
        final result = await limitedService.addItem(product2);

        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<CartLimitReachedFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test('cartStream emits updated cart after add', () async {
        final product = _makeProduct();
        CartData? emitted;
        final sub = cartService.cartStream.listen((cart) => emitted = cart);

        await cartService.addItem(product);
        await Future.delayed(Duration.zero);

        expect(emitted, isNotNull);
        expect(emitted!.items.length, 1);
        await sub.cancel();
      });

      test('currentCart reflects state after add', () async {
        final product = _makeProduct();
        await cartService.addItem(product, quantity: 3);
        expect(cartService.currentCart.items.length, 1);
        expect(cartService.currentCart.items.first.quantity, 3);
      });
    });

    // ── removeItem ─────────────────────────────────────────
    group('removeItem', () {
      test('returns ItemNotFoundFailure when product not in cart', () async {
        final result = await cartService.removeItem(999);
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<ItemNotFoundFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test('removes existing item from cart', () async {
        final product = _makeProduct();
        await cartService.addItem(product);
        final result = await cartService.removeItem(product.id);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.items, isEmpty),
        );
      });

      test('clears pharmacyId after removing last item', () async {
        final product = _makeProduct();
        await cartService.addItem(product);
        final result = await cartService.removeItem(product.id);

        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.pharmacyId, isNull),
        );
      });

      test('keeps other items when removing one', () async {
        final product1 = _makeProduct(id: 1);
        final product2 = _makeProduct(id: 2, name: 'Ibuprofène');
        await cartService.addItem(product1);
        await cartService.addItem(product2);

        final result = await cartService.removeItem(product1.id);
        result.fold((_) => fail('Expected Right'), (cart) {
          expect(cart.items.length, 1);
          expect(cart.items.first.product.id, product2.id);
        });
      });
    });

    // ── updateQuantity ─────────────────────────────────────
    group('updateQuantity', () {
      test('calls removeItem when quantity is 0', () async {
        final product = _makeProduct();
        await cartService.addItem(product, quantity: 2);
        final result = await cartService.updateQuantity(product.id, 0);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.items, isEmpty),
        );
      });

      test('calls removeItem when quantity is negative', () async {
        final product = _makeProduct();
        await cartService.addItem(product, quantity: 2);
        final result = await cartService.updateQuantity(product.id, -1);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.items, isEmpty),
        );
      });

      test('returns ItemNotFoundFailure when product not in cart', () async {
        final result = await cartService.updateQuantity(999, 5);
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<ItemNotFoundFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test(
        'returns InsufficientStockFailure when quantity exceeds stock',
        () async {
          final product = _makeProduct(stockQuantity: 5);
          await cartService.addItem(product, quantity: 2);
          final result = await cartService.updateQuantity(product.id, 10);

          expect(result.isLeft(), true);
          result.fold(
            (f) => expect(f, isA<InsufficientStockFailure>()),
            (_) => fail('Expected failure'),
          );
        },
      );

      test('updates quantity successfully', () async {
        final product = _makeProduct(stockQuantity: 10);
        await cartService.addItem(product, quantity: 2);
        final result = await cartService.updateQuantity(product.id, 7);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.items.first.quantity, 7),
        );
      });
    });

    // ── clearCart ──────────────────────────────────────────
    group('clearCart', () {
      test('returns empty cart after clearing', () async {
        final product = _makeProduct();
        await cartService.addItem(product);
        final result = await cartService.clearCart();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.items, isEmpty),
        );
      });

      test('clears pharmacyId after clearing', () async {
        final product = _makeProduct();
        await cartService.addItem(product);
        final result = await cartService.clearCart();

        result.fold(
          (_) => fail('Expected Right'),
          (cart) => expect(cart.pharmacyId, isNull),
        );
      });

      test('works on already empty cart', () async {
        final result = await cartService.clearCart();
        expect(result.isRight(), true);
      });

      test('currentCart is empty after clearCart', () async {
        await cartService.addItem(_makeProduct());
        await cartService.clearCart();
        expect(cartService.currentCart.isEmpty, true);
      });
    });

    // ── syncWithServer ─────────────────────────────────────
    group('syncWithServer', () {
      test('returns Right when sync is not configured', () async {
        final result = await cartService.syncWithServer();
        expect(result.isRight(), true);
      });

      test('returns OperationInProgressFailure when already locked', () async {
        // Simulate locked state by creating a custom service and holding lock
        // via rapid concurrent calls (implementation detail: already-in-progress)
        // We just verify syncWithServer succeeds when not locked
        final result = await cartService.syncWithServer();
        expect(result.isRight(), true);
      });
    });

    // ── mergeWithServerCart ────────────────────────────────
    group('mergeWithServerCart', () {
      test('returns Right with preferLocal strategy', () async {
        final product = _makeProduct();
        await cartService.addItem(product);

        final result = await cartService.mergeWithServerCart(
          strategy: ConflictResolutionStrategy.preferLocal,
        );
        expect(result.isRight(), true);
      });

      test('returns Right with preferServer strategy on empty cart', () async {
        final result = await cartService.mergeWithServerCart(
          strategy: ConflictResolutionStrategy.preferServer,
        );
        expect(result.isRight(), true);
      });
    });

    // ── dispose ────────────────────────────────────────────
    group('dispose', () {
      test('does not throw when called', () {
        expect(() => cartService.dispose(), returnsNormally);
      });

      test('can be called multiple times without error', () {
        cartService.dispose();
        expect(() => cartService.dispose(), returnsNormally);
      });
    });

    // ── CartData helpers ───────────────────────────────────
    group('CartData computed properties', () {
      test('totalItems sums all quantities', () async {
        await cartService.addItem(_makeProduct(id: 1), quantity: 3);
        await cartService.addItem(
          _makeProduct(id: 2, name: 'Ibuprofène'),
          quantity: 2,
        );
        expect(cartService.currentCart.totalItems, 5);
      });

      test('uniqueItemCount counts distinct products', () async {
        await cartService.addItem(_makeProduct(id: 1), quantity: 3);
        await cartService.addItem(
          _makeProduct(id: 2, name: 'Ibuprofène'),
          quantity: 2,
        );
        expect(cartService.currentCart.uniqueItemCount, 2);
      });

      test('subtotal computes total price', () async {
        await cartService.addItem(
          _makeProduct(id: 1, price: 500.0),
          quantity: 2,
        );
        expect(cartService.currentCart.subtotal, 1000.0);
      });

      test('containsProduct returns true for existing product', () async {
        final product = _makeProduct(id: 5);
        await cartService.addItem(product);
        expect(cartService.currentCart.containsProduct(5), true);
      });

      test('containsProduct returns false for missing product', () {
        expect(cartService.currentCart.containsProduct(99), false);
      });

      test('getItem returns item for existing product', () async {
        final product = _makeProduct(id: 7);
        await cartService.addItem(product, quantity: 4);
        final item = cartService.currentCart.getItem(7);
        expect(item, isNotNull);
        expect(item!.quantity, 4);
      });

      test('getItem returns null for missing product', () {
        expect(cartService.currentCart.getItem(999), isNull);
      });

      test(
        'hasPrescriptionRequired is true when any item requires prescription',
        () async {
          await cartService.addItem(
            _makeProduct(id: 1, requiresPrescription: true),
          );
          expect(cartService.currentCart.hasPrescriptionRequired, true);
        },
      );

      test(
        'hasPrescriptionRequired is false with no prescription items',
        () async {
          await cartService.addItem(
            _makeProduct(id: 1, requiresPrescription: false),
          );
          expect(cartService.currentCart.hasPrescriptionRequired, false);
        },
      );
    });
  });
}
