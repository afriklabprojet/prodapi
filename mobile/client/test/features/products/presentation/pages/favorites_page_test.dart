import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/products/presentation/pages/favorites_page.dart';
import 'package:drpharma_client/features/products/presentation/providers/favorites_provider.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFavoritesNotifier extends StateNotifier<FavoritesState>
    with Mock
    implements FavoritesNotifier {
  MockFavoritesNotifier([FavoritesState? s])
    : super(s ?? const FavoritesState());

  @override
  Future<void> clearAll() async {
    state = const FavoritesState();
  }

  @override
  Future<void> removeFavorite(int productId) async {
    state = FavoritesState(
      favoriteIds: state.favoriteIds.where((id) => id != productId).toSet(),
      favoriteProducts: state.favoriteProducts
          .where((p) => p.id != productId)
          .toList(),
    );
  }

  @override
  Future<void> addFavorite(ProductEntity product) async {}
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier() : super(CartState.initial());

  @override
  Future<bool> addItem(ProductEntity product, {int quantity = 1}) async => true;
}

ProductEntity _makeProduct({
  int id = 1,
  String name = 'Paracétamol 500mg',
  double price = 1500,
}) => ProductEntity(
  id: id,
  name: name,
  price: price,
  stockQuantity: 10,
  requiresPrescription: false,
  pharmacy: PharmacyEntity(
    id: 1,
    name: 'Pharmacie Test',
    address: '12 rue Test',
    phone: '+22500000000',
    status: 'active',
    isOpen: true,
  ),
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  List<Override> _overrides(SharedPreferences prefs, FavoritesState state) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    apiClientProvider.overrideWithValue(FakeApiClient()),
    favoritesProvider.overrideWith((_) => MockFavoritesNotifier(state)),
    cartProvider.overrideWith((_) => MockCartNotifier()),
  ];

  Widget createTestWidget({FavoritesState? initialState}) {
    return ProviderScope(
      overrides: _overrides(
        sharedPreferences,
        initialState ?? const FavoritesState(),
      ),
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FavoritesPage(),
      ),
    );
  }

  Widget createTestWidgetWithProducts(List<ProductEntity> products) {
    final state = FavoritesState(
      favoriteIds: products.map((p) => p.id).toSet(),
      favoriteProducts: products,
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const FavoritesPage()),
        GoRoute(
          path: '/products',
          name: 'productsList',
          builder: (_, __) => const Scaffold(body: Text('Products')),
        ),
      ],
    );

    return ProviderScope(
      overrides: _overrides(sharedPreferences, state),
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Widget createEmptyWithRouter() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const FavoritesPage()),
        GoRoute(
          path: '/products',
          name: 'productsList',
          builder: (_, __) => const Scaffold(body: Text('Products')),
        ),
      ],
    );

    return ProviderScope(
      overrides: _overrides(sharedPreferences, const FavoritesState()),
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('FavoritesPage Widget Tests', () {
    testWidgets('should render favorites page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(FavoritesPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Mes habituels'), findsOneWidget);
    });

    testWidgets('should show empty state when no favorites', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(initialState: const FavoritesState()),
      );
      await tester.pump();
      expect(find.text('Aucun produit habituel'), findsOneWidget);
    });

    testWidgets('should show empty state icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should not show delete all button when no favorites', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });
  });

  group('FavoritesPage Products Tests', () {
    testWidgets('shows delete_sweep button when favorites exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct();
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });

    testWidgets('shows product name in grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct(name: 'Ibuprofène 400mg');
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofène 400mg'), findsOneWidget);
    });

    testWidgets('shows grid when favorites exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct();
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows empty state text when favorites is empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createEmptyWithRouter());
      await tester.pumpAndSettle();
      expect(find.text('Aucun produit habituel'), findsOneWidget);
    });

    testWidgets('shows Parcourir les produits button when empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createEmptyWithRouter());
      await tester.pumpAndSettle();
      expect(find.text('Parcourir les produits'), findsOneWidget);
    });

    testWidgets('tap Parcourir les produits navigates to products', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createEmptyWithRouter());
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('shows multiple products in grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final products = [
        _makeProduct(id: 1, name: 'Produit A'),
        _makeProduct(id: 2, name: 'Produit B'),
      ];
      await tester.pumpWidget(createTestWidgetWithProducts(products));
      await tester.pumpAndSettle();
      expect(find.text('Produit A'), findsOneWidget);
      expect(find.text('Produit B'), findsOneWidget);
    });
  });

  group('FavoritesPage Delete All Tests', () {
    testWidgets('tap delete_sweep shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct();
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer tous les favoris'), findsOneWidget);
    });

    testWidgets('dialog shows Annuler and Supprimer buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct();
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('cancel dialog does not clear favorites', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct(name: 'Produit Gardé');
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      // Dialog dismissed, product still shown
      expect(find.text('Produit Gardé'), findsOneWidget);
    });

    testWidgets('confirm dialog clears all favorites', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = _makeProduct(name: 'Produit Supprimé');
      await tester.pumpWidget(createTestWidgetWithProducts([product]));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      // After clearing, empty state shows
      expect(find.text('Aucun produit habituel'), findsOneWidget);
    });
  });
}
