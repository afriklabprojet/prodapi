import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/app_update_service.dart';
import 'package:courier/core/services/delivery_export_service.dart';

void main() {
  // ════════════════════════════════════════════
  // VersionCheckResult
  // ════════════════════════════════════════════
  group('VersionCheckResult', () {
    test('constructor sets fields', () {
      final result = VersionCheckResult(
        forceUpdate: true,
        updateAvailable: true,
        minVersion: '2.0.0',
        latestVersion: '2.1.0',
        currentVersion: '1.5.0',
        storeUrl: 'https://store.example.com',
        changelog: 'Bug fixes',
      );
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, true);
      expect(result.minVersion, '2.0.0');
      expect(result.latestVersion, '2.1.0');
      expect(result.currentVersion, '1.5.0');
      expect(result.storeUrl, 'https://store.example.com');
      expect(result.changelog, 'Bug fixes');
    });

    test('fromJson with all fields', () {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'update_available': true,
        'min_version': '3.0.0',
        'latest_version': '3.2.0',
        'current_version': '2.9.0',
        'store_url': 'https://play.google.com/app',
        'changelog': 'New features',
      });
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, true);
      expect(result.minVersion, '3.0.0');
      expect(result.latestVersion, '3.2.0');
      expect(result.currentVersion, '2.9.0');
      expect(result.storeUrl, 'https://play.google.com/app');
      expect(result.changelog, 'New features');
    });

    test('fromJson with defaults', () {
      final result = VersionCheckResult.fromJson({});
      expect(result.forceUpdate, false);
      expect(result.updateAvailable, false);
      expect(result.minVersion, '1.0.0');
      expect(result.latestVersion, '1.0.0');
      expect(result.currentVersion, '1.0.0');
      expect(result.storeUrl, '');
      expect(result.changelog, null);
    });
  });

  // ════════════════════════════════════════════
  // isFeatureEnabled
  // ════════════════════════════════════════════
  group('isFeatureEnabled', () {
    test('returns true when flag is true', () {
      expect(isFeatureEnabled({'dark_mode': true}, 'dark_mode'), true);
    });

    test('returns false when flag is false', () {
      expect(isFeatureEnabled({'dark_mode': false}, 'dark_mode'), false);
    });

    test('returns defaultValue when flag missing', () {
      expect(isFeatureEnabled({}, 'dark_mode'), true);
      expect(isFeatureEnabled({}, 'dark_mode', defaultValue: false), false);
    });

    test('returns defaultValue when flag is null', () {
      expect(isFeatureEnabled({'x': null}, 'x'), true);
      expect(isFeatureEnabled({'x': null}, 'x', defaultValue: false), false);
    });
  });

  // ════════════════════════════════════════════
  // ExportedFile
  // ════════════════════════════════════════════
  group('ExportedFile', () {
    test('constructor', () {
      final file = ExportedFile(
        path: '/tmp/export.pdf',
        name: 'export.pdf',
        size: 1024,
        createdAt: DateTime(2024, 1, 1),
        type: ExportType.pdf,
      );
      expect(file.path, '/tmp/export.pdf');
      expect(file.name, 'export.pdf');
      expect(file.size, 1024);
      expect(file.type, ExportType.pdf);
    });

    test('formattedSize bytes', () {
      final file = ExportedFile(
        path: '/tmp/f',
        name: 'f',
        size: 500,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '500 B');
    });

    test('formattedSize KB', () {
      final file = ExportedFile(
        path: '/tmp/f',
        name: 'f',
        size: 2048,
        createdAt: DateTime.now(),
        type: ExportType.csv,
      );
      expect(file.formattedSize, '2.0 KB');
    });

    test('formattedSize MB', () {
      final file = ExportedFile(
        path: '/tmp/f',
        name: 'f',
        size: 2 * 1024 * 1024,
        createdAt: DateTime.now(),
        type: ExportType.pdf,
      );
      expect(file.formattedSize, '2.0 MB');
    });
  });

  // ════════════════════════════════════════════
  // ExportType
  // ════════════════════════════════════════════
  group('ExportType', () {
    test('has 2 values', () {
      expect(ExportType.values.length, 2);
    });

    test('pdf exists', () => expect(ExportType.pdf.index, 0));
    test('csv exists', () => expect(ExportType.csv.index, 1));
  });

  // ════════════════════════════════════════════
  // HistoryStats
  // ════════════════════════════════════════════
  group('HistoryStats export model', () {
    test('constructor', () {
      const stats = HistoryStats(
        totalDeliveries: 10,
        deliveredCount: 8,
        cancelledCount: 2,
        totalEarnings: 50000,
        averageEarnings: 5000,
        totalDistance: 45.5,
      );
      expect(stats.totalDeliveries, 10);
      expect(stats.deliveredCount, 8);
      expect(stats.cancelledCount, 2);
      expect(stats.totalEarnings, 50000);
      expect(stats.averageEarnings, 5000);
      expect(stats.totalDistance, 45.5);
    });
  });
}
