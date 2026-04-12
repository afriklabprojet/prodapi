import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/home/presentation/widgets/favorite_products_section.dart';
import 'package:drpharma_client/features/products/presentation/providers/favorites_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFavoritesNotifier extends StateNotifier<FavoritesState>
    with Mock
    implements FavoritesNotifier {
  MockFavoritesNotifier([FavoritesState? state])
    : super(state ?? const FavoritesState());

  Future<void> loadFavorites() async {}
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier() : super(const CartState.initial());

  @override
  Future<bool> addItem(ProductEntity product, {int quantity = 1}) async => true;
}

ProductEntity _makeProduct({
  int id = 1,
  String name = 'Paracétamol 500mg',
  double price = 500.0,
  int stock = 10,
}) {
  return ProductEntity(
    id: id,
    name: name,
    price: price,
    stockQuantity: stock,
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
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({
    List<ProductEntity> favorites = const [],
    bool isDark = false,
  }) {
    final notifier = MockFavoritesNotifier(
      FavoritesState(favoriteProducts: favorites),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: FavoriteProductsSection(isDark: isDark)),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, __) => const Scaffold(body: Text('Produit')),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const Scaffold(body: Text('Favoris')),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, __) => const Scaffold(body: Text('Panier')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        favoritesProvider.overrideWith((_) => notifier),
        cartProvider.overrideWith((_) => MockCartNotifier()),
      ],
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

  group('FavoriteProductsSection Widget Tests', () {
    testWidgets('renders widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(FavoriteProductsSection), findsOneWidget);
    });

    testWidgets('shows nothing when favorites empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: []));
      await tester.pumpAndSettle();
      expect(find.text('Mes habituels'), findsNothing);
    });

    testWidgets('shows title Mes habituels when favorites exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      expect(find.text('Mes habituels'), findsOneWidget);
    });

    testWidgets('shows Voir tout button when favorites exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      expect(find.text('Voir tout'), findsOneWidget);
    });

    testWidgets('shows product name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(favorites: [_makeProduct(name: 'Ibuprofène 400mg')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofène 400mg'), findsOneWidget);
    });

    testWidgets('shows add_shopping_cart icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no product image', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    });

    testWidgets('shows horizontal ListView', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows multiple product names', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          favorites: [
            _makeProduct(id: 1, name: 'Aspirine'),
            _makeProduct(id: 2, name: 'Doliprane'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aspirine'), findsOneWidget);
      expect(find.text('Doliprane'), findsOneWidget);
    });

    testWidgets('limits display to 6 products', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final products = List.generate(
        8,
        (i) => _makeProduct(id: i, name: 'P$i'),
      );
      await tester.pumpWidget(createTestWidget(favorites: products));
      await tester.pumpAndSettle();
      expect(find.text('Mes habituels'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(isDark: true, favorites: [_makeProduct()]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mes habituels'), findsOneWidget);
    });

    testWidgets('tap Voir tout navigates to favorites', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(favorites: [_makeProduct()]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir tout'));
      await tester.pumpAndSettle();
      expect(find.text('Favoris'), findsOneWidget);
    });

    testWidgets('tap add to cart calls addItem', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(favorites: [_makeProduct(name: 'Aspirine')]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();
      expect(find.byType(FavoriteProductsSection), findsOneWidget);
    });

    testWidgets('tap on product navigates to product details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          favorites: [_makeProduct(id: 42, name: 'Test Médicament')],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Médicament'));
      await tester.pumpAndSettle();
      expect(find.text('Produit'), findsOneWidget);
    });
  });
}
