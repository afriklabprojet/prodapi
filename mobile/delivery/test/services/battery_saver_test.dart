import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:courier/core/services/battery_saver_service.dart';

void main() {
  group('BatteryThresholds', () {
    test('has correct critical value', () {
      expect(BatteryThresholds.critical, 10);
    });

    test('has correct low value', () {
      expect(BatteryThresholds.low, 20);
    });

    test('has correct normal value', () {
      expect(BatteryThresholds.normal, 50);
    });

    test('thresholds are in ascending order', () {
      expect(BatteryThresholds.critical < BatteryThresholds.low, true);
      expect(BatteryThresholds.low < BatteryThresholds.normal, true);
    });
  });

  group('BatterySaverMode', () {
    test('has all expected values', () {
      expect(BatterySaverMode.values.length, 4);
      expect(BatterySaverMode.values, contains(BatterySaverMode.normal));
      expect(BatterySaverMode.values, contains(BatterySaverMode.saver));
      expect(BatterySaverMode.values, contains(BatterySaverMode.critical));
      expect(BatterySaverMode.values, contains(BatterySaverMode.charging));
    });
  });

  group('BatteryStatus', () {
    test('creates with required fields', () {
      final status = BatteryStatus(
        level: 75,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime(2024, 1, 15),
      );

      expect(status.level, 75);
      expect(status.mode, BatterySaverMode.normal);
      expect(status.isCharging, false);
    });

    test('copyWith updates specified fields', () {
      final status = BatteryStatus(
        level: 75,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime(2024, 1, 15),
      );

      final updated = status.copyWith(level: 50, mode: BatterySaverMode.saver);

      expect(updated.level, 50);
      expect(updated.mode, BatterySaverMode.saver);
      expect(updated.isCharging, false); // unchanged
    });

    test('modeDescription returns correct text for each mode', () {
      expect(
        BatteryStatus(
          level: 80,
          mode: BatterySaverMode.normal,
          isCharging: false,
          lastUpdated: DateTime.now(),
        ).modeDescription,
        'GPS précis',
      );
      expect(
        BatteryStatus(
          level: 15,
          mode: BatterySaverMode.saver,
          isCharging: false,
          lastUpdated: DateTime.now(),
        ).modeDescription,
        'Économie activée',
      );
      expect(
        BatteryStatus(
          level: 5,
          mode: BatterySaverMode.critical,
          isCharging: false,
          lastUpdated: DateTime.now(),
        ).modeDescription,
        'Mode minimal',
      );
      expect(
        BatteryStatus(
          level: 20,
          mode: BatterySaverMode.charging,
          isCharging: true,
          lastUpdated: DateTime.now(),
        ).modeDescription,
        'En charge',
      );
    });

    test('modeIcon returns correct icon for each mode', () {
      expect(
        BatteryStatus(
          level: 80,
          mode: BatterySaverMode.normal,
          isCharging: false,
          lastUpdated: DateTime.now(),
        ).modeIcon,
        '🔋',
      );
      expect(
        BatteryStatus(
          level: 5,
          mode: BatterySaverMode.critical,
          isCharging: false,
          lastUpdated: DateTime.now(),
        ).modeIcon,
        '🪫',
      );
      expect(
        BatteryStatus(
          level: 20,
          mode: BatterySaverMode.charging,
          isCharging: true,
          lastUpdated: DateTime.now(),
        ).modeIcon,
        '⚡',
      );
    });

    test('gpsUpdateIntervalSeconds varies by mode', () {
      final normalStatus = BatteryStatus(
        level: 80,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final saverStatus = BatteryStatus(
        level: 15,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final criticalStatus = BatteryStatus(
        level: 5,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );

      expect(normalStatus.gpsUpdateIntervalSeconds, 5);
      expect(saverStatus.gpsUpdateIntervalSeconds, 15);
      expect(criticalStatus.gpsUpdateIntervalSeconds, 30);
    });

    test('gpsAccuracy varies by mode', () {
      final normalStatus = BatteryStatus(
        level: 80,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final saverStatus = BatteryStatus(
        level: 15,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final criticalStatus = BatteryStatus(
        level: 5,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );

      expect(normalStatus.gpsAccuracy, LocationAccuracy.high);
      expect(saverStatus.gpsAccuracy, LocationAccuracy.medium);
      expect(criticalStatus.gpsAccuracy, LocationAccuracy.low);
    });

    test('gpsDistanceFilter varies by mode', () {
      final normalStatus = BatteryStatus(
        level: 80,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final saverStatus = BatteryStatus(
        level: 15,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final criticalStatus = BatteryStatus(
        level: 5,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );

      expect(normalStatus.gpsDistanceFilter, 10);
      expect(saverStatus.gpsDistanceFilter, 30);
      expect(criticalStatus.gpsDistanceFilter, 50);
    });

    test('charging mode uses normal GPS settings', () {
      final chargingStatus = BatteryStatus(
        level: 15,
        mode: BatterySaverMode.charging,
        isCharging: true,
        lastUpdated: DateTime.now(),
      );

      expect(chargingStatus.gpsUpdateIntervalSeconds, 5);
      expect(chargingStatus.gpsAccuracy, LocationAccuracy.high);
      expect(chargingStatus.gpsDistanceFilter, 10);
    });

    test('copyWith updates level only', () {
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime(2024, 1, 1),
      );
      final updated = status.copyWith(level: 25);
      expect(updated.level, 25);
      expect(updated.mode, BatterySaverMode.normal);
      expect(updated.isCharging, false);
    });

    test('copyWith updates mode only', () {
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime(2024, 1, 1),
      );
      final updated = status.copyWith(mode: BatterySaverMode.critical);
      expect(updated.mode, BatterySaverMode.critical);
      expect(updated.level, 50);
    });

    test('copyWith updates isCharging only', () {
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime(2024, 1, 1),
      );
      final updated = status.copyWith(isCharging: true);
      expect(updated.isCharging, true);
      expect(updated.level, 50);
    });

    test('copyWith updates lastUpdated only', () {
      final original = DateTime(2024, 1, 1);
      final newDate = DateTime(2025, 6, 15);
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: original,
      );
      final updated = status.copyWith(lastUpdated: newDate);
      expect(updated.lastUpdated, newDate);
      expect(updated.level, 50);
    });

    test('copyWith preserves all when no changes', () {
      final now = DateTime.now();
      final status = BatteryStatus(
        level: 42,
        mode: BatterySaverMode.saver,
        isCharging: true,
        lastUpdated: now,
      );
      final copy = status.copyWith();
      expect(copy.level, 42);
      expect(copy.mode, BatterySaverMode.saver);
      expect(copy.isCharging, true);
      expect(copy.lastUpdated, now);
    });

    test('modeIcon for saver is battery emoji', () {
      final status = BatteryStatus(
        level: 15,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(status.modeIcon, '🔋');
    });

    test('state field is optional', () {
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(status.state, isNull);
    });

    test('copyWith updates state field', () {
      final innerStatus = BatteryStatus(
        level: 30,
        mode: BatterySaverMode.saver,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final status = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final updated = status.copyWith(state: innerStatus);
      expect(updated.state, isNotNull);
      expect(updated.state!.level, 30);
    });

    test('level 0 works', () {
      final status = BatteryStatus(
        level: 0,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(status.level, 0);
      expect(status.modeDescription, 'Mode minimal');
    });

    test('level 100 works', () {
      final status = BatteryStatus(
        level: 100,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(status.level, 100);
      expect(status.modeDescription, 'GPS précis');
    });
  });

  group('BatterySaverMode indices', () {
    test('normal is 0', () => expect(BatterySaverMode.normal.index, 0));
    test('saver is 1', () => expect(BatterySaverMode.saver.index, 1));
    test('critical is 2', () => expect(BatterySaverMode.critical.index, 2));
    test('charging is 3', () => expect(BatterySaverMode.charging.index, 3));
  });
}
