import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/delivery_alert_service.dart';
import 'package:courier/presentation/screens/battery_optimization_screen.dart';
import 'package:courier/core/services/advanced_battery_service.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('DeliveryAlertActiveNotifier', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(deliveryAlertActiveProvider), false);
    });

    test('activate sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('deactivate sets state to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).activate();
      container.read(deliveryAlertActiveProvider.notifier).deactivate();
      expect(container.read(deliveryAlertActiveProvider), false);
    });

    test('multiple activations keep true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(deliveryAlertActiveProvider.notifier);
      notifier.activate();
      notifier.activate();
      expect(container.read(deliveryAlertActiveProvider), true);
    });

    test('deactivate while already false stays false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(deliveryAlertActiveProvider.notifier).deactivate();
      expect(container.read(deliveryAlertActiveProvider), false);
    });
  });

  group('BatteryOptimizationScreen', () {
    setUpAll(() => initHiveForTests());
    tearDownAll(() => cleanupHiveForTests());

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildWithState(AdvancedBatteryState state, {ThemeData? theme}) {
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          advancedBatteryStateProvider.overrideWith(
            (ref) => Stream.value(state),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: const BatteryOptimizationScreen(),
        ),
      );
    }

    final testBatteryState = AdvancedBatteryState(
      level: 75,
      isCharging: false,
      activeProfile: PowerProfile.balanced,
      lastUpdated: DateTime(2024, 1, 15),
      autoOptimizeEnabled: true,
    );

    Future<void> pumpScreen(
      WidgetTester tester,
      AdvancedBatteryState state, {
      ThemeData? theme,
    }) async {
      // Use a very tall viewport so ListView builds ALL children
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWithState(state, theme: theme));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('renders app bar title', (tester) async {
      await pumpScreen(tester, testBatteryState);
      expect(find.text('Économie de batterie'), findsOneWidget);
    });

    testWidgets('renders info section', (tester) async {
      await pumpScreen(tester, testBatteryState);
      expect(find.text('Comment ça marche'), findsOneWidget);
    });

    testWidgets('renders profile descriptions via RichText', (tester) async {
      await pumpScreen(tester, testBatteryState);
      // _InfoItem uses RichText with TextSpan children
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final allText = richTexts.map((rt) => rt.text.toPlainText()).join(' ');
      expect(allText, contains('GPS précis'));
      expect(allText, contains('Bon compromis'));
      expect(allText, contains('Réduit la fréquence'));
      expect(allText, contains('Mode minimal'));
    });

    testWidgets('renders advanced settings section with data', (tester) async {
      await pumpScreen(tester, testBatteryState);
      expect(find.text('Paramètres du profil actuel'), findsOneWidget);
      expect(find.text('Intervalle GPS'), findsOneWidget);
      expect(find.text('Filtre de distance'), findsOneWidget);
      expect(find.text('Précision GPS'), findsOneWidget);
      expect(find.text('Animations'), findsOneWidget);
      expect(find.text('Vibrations'), findsOneWidget);
      expect(find.text('Sync auto'), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await pumpScreen(tester, testBatteryState, theme: ThemeData.dark());
      expect(find.text('Économie de batterie'), findsOneWidget);
      expect(find.text('Paramètres du profil actuel'), findsOneWidget);
    });

    testWidgets('balanced profile shows correct values', (tester) async {
      await pumpScreen(tester, testBatteryState);
      expect(find.text('10 secondes'), findsOneWidget);
      expect(find.text('15 mètres'), findsOneWidget);
      expect(find.text('Haute'), findsOneWidget);
      expect(find.text('Activées'), findsWidgets);
    });

    testWidgets('ultra saver profile shows correct values', (tester) async {
      final ultraState = AdvancedBatteryState(
        level: 10,
        isCharging: false,
        activeProfile: PowerProfile.ultraSaver,
        lastUpdated: DateTime(2024, 1, 15),
      );
      await pumpScreen(tester, ultraState);
      expect(find.text('45 secondes'), findsOneWidget);
      expect(find.text('50 mètres'), findsOneWidget);
      expect(find.text('Basse'), findsOneWidget);
      expect(find.text('Désactivées'), findsWidgets);
      expect(find.text('Désactivée'), findsOneWidget);
    });

    testWidgets('performance profile shows Navigation accuracy', (
      tester,
    ) async {
      final perfState = AdvancedBatteryState(
        level: 90,
        isCharging: true,
        activeProfile: PowerProfile.performance,
        lastUpdated: DateTime(2024, 1, 15),
      );
      await pumpScreen(tester, perfState);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('3 secondes'), findsOneWidget);
      expect(find.text('5 mètres'), findsOneWidget);
    });

    testWidgets('battery saver profile shows Moyenne accuracy', (tester) async {
      final saverState = AdvancedBatteryState(
        level: 40,
        isCharging: false,
        activeProfile: PowerProfile.batterySaver,
        lastUpdated: DateTime(2024, 1, 15),
      );
      await pumpScreen(tester, saverState);
      expect(find.text('Moyenne'), findsOneWidget);
      expect(find.text('20 secondes'), findsOneWidget);
      expect(find.text('30 mètres'), findsOneWidget);
    });

    testWidgets('shows auto optimize tip text', (tester) async {
      await pumpScreen(tester, testBatteryState);
      // The tip text uses Text widget with 'optimisation automatique'
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final allText = richTexts.map((rt) => rt.text.toPlainText()).join(' ');
      expect(allText, contains('optimisation automatique'));
    });
  });
}
