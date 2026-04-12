import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/advanced_battery_service.dart';
import 'package:courier/presentation/widgets/battery/advanced_battery_widgets.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AdvancedBatteryState', () {
    test('constructor sets defaults', () {
      final state = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.level, 80);
      expect(state.isCharging, false);
      expect(state.autoOptimizeEnabled, true);
      expect(state.stats, isNull);
      expect(state.levelHistory, isEmpty);
    });

    test('isCritical returns true when level <= 10 and not charging', () {
      final state = AdvancedBatteryState(
        level: 8,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isCritical, true);
    });

    test('isCritical returns false when charging', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: true,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isCritical, false);
    });

    test('isLow returns true when level <= 20 and not charging', () {
      final state = AdvancedBatteryState(
        level: 15,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isLow, true);
    });

    test('levelColorValue returns red when critical', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFFF44336);
    });

    test('levelColorValue returns green when charging', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: true,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFF4CAF50);
    });

    test('levelColorValue returns green when level > 50', () {
      final state = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFF4CAF50);
    });

    test('copyWith updates fields', () {
      final state = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      final updated = state.copyWith(level: 50, isCharging: true);
      expect(updated.level, 50);
      expect(updated.isCharging, true);
      expect(updated.activeProfile.id, 'balanced');
    });
  });

  group('PowerProfile', () {
    test('performance has correct id', () {
      expect(PowerProfile.performance.id, 'performance');
    });

    test('balanced has correct id', () {
      expect(PowerProfile.balanced.id, 'balanced');
    });

    test('batterySaver has correct id', () {
      expect(PowerProfile.batterySaver.id, 'battery_saver');
    });

    test('ultraSaver has correct id', () {
      expect(PowerProfile.ultraSaver.id, 'ultra_saver');
    });

    test('all returns 4 profiles', () {
      expect(PowerProfile.all.length, 4);
    });

    test('findById returns correct profile', () {
      expect(PowerProfile.findById('balanced')?.id, 'balanced');
    });

    test('findById returns null for unknown id', () {
      expect(PowerProfile.findById('unknown'), isNull);
    });
  });

  group('BatteryUsageStats', () {
    test('remainingTimeFormatted shows minutes when < 60', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 10,
        estimatedMinutesRemaining: 45,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '45 min');
    });

    test('remainingTimeFormatted shows hours when >= 60', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5,
        estimatedMinutesRemaining: 150,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '2h 30min');
    });

    test('remainingTimeFormatted shows hours only when even', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5,
        estimatedMinutesRemaining: 120,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '2h');
    });
  });

  group('OptimizationTip', () {
    test('constructor sets values', () {
      final tip = OptimizationTip(
        id: 'tip-1',
        title: 'Save battery',
        description: 'Reduce GPS',
        icon: '🔋',
        estimatedSavingsPercent: 20,
      );
      expect(tip.id, 'tip-1');
      expect(tip.isApplied, false);
    });
  });

  group('AdvancedBatteryWidget', () {
    testWidgets('renders loading state when provider is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream<AdvancedBatteryState>.empty(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdvancedBatteryWidget()),
          ),
        ),
      );
      await tester.pump();
      // Should show loading or the widget without error
      expect(find.byType(AdvancedBatteryWidget), findsOneWidget);
    });

    testWidgets('renders data state with battery info', (tester) async {
      final fakeState = AdvancedBatteryState(
        level: 75,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
        levelHistory: [80, 78, 76, 75],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream.value(fakeState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: AdvancedBatteryWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('75'), findsWidgets);
    });
  });

  group('CompactBatteryIndicator', () {
    testWidgets('renders without error', (tester) async {
      final fakeState = AdvancedBatteryState(
        level: 60,
        isCharging: true,
        activeProfile: PowerProfile.performance,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream.value(fakeState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CompactBatteryIndicator()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CompactBatteryIndicator), findsOneWidget);
    });
  });

  group('PowerProfileSelector', () {
    testWidgets('renders without error', (tester) async {
      final fakeState = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream.value(fakeState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PowerProfileSelector()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PowerProfileSelector), findsOneWidget);
    });
  });

  group('AutoOptimizeSwitch', () {
    testWidgets('renders without error', (tester) async {
      final fakeState = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        autoOptimizeEnabled: true,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream.value(fakeState),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: AutoOptimizeSwitch())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AutoOptimizeSwitch), findsOneWidget);
    });
  });

  group('OptimizationTipsList', () {
    testWidgets('renders without error', (tester) async {
      final fakeState = AdvancedBatteryState(
        level: 25,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            advancedBatteryStateProvider.overrideWith(
              (ref) => Stream.value(fakeState),
            ),
            optimizationTipsProvider.overrideWith(
              (ref) => [
                OptimizationTip(
                  id: 'tip-1',
                  title: 'Activer le mode économie',
                  description: 'Réduisez la fréquence GPS',
                  icon: '🔋',
                  estimatedSavingsPercent: 20,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: OptimizationTipsList()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OptimizationTipsList), findsOneWidget);
    });
  });
}
