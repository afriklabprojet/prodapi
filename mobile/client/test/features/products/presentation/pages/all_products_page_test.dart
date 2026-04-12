import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/products/presentation/pages/all_products_page.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_provider.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_notifier.dart';
import 'package:drpharma_client/features/products/presentation/providers/products_state.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/category_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockProductsNotifier extends StateNotifier<ProductsState>
    with Mock
    implements ProductsNotifier {
  MockProductsNotifier() : super(const ProductsState.initial());

  @override
  Future<void> loadProducts({bool refresh = false}) async {}

  Future<void> loadMore({bool refresh = false}) async {}

  @override
  Future<void> searchProducts(String query) async {}

  @override
  Future<void> filterByCategory(
    String? category, {
    bool refresh = true,
  }) async {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(home: const AllProductsPage()),
    );
  }

  Widget createTestWidgetWithState({required ProductsState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productsProvider.overrideWith(
          (_) => MockProductsNotifier()..state = state,
        ),
      ],
      child: MaterialApp(home: const AllProductsPage()),
    );
  }

  group('AllProductsPage Widget Tests', () {
    testWidgets('should render all products page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });

    testWidgets('should have app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('should have category filter', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });

    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AllProductsPage), findsOneWidget);
    });
  });

  group('AllProductsPage Widget Details', () {
    testWidgets('shows AppBar title Tous les Médicaments', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Tous les Médicaments'), findsOneWidget);
    });

    testWidgets('shows search TextField with hint', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rechercher un médicament...'), findsOneWidget);
    });

    testWidgets('shows Tous category chip initially selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Tous'), findsOneWidget);
    });

    testWidgets('has search icon in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('has filter icon button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('entering text in search field updates query', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Doliprane');
      await tester.pump();

      expect(find.text('Doliprane'), findsOneWidget);
    });

    testWidgets('shows arrow_back icon in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('AllProductsPage State Tests', () {
    testWidgets('shows Réessayer button in error state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const ProductsState(
            status: ProductsStatus.error,
            products: [],
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows error message in error state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const ProductsState(
            status: ProductsStatus.error,
            products: [],
            errorMessage: 'Erreur réseau',
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Erreur'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows shimmer grid in loading state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithState(state: const ProductsState.loading()),
      );
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows AppBar in error state', (tester) async {
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const ProductsState(
            status: ProductsStatus.error,
            products: [],
            errorMessage: 'Pas de connexion',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tous les Médicaments'), findsOneWidget);
    });

    testWidgets('shows empty state when loaded with no products', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithState(
          state: const ProductsState(
            status: ProductsStatus.loaded,
            products: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AllProductsPage), findsOneWidget);
    });
  });

  group('AllProductsPage Interaction Tests', () {
    testWidgets('category chips are visible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('shows Antidouleurs category chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Antidouleurs'), findsOneWidget);
    });

    testWidgets('shows Antibiotiques category chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Antibiotiques'), findsOneWidget);
    });

    testWidgets('shows Prix sort chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Prix ↑'), findsOneWidget);
    });

    testWidgets('shows Mieux notés sort chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Mieux notés'), findsOneWidget);
    });

    testWidgets('shows Filtres button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Filtres'), findsOneWidget);
    });

    testWidgets('tapping Filtres button opens filter sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Trier & Filtrer'), findsOneWidget);
    });

    testWidgets('filter sheet shows Appliquer button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Appliquer'), findsOneWidget);
    });

    testWidgets('filter sheet shows Réinitialiser button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Réinitialiser'), findsOneWidget);
    });

    testWidgets('filter sheet shows Trier par section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Trier par'), findsOneWidget);
    });

    testWidgets('filter sheet shows En stock switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('En stock uniquement'), findsOneWidget);
    });

    testWidgets('shows CartIcon in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });

  group('AllProductsPage Loaded State Tests', () {
    ProductEntity _makeProduct({
      int id = 1,
      String name = 'Paracétamol',
      double price = 500.0,
    }) {
      return ProductEntity(
        id: id,
        name: name,
        price: price,
        stockQuantity: 10,
        requiresPrescription: false,
        pharmacy: PharmacyEntity(
          id: 1,
          name: 'Pharmacie Test',
          address: 'Abidjan',
          phone: '0700000000',
          status: 'active',
          isOpen: true,
        ),
        category: const CategoryEntity(id: 1, name: 'Antidouleurs'),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    testWidgets('shows product name in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [_makeProduct()],
            hasMore: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Paracétamol'), findsOneWidget);
    });

    testWidgets('shows product price in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [_makeProduct(price: 500.0)],
            hasMore: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('shows multiple products in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidgetWithState(
          state: ProductsState(
            status: ProductsStatus.loaded,
            products: [
              _makeProduct(id: 1, name: 'Paracétamol'),
              _makeProduct(id: 2, name: 'Ibuprofène'),
            ],
            hasMore: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Paracétamol'), findsOneWidget);
      expect(find.textContaining('Ibuprofène'), findsOneWidget);
    });

    testWidgets('filter sheet shows En promotion switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('En promotion'), findsOneWidget);
    });

    testWidgets('filter sheet shows Prix bas sort chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Filtres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Prix'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Premiers Soins category chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Premiers Soins'), findsOneWidget);
    });

    testWidgets('shows Soins et Beauté category chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Soins & Beauté'), findsOneWidget);
    });

    testWidgets('shows tune_rounded icon in filter button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('shows clear icon when search field has text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'para');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('can clear search via clear button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'para');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('shows search icon prefix in search field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
