import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/auto_theme_service.dart';

void main() {
  group('AutoThemeService - persistence methods', () {
    late AutoThemeService service;

    setUp(() async {
      // Reset prefs before each test
      SharedPreferences.setMockInitialValues({});
      service = AutoThemeService.instance;
      // Dispose to clear old timer/callback
      service.dispose();
      // Init with fresh prefs
      await service.init();
    });

    tearDown(() {
      service.dispose();
    });

    test('setNightStartHour persists to prefs', () async {
      await service.setNightStartHour(22);
      expect(service.nightStartHour, 22);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('night_start_hour'), 22);
    });

    test('setNightStartHour clamps below 0', () async {
      await service.setNightStartHour(-1);
      expect(service.nightStartHour, 0);
    });

    test('setNightStartHour clamps above 23', () async {
      await service.setNightStartHour(30);
      expect(service.nightStartHour, 23);
    });

    test('setNightEndHour persists to prefs', () async {
      await service.setNightEndHour(8);
      expect(service.nightEndHour, 8);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('night_end_hour'), 8);
    });

    test('setNightEndHour clamps below 0', () async {
      await service.setNightEndHour(-5);
      expect(service.nightEndHour, 0);
    });

    test('setNightEndHour clamps above 23', () async {
      await service.setNightEndHour(50);
      expect(service.nightEndHour, 23);
    });

    test('setEnabled true starts auto-check', () async {
      await service.setEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auto_theme_enabled'), true);
      expect(service.isEnabled, true);

      await service.setEnabled(false);
    });

    test('setEnabled false stops auto-check', () async {
      await service.setEnabled(true);
      await service.setEnabled(false);

      expect(service.isEnabled, false);
    });

    test('checkNow runs without error when enabled', () async {
      await service.setEnabled(true);
      service.checkNow(); // should not throw
      await service.setEnabled(false);
    });

    test('getStatusDescription contains Mode actif when enabled', () async {
      await service.setEnabled(true);
      final desc = service.getStatusDescription();
      expect(desc, contains('Mode'));
      expect(desc, contains('actif'));
      await service.setEnabled(false);
    });

    test('getIcon returns emoji when enabled', () async {
      await service.setEnabled(true);
      final icon = service.getIcon();
      expect(icon == '🌙' || icon == '☀️', true);
      await service.setEnabled(false);
    });

    test('dispose clears callback', () async {
      service.onThemeChange = (isDark) {};
      service.dispose();
      expect(service.onThemeChange, isNull);
    });
  });
}
