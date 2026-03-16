import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/theme_service.dart';

void main() {
  group('ThemeMode', () {
    test('should have all expected values', () {
      expect(ThemeMode.values.length, 5);
      expect(ThemeMode.system.index, 0);
      expect(ThemeMode.light.index, 1);
      expect(ThemeMode.dark.index, 2);
      expect(ThemeMode.oled.index, 3);
      expect(ThemeMode.custom.index, 4);
    });
  });

  group('ColorVariant', () {
    test('should have all expected values', () {
      expect(ColorVariant.values.length, 8);
      expect(ColorVariant.blue.index, 0);
      expect(ColorVariant.green.index, 1);
      expect(ColorVariant.orange.index, 2);
      expect(ColorVariant.purple.index, 3);
      expect(ColorVariant.red.index, 4);
      expect(ColorVariant.teal.index, 5);
      expect(ColorVariant.pink.index, 6);
      expect(ColorVariant.custom.index, 7);
    });
  });

  group('ThemePreset', () {
    test('should create with all properties', () {
      const preset = ThemePreset(
        id: 'test_preset',
        name: 'Test Preset',
        primaryColor: Colors.blue,
        secondaryColor: Colors.cyan,
        backgroundColor: Colors.white,
        surfaceColor: Colors.grey,
        errorColor: Colors.red,
        isDark: false,
      );

      expect(preset.id, 'test_preset');
      expect(preset.name, 'Test Preset');
      expect(preset.primaryColor, Colors.blue);
      expect(preset.secondaryColor, Colors.cyan);
      expect(preset.backgroundColor, Colors.white);
      expect(preset.surfaceColor, Colors.grey);
      expect(preset.errorColor, Colors.red);
      expect(preset.isDark, false);
    });
  });

  group('CustomThemeSettings', () {
    test('should create with default values', () {
      const settings = CustomThemeSettings();

      expect(settings.primaryColor, const Color(0xFF2196F3));
      expect(settings.secondaryColor, const Color(0xFF03DAC6));
      expect(settings.backgroundColor, const Color(0xFFFFFFFF));
      expect(settings.surfaceColor, const Color(0xFFF5F5F5));
      expect(settings.textColor, const Color(0xFF212121));
      expect(settings.errorColor, const Color(0xFFB00020));
      expect(settings.borderRadius, 12.0);
      expect(settings.useMaterial3, true);
      expect(settings.fontFamily, isNull);
    });

    test('copyWith should update specified fields', () {
      const settings = CustomThemeSettings();

      final updated = settings.copyWith(
        primaryColor: Colors.green,
        borderRadius: 16.0,
        fontFamily: 'Roboto',
      );

      expect(updated.primaryColor, Colors.green);
      expect(updated.borderRadius, 16.0);
      expect(updated.fontFamily, 'Roboto');
      // Others should remain unchanged
      expect(updated.secondaryColor, const Color(0xFF03DAC6));
      expect(updated.useMaterial3, true);
    });
  });

  group('themePresets', () {
    test('should have multiple presets', () {
      expect(themePresets.length, greaterThanOrEqualTo(7));
    });

    test('each preset should have unique id', () {
      final ids = themePresets.map((p) => p.id).toSet();
      expect(ids.length, themePresets.length);
    });

    test('should have default light preset', () {
      final defaultLight = themePresets.firstWhere(
        (p) => p.id == 'default_light',
        orElse: () => throw Exception('Default light preset not found'),
      );
      expect(defaultLight.name, 'Clair par défaut');
      expect(defaultLight.isDark, false);
    });

    test('should have default dark preset', () {
      final defaultDark = themePresets.firstWhere(
        (p) => p.id == 'default_dark',
        orElse: () => throw Exception('Default dark preset not found'),
      );
      expect(defaultDark.name, 'Sombre par défaut');
      expect(defaultDark.isDark, true);
    });

    test('should have OLED preset', () {
      final oled = themePresets.firstWhere(
        (p) => p.id == 'oled',
        orElse: () => throw Exception('OLED preset not found'),
      );
      expect(oled.name, 'OLED Noir pur');
      expect(oled.isDark, true);
      expect(oled.backgroundColor, const Color(0xFF000000));
    });

    test('should have forest preset', () {
      final forest = themePresets.firstWhere(
        (p) => p.id == 'forest',
        orElse: () => throw Exception('Forest preset not found'),
      );
      expect(forest.name, 'Forêt');
      expect(forest.isDark, true);
    });

    test('should have ocean preset', () {
      final ocean = themePresets.firstWhere(
        (p) => p.id == 'ocean',
        orElse: () => throw Exception('Ocean preset not found'),
      );
      expect(ocean.name, 'Océan');
      expect(ocean.isDark, true);
    });

    test('should have sunset preset', () {
      final sunset = themePresets.firstWhere(
        (p) => p.id == 'sunset',
        orElse: () => throw Exception('Sunset preset not found'),
      );
      expect(sunset.name, 'Coucher de soleil');
      expect(sunset.isDark, true);
    });

    test('should have purple night preset', () {
      final purpleNight = themePresets.firstWhere(
        (p) => p.id == 'purple_night',
        orElse: () => throw Exception('Purple night preset not found'),
      );
      expect(purpleNight.name, 'Nuit violette');
      expect(purpleNight.isDark, true);
    });
  });

  group('AppThemeState', () {
    testWidgets('should create with default values', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();
      
      final state = AppThemeState(
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );

      expect(state.themeMode, ThemeMode.system);
      expect(state.colorVariant, ColorVariant.blue);
      expect(state.useOledBlack, false);
      expect(state.reducedMotion, false);
      expect(state.highContrast, false);
      expect(state.textScale, 1.0);
    });

    testWidgets('copyWith should update specified fields', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();
      
      final state = AppThemeState(
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );

      final updated = state.copyWith(
        themeMode: ThemeMode.dark,
        useOledBlack: true,
        textScale: 1.2,
      );

      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.useOledBlack, true);
      expect(updated.textScale, 1.2);
      // Others should remain unchanged
      expect(updated.colorVariant, ColorVariant.blue);
      expect(updated.reducedMotion, false);
    });

    testWidgets('isDark should return correct value for light mode', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );

      expect(state.isDark, false);
    });

    testWidgets('isDark should return true for dark mode', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.dark,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );

      expect(state.isDark, true);
    });

    testWidgets('isDark should return true for OLED mode', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.oled,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );

      expect(state.isDark, true);
    });

    testWidgets('activeTheme should return correct theme', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();

      final lightState = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );
      expect(lightState.activeTheme, lightTheme);

      final darkState = AppThemeState(
        themeMode: ThemeMode.dark,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );
      expect(darkState.activeTheme, darkTheme);
    });
  });
}
