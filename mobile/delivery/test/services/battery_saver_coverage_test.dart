import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:courier/core/services/battery_saver_service.dart';

void main() {
  group('BatteryThresholds', () {
    test('critical is 10', () {
      expect(BatteryThresholds.critical, 10);
    });

    test('low is 20', () {
      expect(BatteryThresholds.low, 20);
    });

    test('normal is 50', () {
      expect(BatteryThresholds.normal, 50);
    });
  });

  group('BatterySaverMode', () {
    test('has 4 values', () {
      expect(BatterySaverMode.values.length, 4);
    });
  });

  group('BatteryStatus', () {
    BatteryStatus makeStatus({
      int level = 80,
      BatterySaverMode mode = BatterySaverMode.normal,
      bool isCharging = false,
    }) {
      return BatteryStatus(
        level: level,
        mode: mode,
        isCharging: isCharging,
        lastUpdated: DateTime(2024, 1, 1),
      );
    }

    test('constructor and basic properties', () {
      final status = makeStatus(level: 75);
      expect(status.level, 75);
      expect(status.mode, BatterySaverMode.normal);
      expect(status.isCharging, false);
    });

    test('copyWith preserves values', () {
      final status = makeStatus(level: 80);
      final copy = status.copyWith(level: 50);
      expect(copy.level, 50);
      expect(copy.mode, BatterySaverMode.normal);
      expect(copy.isCharging, false);
    });

    test('copyWith updates all fields', () {
      final status = makeStatus();
      final now = DateTime.now();
      final copy = status.copyWith(
        level: 15,
        mode: BatterySaverMode.saver,
        isCharging: true,
        lastUpdated: now,
      );
      expect(copy.level, 15);
      expect(copy.mode, BatterySaverMode.saver);
      expect(copy.isCharging, true);
      expect(copy.lastUpdated, now);
    });

    group('modeDescription', () {
      test('normal returns GPS précis', () {
        expect(
          makeStatus(mode: BatterySaverMode.normal).modeDescription,
          'GPS précis',
        );
      });

      test('saver returns Économie activée', () {
        expect(
          makeStatus(mode: BatterySaverMode.saver).modeDescription,
          'Économie activée',
        );
      });

      test('critical returns Mode minimal', () {
        expect(
          makeStatus(mode: BatterySaverMode.critical).modeDescription,
          'Mode minimal',
        );
      });

      test('charging returns En charge', () {
        expect(
          makeStatus(mode: BatterySaverMode.charging).modeDescription,
          'En charge',
        );
      });
    });

    group('modeIcon', () {
      test('normal returns battery emoji', () {
        expect(makeStatus(mode: BatterySaverMode.normal).modeIcon, '🔋');
      });

      test('saver returns battery emoji', () {
        expect(makeStatus(mode: BatterySaverMode.saver).modeIcon, '🔋');
      });

      test('critical returns low battery emoji', () {
        expect(makeStatus(mode: BatterySaverMode.critical).modeIcon, '🪫');
      });

      test('charging returns lightning emoji', () {
        expect(makeStatus(mode: BatterySaverMode.charging).modeIcon, '⚡');
      });
    });

    group('gpsUpdateIntervalSeconds', () {
      test('normal is 5', () {
        expect(
          makeStatus(mode: BatterySaverMode.normal).gpsUpdateIntervalSeconds,
          5,
        );
      });

      test('saver is 15', () {
        expect(
          makeStatus(mode: BatterySaverMode.saver).gpsUpdateIntervalSeconds,
          15,
        );
      });

      test('critical is 30', () {
        expect(
          makeStatus(mode: BatterySaverMode.critical).gpsUpdateIntervalSeconds,
          30,
        );
      });

      test('charging is 5', () {
        expect(
          makeStatus(mode: BatterySaverMode.charging).gpsUpdateIntervalSeconds,
          5,
        );
      });
    });

    group('gpsAccuracy', () {
      test('normal is high', () {
        expect(
          makeStatus(mode: BatterySaverMode.normal).gpsAccuracy,
          LocationAccuracy.high,
        );
      });

      test('saver is medium', () {
        expect(
          makeStatus(mode: BatterySaverMode.saver).gpsAccuracy,
          LocationAccuracy.medium,
        );
      });

      test('critical is low', () {
        expect(
          makeStatus(mode: BatterySaverMode.critical).gpsAccuracy,
          LocationAccuracy.low,
        );
      });

      test('charging is high', () {
        expect(
          makeStatus(mode: BatterySaverMode.charging).gpsAccuracy,
          LocationAccuracy.high,
        );
      });
    });

    group('gpsDistanceFilter', () {
      test('normal is 10', () {
        expect(makeStatus(mode: BatterySaverMode.normal).gpsDistanceFilter, 10);
      });

      test('saver is 30', () {
        expect(makeStatus(mode: BatterySaverMode.saver).gpsDistanceFilter, 30);
      });

      test('critical is 50', () {
        expect(
          makeStatus(mode: BatterySaverMode.critical).gpsDistanceFilter,
          50,
        );
      });

      test('charging is 10', () {
        expect(
          makeStatus(mode: BatterySaverMode.charging).gpsDistanceFilter,
          10,
        );
      });
    });
  });
}
