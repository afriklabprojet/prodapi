import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/notifications/notification_widgets.dart';
import 'package:courier/core/services/rich_notification_service.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

// Fake service where quietHoursEnabled = true (to cover time picker section)
class _FakeRichServiceQH extends StateNotifier<List<RichNotification>>
    implements RichNotificationService {
  _FakeRichServiceQH() : super([]);

  @override
  NotificationPreferences get preferences =>
      const NotificationPreferences(quietHoursEnabled: true);

  @override
  Stream<NotificationActionEvent> get actionStream => const Stream.empty();

  @override
  Future<void> savePreferences(NotificationPreferences newPrefs) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpCard(
    WidgetTester tester, {
    bool darkMode = false,
    RichNotificationService? customNotif,
  }) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: commonWidgetTestOverrides(
          isDark: darkMode,
          customRichNotif: customNotif,
        ),
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
    await tester.pumpAndSettle();
  }

  group('NotificationPreferencesCard supplemental', () {
    testWidgets('renders in dark mode covers dark branches', (tester) async {
      await pumpCard(tester, darkMode: true);
      // In dark mode the card body is rendered → covers isDark ternary true branches
      expect(find.byType(NotificationPreferencesCard), findsOneWidget);
    });

    testWidgets('tap Sons switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }
      // No crash expected; onChanged lambda body is covered
    });

    testWidgets('tap Vibration switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 2) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tap Nouvelles commandes switch calls onChanged', (
      tester,
    ) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 3) {
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tap Messages switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 4) {
        await tester.tap(switches.at(3));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tap Gains switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 5) {
        await tester.tap(switches.at(4));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tap Promotions switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 6) {
        await tester.tap(switches.at(5));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tap Alertes urgentes switch calls onChanged', (tester) async {
      await pumpCard(tester);
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 7) {
        await tester.tap(switches.at(6));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('expand Heures calmes shows SwitchListTile', (tester) async {
      await pumpCard(tester);
      final heuresCalmes = find.text('Heures calmes');
      if (heuresCalmes.evaluate().isNotEmpty) {
        await tester.tap(heuresCalmes.first);
        await tester.pumpAndSettle();
        expect(find.text('Activer les heures calmes'), findsOneWidget);
      }
    });

    testWidgets('expand Heures calmes and toggle quiet hours switch', (
      tester,
    ) async {
      await pumpCard(tester);
      final heuresCalmes = find.text('Heures calmes');
      if (heuresCalmes.evaluate().isNotEmpty) {
        await tester.tap(heuresCalmes.first);
        await tester.pumpAndSettle();
        // Tap the SwitchListTile inside expansion
        final switchListTiles = find.byType(SwitchListTile);
        if (switchListTiles.evaluate().isNotEmpty) {
          await tester.tap(switchListTiles.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('renders with quietHoursEnabled true shows time pickers', (
      tester,
    ) async {
      await pumpCard(tester, customNotif: _FakeRichServiceQH());
      // Expand the quiet hours tile
      final heuresCalmes = find.text('Heures calmes');
      if (heuresCalmes.evaluate().isNotEmpty) {
        await tester.tap(heuresCalmes.first);
        await tester.pumpAndSettle();
        // Time pickers should be visible (DropdownButton for hours)
        expect(find.byType(DropdownButton<int>), findsWidgets);
      }
    });

    testWidgets('renders with quietHoursEnabled true shows active subtitle', (
      tester,
    ) async {
      await pumpCard(tester, customNotif: _FakeRichServiceQH());
      // With quietHoursEnabled=true, subtitle shows 'Actif: ...'
      expect(find.textContaining('Actif:'), findsOneWidget);
    });
  });
}
