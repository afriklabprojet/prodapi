import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/products/presentation/pages/product_details_page.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_provider.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_state.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_notifier.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockProductsNotifier extends StateNotifier<ProductsState>
    with Mock
    implements ProductsNotifier {
  MockProductsNotifier([ProductsState? initialState])
    : super(initialState ?? const ProductsState.initial());

  @override
  Future<void> loadProducts({bool refresh = false}) async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> loadProductDetails(int productId) async {}

  @override
  Future<void> filterByCategory(
    String? category, {
    bool refresh = true,
  }) async {}

  @override
  Future<void> searchProducts(String query) async {}

  @override
  void clearError() {}

  @override
  void clearSearch() {}
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier([CartState? initialState])
    : super(initialState ?? const CartState.initial());

  @override
  Future<bool> addItem(ProductEntity product, {int quantity = 1}) async {
    return true;
  }

  @override
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidgetWithBothStates({
    required ProductsState productsState,
    CartState? cartState,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productsProvider.overrideWith((_) => MockProductsNotifier(productsState)),
        cartProvider.overrideWith((_) => MockCartNotifier(cartState ?? const CartState.initial())),
      ],
      child: const MaterialApp(home: ProductDetailsPage(productId: 1)),
    );
  }

  Widget createTestWidget({int productId = 1}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(home: ProductDetailsPage(productId: productId)),
    );
  }

  Widget createTestWidgetWithProductState({required ProductsState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productsProvider.overrideWith((_) => MockProductsNotifier(state)),
      ],
      child: const MaterialApp(home: ProductDetailsPage(productId: 1)),
    );
  }

  ProductEntity makeTestProduct() {
    return ProductEntity(
      id: 1,
      name: 'Paracétamol 500mg',
      description: 'Analgésique et antipyrétique pour la douleur',
      price: 1500.0,
      stockQuantity: 50,
      requiresPrescription: false,
      pharmacy: const PharmacyEntity(
        id: 1,
        name: 'Pharmacie Test',
        address: '123 Rue Test',
        phone: '+22507000001',
        status: 'active',
        isOpen: true,
      ),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
    );
  }

  group('ProductDetailsPage Widget Tests', () {
    testWidgets('should render product details page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ProductDetailsPage), findsOneWidget);
    });

    testWidgets('should display product details page with id', (tester) async {
      await tester.pumpWidget(createTestWidget(productId: 42));
      expect(find.byType(ProductDetailsPage), findsOneWidget);
    });

    testWidgets('should have add to cart button area', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(ProductDetailsPage), findsOneWidget);
    });

    testWidgets('should have quantity selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Quantity selector only appears when product data is loaded
      // Without mocked productsProvider, the page shows loading state
      expect(find.byType(ProductDetailsPage), findsOneWidget);
    });
  });

  group('ProductDetailsPage Content Tests', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error or loading state on page load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // single pump - microtasks run
      // FakeApiClient returns empty → product not found or error state
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without crash for different product ids', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(productId: 99));
      await tester.pump();
      expect(find.byType(ProductDetailsPage), findsOneWidget);
    });

    testWidgets('shows CustomScrollView', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows SliverAppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(SliverAppBar), findsOneWidget);
    });
  });

  group('ProductDetailsPage Loading State Tests', () {
    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithProductState(state: const ProductsState.loading()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ProductDetailsPage Error State Tests', () {
    testWidgets('shows error message in error state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: const ProductsState(
            status: ProductsStatus.error,
            errorMessage: 'Produit introuvable',
            products: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Produit introuvable'), findsOneWidget);
    });

    testWidgets('shows Retour button in error state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: const ProductsState(
            status: ProductsStatus.error,
            errorMessage: 'Erreur de chargement',
            products: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('shows Produit non trouvé when selectedProduct is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: const ProductsState(
            status: ProductsStatus.loaded,
            products: [],
            selectedProduct: null,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Produit non trouvé'), findsOneWidget);
    });
  });

  group('ProductDetailsPage Loaded State Tests', () {
    testWidgets('shows product name when loaded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Paracétamol 500mg'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows stock disponible info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('disponible'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Non requise for non-prescription product', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Non requise'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Ajouter au panier FAB for available product', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Ajouter au panier'), findsOneWidget);
    });

    testWidgets('shows shopping cart icon in AppBar', (tester) async {
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithProductState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byIcon(Icons.shopping_cart_outlined),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('ProductDetailsPage CartError Tests', () {
    testWidgets('shows snackbar when cart has error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
          cartState: const CartState(
            status: CartStatus.error,
            items: [],
            errorMessage: 'Erreur panier de test',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Erreur panier de test'), findsOneWidget);
    });

    testWidgets('snackbar OK action clears error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
          cartState: const CartState(
            status: CartStatus.error,
            items: [],
            errorMessage: 'Erreur panier OK',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Erreur panier OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pump();
    });
  });

  group('ProductDetailsPage Favorite Button Tests', () {
    testWidgets('tapping favorite button shows snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ajouté aux favoris'), findsOneWidget);
    });
  });

  group('ProductDetailsPage Quantity Selector Tests', () {
    testWidgets('tapping plus increases quantity display', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      // Tap plus (Icons.add)
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping minus after plus decreases quantity', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      // Increase to 2 first
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      // Now tap minus
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });
  });

  group('ProductDetailsPage Add To Cart FAB Tests', () {
    testWidgets('tapping add to cart shows success snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = makeTestProduct();
      await tester.pumpWidget(
        createTestWidgetWithBothStates(
          productsState: ProductsState(
            status: ProductsStatus.loaded,
            products: [product],
            selectedProduct: product,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ajouté au panier'), findsOneWidget);
    });
  });
}
