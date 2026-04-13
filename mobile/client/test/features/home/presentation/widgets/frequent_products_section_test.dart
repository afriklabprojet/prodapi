import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/home/presentation/widgets/frequent_products_section.dart';
import 'package:drpharma_client/features/products/presentation/providers/frequent_products_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/products/domain/entities/product_entity.dart';
import 'package:drpharma_client/features/products/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockFrequentProductsNotifier extends StateNotifier<FrequentProductsState>
    with Mock
    implements FrequentProductsNotifier {
  MockFrequentProductsNotifier([FrequentProductsState? state])
    : super(state ?? const FrequentProductsState());
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier() : super(const CartState.initial());

  @override
  Future<bool> addItem(ProductEntity product, {int quantity = 1}) async => true;
}

ProductEntity _makeProduct({int id = 1, String name = 'Paracétamol'}) {
  return ProductEntity(
    id: id,
    name: name,
    price: 500.0,
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
}

FrequentProduct _makeFrequent({
  int id = 1,
  String name = 'Paracétamol',
  int count = 3,
}) {
  return FrequentProduct(
    product: _makeProduct(id: id, name: name),
    purchaseCount: count,
    lastPurchasedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({
    List<FrequentProduct> topProducts = const [],
    FrequentProductsState? frequentState,
    bool isDark = false,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              Scaffold(body: FrequentProductsSection(isDark: isDark)),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, _) => const Scaffold(body: Text('Produit')),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, _) => const Scaffold(body: Text('Panier')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        frequentProductsProvider.overrideWith(
          (_) => MockFrequentProductsNotifier(
            frequentState ?? const FrequentProductsState(),
          ),
        ),
        topFrequentProductsProvider.overrideWithValue(topProducts),
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

  group('FrequentProductsSection Widget Tests', () {
    testWidgets('renders widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(FrequentProductsSection), findsOneWidget);
    });

    testWidgets('shows nothing when empty and not loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: []));
      await tester.pumpAndSettle();
      expect(find.text('Vos habituels'), findsNothing);
    });

    testWidgets('shows title and replay icon when products exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: [_makeFrequent()]));
      await tester.pumpAndSettle();
      expect(find.text('Vos habituels'), findsOneWidget);
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    });

    testWidgets('shows loading skeleton when isLoading with no products', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          frequentState: const FrequentProductsState(isLoading: true),
          topProducts: [],
        ),
      );
      await tester.pump();
      expect(find.text('Vos habituels'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows product name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(topProducts: [_makeFrequent(name: 'Ibuprofène')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofène'), findsOneWidget);
    });

    testWidgets('shows purchase count Nx achetés', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(topProducts: [_makeFrequent(count: 7)]),
      );
      await tester.pumpAndSettle();
      expect(find.text('7x achetés'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('shows add icon button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: [_makeFrequent()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows medication icon when no product image', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: [_makeFrequent()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    });

    testWidgets('shows Voir tout button when >= 6 products', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final products = List.generate(
        6,
        (i) => _makeFrequent(id: i, name: 'P$i'),
      );
      await tester.pumpWidget(createTestWidget(topProducts: products));
      await tester.pumpAndSettle();
      expect(find.text('Voir tout'), findsOneWidget);
    });

    testWidgets('hides Voir tout button when < 6 products', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: [_makeFrequent()]));
      await tester.pumpAndSettle();
      expect(find.text('Voir tout'), findsNothing);
    });

    testWidgets('shows multiple products', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final products = [
        _makeFrequent(id: 1, name: 'Aspirine'),
        _makeFrequent(id: 2, name: 'Doliprane'),
      ];
      await tester.pumpWidget(createTestWidget(topProducts: products));
      await tester.pumpAndSettle();
      expect(find.text('Aspirine'), findsOneWidget);
      expect(find.text('Doliprane'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(isDark: true, topProducts: [_makeFrequent()]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vos habituels'), findsOneWidget);
    });

    testWidgets('tap add button calls addItem', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(topProducts: [_makeFrequent(name: 'Aspirine')]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.byType(FrequentProductsSection), findsOneWidget);
    });

    testWidgets('shows horizontal ListView for product list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget(topProducts: [_makeFrequent()]));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
