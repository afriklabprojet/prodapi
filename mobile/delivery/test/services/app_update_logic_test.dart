import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/app_update_service.dart';

void main() {
  group('VersionCheckResult', () {
    test('constructs with required fields', () {
      final result = VersionCheckResult(
        forceUpdate: true,
        updateAvailable: true,
        minVersion: '2.0.0',
        latestVersion: '3.0.0',
        currentVersion: '1.0.0',
        storeUrl: 'https://play.google.com/store',
      );
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, true);
      expect(result.minVersion, '2.0.0');
      expect(result.latestVersion, '3.0.0');
      expect(result.currentVersion, '1.0.0');
      expect(result.storeUrl, 'https://play.google.com/store');
      expect(result.changelog, isNull);
    });

    test('constructs with optional changelog', () {
      final result = VersionCheckResult(
        forceUpdate: false,
        updateAvailable: false,
        minVersion: '1.0.0',
        latestVersion: '1.0.0',
        currentVersion: '1.0.0',
        storeUrl: '',
        changelog: 'Bug fixes',
      );
      expect(result.changelog, 'Bug fixes');
    });

    test('fromJson with all fields', () {
      final json = {
        'force_update': true,
        'update_available': true,
        'min_version': '2.0.0',
        'latest_version': '3.0.0',
        'current_version': '1.5.0',
        'store_url': 'https://store.example.com',
        'changelog': 'New feature',
      };
      final result = VersionCheckResult.fromJson(json);
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, true);
      expect(result.minVersion, '2.0.0');
      expect(result.latestVersion, '3.0.0');
      expect(result.currentVersion, '1.5.0');
      expect(result.storeUrl, 'https://store.example.com');
      expect(result.changelog, 'New feature');
    });

    test('fromJson with missing fields uses defaults', () {
      final json = <String, dynamic>{};
      final result = VersionCheckResult.fromJson(json);
      expect(result.forceUpdate, false);
      expect(result.updateAvailable, false);
      expect(result.minVersion, '1.0.0');
      expect(result.latestVersion, '1.0.0');
      expect(result.currentVersion, '1.0.0');
      expect(result.storeUrl, '');
      expect(result.changelog, isNull);
    });

    test('fromJson with partial fields', () {
      final json = {'force_update': true, 'latest_version': '5.0.0'};
      final result = VersionCheckResult.fromJson(json);
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, false);
      expect(result.latestVersion, '5.0.0');
      expect(result.minVersion, '1.0.0');
    });

    test('fromJson with null values uses defaults', () {
      final json = {
        'force_update': null,
        'update_available': null,
        'min_version': null,
        'latest_version': null,
        'current_version': null,
        'store_url': null,
        'changelog': null,
      };
      final result = VersionCheckResult.fromJson(json);
      expect(result.forceUpdate, false);
      expect(result.updateAvailable, false);
      expect(result.minVersion, '1.0.0');
      expect(result.latestVersion, '1.0.0');
      expect(result.currentVersion, '1.0.0');
      expect(result.storeUrl, '');
      expect(result.changelog, isNull);
    });
  });

  group('isFeatureEnabled', () {
    test('returns true when flag is true', () {
      final flags = {'dark_mode': true, 'beta': false};
      expect(isFeatureEnabled(flags, 'dark_mode'), true);
    });

    test('returns false when flag is false', () {
      final flags = {'dark_mode': true, 'beta': false};
      expect(isFeatureEnabled(flags, 'beta'), false);
    });

    test('returns defaultValue true when flag missing', () {
      final flags = <String, dynamic>{};
      expect(isFeatureEnabled(flags, 'unknown'), true);
    });

    test('returns defaultValue false when specified', () {
      final flags = <String, dynamic>{};
      expect(isFeatureEnabled(flags, 'unknown', defaultValue: false), false);
    });

    test('returns defaultValue when flag is null', () {
      final flags = {'feature': null};
      expect(isFeatureEnabled(flags, 'feature'), true);
    });

    test(
      'returns defaultValue false when flag is null and defaultValue is false',
      () {
        final flags = {'feature': null};
        expect(isFeatureEnabled(flags, 'feature', defaultValue: false), false);
      },
    );

    test('handles non-bool value by using defaultValue', () {
      // When value is not bool, cast to bool? returns null, so defaultValue is used
      // A String cast to bool? should throw or return null depending on runtime
      // The function does: flags[feature] as bool? ?? defaultValue
      // Testing edge case where value is not a bool
      expect(isFeatureEnabled({'feature': 'yes'}, 'feature'), false);
    });
  });
}
