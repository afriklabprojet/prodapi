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

      final updated = status.copyWith(
        level: 50,
        mode: BatterySaverMode.saver,
      );

      expect(updated.level, 50);
      expect(updated.mode, BatterySaverMode.saver);
      expect(updated.isCharging, false); // unchanged
    });

    test('modeDescription returns correct text for each mode', () {
      expect(
        BatteryStatus(level: 80, mode: BatterySaverMode.normal, isCharging: false, lastUpdated: DateTime.now()).modeDescription,
        'GPS précis',
      );
      expect(
        BatteryStatus(level: 15, mode: BatterySaverMode.saver, isCharging: false, lastUpdated: DateTime.now()).modeDescription,
        'Économie activée',
      );
      expect(
        BatteryStatus(level: 5, mode: BatterySaverMode.critical, isCharging: false, lastUpdated: DateTime.now()).modeDescription,
        'Mode minimal',
      );
      expect(
        BatteryStatus(level: 20, mode: BatterySaverMode.charging, isCharging: true, lastUpdated: DateTime.now()).modeDescription,
        'En charge',
      );
    });

    test('modeIcon returns correct icon for each mode', () {
      expect(
        BatteryStatus(level: 80, mode: BatterySaverMode.normal, isCharging: false, lastUpdated: DateTime.now()).modeIcon,
        '🔋',
      );
      expect(
        BatteryStatus(level: 5, mode: BatterySaverMode.critical, isCharging: false, lastUpdated: DateTime.now()).modeIcon,
        '🪫',
      );
      expect(
        BatteryStatus(level: 20, mode: BatterySaverMode.charging, isCharging: true, lastUpdated: DateTime.now()).modeIcon,
        '⚡',
      );
    });

    test('gpsUpdateIntervalSeconds varies by mode', () {
      final normalStatus = BatteryStatus(level: 80, mode: BatterySaverMode.normal, isCharging: false, lastUpdated: DateTime.now());
      final saverStatus = BatteryStatus(level: 15, mode: BatterySaverMode.saver, isCharging: false, lastUpdated: DateTime.now());
      final criticalStatus = BatteryStatus(level: 5, mode: BatterySaverMode.critical, isCharging: false, lastUpdated: DateTime.now());

      expect(normalStatus.gpsUpdateIntervalSeconds, 5);
      expect(saverStatus.gpsUpdateIntervalSeconds, 15);
      expect(criticalStatus.gpsUpdateIntervalSeconds, 30);
    });

    test('gpsAccuracy varies by mode', () {
      final normalStatus = BatteryStatus(level: 80, mode: BatterySaverMode.normal, isCharging: false, lastUpdated: DateTime.now());
      final saverStatus = BatteryStatus(level: 15, mode: BatterySaverMode.saver, isCharging: false, lastUpdated: DateTime.now());
      final criticalStatus = BatteryStatus(level: 5, mode: BatterySaverMode.critical, isCharging: false, lastUpdated: DateTime.now());

      expect(normalStatus.gpsAccuracy, LocationAccuracy.high);
      expect(saverStatus.gpsAccuracy, LocationAccuracy.medium);
      expect(criticalStatus.gpsAccuracy, LocationAccuracy.low);
    });

    test('gpsDistanceFilter varies by mode', () {
      final normalStatus = BatteryStatus(level: 80, mode: BatterySaverMode.normal, isCharging: false, lastUpdated: DateTime.now());
      final saverStatus = BatteryStatus(level: 15, mode: BatterySaverMode.saver, isCharging: false, lastUpdated: DateTime.now());
      final criticalStatus = BatteryStatus(level: 5, mode: BatterySaverMode.critical, isCharging: false, lastUpdated: DateTime.now());

      expect(normalStatus.gpsDistanceFilter, 10);
      expect(saverStatus.gpsDistanceFilter, 30);
      expect(criticalStatus.gpsDistanceFilter, 50);
    });

    test('charging mode uses normal GPS settings', () {
      final chargingStatus = BatteryStatus(level: 15, mode: BatterySaverMode.charging, isCharging: true, lastUpdated: DateTime.now());

      expect(chargingStatus.gpsUpdateIntervalSeconds, 5);
      expect(chargingStatus.gpsAccuracy, LocationAccuracy.high);
      expect(chargingStatus.gpsDistanceFilter, 10);
    });
  });
}
