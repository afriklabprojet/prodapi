import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/battery/battery_indicator_widget.dart';
import 'package:courier/core/services/battery_saver_service.dart';
import 'package:courier/core/theme/theme_provider.dart';
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

  Widget buildWidget({
    BatteryStatus? batteryData,
    bool hasError = false,
    bool isLoading = false,
    bool compact = false,
  }) {
    return ProviderScope(
      overrides: [
        isDarkModeProvider.overrideWithValue(false),
        batteryStateProvider.overrideWith((ref) {
          if (hasError) return Stream.error(Exception('No battery'));
          if (isLoading) return const Stream<BatteryStatus>.empty();
          return Stream.value(batteryData!);
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: BatteryIndicatorWidget(compact: compact)),
      ),
    );
  }

  group('BatteryIndicatorWidget - saver mode', () {
    testWidgets('non-compact saver mode shows eco message', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final saverState = BatteryStatus(
        level: 18,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: saverState, compact: false),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Mode économie'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('non-compact critical mode shows critical eco message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final criticalState = BatteryStatus(
        level: 8,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: criticalState, compact: false),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Mode économie critique'), findsOneWidget);
    });

    testWidgets('compact saver mode shows eco icon', (tester) async {
      final saverState = BatteryStatus(
        level: 18,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: saverState, compact: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
    });

    testWidgets('compact critical mode shows eco icon and alert', (
      tester,
    ) async {
      final criticalState = BatteryStatus(
        level: 5,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: criticalState, compact: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.byIcon(Icons.battery_alert), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
    });
  });

  group('BatteryIndicatorWidget - charging state', () {
    testWidgets('compact charging shows charging icon', (tester) async {
      final chargingState = BatteryStatus(
        level: 60,
        mode: BatterySaverMode.charging,
        isCharging: true,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: chargingState, compact: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.battery_charging_full), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('non-compact charging shows En charge text', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final chargingState = BatteryStatus(
        level: 60,
        mode: BatterySaverMode.charging,
        isCharging: true,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: chargingState, compact: false),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('En charge'), findsWidgets);
    });
  });

  group('BatteryIndicatorWidget - normal state', () {
    testWidgets('compact normal shows full battery', (tester) async {
      final normalState = BatteryStatus(
        level: 85,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: normalState, compact: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.battery_full), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('non-compact normal shows percentage and GPS interval', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalState = BatteryStatus(
        level: 85,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: normalState, compact: false),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('85%'), findsWidgets);
      expect(find.text('5s'), findsOneWidget); // GPS interval for normal
    });

    testWidgets('compact mid-range battery shows 3 bar icon', (tester) async {
      final midState = BatteryStatus(
        level: 40,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      await tester.pumpWidget(
        buildWidget(batteryData: midState, compact: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.battery_3_bar), findsOneWidget);
    });
  });

  group('BatteryIndicatorWidget - loading state', () {
    testWidgets('compact loading shows small progress indicator', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(isLoading: true, compact: true));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('non-compact loading shows LoadingCard', (tester) async {
      await tester.pumpWidget(buildWidget(isLoading: true, compact: false));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Chargement...'), findsOneWidget);
    });
  });
}
