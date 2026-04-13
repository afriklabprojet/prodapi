import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/products/presentation/widgets/price_comparison_section.dart';
import 'package:drpharma_client/features/products/presentation/providers/price_comparison_provider.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockPriceComparisonNotifier extends StateNotifier<PriceComparisonState>
    with Mock
    implements PriceComparisonNotifier {
  MockPriceComparisonNotifier([PriceComparisonState? state])
    : super(state ?? const PriceComparisonState());

  @override
  Future<void> comparePrices(int productId) async {}
}

PriceAlternative _makeAlt({
  int id = 1,
  String name = 'Paracétamol',
  double price = 400.0,
  String pharmacyName = 'Pharmacie Centrale',
  bool hasPromo = false,
  double? originalPrice,
}) {
  return PriceAlternative(
    id: id,
    name: name,
    price: price,
    originalPrice: originalPrice,
    hasPromo: hasPromo,
    stock: 5,
    pharmacyId: id,
    pharmacyName: pharmacyName,
    pharmacyAddress: '12 rue Test',
  );
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({
    PriceComparisonState? state,
    int productId = 1,
    double currentPrice = 500.0,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: PriceComparisonSection(
              productId: productId,
              currentPrice: currentPrice,
            ),
          ),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, _) => const Scaffold(body: Text('Produit')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        priceComparisonProvider(productId).overrideWith(
          (_) => MockPriceComparisonNotifier(
            state ?? const PriceComparisonState(),
          ),
        ),
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

  group('PriceComparisonSection Widget Tests', () {
    testWidgets('renders widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(PriceComparisonSection), findsOneWidget);
    });

    testWidgets('shows nothing when loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(state: const PriceComparisonState(isLoading: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aussi disponible ailleurs'), findsNothing);
    });

    testWidgets('shows nothing when no alternatives', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(state: const PriceComparisonState(alternatives: [])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aussi disponible ailleurs'), findsNothing);
    });

    testWidgets('shows header when alternatives exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(alternatives: [_makeAlt()]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aussi disponible ailleurs'), findsOneWidget);
    });

    testWidgets('shows compare_arrows icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(alternatives: [_makeAlt()]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
    });

    testWidgets('shows pharmacy name for alternative', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(
            alternatives: [_makeAlt(pharmacyName: 'Pharmacie du Port')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pharmacie du Port'), findsOneWidget);
    });

    testWidgets('shows local_pharmacy icon for alternative', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(alternatives: [_makeAlt()]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.local_pharmacy), findsOneWidget);
    });

    testWidgets('shows chevron_right icon for alternative', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(alternatives: [_makeAlt()]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows savings badge when alternative is cheaper', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          currentPrice: 600.0,
          state: PriceComparisonState(alternatives: [_makeAlt(price: 400.0)]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Économisez'), findsOneWidget);
    });

    testWidgets('shows arrow_downward icon when alternative is cheaper', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          currentPrice: 600.0,
          state: PriceComparisonState(alternatives: [_makeAlt(price: 400.0)]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows Voir plus button when > 3 alternatives', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final alts = List.generate(
        5,
        (i) => _makeAlt(
          id: i,
          pharmacyName: 'Pharmacie $i',
          price: 300.0 + i * 10,
        ),
      );
      await tester.pumpWidget(
        createTestWidget(state: PriceComparisonState(alternatives: alts)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Voir'), findsWidgets);
    });

    testWidgets('shows multiple alternatives', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(
            alternatives: [
              _makeAlt(id: 1, pharmacyName: 'Pharmacie A'),
              _makeAlt(id: 2, pharmacyName: 'Pharmacie B'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pharmacie A'), findsOneWidget);
      expect(find.text('Pharmacie B'), findsOneWidget);
    });

    testWidgets('tap on alternative navigates to product page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          state: PriceComparisonState(
            alternatives: [_makeAlt(id: 5, pharmacyName: 'Pharmacie Test')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pharmacie Test'));
      await tester.pumpAndSettle();
      expect(find.text('Produit'), findsOneWidget);
    });

    testWidgets('shows no savings badge when alternative is not cheaper', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          currentPrice: 300.0,
          state: PriceComparisonState(alternatives: [_makeAlt(price: 500.0)]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Économisez'), findsNothing);
    });
  });
}
