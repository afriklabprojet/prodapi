import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    setUp(() {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    test('should have light theme mode by default', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Wait for provider to initialize
      await Future.delayed(const Duration(milliseconds: 100));
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('should persist theme mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Change theme to dark
      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      
      // Verify the change
      expect(container.read(themeProvider), ThemeMode.dark);
      
      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('should load saved theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('should toggle between light and dark mode', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Force initialization and wait for _loadTheme to complete
      container.read(themeProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));
      
      expect(container.read(themeProvider), ThemeMode.light);
      
      await container.read(themeProvider.notifier).toggleTheme();
      
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('should toggle from dark back to light', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Explicitly set dark first (reliable, no async race)
      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);

      await container.read(themeProvider.notifier).toggleTheme();
      
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('should load saved dark theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Force read of the notifier to trigger build() + _loadTheme()
      container.read(themeProvider.notifier);
      
      // Give microtasks and timer callbacks time to complete
      await Future.delayed(const Duration(milliseconds: 100));
      // Re-pump to ensure state update propagated
      await Future.delayed(const Duration(milliseconds: 100));
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('should load saved system theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Force read of the notifier to trigger build() + _loadTheme()
      container.read(themeProvider.notifier);
      
      // Give microtasks and timer callbacks time to complete
      await Future.delayed(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 100));
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.system);
    });

    test('should fallback to light for invalid saved theme', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid_mode'});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('isDark getter works', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(container.read(themeProvider.notifier).isDark, isFalse);
      
      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider.notifier).isDark, isTrue);
    });

    test('isLight getter works', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(container.read(themeProvider.notifier).isLight, isTrue);
      
      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider.notifier).isLight, isFalse);
    });

    test('isSystem getter works', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(container.read(themeProvider.notifier).isSystem, isFalse);
      
      await container.read(themeProvider.notifier).setTheme(ThemeMode.system);
      expect(container.read(themeProvider.notifier).isSystem, isTrue);
    });

    test('setTheme to system mode', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await container.read(themeProvider.notifier).setTheme(ThemeMode.system);
      
      expect(container.read(themeProvider), ThemeMode.system);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'system');
    });
  });

  group('Light Theme Tests', () {
    test('should use Material 3', () {
      expect(lightTheme.useMaterial3, isTrue);
    });

    test('should have correct scaffold background', () {
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8F9FD));
    });

    test('should have correct app bar theme', () {
      expect(lightTheme.appBarTheme.backgroundColor, Colors.white);
      expect(lightTheme.appBarTheme.foregroundColor, Colors.black);
      expect(lightTheme.appBarTheme.centerTitle, isTrue);
    });
  });

  group('Dark Theme Tests', () {
    test('should use Material 3', () {
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('should have dark scaffold background', () {
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF121212));
    });

    test('should have correct app bar theme', () {
      expect(darkTheme.appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
      expect(darkTheme.appBarTheme.foregroundColor, Colors.white);
      expect(darkTheme.appBarTheme.centerTitle, isTrue);
    });

    test('should have correct card theme', () {
      expect(darkTheme.cardTheme.color, const Color(0xFF1E1E1E));
      expect(darkTheme.cardTheme.elevation, 4);
    });

    test('should have correct bottom nav bar theme', () {
      expect(darkTheme.bottomNavigationBarTheme.backgroundColor, const Color(0xFF1E1E1E));
      expect(darkTheme.bottomNavigationBarTheme.selectedItemColor, const Color(0xFF6EC889));
      expect(darkTheme.bottomNavigationBarTheme.unselectedItemColor, Colors.grey);
    });

    test('should have correct bottom sheet theme', () {
      expect(darkTheme.bottomSheetTheme.backgroundColor, const Color(0xFF1E1E1E));
    });

    test('should have correct divider theme', () {
      expect(darkTheme.dividerTheme.color, const Color(0xFF2C2C2C));
    });

    test('should have correct list tile theme', () {
      expect(darkTheme.listTileTheme.iconColor, Colors.white70);
      expect(darkTheme.listTileTheme.textColor, Colors.white);
    });
  });

  group('Light Theme detailed', () {
    test('should have correct bottom nav bar', () {
      expect(lightTheme.bottomNavigationBarTheme.backgroundColor, Colors.white);
      expect(lightTheme.bottomNavigationBarTheme.selectedItemColor, const Color(0xFF54AB70));
    });

    test('should have correct card theme', () {
      expect(lightTheme.cardTheme.color, Colors.white);
      expect(lightTheme.cardTheme.elevation, 2);
    });
  });
}
