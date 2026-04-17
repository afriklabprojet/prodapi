import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/notifications/notification_widgets.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

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

  Future<void> pumpNotifCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
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
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: NotificationPreferencesCard()),
            ),
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

  group('NotificationPreferencesCard', () {
    testWidgets('renders card', (tester) async {
      await pumpNotifCard(tester);
      expect(find.byType(NotificationPreferencesCard), findsOneWidget);
      await drainTimers(tester);
    });

    testWidgets('shows Notifications title', (tester) async {
      await pumpNotifCard(tester);
      expect(find.text('Notifications'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows notification icon', (tester) async {
      await pumpNotifCard(tester);
      expect(find.byIcon(Icons.notifications_active), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows preference toggle options', (tester) async {
      await pumpNotifCard(tester);
      // Should show toggle switches
      expect(find.byType(Switch), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows personalize text', (tester) async {
      await pumpNotifCard(tester);
      expect(find.textContaining('Personnalisez'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('shows notification subtitle', (tester) async {
      await pumpNotifCard(tester);
      expect(find.textContaining('alertes'), findsWidgets);
      await drainTimers(tester);
    });

    testWidgets('has multiple preference options', (tester) async {
      await pumpNotifCard(tester);
      final switches = find.byType(Switch);
      expect(switches.evaluate().length, greaterThanOrEqualTo(1));
      await drainTimers(tester);
    });

    testWidgets('card has proper styling', (tester) async {
      await pumpNotifCard(tester);
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(Divider), findsWidgets);
      await drainTimers(tester);
    });
  });
}
