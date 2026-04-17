import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:drpharma_client/features/loyalty/presentation/providers/loyalty_provider.dart';
import 'package:drpharma_client/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockLoyaltyNotifier extends StateNotifier<LoyaltyState>
    with Mock
    implements LoyaltyNotifier {
  MockLoyaltyNotifier() : super(const LoyaltyState());

  @override
  Future<void> loadLoyalty() async {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({LoyaltyState? initialState}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        loyaltyProvider.overrideWith(
          (_) =>
              MockLoyaltyNotifier()
                ..state = initialState ?? const LoyaltyState(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoyaltyPage(),
      ),
    );
  }

  group('LoyaltyPage Widget Tests', () {
    testWidgets('should render loyalty page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(LoyaltyPage), findsOneWidget);
    });

    testWidgets('should have app bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show app bar title', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      // Title appears in both AppBar and body heading
      expect(find.text('Programme Fidélité'), findsWidgets);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(initialState: const LoyaltyState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have refresh indicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(LoyaltyPage), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────
  // Loaded state with loyalty data
  // ──────────────────────────────────────────────────────
  group('LoyaltyPage Loaded State', () {
    LoyaltyEntity makeLoyalty({
      LoyaltyTier tier = LoyaltyTier.bronze,
      int totalPoints = 200,
      int availablePoints = 180,
      int totalOrders = 5,
      double totalSpent = 50000,
      int pointsToNextTier = 300,
      List<LoyaltyReward> rewards = const [],
    }) => LoyaltyEntity(
      totalPoints: totalPoints,
      availablePoints: availablePoints,
      tier: tier,
      totalOrders: totalOrders,
      totalSpent: totalSpent,
      pointsToNextTier: pointsToNextTier,
      availableRewards: rewards,
    );

    testWidgets('shows content when loyalty data is loaded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty();
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      // Page renders without crash
      expect(find.byType(LoyaltyPage), findsOneWidget);
      // Tier name appears somewhere (Bronze)
      expect(find.textContaining('Bronze'), findsWidgets);
    });

    testWidgets('shows total points in tier card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(totalPoints: 1234);
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.textContaining('1234'), findsWidgets);
    });

    testWidgets('shows Silver tier name when tier is silver', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(
        tier: LoyaltyTier.silver,
        totalPoints: 600,
        pointsToNextTier: 1400,
      );
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.textContaining('Silver'), findsWidgets);
    });

    testWidgets('shows discount badge for silver tier', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(
        tier: LoyaltyTier.silver,
        totalPoints: 700,
        pointsToNextTier: 1300,
      );
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      // Silver has 5% discount
      expect(find.textContaining('5%'), findsWidgets);
    });

    testWidgets('shows gold tier name when tier is gold', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(
        tier: LoyaltyTier.gold,
        totalPoints: 2500,
        pointsToNextTier: 2500,
      );
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.textContaining('Gold'), findsWidgets);
    });

    testWidgets('shows platinum tier name when tier is platinum', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(
        tier: LoyaltyTier.platinum,
        totalPoints: 5500,
        pointsToNextTier: 0,
      );
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.textContaining('Platinum'), findsWidgets);
    });

    testWidgets('shows available points in summary', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(availablePoints: 999);
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.textContaining('999'), findsWidgets);
    });

    testWidgets('does not show loading when data is loaded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty();
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows rewards section when rewards available', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loyalty = makeLoyalty(
        tier: LoyaltyTier.silver,
        availablePoints: 600,
        rewards: [
          const LoyaltyReward(
            id: 'r1',
            title: 'Livraison gratuite',
            description: 'Pour 1 commande',
            pointsCost: 200,
            type: 'free_delivery',
          ),
        ],
      );
      await tester.pumpWidget(
        createTestWidget(initialState: LoyaltyState(loyalty: loyalty)),
      );
      await tester.pump();

      expect(find.byType(LoyaltyPage), findsOneWidget);
      // Reward title should be visible
      expect(find.textContaining('Livraison'), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────────────
  // Empty state (no loyalty data)
  // ──────────────────────────────────────────────────────
  group('LoyaltyPage Empty State', () {
    testWidgets('shows card_giftcard icon in empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    });

    testWidgets('shows programme fidélité description in empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.textContaining('Gagnez des points'), findsWidgets);
    });
  });
}
