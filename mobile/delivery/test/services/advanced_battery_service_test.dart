import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:courier/core/services/advanced_battery_service.dart';

void main() {
  group('AdvancedBatteryService', () {
    group('PowerProfile', () {
      test('performance profile has correct settings', () {
        final profile = PowerProfile.performance;
        expect(profile.id, 'performance');
        expect(profile.name, 'Performance');
        expect(profile.gpsIntervalSeconds, 3);
        expect(profile.distanceFilterMeters, 5);
        expect(profile.accuracy, LocationAccuracy.bestForNavigation);
        expect(profile.enableAnimations, true);
        expect(profile.enableVibration, true);
        expect(profile.enableAutoSync, true);
        expect(profile.syncIntervalMinutes, 2);
        expect(profile.brightnessMultiplier, 1.0);
      });

      test('balanced profile has correct settings', () {
        final profile = PowerProfile.balanced;
        expect(profile.id, 'balanced');
        expect(profile.name, 'Équilibré');
        expect(profile.gpsIntervalSeconds, 10);
        expect(profile.distanceFilterMeters, 15);
        expect(profile.accuracy, LocationAccuracy.high);
        expect(profile.enableAnimations, true);
        expect(profile.enableVibration, true);
        expect(profile.enableAutoSync, true);
        expect(profile.syncIntervalMinutes, 5);
        expect(profile.brightnessMultiplier, 0.9);
      });

      test('batterySaver profile has correct settings', () {
        final profile = PowerProfile.batterySaver;
        expect(profile.id, 'battery_saver');
        expect(profile.name, 'Économie');
        expect(profile.gpsIntervalSeconds, 20);
        expect(profile.distanceFilterMeters, 30);
        expect(profile.accuracy, LocationAccuracy.medium);
        expect(profile.enableAnimations, false);
        expect(profile.enableVibration, false);
        expect(profile.enableAutoSync, true);
        expect(profile.syncIntervalMinutes, 10);
        expect(profile.brightnessMultiplier, 0.7);
      });

      test('ultraSaver profile has correct settings', () {
        final profile = PowerProfile.ultraSaver;
        expect(profile.id, 'ultra_saver');
        expect(profile.name, 'Ultra économie');
        expect(profile.gpsIntervalSeconds, 45);
        expect(profile.distanceFilterMeters, 50);
        expect(profile.accuracy, LocationAccuracy.low);
        expect(profile.enableAnimations, false);
        expect(profile.enableVibration, false);
        expect(profile.enableAutoSync, false);
        expect(profile.syncIntervalMinutes, 30);
        expect(profile.brightnessMultiplier, 0.5);
      });

      test('all profiles returns list of 4 profiles', () {
        expect(PowerProfile.all.length, 4);
        expect(PowerProfile.all, contains(PowerProfile.performance));
        expect(PowerProfile.all, contains(PowerProfile.balanced));
        expect(PowerProfile.all, contains(PowerProfile.batterySaver));
        expect(PowerProfile.all, contains(PowerProfile.ultraSaver));
      });

      test('findById returns correct profile', () {
        expect(PowerProfile.findById('performance'), PowerProfile.performance);
        expect(PowerProfile.findById('balanced'), PowerProfile.balanced);
        expect(PowerProfile.findById('battery_saver'), PowerProfile.batterySaver);
        expect(PowerProfile.findById('ultra_saver'), PowerProfile.ultraSaver);
      });

      test('findById returns null for unknown id', () {
        expect(PowerProfile.findById('unknown'), isNull);
        expect(PowerProfile.findById(''), isNull);
      });
    });

    group('BatteryUsageStats', () {
      test('creates with required fields', () {
        final stats = BatteryUsageStats(
          averageDrainPerHour: 10.5,
          estimatedMinutesRemaining: 180,
          lastFullCharge: DateTime(2024, 1, 15, 8, 0),
        );
        
        expect(stats.averageDrainPerHour, 10.5);
        expect(stats.estimatedMinutesRemaining, 180);
        expect(stats.cyclesSinceCharge, 0);
        expect(stats.usageByFeature, isEmpty);
      });

      test('remainingTimeFormatted shows minutes for short duration', () {
        final stats = BatteryUsageStats(
          averageDrainPerHour: 20.0,
          estimatedMinutesRemaining: 45,
          lastFullCharge: DateTime.now(),
        );
        
        expect(stats.remainingTimeFormatted, '45 min');
      });

      test('remainingTimeFormatted shows hours for long duration', () {
        final stats = BatteryUsageStats(
          averageDrainPerHour: 10.0,
          estimatedMinutesRemaining: 180,
          lastFullCharge: DateTime.now(),
        );
        
        expect(stats.remainingTimeFormatted, '3h');
      });

      test('remainingTimeFormatted shows hours and minutes', () {
        final stats = BatteryUsageStats(
          averageDrainPerHour: 10.0,
          estimatedMinutesRemaining: 150,
          lastFullCharge: DateTime.now(),
        );
        
        expect(stats.remainingTimeFormatted, '2h 30min');
      });
    });

    group('AdvancedBatteryState', () {
      test('creates with required fields', () {
        final state = AdvancedBatteryState(
          level: 75,
          isCharging: false,
          activeProfile: PowerProfile.balanced,
          lastUpdated: DateTime(2024, 1, 15),
        );
        
        expect(state.level, 75);
        expect(state.isCharging, false);
        expect(state.activeProfile, PowerProfile.balanced);
        expect(state.autoOptimizeEnabled, true);
        expect(state.stats, isNull);
        expect(state.levelHistory, isEmpty);
      });

      test('copyWith updates specified fields', () {
        final state = AdvancedBatteryState(
          level: 75,
          isCharging: false,
          activeProfile: PowerProfile.balanced,
          lastUpdated: DateTime(2024, 1, 15),
        );
        
        final updated = state.copyWith(
          level: 50,
          isCharging: true,
        );
        
        expect(updated.level, 50);
        expect(updated.isCharging, true);
        expect(updated.activeProfile, PowerProfile.balanced); // unchanged
      });

      test('copyWith preserves unspecified fields', () {
        final state = AdvancedBatteryState(
          level: 75,
          isCharging: false,
          activeProfile: PowerProfile.performance,
          autoOptimizeEnabled: false,
          lastUpdated: DateTime(2024, 1, 15),
          levelHistory: [80, 75, 70],
        );
        
        final updated = state.copyWith(level: 65);
        
        expect(updated.level, 65);
        expect(updated.isCharging, false);
        expect(updated.activeProfile, PowerProfile.performance);
        expect(updated.autoOptimizeEnabled, false);
        expect(updated.levelHistory, [80, 75, 70]);
      });

      test('copyWith can update activeProfile', () {
        final state = AdvancedBatteryState(
          level: 25,
          isCharging: false,
          activeProfile: PowerProfile.balanced,
          lastUpdated: DateTime.now(),
        );
        
        final updated = state.copyWith(activeProfile: PowerProfile.ultraSaver);
        
        expect(updated.activeProfile.id, 'ultra_saver');
        expect(updated.activeProfile.enableAnimations, false);
      });
    });
  });
}
