import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/main_shell_page.dart';
import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_state.dart';
import 'package:drpharma_client/features/orders/presentation/providers/cart_notifier.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_notifier.dart';
import 'package:drpharma_client/features/pharmacies/presentation/providers/pharmacies_state.dart';
import 'package:drpharma_client/features/treatments/data/services/smart_refill_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/fake_api_client.dart';

class MockAuthNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState.initial());
}

class MockCartNotifier extends StateNotifier<CartState>
    with Mock
    implements CartNotifier {
  MockCartNotifier() : super(CartState.initial());
}

class MockPharmaciesNotifier extends StateNotifier<PharmaciesState>
    with Mock
    implements PharmaciesNotifier {
  MockPharmaciesNotifier() : super(const PharmaciesState());

  @override
  Future<void> fetchFeaturedPharmacies({bool isRetry = false}) async {}

  @override
  Future<void> fetchPharmacies({bool refresh = false}) async {}

  @override
  Future<void> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {}

  @override
  Future<void> fetchOnDutyPharmacies({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {}

  @override
  Future<void> fetchPharmacyDetails(int id) async {}
}

class MockSmartRefillNotifier extends StateNotifier<SmartRefillState>
    implements SmartRefillNotifier {
  MockSmartRefillNotifier() : super(const SmartRefillState());

  @override
  Future<void> checkRefills() async {}

  @override
  Future<void> dismissSuggestion(String treatmentId) async {}

  @override
  Future<void> markAsOrdered(String treatmentId) async {}
}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  late SharedPreferences sharedPreferences;
  late MockPharmaciesNotifier mockPharmaciesNotifier;

  setUpAll(() {
    registerFallbackValue(FakeAuthState());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    mockPharmaciesNotifier = MockPharmaciesNotifier();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        authProvider.overrideWith((_) => MockAuthNotifier()),
        cartProvider.overrideWith((_) => MockCartNotifier()),
        pharmaciesProvider.overrideWith((_) => mockPharmaciesNotifier),
        smartRefillProvider.overrideWith((_) => MockSmartRefillNotifier()),
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
        home: const MainShellPage(),
      ),
    );
  }

  group('MainShellPage Widget Tests', () {
    testWidgets('should render main shell page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(MainShellPage), findsOneWidget);
    });

    testWidgets('should have bottom navigation bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('should show 4 navigation destinations', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('should show Accueil navigation label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Accueil'), findsWidgets);
    });

    testWidgets('should show Commandes navigation label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Commandes'), findsWidgets);
    });

    testWidgets('should show Portefeuille navigation label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Portefeuille'), findsWidgets);
    });

    testWidgets('should show Mon Profil navigation label', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Mon Profil'), findsWidgets);
    });

    testWidgets('should start on first tab (Accueil)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      // First tab is active - verify NavigationBar exists with correct state
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(0));
    });
  });
}
