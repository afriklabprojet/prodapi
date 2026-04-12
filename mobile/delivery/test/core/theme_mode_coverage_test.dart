import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/theme/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppThemeModeNotifier', () {
    test('initial state is light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final mode = container.read(appThemeModeProvider);
      expect(mode, AppThemeMode.light);
    });

    test('modeLabel returns Clair for light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appThemeModeProvider.notifier);
      expect(notifier.modeLabel, 'Clair');
    });

    test('modeIcon returns light_mode for light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appThemeModeProvider.notifier);
      expect(notifier.modeIcon, Icons.light_mode);
    });

    test('setMode to dark updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Read themeProvider first so it's available for setMode
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.dark);
      expect(container.read(appThemeModeProvider), AppThemeMode.dark);
      expect(notifier.modeLabel, 'Sombre');
    });

    test('setMode to system updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.system);
      expect(container.read(appThemeModeProvider), AppThemeMode.system);
      expect(notifier.modeLabel, 'Système');
    });

    test('setMode to auto updates state', () async {
      final container = ProviderContainer();
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.auto);
      expect(container.read(appThemeModeProvider), AppThemeMode.auto);
      expect(notifier.modeLabel, 'Intelligent');
      // Let _initAutoTheme async work complete before disposing
      await Future.delayed(const Duration(milliseconds: 300));
      container.dispose();
    });

    test('modeDescription for light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appThemeModeProvider.notifier);
      expect(notifier.modeDescription, 'Toujours en mode clair');
    });

    test('modeDescription for dark', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.dark);
      expect(notifier.modeDescription, 'Toujours en mode sombre');
    });

    test('modeDescription for system', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.system);
      expect(notifier.modeDescription, contains('appareil'));
    });

    test('setMode persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      final notifier = container.read(appThemeModeProvider.notifier);
      await notifier.setMode(AppThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');
    });

    test('loadMode restores persisted theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Initial state is light, then _loadMode runs via Future.microtask
      container.read(appThemeModeProvider);
      // Wait for microtask to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(container.read(appThemeModeProvider), AppThemeMode.dark);
    });

    test('loadMode restores system theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appThemeModeProvider);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(container.read(appThemeModeProvider), AppThemeMode.system);
    });
  });

  group('AppThemeMode enum', () {
    test('has 4 values', () {
      expect(AppThemeMode.values.length, 4);
    });

    test('values are light, dark, system, auto', () {
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.auto));
    });
  });
}
