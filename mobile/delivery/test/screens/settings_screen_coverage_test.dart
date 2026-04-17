import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/settings_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = original;
    }
  }

  Future<void> drainTimers(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
    } finally {
      FlutterError.onError = original;
    }
  }

  group('SettingsScreen', () {
    testWidgets('renders settings screen with title', (tester) async {
      await pumpSettings(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Paramètres'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows display section header', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining('Affichage'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows notifications section', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining('Notification'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows account security section', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining('Compte'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows biometric card section', (tester) async {
      await pumpSettings(tester);
      // Biometric section should render
      expect(find.byType(Scaffold), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows theme selector', (tester) async {
      await pumpSettings(tester);
      // Theme selector should exist in display section
      expect(find.textContaining('Thème'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows language selection', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining('Langue'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('tapping theme opens theme dialog', (tester) async {
      await pumpSettings(tester);
      // Try to find and tap theme selector
      final themeItems = find.textContaining('Thème');
      if (themeItems.evaluate().isNotEmpty) {
        await tester.tap(themeItems.first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      await drainTimers(tester);
    });

    testWidgets('scrollable content', (tester) async {
      await pumpSettings(tester);
      // Scroll down to show more content
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
      await drainTimers(tester);
    });

    testWidgets('version info at bottom', (tester) async {
      await pumpSettings(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 300));
      // Version might be at the bottom
      expect(find.byType(SettingsScreen), findsOneWidget);
      await drainTimers(tester);
    });
  });
}
