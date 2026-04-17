import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/advanced_battery_service.dart';
import 'package:courier/presentation/widgets/battery/advanced_battery_widgets.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  AdvancedBatteryState makeState({
    int level = 75,
    bool isCharging = false,
    BatteryUsageStats? stats,
    List<int> levelHistory = const [],
  }) {
    return AdvancedBatteryState(
      level: level,
      isCharging: isCharging,
      activeProfile: PowerProfile.balanced,
      lastUpdated: DateTime.now(),
      stats: stats,
      levelHistory: levelHistory,
    );
  }

  BatteryUsageStats makeStats({
    Map<String, double> usageByFeature = const {
      'GPS': 35,
      'Réseau': 25,
      'Écran': 30,
      'Autre': 10,
    },
  }) {
    return BatteryUsageStats(
      averageDrainPerHour: 8.5,
      estimatedMinutesRemaining: 90,
      usageByFeature: usageByFeature,
      lastFullCharge: DateTime.now().subtract(const Duration(hours: 3)),
      cyclesSinceCharge: 2,
    );
  }

  Widget buildWidget({required Stream<AdvancedBatteryState> stream}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        advancedBatteryStateProvider.overrideWith((_) => stream),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AdvancedBatteryWidget()),
        ),
      ),
    );
  }

  group('AdvancedBatteryWidget - supplemental coverage', () {
    testWidgets('renders error widget when stream emits error', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          stream: Stream.error(
            Exception('Battery read error'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Impossible de lire la batterie'), findsOneWidget);
    });

    testWidgets('shows remaining time text when stats is non-null', (
      tester,
    ) async {
      final state = makeState(stats: makeStats());

      await tester.pumpWidget(buildWidget(stream: Stream.value(state)));
      await tester.pumpAndSettle();

      // Remaining time formatted from 90 minutes: "1h 30min" or "1h30 min"
      expect(find.textContaining('Reste environ'), findsOneWidget);
    });

    testWidgets('renders _UsageBreakdown when stats has usageByFeature', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stats = makeStats();
      final state = makeState(stats: stats);

      await tester.pumpWidget(buildWidget(stream: Stream.value(state)));
      await tester.pumpAndSettle();

      expect(find.text('Utilisation par fonctionnalité'), findsOneWidget);
      // Each feature key appears in the legend
      expect(find.textContaining('GPS'), findsWidgets);
    });

    testWidgets('charging state: shows bolt icon when isCharging = true', (
      tester,
    ) async {
      final state = makeState(isCharging: true, level: 50);

      await tester.pumpWidget(buildWidget(stream: Stream.value(state)));
      // Use pump with duration instead of pumpAndSettle to avoid timeout
      // from the infinite charging animation (AnimationController.repeat)
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('didUpdateWidget: start charging triggers animation update', (
      tester,
    ) async {
      final controller = StreamController<AdvancedBatteryState>();

      await tester.pumpWidget(buildWidget(stream: controller.stream));

      // First emit: not charging
      controller.add(makeState(isCharging: false, level: 60));
      await tester.pump(const Duration(milliseconds: 100));

      // Second emit: now charging — triggers didUpdateWidget with isCharging change
      // Use pump(duration) since charging starts infinite animation
      controller.add(makeState(isCharging: true, level: 60));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.bolt), findsOneWidget);

      await controller.close();
    });

    testWidgets('didUpdateWidget: stop charging triggers animation stop', (
      tester,
    ) async {
      final controller = StreamController<AdvancedBatteryState>();

      await tester.pumpWidget(buildWidget(stream: controller.stream));

      // First: charging — pump finite duration to avoid pumpAndSettle timeout
      controller.add(makeState(isCharging: true, level: 70));
      await tester.pump(const Duration(milliseconds: 300));

      // Second: not charging — triggers the else branch in didUpdateWidget,
      // which calls _controller.stop() + _controller.value = 0
      controller.add(makeState(isCharging: false, level: 69));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // animation stopped, safe now

      // bolt icon no longer shown when not charging
      expect(find.byIcon(Icons.bolt), findsNothing);

      await controller.close();
    });

    testWidgets('renders AdvancedBatteryWidget without showGraph', (
      tester,
    ) async {
      final state = makeState(levelHistory: [80, 78, 75], level: 75);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (_) => Stream.value(state),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdvancedBatteryWidget(showGraph: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdvancedBatteryWidget), findsOneWidget);
    });

    testWidgets('renders AdvancedBatteryWidget without showProfile', (
      tester,
    ) async {
      final state = makeState(level: 80);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (_) => Stream.value(state),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdvancedBatteryWidget(showProfile: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdvancedBatteryWidget), findsOneWidget);
    });
  });
}
