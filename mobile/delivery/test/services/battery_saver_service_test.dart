import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:courier/core/services/battery_saver_service.dart';

void main() {
  // ── BatteryThresholds ──────────────────────────────
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

    test('critical < low < normal', () {
      expect(BatteryThresholds.critical, lessThan(BatteryThresholds.low));
      expect(BatteryThresholds.low, lessThan(BatteryThresholds.normal));
    });
  });

  // ── BatterySaverMode ──────────────────────────────
  group('BatterySaverMode', () {
    test('has 4 values', () {
      expect(BatterySaverMode.values.length, 4);
    });

    test('normal is index 0', () {
      expect(BatterySaverMode.normal.index, 0);
    });

    test('saver is index 1', () {
      expect(BatterySaverMode.saver.index, 1);
    });

    test('critical is index 2', () {
      expect(BatterySaverMode.critical.index, 2);
    });

    test('charging is index 3', () {
      expect(BatterySaverMode.charging.index, 3);
    });
  });

  // ── BatteryStatus - modeDescription ─────────────────
  group('BatteryStatus modeDescription', () {
    BatteryStatus makeStatus(BatterySaverMode mode) {
      return BatteryStatus(
        level: 50,
        mode: mode,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }

    test('normal returns GPS précis', () {
      expect(makeStatus(BatterySaverMode.normal).modeDescription, 'GPS précis');
    });

    test('saver returns Économie activée', () {
      expect(makeStatus(BatterySaverMode.saver).modeDescription, 'Économie activée');
    });

    test('critical returns Mode minimal', () {
      expect(makeStatus(BatterySaverMode.critical).modeDescription, 'Mode minimal');
    });

    test('charging returns En charge', () {
      expect(makeStatus(BatterySaverMode.charging).modeDescription, 'En charge');
    });
  });

  // ── BatteryStatus - modeIcon ────────────────────────
  group('BatteryStatus modeIcon', () {
    BatteryStatus makeStatus(BatterySaverMode mode) {
      return BatteryStatus(
        level: 50,
        mode: mode,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }

    test('normal icon is battery emoji', () {
      expect(makeStatus(BatterySaverMode.normal).modeIcon, '🔋');
    });

    test('saver icon is battery emoji', () {
      expect(makeStatus(BatterySaverMode.saver).modeIcon, '🔋');
    });

    test('critical icon is low battery emoji', () {
      expect(makeStatus(BatterySaverMode.critical).modeIcon, '🪫');
    });

    test('charging icon is lightning emoji', () {
      expect(makeStatus(BatterySaverMode.charging).modeIcon, '⚡');
    });
  });

  // ── BatteryStatus - gpsUpdateIntervalSeconds ────────
  group('BatteryStatus gpsUpdateIntervalSeconds', () {
    BatteryStatus makeStatus(BatterySaverMode mode) {
      return BatteryStatus(
        level: 50,
        mode: mode,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }

    test('normal is 5 seconds', () {
      expect(makeStatus(BatterySaverMode.normal).gpsUpdateIntervalSeconds, 5);
    });

    test('saver is 15 seconds', () {
      expect(makeStatus(BatterySaverMode.saver).gpsUpdateIntervalSeconds, 15);
    });

    test('critical is 30 seconds', () {
      expect(makeStatus(BatterySaverMode.critical).gpsUpdateIntervalSeconds, 30);
    });

    test('charging is 5 seconds', () {
      expect(makeStatus(BatterySaverMode.charging).gpsUpdateIntervalSeconds, 5);
    });

    test('normal and charging have same interval', () {
      expect(
        makeStatus(BatterySaverMode.normal).gpsUpdateIntervalSeconds,
        makeStatus(BatterySaverMode.charging).gpsUpdateIntervalSeconds,
      );
    });

    test('intervals increase: normal < saver < critical', () {
      final normalInt = makeStatus(BatterySaverMode.normal).gpsUpdateIntervalSeconds;
      final saverInt = makeStatus(BatterySaverMode.saver).gpsUpdateIntervalSeconds;
      final criticalInt = makeStatus(BatterySaverMode.critical).gpsUpdateIntervalSeconds;
      expect(normalInt, lessThan(saverInt));
      expect(saverInt, lessThan(criticalInt));
    });
  });

  // ── BatteryStatus - gpsAccuracy ─────────────────────
  group('BatteryStatus gpsAccuracy', () {
    BatteryStatus makeStatus(BatterySaverMode mode) {
      return BatteryStatus(
        level: 50,
        mode: mode,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }

    test('normal is high', () {
      expect(makeStatus(BatterySaverMode.normal).gpsAccuracy, LocationAccuracy.high);
    });

    test('saver is medium', () {
      expect(makeStatus(BatterySaverMode.saver).gpsAccuracy, LocationAccuracy.medium);
    });

    test('critical is low', () {
      expect(makeStatus(BatterySaverMode.critical).gpsAccuracy, LocationAccuracy.low);
    });

    test('charging is high', () {
      expect(makeStatus(BatterySaverMode.charging).gpsAccuracy, LocationAccuracy.high);
    });
  });

  // ── BatteryStatus - gpsDistanceFilter ───────────────
  group('BatteryStatus gpsDistanceFilter', () {
    BatteryStatus makeStatus(BatterySaverMode mode) {
      return BatteryStatus(
        level: 50,
        mode: mode,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
    }

    test('normal is 10 meters', () {
      expect(makeStatus(BatterySaverMode.normal).gpsDistanceFilter, 10);
    });

    test('saver is 30 meters', () {
      expect(makeStatus(BatterySaverMode.saver).gpsDistanceFilter, 30);
    });

    test('critical is 50 meters', () {
      expect(makeStatus(BatterySaverMode.critical).gpsDistanceFilter, 50);
    });

    test('charging is 10 meters', () {
      expect(makeStatus(BatterySaverMode.charging).gpsDistanceFilter, 10);
    });

    test('filters increase: normal < saver < critical', () {
      final normalF = makeStatus(BatterySaverMode.normal).gpsDistanceFilter;
      final saverF = makeStatus(BatterySaverMode.saver).gpsDistanceFilter;
      final criticalF = makeStatus(BatterySaverMode.critical).gpsDistanceFilter;
      expect(normalF, lessThan(saverF));
      expect(saverF, lessThan(criticalF));
    });
  });

  // ── BatteryStatus - copyWith ────────────────────────
  group('BatteryStatus copyWith', () {
    final now = DateTime.now();
    final status = BatteryStatus(
      level: 75,
      mode: BatterySaverMode.normal,
      isCharging: false,
      lastUpdated: now,
    );

    test('copyWith preserves all when no changes', () {
      final copy = status.copyWith();
      expect(copy.level, 75);
      expect(copy.mode, BatterySaverMode.normal);
      expect(copy.isCharging, false);
      expect(copy.lastUpdated, now);
    });

    test('copyWith updates level only', () {
      final copy = status.copyWith(level: 50);
      expect(copy.level, 50);
      expect(copy.mode, BatterySaverMode.normal);
    });

    test('copyWith updates mode only', () {
      final copy = status.copyWith(mode: BatterySaverMode.saver);
      expect(copy.mode, BatterySaverMode.saver);
      expect(copy.level, 75);
    });

    test('copyWith updates isCharging only', () {
      final copy = status.copyWith(isCharging: true);
      expect(copy.isCharging, true);
      expect(copy.mode, BatterySaverMode.normal);
    });

    test('copyWith updates lastUpdated only', () {
      final newTime = DateTime(2030, 1, 1);
      final copy = status.copyWith(lastUpdated: newTime);
      expect(copy.lastUpdated, newTime);
      expect(copy.level, 75);
    });

    test('copyWith updates all fields at once', () {
      final newTime = DateTime(2030, 1, 1);
      final copy = status.copyWith(
        level: 10,
        mode: BatterySaverMode.critical,
        isCharging: true,
        lastUpdated: newTime,
      );
      expect(copy.level, 10);
      expect(copy.mode, BatterySaverMode.critical);
      expect(copy.isCharging, true);
      expect(copy.lastUpdated, newTime);
    });
  });

  // ── BatteryStatus - constructor ─────────────────────
  group('BatteryStatus constructor', () {
    test('stores all required fields', () {
      final now = DateTime.now();
      final s = BatteryStatus(
        level: 100,
        mode: BatterySaverMode.charging,
        isCharging: true,
        lastUpdated: now,
      );
      expect(s.level, 100);
      expect(s.mode, BatterySaverMode.charging);
      expect(s.isCharging, true);
      expect(s.lastUpdated, now);
      expect(s.state, isNull);
    });

    test('state field is nullable', () {
      final inner = BatteryStatus(
        level: 50,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      final outer = BatteryStatus(
        level: 75,
        mode: BatterySaverMode.saver,
        state: inner,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(outer.state, isNotNull);
      expect(outer.state!.level, 50);
    });

    test('level 0 is valid', () {
      final s = BatteryStatus(
        level: 0,
        mode: BatterySaverMode.critical,
        isCharging: false,
        lastUpdated: DateTime.now(),
      );
      expect(s.level, 0);
    });

    test('level 100 is valid', () {
      final s = BatteryStatus(
        level: 100,
        mode: BatterySaverMode.normal,
        isCharging: true,
        lastUpdated: DateTime.now(),
      );
      expect(s.level, 100);
    });
  });

  // ── BatteryStatus - derived property consistency ────
  group('BatteryStatus derived property consistency', () {
    test('all modes have non-empty modeDescription', () {
      for (final mode in BatterySaverMode.values) {
        final s = BatteryStatus(
          level: 50,
          mode: mode,
          isCharging: false,
          lastUpdated: DateTime.now(),
        );
        expect(s.modeDescription, isNotEmpty);
      }
    });

    test('all modes have non-empty modeIcon', () {
      for (final mode in BatterySaverMode.values) {
        final s = BatteryStatus(
          level: 50,
          mode: mode,
          isCharging: false,
          lastUpdated: DateTime.now(),
        );
        expect(s.modeIcon, isNotEmpty);
      }
    });

    test('all modes have positive gpsUpdateIntervalSeconds', () {
      for (final mode in BatterySaverMode.values) {
        final s = BatteryStatus(
          level: 50,
          mode: mode,
          isCharging: false,
          lastUpdated: DateTime.now(),
        );
        expect(s.gpsUpdateIntervalSeconds, greaterThan(0));
      }
    });

    test('all modes have positive gpsDistanceFilter', () {
      for (final mode in BatterySaverMode.values) {
        final s = BatteryStatus(
          level: 50,
          mode: mode,
          isCharging: false,
          lastUpdated: DateTime.now(),
        );
        expect(s.gpsDistanceFilter, greaterThan(0));
      }
    });
  });
}
