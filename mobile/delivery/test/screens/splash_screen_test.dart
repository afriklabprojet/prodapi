import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:courier/presentation/screens/splash_screen.dart';
import 'package:courier/core/services/app_startup_service.dart';
import '../helpers/widget_test_helpers.dart';

class MockAppStartupService extends Mock implements AppStartupService {}

void main() {
  late MockAppStartupService mockStartup;

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStartup = MockAppStartupService();
    when(
      () => mockStartup.initialize(),
    ).thenAnswer((_) async => StartupResult.unauthenticated);
    when(() => mockStartup.warmUpSecureServices()).thenReturn(null);
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const Scaffold(body: Text('Onboarding')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
  }

  Future<void> pumpSplash(
    WidgetTester tester,
    GoRouter router,
    MockAppStartupService mockStartup,
  ) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            appStartupProvider.overrideWithValue(mockStartup),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('SplashScreen', () {
    testWidgets('renders splash screen', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('contains Scaffold', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('navigates to login when unauthenticated', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      // After startup resolves to unauthenticated, should navigate to login
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('calls initialize on startup service', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      verify(() => mockStartup.initialize()).called(1);
    });

    testWidgets('navigates to onboarding when result is onboarding', (
      tester,
    ) async {
      when(
        () => mockStartup.initialize(),
      ).thenAnswer((_) async => StartupResult.onboarding);
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('navigates to dashboard when authenticated', (tester) async {
      when(
        () => mockStartup.initialize(),
      ).thenAnswer((_) async => StartupResult.authenticated);
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('calls warmUpSecureServices', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      verify(() => mockStartup.warmUpSecureServices()).called(1);
    });

    testWidgets('renders ProviderScope', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpSplash(tester, router, mockStartup);
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
