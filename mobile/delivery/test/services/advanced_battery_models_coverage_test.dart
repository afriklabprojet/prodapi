import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:courier/core/services/advanced_battery_service.dart';

void main() {
  group('PowerProfile', () {
    test('performance has correct id and name', () {
      expect(PowerProfile.performance.id, 'performance');
      expect(PowerProfile.performance.name, 'Performance');
      expect(PowerProfile.performance.gpsIntervalSeconds, 3);
      expect(PowerProfile.performance.distanceFilterMeters, 5);
      expect(
        PowerProfile.performance.accuracy,
        LocationAccuracy.bestForNavigation,
      );
      expect(PowerProfile.performance.enableAnimations, true);
      expect(PowerProfile.performance.enableVibration, true);
      expect(PowerProfile.performance.enableAutoSync, true);
      expect(PowerProfile.performance.syncIntervalMinutes, 2);
      expect(PowerProfile.performance.brightnessMultiplier, 1.0);
    });

    test('balanced has correct id and name', () {
      expect(PowerProfile.balanced.id, 'balanced');
      expect(PowerProfile.balanced.name, 'Équilibré');
      expect(PowerProfile.balanced.gpsIntervalSeconds, 10);
      expect(PowerProfile.balanced.accuracy, LocationAccuracy.high);
      expect(PowerProfile.balanced.brightnessMultiplier, 0.9);
    });

    test('batterySaver has correct id and name', () {
      expect(PowerProfile.batterySaver.id, 'battery_saver');
      expect(PowerProfile.batterySaver.name, 'Économie');
      expect(PowerProfile.batterySaver.gpsIntervalSeconds, 20);
      expect(PowerProfile.batterySaver.accuracy, LocationAccuracy.medium);
      expect(PowerProfile.batterySaver.enableAnimations, false);
      expect(PowerProfile.batterySaver.enableVibration, false);
    });

    test('ultraSaver has correct id and name', () {
      expect(PowerProfile.ultraSaver.id, 'ultra_saver');
      expect(PowerProfile.ultraSaver.name, 'Ultra économie');
      expect(PowerProfile.ultraSaver.gpsIntervalSeconds, 45);
      expect(PowerProfile.ultraSaver.accuracy, LocationAccuracy.low);
      expect(PowerProfile.ultraSaver.enableAutoSync, false);
      expect(PowerProfile.ultraSaver.brightnessMultiplier, 0.5);
    });

    test('all returns 4 profiles', () {
      expect(PowerProfile.all.length, 4);
      expect(PowerProfile.all[0].id, 'performance');
      expect(PowerProfile.all[1].id, 'balanced');
      expect(PowerProfile.all[2].id, 'battery_saver');
      expect(PowerProfile.all[3].id, 'ultra_saver');
    });

    test('findById returns correct profile', () {
      expect(PowerProfile.findById('performance')?.id, 'performance');
      expect(PowerProfile.findById('balanced')?.name, 'Équilibré');
      expect(PowerProfile.findById('battery_saver')?.id, 'battery_saver');
      expect(PowerProfile.findById('ultra_saver')?.id, 'ultra_saver');
    });

    test('findById returns null for unknown id', () {
      expect(PowerProfile.findById('unknown'), isNull);
      expect(PowerProfile.findById(''), isNull);
    });
  });

  group('BatteryUsageStats', () {
    test('remainingTimeFormatted for minutes < 60', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 45,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.remainingTimeFormatted, '45 min');
    });

    test('remainingTimeFormatted for exactly 60 min', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 60,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.remainingTimeFormatted, '1h');
    });

    test('remainingTimeFormatted for hours and minutes', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 3.0,
        estimatedMinutesRemaining: 150,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.remainingTimeFormatted, '2h 30min');
    });

    test('remainingTimeFormatted for exact hours', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 4.0,
        estimatedMinutesRemaining: 120,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.remainingTimeFormatted, '2h');
    });

    test('usageByFeature defaults to empty', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 30,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.usageByFeature, isEmpty);
    });

    test('cyclesSinceCharge defaults to 0', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 30,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      expect(stats.cyclesSinceCharge, 0);
    });

    test('constructor with all fields', () {
      final now = DateTime.now();
      final stats = BatteryUsageStats(
        averageDrainPerHour: 7.5,
        estimatedMinutesRemaining: 90,
        usageByFeature: {'GPS': 40.0, 'Screen': 30.0},
        lastFullCharge: now,
        cyclesSinceCharge: 3,
      );
      expect(stats.averageDrainPerHour, 7.5);
      expect(stats.estimatedMinutesRemaining, 90);
      expect(stats.usageByFeature, {'GPS': 40.0, 'Screen': 30.0});
      expect(stats.lastFullCharge, now);
      expect(stats.cyclesSinceCharge, 3);
    });
  });

  group('AdvancedBatteryState', () {
    AdvancedBatteryState makeState({
      int level = 75,
      bool isCharging = false,
      PowerProfile? profile,
    }) {
      return AdvancedBatteryState(
        level: level,
        isCharging: isCharging,
        activeProfile: profile ?? PowerProfile.balanced,
        lastUpdated: DateTime(2024, 1, 1),
      );
    }

    test('isCritical when level <= 10 and not charging', () {
      expect(makeState(level: 10).isCritical, true);
      expect(makeState(level: 5).isCritical, true);
    });

    test('isCritical false when level > 10', () {
      expect(makeState(level: 11).isCritical, false);
      expect(makeState(level: 50).isCritical, false);
    });

    test('isCritical false when charging even at low level', () {
      expect(makeState(level: 5, isCharging: true).isCritical, false);
    });

    test('isLow when level <= 20 and not charging', () {
      expect(makeState(level: 20).isLow, true);
      expect(makeState(level: 15).isLow, true);
    });

    test('isLow false when level > 20', () {
      expect(makeState(level: 21).isLow, false);
    });

    test('isLow false when charging', () {
      expect(makeState(level: 15, isCharging: true).isLow, false);
    });

    test('levelColorValue green when charging', () {
      expect(makeState(level: 5, isCharging: true).levelColorValue, 0xFF4CAF50);
    });

    test('levelColorValue red when <= 10', () {
      expect(makeState(level: 10).levelColorValue, 0xFFF44336);
      expect(makeState(level: 5).levelColorValue, 0xFFF44336);
    });

    test('levelColorValue orange when <= 20', () {
      expect(makeState(level: 20).levelColorValue, 0xFFFF9800);
      expect(makeState(level: 15).levelColorValue, 0xFFFF9800);
    });

    test('levelColorValue yellow when <= 50', () {
      expect(makeState(level: 50).levelColorValue, 0xFFFFEB3B);
      expect(makeState(level: 30).levelColorValue, 0xFFFFEB3B);
    });

    test('levelColorValue green when > 50', () {
      expect(makeState(level: 51).levelColorValue, 0xFF4CAF50);
      expect(makeState(level: 100).levelColorValue, 0xFF4CAF50);
    });

    test('copyWith preserves values when no args', () {
      final state = makeState(level: 60, isCharging: true);
      final copy = state.copyWith();
      expect(copy.level, 60);
      expect(copy.isCharging, true);
      expect(copy.activeProfile.id, 'balanced');
    });

    test('copyWith updates specified fields', () {
      final state = makeState(level: 60);
      final copy = state.copyWith(
        level: 30,
        isCharging: true,
        activeProfile: PowerProfile.ultraSaver,
        autoOptimizeEnabled: false,
        levelHistory: [80, 70, 60],
      );
      expect(copy.level, 30);
      expect(copy.isCharging, true);
      expect(copy.activeProfile.id, 'ultra_saver');
      expect(copy.autoOptimizeEnabled, false);
      expect(copy.levelHistory, [80, 70, 60]);
    });

    test('autoOptimizeEnabled defaults to true', () {
      expect(makeState().autoOptimizeEnabled, true);
    });

    test('stats defaults to null', () {
      expect(makeState().stats, isNull);
    });

    test('levelHistory defaults to empty', () {
      expect(makeState().levelHistory, isEmpty);
    });

    test('constructor with stats', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 120,
        lastFullCharge: DateTime(2024, 1, 1),
      );
      final state = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.performance,
        stats: stats,
        lastUpdated: DateTime(2024, 1, 1),
      );
      expect(state.stats, isNotNull);
      expect(state.stats!.estimatedMinutesRemaining, 120);
    });
  });
}
