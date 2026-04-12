import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/core/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    notifier = ThemeNotifier(prefs);
    // Wait for _loadTheme async init
    await Future.microtask(() {});
  });

  // ── ThemeState ────────────────────────────────────────
  group('ThemeState', () {
    test('default state is system mode', () {
      const s = ThemeState();
      expect(s.appThemeMode, AppThemeMode.system);
      expect(s.themeMode, ThemeMode.system);
      expect(s.isSystemMode, true);
    });

    test('isLightMode is opposite of isDarkMode', () {
      const s = ThemeState(
        appThemeMode: AppThemeMode.light,
        themeMode: ThemeMode.light,
      );
      expect(s.isLightMode, true);
      expect(s.isDarkMode, false);
    });

    test('isDarkMode true for dark mode', () {
      const s = ThemeState(
        appThemeMode: AppThemeMode.dark,
        themeMode: ThemeMode.dark,
      );
      expect(s.isDarkMode, true);
    });

    test('isSystemMode false for explicit light', () {
      const s = ThemeState(
        appThemeMode: AppThemeMode.light,
        themeMode: ThemeMode.light,
      );
      expect(s.isSystemMode, false);
    });

    test('copyWith overrides appThemeMode and themeMode', () {
      const s = ThemeState();
      final s2 = s.copyWith(
        appThemeMode: AppThemeMode.dark,
        themeMode: ThemeMode.dark,
      );
      expect(s2.appThemeMode, AppThemeMode.dark);
      expect(s2.themeMode, ThemeMode.dark);
    });

    test('copyWith preserves unchanged fields', () {
      const s = ThemeState(
        appThemeMode: AppThemeMode.dark,
        themeMode: ThemeMode.dark,
      );
      final s2 = s.copyWith();
      expect(s2.appThemeMode, AppThemeMode.dark);
      expect(s2.themeMode, ThemeMode.dark);
    });

    test('equality with same values', () {
      const s1 = ThemeState(
        appThemeMode: AppThemeMode.light,
        themeMode: ThemeMode.light,
      );
      const s2 = ThemeState(
        appThemeMode: AppThemeMode.light,
        themeMode: ThemeMode.light,
      );
      expect(s1, s2);
    });

    test('inequality with different values', () {
      const s1 = ThemeState(appThemeMode: AppThemeMode.light);
      const s2 = ThemeState(
        appThemeMode: AppThemeMode.dark,
        themeMode: ThemeMode.dark,
      );
      expect(s1, isNot(s2));
    });

    test('hashCode is consistent', () {
      const s = ThemeState(
        appThemeMode: AppThemeMode.dark,
        themeMode: ThemeMode.dark,
      );
      expect(s.hashCode, s.hashCode);
    });
  });

  // ── ThemeNotifier.setAppThemeMode ─────────────────────
  group('ThemeNotifier.setAppThemeMode', () {
    test('setDarkMode updates state and persists', () async {
      await notifier.setDarkMode();
      expect(notifier.state.appThemeMode, AppThemeMode.dark);
      expect(notifier.state.themeMode, ThemeMode.dark);
    });

    test('setLightMode updates state', () async {
      await notifier.setLightMode();
      expect(notifier.state.appThemeMode, AppThemeMode.light);
      expect(notifier.state.themeMode, ThemeMode.light);
    });

    test('setSystemMode updates state', () async {
      await notifier.setDarkMode();
      await notifier.setSystemMode();
      expect(notifier.state.appThemeMode, AppThemeMode.system);
      expect(notifier.state.themeMode, ThemeMode.system);
    });
  });

  // ── ThemeNotifier.setTheme (legacy) ───────────────────
  group('ThemeNotifier.setTheme', () {
    test('ThemeMode.dark → AppThemeMode.dark', () async {
      await notifier.setTheme(ThemeMode.dark);
      expect(notifier.state.appThemeMode, AppThemeMode.dark);
    });

    test('ThemeMode.light → AppThemeMode.light', () async {
      await notifier.setTheme(ThemeMode.light);
      expect(notifier.state.appThemeMode, AppThemeMode.light);
    });

    test('ThemeMode.system → AppThemeMode.system', () async {
      await notifier.setTheme(ThemeMode.system);
      expect(notifier.state.appThemeMode, AppThemeMode.system);
    });
  });

  // ── ThemeNotifier.toggleTheme ────────────────────────
  group('ThemeNotifier.toggleTheme', () {
    test('toggles from light to dark', () async {
      await notifier.setLightMode();
      await notifier.toggleTheme();
      expect(notifier.state.appThemeMode, AppThemeMode.dark);
    });

    test('toggles from dark to light', () async {
      await notifier.setDarkMode();
      await notifier.toggleTheme();
      expect(notifier.state.appThemeMode, AppThemeMode.light);
    });
  });

  // ── ThemeNotifier persistence (reload) ───────────────
  group('ThemeNotifier persistence', () {
    test('reloads saved theme from prefs on construction', () async {
      await notifier.setDarkMode();

      // Create new notifier with same prefs instance
      final prefs = await SharedPreferences.getInstance();
      final notifier2 = ThemeNotifier(prefs);
      await Future.microtask(() {});

      expect(notifier2.state.appThemeMode, AppThemeMode.dark);
    });

    test('defaults to system mode when no saved theme', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier2 = ThemeNotifier(prefs);
      await Future.microtask(() {});

      expect(notifier2.state.appThemeMode, AppThemeMode.system);
    });
  });
}
