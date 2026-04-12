import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/settings/home_widget_settings_screen.dart';
import 'package:courier/core/services/advanced_home_widget_service.dart';
import '../../helpers/widget_test_helpers.dart';

/// A notifier subclass that builds with a custom initial state
class _FixedHomeWidgetNotifier extends AdvancedHomeWidgetService {
  final HomeWidgetState _initial;
  _FixedHomeWidgetNotifier(this._initial);

  @override
  HomeWidgetState build() => _initial;
}

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

  Widget buildScreen(HomeWidgetState initialState) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        advancedHomeWidgetProvider.overrideWith(
          () => _FixedHomeWidgetNotifier(initialState),
        ),
      ],
      child: const MaterialApp(home: HomeWidgetSettingsScreen()),
    );
  }

  group('HomeWidgetSettingsScreen - online with deliveries', () {
    testWidgets('shows online badge in preview', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: true,
        courierName: 'Mohamed',
        todayDeliveries: 3,
        todayEarnings: 15000,
        dailyGoal: 5,
        style: WidgetStyle.standard,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('En ligne'), findsOneWidget);
    });

    testWidgets('shows delivery stats in standard mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: true,
        todayDeliveries: 7,
        todayEarnings: 35000,
        dailyGoal: 10,
        style: WidgetStyle.standard,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Livraisons'), findsOneWidget);
      expect(find.text('FCFA'), findsOneWidget);
    });

    testWidgets('shows active delivery section', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: true,
        hasActiveDelivery: true,
        deliveryStep: WidgetDeliveryStep.toCustomer,
        customerAddress: '456 Rue du Client',
        estimatedTime: '10 min',
        todayDeliveries: 4,
        todayEarnings: 20000,
        dailyGoal: 5,
        style: WidgetStyle.standard,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('456 Rue du Client'), findsOneWidget);
    });
  });

  group('HomeWidgetSettingsScreen - detailed style', () {
    testWidgets('shows goal progress in detailed style', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: true,
        todayDeliveries: 4,
        dailyGoal: 5,
        style: WidgetStyle.detailed,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Objectif'), findsWidgets);
    });

    testWidgets('shows 80% progress text in detailed', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: true,
        todayDeliveries: 4,
        dailyGoal: 5,
        style: WidgetStyle.detailed,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('80%'), findsOneWidget);
    });
  });

  group('HomeWidgetSettingsScreen - compact style', () {
    testWidgets('compact style shows no stats section', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(
        isOnline: false,
        style: WidgetStyle.compact,
        showEarnings: true,
      );

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hors ligne'), findsOneWidget);
      // Compact does not show delivery stats
      expect(find.text('Livraisons'), findsNothing);
    });
  });

  group('HomeWidgetSettingsScreen - daily goal section', () {
    testWidgets('shows daily goal slider', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState(dailyGoal: 8);

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byType(Slider),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('8'), findsWidgets);
    });

    testWidgets('shows add widget instructions section', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState();

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Ajouter le Widget'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Ajouter le Widget'), findsOneWidget);
    });

    testWidgets('tap refresh shows snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = const HomeWidgetState();

      await tester.pumpWidget(buildScreen(state));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Widget actualisé'), findsOneWidget);
    });
  });
}
