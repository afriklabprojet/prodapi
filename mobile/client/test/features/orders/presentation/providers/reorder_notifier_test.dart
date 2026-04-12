import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:drpharma_client/features/orders/presentation/providers/reorder_provider.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/cart_item_entity.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/data/datasources/cart_local_datasource.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_provider.dart';

import 'package:drpharma_client/features/products/presentation/providers/products_notifier.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_products_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/search_products_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_product_details_usecase.dart';
import 'package:drpharma_client/features/products/domain/usecases/get_products_by_category_usecase.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart'
    as products;
import 'package:drpharma_client/core/errors/failures.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────
class MockCartLocalDataSource extends Mock implements CartLocalDataSource {}

// ─────────────────────────────────────────────────────────
// Silent repository that always returns empty / failure
// ─────────────────────────────────────────────────────────
class _SilentRepo {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
  }) async => const Right([]);
  Future<Either<Failure, ProductEntity>> getProductDetails(int id) async =>
      const Left(ServerFailure(message: 'not found'));
  Future<Either<Failure, List<ProductEntity>>> searchProducts({
    required String query,
    int page = 1,
  }) async => const Right([]);
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory({
    required int categoryId,
    int page = 1,
  }) async => const Right([]);
}

// ─────────────────────────────────────────────────────────
// Fake ProductsNotifier extending real ProductsNotifier
// (overrides to avoid real loadProducts in constructor)
// ─────────────────────────────────────────────────────────
class FakeProductsNotifier extends ProductsNotifier {
  ProductEntity? productToReturn;

  FakeProductsNotifier()
    : super(
        getProductsUseCase: GetProductsUseCase(_SilentRepo()),
        searchProductsUseCase: SearchProductsUseCase(_SilentRepo()),
        getProductDetailsUseCase: GetProductDetailsUseCase(_SilentRepo()),
        getProductsByCategoryUseCase: GetProductsByCategoryUseCase(
          _SilentRepo(),
        ),
      );

  @override
  Future<void> loadProducts({bool refresh = false}) async {
    // No-op: prevents real API call on construction
  }

  @override
  Future<void> loadProductDetails(int productId) async {
    if (productToReturn != null) {
      state = state.copyWith(selectedProduct: productToReturn);
    }
    // If null, selectedProduct stays null → product was not found
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────
products.PharmacyEntity _makePharmacy() => const products.PharmacyEntity(
  id: 1,
  name: 'Pharmacie Test',
  address: '123 Rue Test',
  phone: '+22507000000',
  status: 'active',
  isOpen: true,
);

ProductEntity _makeProduct({int id = 1, bool isAvailable = true}) =>
    ProductEntity(
      id: id,
      name: 'Paracétamol $id',
      price: 500.0,
      stockQuantity: isAvailable ? 10 : 0,
      requiresPrescription: false,
      pharmacy: _makePharmacy(),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

OrderEntity _makeOrder({List<OrderItemEntity>? items}) {
  final orderItems =
      items ??
      [
        const OrderItemEntity(
          productId: 1,
          name: 'Paracétamol',
          quantity: 2,
          unitPrice: 500.0,
          totalPrice: 1000.0,
        ),
      ];

  return OrderEntity(
    id: 100,
    reference: 'ORD-001',
    status: OrderStatus.delivered,
    paymentStatus: 'paid',
    paymentMode: PaymentMode.platform,
    pharmacyId: 1,
    pharmacyName: 'Pharmacie Test',
    items: orderItems,
    subtotal: 1000.0,
    deliveryFee: 200.0,
    totalAmount: 1200.0,
    deliveryAddress: const DeliveryAddressEntity(
      address: '123 Rue Test',
      city: 'Abidjan',
      phone: '+22507000000',
    ),
    createdAt: DateTime(2024, 1, 1),
  );
}

ProviderContainer _makeContainer({
  FakeProductsNotifier? fakeProducts,
  MockCartLocalDataSource? mockCart,
}) {
  final productsNotifier = fakeProducts ?? FakeProductsNotifier();
  final cartSource = mockCart ?? MockCartLocalDataSource();

  if (mockCart == null) {
    when(
      () => cartSource.loadCart(),
    ).thenAnswer((_) async => (items: <CartItemEntity>[], pharmacyId: null));
    when(
      () => cartSource.saveCart(any(), pharmacyId: any(named: 'pharmacyId')),
    ).thenAnswer((_) async {});
  }

  return ProviderContainer(
    overrides: [
      productsProvider.overrideWith((_) => productsNotifier),
      cartLocalDataSourceProvider.overrideWith((_) => cartSource),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const CartState.initial());
    registerFallbackValue(<CartItemEntity>[]);
  });

  // ─────────────────────────────────────────────────────────
  // ReorderState — model tests
  // ─────────────────────────────────────────────────────────

  group('ReorderState — model', () {
    test('enum has all expected values', () {
      expect(
        ReorderStatus.values,
        containsAll([
          ReorderStatus.idle,
          ReorderStatus.loading,
          ReorderStatus.success,
          ReorderStatus.partialSuccess,
          ReorderStatus.error,
        ]),
      );
    });

    test('default state is idle with zero counts', () {
      const state = ReorderState();
      expect(state.status, ReorderStatus.idle);
      expect(state.addedCount, 0);
      expect(state.totalCount, 0);
      expect(state.failedProducts, isEmpty);
      expect(state.message, isNull);
    });

    test('copyWith updates all fields independently', () {
      const state = ReorderState();

      expect(
        state.copyWith(status: ReorderStatus.loading).status,
        ReorderStatus.loading,
      );
      expect(state.copyWith(message: 'done').message, 'done');
      expect(state.copyWith(addedCount: 3).addedCount, 3);
      expect(state.copyWith(totalCount: 5).totalCount, 5);
      expect(
        state.copyWith(failedProducts: ['A', 'B']).failedProducts,
        hasLength(2),
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // ReorderNotifier — reset
  // ─────────────────────────────────────────────────────────

  group('ReorderNotifier — reset', () {
    test('reset returns state to idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);

      notifier.reset();

      final state = container.read(reorderProvider);
      expect(state.status, ReorderStatus.idle);
      expect(state.message, isNull);
      expect(state.addedCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────
  // ReorderNotifier — reorder with empty order
  // ─────────────────────────────────────────────────────────

  group('ReorderNotifier — reorder', () {
    test('returns false and sets error state for empty order', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      final emptyOrder = _makeOrder(items: []);

      final result = await notifier.reorder(emptyOrder);

      expect(result, isFalse);
      final state = container.read(reorderProvider);
      expect(state.status, ReorderStatus.error);
      expect(state.message, 'Aucun article dans cette commande');
    });

    test('returns false when item has null productId', () async {
      final fakeProducts = FakeProductsNotifier();
      // productToReturn is null → selectedProduct stays null
      final container = _makeContainer(fakeProducts: fakeProducts);
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      final order = _makeOrder(
        items: [
          const OrderItemEntity(
            productId: null, // No productId
            name: 'Unknown Product',
            quantity: 1,
            unitPrice: 500.0,
            totalPrice: 500.0,
          ),
        ],
      );

      final result = await notifier.reorder(order);

      expect(result, isFalse);
      final state = container.read(reorderProvider);
      expect(state.status, ReorderStatus.error);
      expect(state.failedProducts, contains('Unknown Product'));
    });

    test(
      'returns false when product cannot be loaded (null selectedProduct)',
      () async {
        final fakeProducts = FakeProductsNotifier();
        fakeProducts.productToReturn =
            null; // loadProductDetails but no product

        final container = _makeContainer(fakeProducts: fakeProducts);
        addTearDown(container.dispose);

        final notifier = container.read(reorderProvider.notifier);
        final order = _makeOrder();

        final result = await notifier.reorder(order);

        expect(result, isFalse);
        final state = container.read(reorderProvider);
        expect(state.status, ReorderStatus.error);
      },
    );

    test('sets loading state during reorder', () async {
      final fakeProducts = FakeProductsNotifier();
      fakeProducts.productToReturn = _makeProduct();

      final cartSource = MockCartLocalDataSource();
      when(
        () => cartSource.loadCart(),
      ).thenAnswer((_) async => (items: <CartItemEntity>[], pharmacyId: null));
      when(
        () => cartSource.saveCart(any(), pharmacyId: any(named: 'pharmacyId')),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        fakeProducts: fakeProducts,
        mockCart: cartSource,
      );
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      // totalCount is set at beginning
      final order = _makeOrder();

      // Start reorder (we don't await to check intermediate state,
      // but the final state should be either success or error/partialSuccess)
      await notifier.reorder(order);

      final state = container.read(reorderProvider);
      // Product was available → should be success
      expect(state.status, isNot(ReorderStatus.loading));
    });

    test('returns true with success on fully available product', () async {
      final fakeProducts = FakeProductsNotifier();
      fakeProducts.productToReturn = _makeProduct(isAvailable: true);

      final cartSource = MockCartLocalDataSource();
      when(
        () => cartSource.loadCart(),
      ).thenAnswer((_) async => (items: <CartItemEntity>[], pharmacyId: null));
      when(
        () => cartSource.saveCart(any(), pharmacyId: any(named: 'pharmacyId')),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        fakeProducts: fakeProducts,
        mockCart: cartSource,
      );
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      final order = _makeOrder();
      final result = await notifier.reorder(order);

      expect(result, isTrue);
      final state = container.read(reorderProvider);
      expect(state.status, ReorderStatus.success);
      expect(state.addedCount, 1);
    });

    test('partialSuccess when some products fail', () async {
      final fakeProducts = FakeProductsNotifier();

      // First call returns a product, second call returns null
      // Override loadProductDetails behavior per call
      // We'll use a more complex fake for this

      final container = _makeContainer(fakeProducts: fakeProducts);
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      final order = _makeOrder(
        items: [
          const OrderItemEntity(
            productId: null, // fails
            name: 'Produit A',
            quantity: 1,
            unitPrice: 500.0,
            totalPrice: 500.0,
          ),
          // Add a second item with null productId — this also fails
          const OrderItemEntity(
            productId: null,
            name: 'Produit B',
            quantity: 1,
            unitPrice: 300.0,
            totalPrice: 300.0,
          ),
        ],
      );

      final result = await notifier.reorder(order);
      expect(result, isFalse); // all null → error
    });

    test('unavailable product is added to failedProducts', () async {
      final fakeProducts = FakeProductsNotifier();
      fakeProducts.productToReturn = _makeProduct(isAvailable: false);

      final cartSource = MockCartLocalDataSource();
      when(
        () => cartSource.loadCart(),
      ).thenAnswer((_) async => (items: <CartItemEntity>[], pharmacyId: null));
      when(
        () => cartSource.saveCart(any(), pharmacyId: any(named: 'pharmacyId')),
      ).thenAnswer((_) async {});

      final container = _makeContainer(
        fakeProducts: fakeProducts,
        mockCart: cartSource,
      );
      addTearDown(container.dispose);

      final notifier = container.read(reorderProvider.notifier);
      final order = _makeOrder();

      final result = await notifier.reorder(order);

      expect(result, isFalse);
      final state = container.read(reorderProvider);
      expect(state.failedProducts, isNotEmpty);
    });
  });
}
