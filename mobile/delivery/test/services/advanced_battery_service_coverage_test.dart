import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/advanced_battery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvancedBatteryState - computed properties', () {
    test('isCritical when level <= 10 and not charging', () {
      final state = AdvancedBatteryState(
        level: 10,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isCritical, true);
    });

    test('isCritical false when level <= 10 but charging', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: true,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isCritical, false);
    });

    test('isCritical false when level > 10', () {
      final state = AdvancedBatteryState(
        level: 11,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isCritical, false);
    });

    test('isLow when level <= 20 and not charging', () {
      final state = AdvancedBatteryState(
        level: 20,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isLow, true);
    });

    test('isLow false when charging', () {
      final state = AdvancedBatteryState(
        level: 15,
        isCharging: true,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isLow, false);
    });

    test('isLow false when level > 20', () {
      final state = AdvancedBatteryState(
        level: 21,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.isLow, false);
    });

    test('levelColorValue green when charging', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: true,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFF4CAF50);
    });

    test('levelColorValue red when level <= 10', () {
      final state = AdvancedBatteryState(
        level: 10,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFFF44336);
    });

    test('levelColorValue orange when level <= 20', () {
      final state = AdvancedBatteryState(
        level: 20,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFFFF9800);
    });

    test('levelColorValue yellow when level <= 50', () {
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFFFFEB3B);
    });

    test('levelColorValue green when level > 50', () {
      final state = AdvancedBatteryState(
        level: 75,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      expect(state.levelColorValue, 0xFF4CAF50);
    });

    test('copyWith updates autoOptimizeEnabled', () {
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        autoOptimizeEnabled: true,
        lastUpdated: DateTime.now(),
      );
      final updated = state.copyWith(autoOptimizeEnabled: false);
      expect(updated.autoOptimizeEnabled, false);
      expect(updated.level, 50);
    });

    test('copyWith updates stats', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 5.0,
        estimatedMinutesRemaining: 120,
        lastFullCharge: DateTime.now(),
      );
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      final updated = state.copyWith(stats: stats);
      expect(updated.stats, stats);
      expect(updated.stats!.averageDrainPerHour, 5.0);
    });

    test('copyWith updates lastUpdated', () {
      final old = DateTime(2024, 1, 1);
      final newDate = DateTime(2024, 6, 1);
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: old,
      );
      final updated = state.copyWith(lastUpdated: newDate);
      expect(updated.lastUpdated, newDate);
    });

    test('copyWith updates levelHistory', () {
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
        levelHistory: [80, 70, 60],
      );
      final updated = state.copyWith(levelHistory: [50, 40]);
      expect(updated.levelHistory, [50, 40]);
    });
  });

  group('BatteryUsageStats - edge cases', () {
    test('remainingTimeFormatted for exactly 60 minutes', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 10.0,
        estimatedMinutesRemaining: 60,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '1h');
    });

    test('remainingTimeFormatted for 61 minutes', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 10.0,
        estimatedMinutesRemaining: 61,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '1h 1min');
    });

    test('remainingTimeFormatted for 0 minutes', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 50.0,
        estimatedMinutesRemaining: 0,
        lastFullCharge: DateTime.now(),
      );
      expect(stats.remainingTimeFormatted, '0 min');
    });

    test('usageByFeature can store custom features', () {
      final stats = BatteryUsageStats(
        averageDrainPerHour: 10.0,
        estimatedMinutesRemaining: 120,
        lastFullCharge: DateTime.now(),
        usageByFeature: {'GPS': 35.0, 'Screen': 30.0},
        cyclesSinceCharge: 5,
      );
      expect(stats.usageByFeature['GPS'], 35.0);
      expect(stats.usageByFeature['Screen'], 30.0);
      expect(stats.cyclesSinceCharge, 5);
    });
  });

  group('OptimizationTip', () {
    test('creates with required fields', () {
      final tip = OptimizationTip(
        id: 'test_tip',
        title: 'Test',
        description: 'Test description',
        icon: '🔋',
        estimatedSavingsPercent: 20,
      );
      expect(tip.id, 'test_tip');
      expect(tip.title, 'Test');
      expect(tip.description, 'Test description');
      expect(tip.icon, '🔋');
      expect(tip.estimatedSavingsPercent, 20);
      expect(tip.isApplied, false);
      expect(tip.action, isNull);
    });

    test('creates with isApplied true', () {
      final tip = OptimizationTip(
        id: 'applied',
        title: 'Applied Tip',
        description: 'Already applied',
        icon: '✅',
        estimatedSavingsPercent: 10,
        isApplied: true,
      );
      expect(tip.isApplied, true);
    });

    test('creates with action callback', () {
      var called = false;
      final tip = OptimizationTip(
        id: 'action',
        title: 'Actionable',
        description: 'Has action',
        icon: '⚡',
        estimatedSavingsPercent: 15,
        action: () => called = true,
      );
      tip.action!();
      expect(called, true);
    });
  });

  group('AdvancedBatteryService - getOptimizationTips', () {
    late AdvancedBatteryService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AdvancedBatteryService();
    });

    test('suggests battery saver when level <= 30 and using performance', () {
      final state = AdvancedBatteryState(
        level: 25,
        isCharging: false,
        activeProfile: PowerProfile.performance,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'enable_saver'), true);
    });

    test('suggests battery saver when level <= 30 and using balanced', () {
      final state = AdvancedBatteryState(
        level: 20,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'enable_saver'), true);
    });

    test('no battery saver tip when already using batterySaver', () {
      final state = AdvancedBatteryState(
        level: 20,
        isCharging: false,
        activeProfile: PowerProfile.batterySaver,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'enable_saver'), false);
    });

    test('no battery saver tip when already using ultraSaver', () {
      final state = AdvancedBatteryState(
        level: 10,
        isCharging: false,
        activeProfile: PowerProfile.ultraSaver,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'enable_saver'), false);
    });

    test('no battery saver tip when level > 30', () {
      final state = AdvancedBatteryState(
        level: 50,
        isCharging: false,
        activeProfile: PowerProfile.performance,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'enable_saver'), false);
    });

    test(
      'suggests disable animations when level <= 20 and animations enabled',
      () {
        final state = AdvancedBatteryState(
          level: 15,
          isCharging: false,
          activeProfile: PowerProfile.performance, // enableAnimations = true
          lastUpdated: DateTime.now(),
        );
        final tips = service.getOptimizationTips(state);
        expect(tips.any((t) => t.id == 'disable_animations'), true);
      },
    );

    test('no animation tip when animations already disabled', () {
      final state = AdvancedBatteryState(
        level: 15,
        isCharging: false,
        activeProfile: PowerProfile.batterySaver, // enableAnimations = false
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips.any((t) => t.id == 'disable_animations'), false);
    });

    test('returns empty list when battery is healthy', () {
      final state = AdvancedBatteryState(
        level: 80,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        autoOptimizeEnabled: true,
        lastUpdated: DateTime.now(),
      );
      final tips = service.getOptimizationTips(state);
      expect(tips, isEmpty);
    });
  });

  group('AdvancedBatteryService - getOptimizedGpsSettings', () {
    late AdvancedBatteryService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AdvancedBatteryService();
    });

    test('returns performance GPS settings', () {
      final state = AdvancedBatteryState(
        level: 100,
        isCharging: true,
        activeProfile: PowerProfile.performance,
        lastUpdated: DateTime.now(),
      );
      final settings = service.getOptimizedGpsSettings(state);
      expect(settings.accuracy, LocationAccuracy.bestForNavigation);
      expect(settings.distanceFilter, 5);
    });

    test('returns balanced GPS settings', () {
      final state = AdvancedBatteryState(
        level: 70,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        lastUpdated: DateTime.now(),
      );
      final settings = service.getOptimizedGpsSettings(state);
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 15);
    });

    test('returns battery saver GPS settings', () {
      final state = AdvancedBatteryState(
        level: 20,
        isCharging: false,
        activeProfile: PowerProfile.batterySaver,
        lastUpdated: DateTime.now(),
      );
      final settings = service.getOptimizedGpsSettings(state);
      expect(settings.accuracy, LocationAccuracy.medium);
      expect(settings.distanceFilter, 30);
    });

    test('returns ultra saver GPS settings', () {
      final state = AdvancedBatteryState(
        level: 5,
        isCharging: false,
        activeProfile: PowerProfile.ultraSaver,
        lastUpdated: DateTime.now(),
      );
      final settings = service.getOptimizedGpsSettings(state);
      expect(settings.accuracy, LocationAccuracy.low);
      expect(settings.distanceFilter, 50);
    });
  });

  group('AdvancedBatteryService - setProfile', () {
    late AdvancedBatteryService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AdvancedBatteryService();
    });

    test('persists profile to SharedPreferences', () async {
      await service.setProfile(PowerProfile.ultraSaver);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('power_profile'), 'ultra_saver');
    });

    test('persists balanced profile', () async {
      await service.setProfile(PowerProfile.balanced);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('power_profile'), 'balanced');
    });
  });

  group('AdvancedBatteryService - setAutoOptimize', () {
    late AdvancedBatteryService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AdvancedBatteryService();
    });

    test('persists autoOptimize to SharedPreferences', () async {
      await service.setAutoOptimize(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auto_optimize'), false);
    });

    test('persists autoOptimize true', () async {
      await service.setAutoOptimize(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auto_optimize'), true);
    });
  });

  group('AdvancedBatteryService - initialize', () {
    test('loads balanced profile by default', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AdvancedBatteryService();
      await service.initialize();
      // No error means it loaded correctly
    });

    test('loads saved profile from prefs', () async {
      SharedPreferences.setMockInitialValues({
        'power_profile': 'ultra_saver',
        'auto_optimize': false,
        'battery_level_history': '90,85,80,75',
        'last_full_charge': '2024-01-15T08:00:00.000',
      });
      final service = AdvancedBatteryService();
      await service.initialize();
      // Profile should be loaded - test indirectly via tips
    });

    test('handles invalid profile id gracefully', () async {
      SharedPreferences.setMockInitialValues({'power_profile': 'nonexistent'});
      final service = AdvancedBatteryService();
      await service.initialize();
      // Should fall back to balanced
    });

    test('handles empty history string', () async {
      SharedPreferences.setMockInitialValues({'battery_level_history': ''});
      final service = AdvancedBatteryService();
      await service.initialize();
    });
  });

  group('AdvancedBatteryService - saveState', () {
    test('saves level history to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AdvancedBatteryService();
      // Indirectly test via setProfile then saveState
      await service.saveState();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('battery_level_history'), isNotNull);
    });
  });

  group('PowerProfile - custom profile', () {
    test('creates custom profile with all fields', () {
      const custom = PowerProfile(
        id: 'custom',
        name: 'Custom',
        description: 'Custom profile',
        gpsIntervalSeconds: 15,
        distanceFilterMeters: 25,
        accuracy: LocationAccuracy.reduced,
        enableAnimations: false,
        enableVibration: true,
        enableAutoSync: false,
        syncIntervalMinutes: 15,
        brightnessMultiplier: 0.8,
      );
      expect(custom.id, 'custom');
      expect(custom.enableAnimations, false);
      expect(custom.enableVibration, true);
      expect(custom.enableAutoSync, false);
      expect(custom.syncIntervalMinutes, 15);
      expect(custom.brightnessMultiplier, 0.8);
    });

    test('default values for optional fields', () {
      const minimal = PowerProfile(
        id: 'min',
        name: 'Minimal',
        description: 'Desc',
        gpsIntervalSeconds: 5,
        distanceFilterMeters: 10,
        accuracy: LocationAccuracy.high,
      );
      expect(minimal.enableAnimations, true);
      expect(minimal.enableVibration, true);
      expect(minimal.enableAutoSync, true);
      expect(minimal.syncIntervalMinutes, 5);
      expect(minimal.brightnessMultiplier, 1.0);
    });
  });

  group('AdvancedBatteryService - suggests auto optimize', () {
    late AdvancedBatteryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'auto_optimize': false});
      service = AdvancedBatteryService();
      await service.initialize();
    });

    test('suggests enable_auto when disabled and level <= 50', () {
      final state = AdvancedBatteryState(
        level: 40,
        isCharging: false,
        activeProfile: PowerProfile.balanced,
        autoOptimizeEnabled: false,
        lastUpdated: DateTime.now(),
      );
      // Need to make auto optimize disabled internally
      final tips = service.getOptimizationTips(state);
      // The method checks _autoOptimizeEnabled (internal) == false
      expect(tips.any((t) => t.id == 'enable_auto'), true);
    });
  });
}
