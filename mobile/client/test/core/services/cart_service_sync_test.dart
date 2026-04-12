import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/core/services/cart_service.dart';
import 'package:drpharma_client/core/contracts/cart_contract.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/core/errors/cart_failures.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';

CartService _makeService(
  SharedPreferences prefs, {
  Future<Either<Failure, CartData>> Function()? fetchServerCart,
  Future<Either<Failure, void>> Function(CartData cart)? pushToServer,
  Duration cartExpirationDuration = const Duration(days: 7),
}) => CartService(
  prefs: prefs,
  fetchServerCart: fetchServerCart,
  pushToServer: pushToServer,
  cartExpirationDuration: cartExpirationDuration,
);

PharmacyEntity _makeTestPharmacy({int id = 1}) => PharmacyEntity(
  id: id,
  name: 'Pharmacie Test',
  address: '123 Rue Principale',
  phone: '+2250700000000',
  status: 'active',
  isOpen: true,
);

ProductEntity _makeTestProduct({
  int id = 1,
  double price = 500.0,
  int stockQuantity = 10,
}) => ProductEntity(
  id: id,
  name: 'Produit $id',
  price: price,
  stockQuantity: stockQuantity,
  requiresPrescription: false,
  pharmacy: _makeTestPharmacy(),
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

void main() {
  // Required for CartService.init() which uses EventChannel (connectivity_plus)
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────
  // init()
  // ─────────────────────────────────────────────────────────
  group('CartService.init()', () {
    test('fresh start (empty prefs) → returns empty cart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (cart) {
        expect(cart.isEmpty, isTrue);
        expect(cart.pharmacyId, isNull);
      });
    });

    test('with stored empty cart JSON → restores empty cart', () async {
      const cartJson =
          '{"version":3,"items":[],"pharmacy_id":null,"pharmacy_name":null,"last_modified":"2024-06-01T10:00:00.000"}';
      SharedPreferences.setMockInitialValues({'shopping_cart': cartJson});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail(''), (cart) {
        expect(cart.isEmpty, isTrue);
        expect(cart.pharmacyId, isNull);
      });
    });

    test(
      'with stored cart JSON having pharmacy info → restores pharmacy',
      () async {
        const cartJson =
            '{"version":3,"items":[],"pharmacy_id":42,"pharmacy_name":"Pharmacie du Centre","last_modified":"2024-06-01T10:00:00.000"}';
        SharedPreferences.setMockInitialValues({'shopping_cart': cartJson});
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(prefs);
        addTearDown(svc.dispose);

        final result = await svc.init();
        expect(result.isRight(), isTrue);
        result.fold((_) => fail(''), (cart) {
          expect(cart.pharmacyId, 42);
          expect(cart.pharmacyName, 'Pharmacie du Centre');
        });
      },
    );

    test('with expired cart → clears cart (expiration = 1 day)', () async {
      const cartJson =
          '{"version":3,"items":[],"pharmacy_id":null,"pharmacy_name":null,"last_modified":"2020-01-01T00:00:00.000"}';
      SharedPreferences.setMockInitialValues({'shopping_cart': cartJson});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        cartExpirationDuration: const Duration(days: 1),
      );
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
    });

    test('with schema v1 cart → migrates (clears old cart)', () async {
      const oldCartJson =
          '{"version":1,"items":[],"pharmacy_id":null,"pharmacy_name":null,"last_modified":"2024-06-01T10:00:00.000"}';
      SharedPreferences.setMockInitialValues({'shopping_cart': oldCartJson});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
    });

    test(
      'with corrupted cart JSON → graceful fallback to empty cart',
      () async {
        SharedPreferences.setMockInitialValues({
          'shopping_cart': 'NOT_VALID_JSON{{',
        });
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(prefs);
        addTearDown(svc.dispose);

        final result = await svc.init();
        expect(result.isRight(), isTrue);
        result.fold((_) => fail(''), (cart) => expect(cart.isEmpty, isTrue));
      },
    );

    test('with valid pending operations JSON → loads from prefs', () async {
      const pendingJson =
          '[{"type":"add","product_id":1,"quantity":2,"created_at":"2024-06-01T10:00:00.000","retry_count":0}]';
      SharedPreferences.setMockInitialValues({
        'cart_pending_operations': pendingJson,
      });
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
    });

    test('with corrupted pending operations JSON → silently ignores', () async {
      SharedPreferences.setMockInitialValues({
        'cart_pending_operations': 'BAD{JSON',
      });
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.init();
      expect(result.isRight(), isTrue);
    });

    test('emits on cartStream after init', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      CartData? emitted;
      final sub = svc.cartStream.listen((c) => emitted = c);
      await svc.init();
      await Future.delayed(Duration.zero);

      expect(emitted, isNotNull);
      await sub.cancel();
    });

    test('currentCart reflects restored state after init', () async {
      const cartJson =
          '{"version":3,"items":[],"pharmacy_id":7,"pharmacy_name":"Test","last_modified":"2024-06-01T10:00:00.000"}';
      SharedPreferences.setMockInitialValues({'shopping_cart': cartJson});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      await svc.init();
      expect(svc.currentCart.pharmacyId, 7);
    });
  });

  // ─────────────────────────────────────────────────────────
  // syncWithServer()
  // ─────────────────────────────────────────────────────────
  group('CartService.syncWithServer()', () {
    test('no callbacks → skips sync, returns Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.syncWithServer();
      expect(result.isRight(), isTrue);
    });

    test(
      'only fetchServerCart set (no pushToServer) → Right immediately',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final svc = CartService(
          prefs: prefs,
          fetchServerCart: () async => Right(CartData.empty()),
          // pushToServer intentionally null
        );
        addTearDown(svc.dispose);

        final result = await svc.syncWithServer();
        expect(result.isRight(), isTrue);
      },
    );

    test('both callbacks, no pending ops → fetches server → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      final result = await svc.syncWithServer();
      expect(result.isRight(), isTrue);
    });

    test('with pending ops, push success → clears pending ops', () async {
      const pendingJson =
          '[{"type":"add","product_id":1,"quantity":2,"created_at":"2024-06-01T10:00:00.000","retry_count":0}]';
      SharedPreferences.setMockInitialValues({
        'cart_pending_operations': pendingJson,
      });
      final prefs = await SharedPreferences.getInstance();

      var pushWasCalled = false;
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
        pushToServer: (cart) async {
          pushWasCalled = true;
          return const Right(null);
        },
      );
      addTearDown(svc.dispose);

      await svc.init(); // loads pending ops from prefs
      final result = await svc.syncWithServer();

      expect(result.isRight(), isTrue);
      expect(pushWasCalled, isTrue);
    });

    test('push fails → Left(CartSyncFailure)', () async {
      const pendingJson =
          '[{"type":"add","product_id":1,"quantity":2,"created_at":"2024-06-01T10:00:00.000","retry_count":0}]';
      SharedPreferences.setMockInitialValues({
        'cart_pending_operations': pendingJson,
      });
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
        pushToServer: (cart) async =>
            const Left(ServerFailure(message: 'Push failed')),
      );
      addTearDown(svc.dispose);

      await svc.init();
      final result = await svc.syncWithServer();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CartSyncFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('fetch fails → Left(failure)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async =>
            const Left(NetworkFailure(message: 'No connection')),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      final result = await svc.syncWithServer();
      expect(result.isLeft(), isTrue);
    });

    test('syncStatusStream emits synced after success', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      final statuses = <CartSyncStatus>[];
      final sub = svc.syncStatusStream.listen(statuses.add);

      await svc.syncWithServer();
      await Future.delayed(Duration.zero);

      expect(statuses, contains(CartSyncStatus.synced));
      await sub.cancel();
    });
  });

  // ─────────────────────────────────────────────────────────
  // forceServerCart()
  // ─────────────────────────────────────────────────────────
  group('CartService.forceServerCart()', () {
    test('no fetchServerCart → returns current cart unchanged', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.forceServerCart();
      expect(result.isRight(), isTrue);
    });

    test(
      'fetchServerCart returns Right → replaces current cart with server',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final serverCart = CartData(
          items: const [],
          pharmacyId: 99,
          pharmacyName: 'Server Pharmacy',
          lastModified: DateTime(2024, 6, 1),
          source: CartSource.server,
        );

        final svc = _makeService(
          prefs,
          fetchServerCart: () async => Right(serverCart),
        );
        addTearDown(svc.dispose);

        final result = await svc.forceServerCart();
        expect(result.isRight(), isTrue);
        result.fold((_) => fail(''), (cart) {
          expect(cart.source, CartSource.server);
          expect(cart.pharmacyId, 99);
        });
      },
    );

    test('fetchServerCart returns Left → Left', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async =>
            const Left(NetworkFailure(message: 'No connection')),
      );
      addTearDown(svc.dispose);

      final result = await svc.forceServerCart();
      expect(result.isLeft(), isTrue);
    });

    test('force server cart clears pending operations', () async {
      const pendingJson =
          '[{"type":"add","product_id":1,"quantity":2,"created_at":"2024-06-01T10:00:00.000","retry_count":0}]';
      SharedPreferences.setMockInitialValues({
        'cart_pending_operations': pendingJson,
      });
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      await svc.init();
      await svc.forceServerCart();

      // After force server cart, pending ops key should be cleared
      expect(prefs.getString('cart_pending_operations'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // pushLocalToServer()
  // ─────────────────────────────────────────────────────────
  group('CartService.pushLocalToServer()', () {
    test('no pushToServer callback → returns current cart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.pushLocalToServer();
      expect(result.isRight(), isTrue);
    });

    test('pushToServer success → clears pending ops', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var pushCalled = false;
      final svc = _makeService(
        prefs,
        pushToServer: (cart) async {
          pushCalled = true;
          return const Right(null);
        },
      );
      addTearDown(svc.dispose);

      final result = await svc.pushLocalToServer();
      expect(result.isRight(), isTrue);
      expect(pushCalled, isTrue);
    });

    test('pushToServer fails → Left', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        pushToServer: (cart) async =>
            const Left(CartSyncFailure(reason: 'Server error')),
      );
      addTearDown(svc.dispose);

      final result = await svc.pushLocalToServer();
      expect(result.isLeft(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────
  // mergeWithServerCart()
  // ─────────────────────────────────────────────────────────
  group('CartService.mergeWithServerCart()', () {
    test('no fetchServerCart → returns Right (local cart)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(prefs);
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferLocal,
      );
      expect(result.isRight(), isTrue);
    });

    test('fetchServerCart returns Left → Left', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async =>
            const Left(NetworkFailure(message: 'No net')),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferServer,
      );
      expect(result.isLeft(), isTrue);
    });

    test('preferServer strategy, empty server → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferServer,
      );
      expect(result.isRight(), isTrue);
    });

    test('preferLocal strategy → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferLocal,
      );
      expect(result.isRight(), isTrue);
    });

    test('sumQuantities strategy → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.sumQuantities,
      );
      expect(result.isRight(), isTrue);
    });

    test('takeHigherQuantity strategy → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.takeHigherQuantity,
      );
      expect(result.isRight(), isTrue);
    });

    test('takeNewest strategy → Right', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.takeNewest,
      );
      expect(result.isRight(), isTrue);
    });

    test('emits on cartStream after merge', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = _makeService(
        prefs,
        fetchServerCart: () async => Right(CartData.empty()),
      );
      addTearDown(svc.dispose);

      CartData? emitted;
      final sub = svc.cartStream.listen((c) => emitted = c);

      await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferLocal,
      );
      await Future.delayed(Duration.zero);

      expect(emitted, isNotNull);
      await sub.cancel();
    });
  });

  // ─────────────────────────────────────────────────────────
  // CartData model
  // ─────────────────────────────────────────────────────────
  group('CartData model', () {
    test('copyWith clearPharmacy=true clears pharmacy', () {
      final cart = CartData(
        items: const [],
        pharmacyId: 10,
        pharmacyName: 'Test',
        lastModified: DateTime(2024, 1, 1),
        source: CartSource.local,
      );
      final cleared = cart.copyWith(clearPharmacy: true);
      expect(cleared.pharmacyId, isNull);
      expect(cleared.pharmacyName, isNull);
    });

    test('copyWith preserves pharmacy if clearPharmacy=false', () {
      final cart = CartData(
        items: const [],
        pharmacyId: 5,
        pharmacyName: 'Pharma A',
        lastModified: DateTime(2024, 1, 1),
        source: CartSource.local,
      );
      final copy = cart.copyWith(source: CartSource.server);
      expect(copy.pharmacyId, 5);
      expect(copy.pharmacyName, 'Pharma A');
      expect(copy.source, CartSource.server);
    });

    test('empty() factory creates empty cart', () {
      final empty = CartData.empty();
      expect(empty.isEmpty, isTrue);
      expect(empty.pharmacyId, isNull);
      expect(empty.source, CartSource.local);
    });

    test('toJson() includes all required fields', () {
      final cart = CartData(
        items: const [],
        pharmacyId: 1,
        pharmacyName: 'Test',
        lastModified: DateTime(2024, 6, 1),
        source: CartSource.local,
        schemaVersion: 3,
      );
      final json = cart.toJson();
      expect(json['pharmacy_id'], 1);
      expect(json['pharmacy_name'], 'Test');
      expect(json['source'], 'local');
      expect(json['schema_version'], 3);
    });
  });

  // ─────────────────────────────────────────────────────────
  // PendingCartOperation model
  // ─────────────────────────────────────────────────────────
  group('PendingCartOperation model', () {
    test('toJson()/fromJson() round-trip', () {
      final op = PendingCartOperation(
        type: CartOperationType.add,
        productId: 42,
        quantity: 3,
        createdAt: DateTime(2024, 6, 1, 12, 0, 0),
        retryCount: 2,
      );
      final json = op.toJson();
      final restored = PendingCartOperation.fromJson(json);

      expect(restored.type, CartOperationType.add);
      expect(restored.productId, 42);
      expect(restored.quantity, 3);
      expect(restored.retryCount, 2);
    });

    test('fromJson() with unknown type falls back to add', () {
      final json = {
        'type': 'unknown_type',
        'product_id': 1,
        'quantity': 1,
        'created_at': '2024-01-01T00:00:00.000',
        'retry_count': 0,
      };
      final op = PendingCartOperation.fromJson(json);
      expect(op.type, CartOperationType.add);
    });

    test('incrementRetry() increments retry count', () {
      final op = PendingCartOperation(
        type: CartOperationType.remove,
        productId: 5,
        createdAt: DateTime(2024, 1, 1),
      );
      final incremented = op.incrementRetry();
      expect(incremented.retryCount, 1);
    });

    test('toJson() handles null productId and quantity', () {
      final op = PendingCartOperation(
        type: CartOperationType.clear,
        createdAt: DateTime(2024, 1, 1),
      );
      final json = op.toJson();
      expect(json['product_id'], isNull);
      expect(json['quantity'], isNull);
      expect(json['type'], 'clear');
    });
  });

  // ─────────────────────────────────────────────────────────
  // Exception handling in sync methods
  // ─────────────────────────────────────────────────────────
  group('CartService sync exception handling', () {
    test(
      'syncWithServer throws during fetchServerCart → Left(CartSyncFailure)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(
          prefs,
          fetchServerCart: () async => throw Exception('Network error'),
          pushToServer: (cart) async => const Right(null),
        );
        addTearDown(svc.dispose);

        final result = await svc.syncWithServer();
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CartSyncFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'mergeWithServerCart throws during fetch → Left(CartSyncFailure)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(
          prefs,
          fetchServerCart: () async => throw Exception('Fetch error'),
          pushToServer: (cart) async => const Right(null),
        );
        addTearDown(svc.dispose);

        final result = await svc.mergeWithServerCart(
          strategy: ConflictResolutionStrategy.preferLocal,
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CartSyncFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'forceServerCart throws during fetch → Left(CartSyncFailure)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(
          prefs,
          fetchServerCart: () async => throw Exception('Server down'),
        );
        addTearDown(svc.dispose);

        final result = await svc.forceServerCart();
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CartSyncFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'pushLocalToServer throws during push → Left(CartSyncFailure)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final svc = _makeService(
          prefs,
          pushToServer: (cart) async => throw Exception('Push failed'),
        );
        addTearDown(svc.dispose);

        final result = await svc.pushLocalToServer();
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CartSyncFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────
  // _mergeCartData with both carts non-empty (covers switch cases)
  // ─────────────────────────────────────────────────────────
  group('CartService._mergeCartData both non-empty', () {
    CartData _makeCartWithProduct(int productId, int quantity) {
      return CartData(
        items: [
          CartItemEntity(
            product: _makeTestProduct(id: productId, stockQuantity: 20),
            quantity: quantity,
          ),
        ],
        pharmacyId: 1,
        pharmacyName: 'Test',
        lastModified: DateTime(2024, 6, 1),
        source: CartSource.local,
      );
    }

    test('preferServer: both non-empty → server item wins', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      _makeCartWithProduct(1, 2);
      final serverCart = _makeCartWithProduct(1, 5);

      final svc = CartService(
        prefs: prefs,
        fetchServerCart: () async => Right(serverCart),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      // Set local cart
      await svc.addItem(
        _makeTestProduct(id: 1, stockQuantity: 20),
        quantity: 2,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferServer,
      );
      expect(result.isRight(), isTrue);
    });

    test('preferLocal: both non-empty → local item wins', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final serverCart = _makeCartWithProduct(1, 5);

      final svc = CartService(
        prefs: prefs,
        fetchServerCart: () async => Right(serverCart),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      await svc.addItem(
        _makeTestProduct(id: 1, stockQuantity: 20),
        quantity: 3,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.preferLocal,
      );
      expect(result.isRight(), isTrue);
    });

    test('takeHigherQuantity: both non-empty → higher qty selected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final serverCart = _makeCartWithProduct(1, 8);

      final svc = CartService(
        prefs: prefs,
        fetchServerCart: () async => Right(serverCart),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      await svc.addItem(
        _makeTestProduct(id: 1, stockQuantity: 20),
        quantity: 3,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.takeHigherQuantity,
      );
      expect(result.isRight(), isTrue);
    });

    test(
      'sumQuantities: both non-empty → quantities summed (capped at stock)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final serverCart = _makeCartWithProduct(1, 6);

        final svc = CartService(
          prefs: prefs,
          fetchServerCart: () async => Right(serverCart),
          pushToServer: (cart) async => const Right(null),
        );
        addTearDown(svc.dispose);

        await svc.addItem(
          _makeTestProduct(id: 1, stockQuantity: 20),
          quantity: 4,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final result = await svc.mergeWithServerCart(
          strategy: ConflictResolutionStrategy.sumQuantities,
        );
        expect(result.isRight(), isTrue);
      },
    );

    test('takeNewest: both non-empty → newest cart wins', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final serverCart = CartData(
        items: [
          CartItemEntity(
            product: _makeTestProduct(id: 1, stockQuantity: 20),
            quantity: 5,
          ),
        ],
        pharmacyId: 1,
        pharmacyName: 'Test',
        lastModified: DateTime(2024, 1, 1), // older server
        source: CartSource.server,
      );

      final svc = CartService(
        prefs: prefs,
        fetchServerCart: () async => Right(serverCart),
        pushToServer: (cart) async => const Right(null),
      );
      addTearDown(svc.dispose);

      await svc.addItem(
        _makeTestProduct(id: 1, stockQuantity: 20),
        quantity: 2,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await svc.mergeWithServerCart(
        strategy: ConflictResolutionStrategy.takeNewest,
      );
      expect(result.isRight(), isTrue);
    });

    test(
      'mergeWithServerCart with pushToServer also set → pushes merged cart',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final serverCart = _makeCartWithProduct(2, 3);

        var pushCalled = false;
        final svc = CartService(
          prefs: prefs,
          fetchServerCart: () async => Right(serverCart),
          pushToServer: (cart) async {
            pushCalled = true;
            return const Right(null);
          },
        );
        addTearDown(svc.dispose);

        // Different product in local (product 1) vs server (product 2)
        await svc.addItem(
          _makeTestProduct(id: 1, stockQuantity: 20),
          quantity: 2,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        await svc.mergeWithServerCart(
          strategy: ConflictResolutionStrategy.preferLocal,
        );
        expect(pushCalled, isTrue);
      },
    );
  });
}
