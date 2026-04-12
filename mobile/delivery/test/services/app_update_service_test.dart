import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/app_update_service.dart';

void main() {
  group('VersionCheckResult', () {
    test('creates from full JSON', () {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'update_available': true,
        'min_version': '2.0.0',
        'latest_version': '2.1.0',
        'current_version': '1.5.0',
        'store_url':
            'https://play.google.com/store/apps/details?id=com.drpharma.courier',
        'changelog': 'New features and bug fixes',
      });
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, true);
      expect(result.minVersion, '2.0.0');
      expect(result.latestVersion, '2.1.0');
      expect(result.currentVersion, '1.5.0');
      expect(result.storeUrl, contains('play.google.com'));
      expect(result.changelog, 'New features and bug fixes');
    });

    test('fromJson uses defaults for missing fields', () {
      final result = VersionCheckResult.fromJson({});
      expect(result.forceUpdate, false);
      expect(result.updateAvailable, false);
      expect(result.minVersion, '1.0.0');
      expect(result.latestVersion, '1.0.0');
      expect(result.currentVersion, '1.0.0');
      expect(result.storeUrl, '');
      expect(result.changelog, isNull);
    });

    test('fromJson with partial data', () {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'latest_version': '3.0.0',
      });
      expect(result.forceUpdate, true);
      expect(result.updateAvailable, false);
      expect(result.latestVersion, '3.0.0');
    });

    test('fromJson preserves iOS store URL', () {
      final result = VersionCheckResult.fromJson({
        'store_url': 'https://apps.apple.com/app/id123456789',
      });
      expect(result.storeUrl, contains('apps.apple.com'));
    });

    test('fromJson with long changelog', () {
      final longChangelog = 'Bug fix ' * 100;
      final result = VersionCheckResult.fromJson({'changelog': longChangelog});
      expect(result.changelog, longChangelog);
    });

    test('fromJson with null changelog', () {
      final result = VersionCheckResult.fromJson({'changelog': null});
      expect(result.changelog, isNull);
    });
  });

  group('isFeatureEnabled', () {
    test('returns true when feature is enabled', () {
      final flags = {'dark_mode': true, 'chat': false};
      expect(isFeatureEnabled(flags, 'dark_mode'), true);
    });

    test('returns false when feature is disabled', () {
      final flags = {'dark_mode': true, 'chat': false};
      expect(isFeatureEnabled(flags, 'chat'), false);
    });

    test('returns default value when feature not in flags', () {
      final flags = <String, dynamic>{};
      expect(isFeatureEnabled(flags, 'unknown'), true);
      expect(isFeatureEnabled(flags, 'unknown', defaultValue: false), false);
    });

    test('throws when value is not bool', () {
      final flags = {'feature': 'yes'};
      expect(
        () => isFeatureEnabled(flags, 'feature'),
        throwsA(isA<TypeError>()),
      );
    });

    test('returns true for explicitly true feature', () {
      final flags = {'new_feature': true};
      expect(isFeatureEnabled(flags, 'new_feature', defaultValue: false), true);
    });

    test('returns false for explicitly false feature ignoring default', () {
      final flags = {'disabled_feature': false};
      expect(
        isFeatureEnabled(flags, 'disabled_feature', defaultValue: true),
        false,
      );
    });

    test('handles multiple features', () {
      final flags = {'a': true, 'b': false, 'c': true};
      expect(isFeatureEnabled(flags, 'a'), true);
      expect(isFeatureEnabled(flags, 'b'), false);
      expect(isFeatureEnabled(flags, 'c'), true);
      expect(isFeatureEnabled(flags, 'd'), true);
    });
  });

  group('ForceUpdateDialog', () {
    testWidgets('displays title and icon', (tester) async {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'current_version': '1.0.0',
        'min_version': '2.0.0',
        'latest_version': '2.1.0',
        'changelog': 'Important security update',
        'store_url': 'https://play.google.com/store/apps/details?id=test',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ForceUpdateDialog(result: result)),
        ),
      );

      expect(find.text('Mise à jour requise'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });

    testWidgets('displays changelog', (tester) async {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'current_version': '1.0.0',
        'min_version': '2.0.0',
        'changelog': 'Security fixes and improvements',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ForceUpdateDialog(result: result)),
        ),
      );

      expect(find.text('Security fixes and improvements'), findsOneWidget);
    });

    testWidgets('displays default message when no changelog', (tester) async {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'current_version': '1.0.0',
        'min_version': '2.0.0',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ForceUpdateDialog(result: result)),
        ),
      );

      expect(find.textContaining('mise à jour critique'), findsOneWidget);
    });

    testWidgets('displays version info', (tester) async {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'current_version': '1.5.0',
        'min_version': '2.0.0',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ForceUpdateDialog(result: result)),
        ),
      );

      expect(find.textContaining('Version actuelle: 1.5.0'), findsOneWidget);
      expect(find.textContaining('Version requise: 2.0.0'), findsOneWidget);
    });

    testWidgets('has update button', (tester) async {
      final result = VersionCheckResult.fromJson({
        'force_update': true,
        'current_version': '1.0.0',
        'min_version': '2.0.0',
        'store_url': 'https://play.google.com/store/apps/details?id=test',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ForceUpdateDialog(result: result)),
        ),
      );

      expect(find.text('Mettre à jour'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('UpdateAvailableBanner', () {
    testWidgets('displays new version message', (tester) async {
      final result = VersionCheckResult.fromJson({
        'update_available': true,
        'latest_version': '2.5.0',
        'store_url': 'https://example.com/app',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateAvailableBanner(result: result)),
        ),
      );

      expect(find.textContaining('2.5.0'), findsOneWidget);
      expect(find.textContaining('Nouvelle version'), findsOneWidget);
    });

    testWidgets('displays info icon', (tester) async {
      final result = VersionCheckResult.fromJson({
        'update_available': true,
        'latest_version': '3.0.0',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateAvailableBanner(result: result)),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('has Plus tard button', (tester) async {
      final result = VersionCheckResult.fromJson({
        'update_available': true,
        'latest_version': '2.0.0',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateAvailableBanner(result: result)),
        ),
      );

      expect(find.text('Plus tard'), findsOneWidget);
    });

    testWidgets('calls onDismiss when Plus tard tapped', (tester) async {
      bool dismissed = false;
      final result = VersionCheckResult.fromJson({
        'update_available': true,
        'latest_version': '2.0.0',
        'store_url': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateAvailableBanner(
              result: result,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Plus tard'));
      expect(dismissed, isTrue);
    });

    testWidgets('has Mettre à jour button', (tester) async {
      final result = VersionCheckResult.fromJson({
        'update_available': true,
        'latest_version': '2.0.0',
        'store_url': 'https://example.com',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateAvailableBanner(result: result)),
        ),
      );

      expect(find.text('Mettre à jour'), findsOneWidget);
    });
  });
}
