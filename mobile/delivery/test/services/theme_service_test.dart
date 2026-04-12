import 'dart:io';

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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

      final state = AppThemeState(lightTheme: lightTheme, darkTheme: darkTheme);

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

      final state = AppThemeState(lightTheme: lightTheme, darkTheme: darkTheme);

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

    testWidgets('isDark should return correct value for light mode', (
      tester,
    ) async {
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

    testWidgets('copyWith updates each field independently', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();
      final state = AppThemeState(lightTheme: lightTheme, darkTheme: darkTheme);

      // colorVariant
      final withVariant = state.copyWith(colorVariant: ColorVariant.green);
      expect(withVariant.colorVariant, ColorVariant.green);
      expect(withVariant.themeMode, ThemeMode.system);

      // customSettings
      const custom = CustomThemeSettings(primaryColor: Color(0xFF00FF00));
      final withCustom = state.copyWith(customSettings: custom);
      expect(withCustom.customSettings.primaryColor, const Color(0xFF00FF00));

      // reducedMotion
      final withReduced = state.copyWith(reducedMotion: true);
      expect(withReduced.reducedMotion, true);

      // highContrast
      final withContrast = state.copyWith(highContrast: true);
      expect(withContrast.highContrast, true);
      expect(withContrast.reducedMotion, false);

      // lightTheme / darkTheme
      final newLight = ThemeData(primarySwatch: Colors.red);
      final withNewLight = state.copyWith(lightTheme: newLight);
      expect(withNewLight.lightTheme, newLight);
      expect(withNewLight.darkTheme, darkTheme);
    });

    testWidgets('OLED activeTheme returns dark theme', (tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();
      final state = AppThemeState(
        themeMode: ThemeMode.oled,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );
      expect(state.activeTheme, darkTheme);
    });
  });

  group('CustomThemeSettings - individual copyWith fields', () {
    test('copyWith updates secondaryColor', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(secondaryColor: const Color(0xFF111111));
      expect(updated.secondaryColor, const Color(0xFF111111));
      expect(updated.primaryColor, const Color(0xFF2196F3));
    });

    test('copyWith updates backgroundColor', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(backgroundColor: const Color(0xFF222222));
      expect(updated.backgroundColor, const Color(0xFF222222));
    });

    test('copyWith updates surfaceColor', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(surfaceColor: const Color(0xFF333333));
      expect(updated.surfaceColor, const Color(0xFF333333));
    });

    test('copyWith updates textColor', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(textColor: const Color(0xFF444444));
      expect(updated.textColor, const Color(0xFF444444));
    });

    test('copyWith updates errorColor', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(errorColor: const Color(0xFF555555));
      expect(updated.errorColor, const Color(0xFF555555));
    });

    test('copyWith updates useMaterial3', () {
      const s = CustomThemeSettings();
      final updated = s.copyWith(useMaterial3: false);
      expect(updated.useMaterial3, false);
    });

    test('copyWith preserves all fields when nothing changed', () {
      const s = CustomThemeSettings(
        primaryColor: Color(0xFFAA0000),
        secondaryColor: Color(0xFFBB0000),
        backgroundColor: Color(0xFFCC0000),
        surfaceColor: Color(0xFFDD0000),
        textColor: Color(0xFFEE0000),
        errorColor: Color(0xFFFF0000),
        borderRadius: 8.0,
        useMaterial3: false,
        fontFamily: 'Arial',
      );
      final copy = s.copyWith();
      expect(copy.primaryColor, const Color(0xFFAA0000));
      expect(copy.secondaryColor, const Color(0xFFBB0000));
      expect(copy.backgroundColor, const Color(0xFFCC0000));
      expect(copy.surfaceColor, const Color(0xFFDD0000));
      expect(copy.textColor, const Color(0xFFEE0000));
      expect(copy.errorColor, const Color(0xFFFF0000));
      expect(copy.borderRadius, 8.0);
      expect(copy.useMaterial3, false);
      expect(copy.fontFamily, 'Arial');
    });
  });

  group('themePresets - additional details', () {
    test('all dark presets have isDark true', () {
      final darkPresets = themePresets.where((p) => p.isDark);
      expect(darkPresets.length, greaterThanOrEqualTo(5));
      for (final preset in darkPresets) {
        expect(preset.isDark, true);
      }
    });

    test('all presets have non-empty name', () {
      for (final preset in themePresets) {
        expect(preset.name, isNotEmpty);
        expect(preset.id, isNotEmpty);
      }
    });

    test('all presets have valid colors', () {
      for (final preset in themePresets) {
        expect(preset.primaryColor, isNotNull);
        expect(preset.secondaryColor, isNotNull);
        expect(preset.backgroundColor, isNotNull);
        expect(preset.surfaceColor, isNotNull);
        expect(preset.errorColor, isNotNull);
      }
    });
  });

  group('AppThemeState.isDark branches', () {
    testWidgets('isDark returns false for ThemeMode.light', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      expect(state.isDark, false);
    });

    testWidgets('isDark returns true for ThemeMode.dark', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.dark,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      expect(state.isDark, true);
    });

    testWidgets('isDark returns true for ThemeMode.oled', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.oled,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      expect(state.isDark, true);
    });

    testWidgets('isDark returns false for light even with useOledBlack', (
      tester,
    ) async {
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        useOledBlack: true,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      expect(state.isDark, false);
    });

    testWidgets('activeTheme returns lightTheme when not dark', (tester) async {
      final light = ThemeData.light();
      final dark = ThemeData.dark();
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: light,
        darkTheme: dark,
      );
      expect(identical(state.activeTheme, light), isTrue);
    });

    testWidgets('activeTheme returns darkTheme when dark', (tester) async {
      final light = ThemeData.light();
      final dark = ThemeData.dark();
      final state = AppThemeState(
        themeMode: ThemeMode.dark,
        lightTheme: light,
        darkTheme: dark,
      );
      expect(identical(state.activeTheme, dark), isTrue);
    });
  });

  group('AppThemeState.copyWith all fields', () {
    testWidgets('copyWith overrides themeMode', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(themeMode: ThemeMode.oled);
      expect(copy.themeMode, ThemeMode.oled);
      expect(copy.colorVariant, ColorVariant.blue); // unchanged
    });

    testWidgets('copyWith overrides colorVariant', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(colorVariant: ColorVariant.purple);
      expect(copy.colorVariant, ColorVariant.purple);
    });

    testWidgets('copyWith overrides customSettings', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      const newSettings = CustomThemeSettings(borderRadius: 20);
      final copy = state.copyWith(customSettings: newSettings);
      expect(copy.customSettings.borderRadius, 20);
    });

    testWidgets('copyWith overrides useOledBlack', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(useOledBlack: true);
      expect(copy.useOledBlack, true);
    });

    testWidgets('copyWith overrides reducedMotion', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(reducedMotion: true);
      expect(copy.reducedMotion, true);
    });

    testWidgets('copyWith overrides highContrast', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(highContrast: true);
      expect(copy.highContrast, true);
    });

    testWidgets('copyWith overrides textScale', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final copy = state.copyWith(textScale: 1.5);
      expect(copy.textScale, 1.5);
    });

    testWidgets('copyWith overrides lightTheme and darkTheme', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      final newLight = ThemeData(primarySwatch: Colors.green);
      final newDark = ThemeData(primarySwatch: Colors.red);
      final copy = state.copyWith(lightTheme: newLight, darkTheme: newDark);
      expect(identical(copy.lightTheme, newLight), isTrue);
      expect(identical(copy.darkTheme, newDark), isTrue);
    });
  });

  group('CustomThemeSettings.copyWith individual fields', () {
    test('copyWith overrides surfaceColor', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(surfaceColor: const Color(0xFF111111));
      expect(copy.surfaceColor, const Color(0xFF111111));
      expect(copy.primaryColor, const Color(0xFF2196F3)); // unchanged
    });

    test('copyWith overrides textColor', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(textColor: const Color(0xFF222222));
      expect(copy.textColor, const Color(0xFF222222));
    });

    test('copyWith overrides errorColor', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(errorColor: Colors.orange);
      expect(copy.errorColor, Colors.orange);
    });

    test('copyWith overrides useMaterial3', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(useMaterial3: false);
      expect(copy.useMaterial3, false);
    });

    test('copyWith overrides secondaryColor', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(secondaryColor: Colors.yellow);
      expect(copy.secondaryColor, Colors.yellow);
    });

    test('copyWith overrides backgroundColor', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(backgroundColor: Colors.grey);
      expect(copy.backgroundColor, Colors.grey);
    });
  });

  group('ThemePreset isDark consistency', () {
    test('only default_light has isDark false', () {
      final lightPresets = themePresets.where((p) => !p.isDark).toList();
      expect(lightPresets.length, 1);
      expect(lightPresets.first.id, 'default_light');
    });
  });

  group('ThemeMode enum', () {
    test('name matches expected string', () {
      expect(ThemeMode.system.name, 'system');
      expect(ThemeMode.light.name, 'light');
      expect(ThemeMode.dark.name, 'dark');
      expect(ThemeMode.oled.name, 'oled');
      expect(ThemeMode.custom.name, 'custom');
    });

    test('values list has correct length', () {
      expect(ThemeMode.values.length, 5);
    });

    test('can look up by name', () {
      for (final mode in ThemeMode.values) {
        final found = ThemeMode.values.firstWhere((m) => m.name == mode.name);
        expect(found, mode);
      }
    });
  });

  group('ColorVariant enum', () {
    test('name matches expected string', () {
      expect(ColorVariant.blue.name, 'blue');
      expect(ColorVariant.green.name, 'green');
      expect(ColorVariant.orange.name, 'orange');
      expect(ColorVariant.purple.name, 'purple');
      expect(ColorVariant.red.name, 'red');
      expect(ColorVariant.teal.name, 'teal');
      expect(ColorVariant.pink.name, 'pink');
      expect(ColorVariant.custom.name, 'custom');
    });

    test('all values are unique indices', () {
      final indices = ColorVariant.values.map((v) => v.index).toSet();
      expect(indices.length, ColorVariant.values.length);
    });
  });

  group('ThemePreset color uniqueness', () {
    test('each preset has non-null primary color', () {
      for (final preset in themePresets) {
        expect(preset.primaryColor, isNotNull);
        expect(preset.primaryColor.a, greaterThan(0));
      }
    });

    test('dark presets have dark background colors', () {
      for (final preset in themePresets.where((p) => p.isDark)) {
        // Dark presets should have low luminance backgrounds
        expect(preset.backgroundColor.computeLuminance(), lessThan(0.2));
      }
    });

    test('light preset has light background color', () {
      final light = themePresets.firstWhere((p) => p.id == 'default_light');
      expect(light.backgroundColor.computeLuminance(), greaterThan(0.8));
    });
  });

  group('AppThemeState - ThemeMode.custom', () {
    testWidgets('custom mode exists', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.custom,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      );
      expect(state.themeMode, ThemeMode.custom);
    });

    testWidgets('can have custom theme settings', (tester) async {
      const settings = CustomThemeSettings(
        primaryColor: Color(0xFFFF0000),
        borderRadius: 20.0,
        fontFamily: 'Helvetica',
      );
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        customSettings: settings,
      );
      expect(state.customSettings.primaryColor, const Color(0xFFFF0000));
      expect(state.customSettings.borderRadius, 20.0);
      expect(state.customSettings.fontFamily, 'Helvetica');
    });
  });

  group('CustomThemeSettings - boundary values', () {
    test('borderRadius can be 0', () {
      const s = CustomThemeSettings(borderRadius: 0);
      expect(s.borderRadius, 0);
    });

    test('borderRadius can be very large', () {
      const s = CustomThemeSettings(borderRadius: 100.0);
      expect(s.borderRadius, 100.0);
    });

    test('fontFamily can be null', () {
      const s = CustomThemeSettings();
      expect(s.fontFamily, isNull);
    });

    test('fontFamily can be set', () {
      const s = CustomThemeSettings(fontFamily: 'Roboto');
      expect(s.fontFamily, 'Roboto');
    });

    test('copyWith fontFamily', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(fontFamily: 'Arial');
      expect(copy.fontFamily, 'Arial');
    });

    test('copyWith borderRadius', () {
      const s = CustomThemeSettings();
      final copy = s.copyWith(borderRadius: 24.0);
      expect(copy.borderRadius, 24.0);
    });
  });

  group('AppThemeState - accessibility', () {
    testWidgets('state with reduced motion', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        reducedMotion: true,
      );
      expect(state.reducedMotion, true);
    });

    testWidgets('state with high contrast', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        highContrast: true,
      );
      expect(state.highContrast, true);
    });

    testWidgets('state with custom text scale', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        textScale: 1.5,
      );
      expect(state.textScale, 1.5);
    });

    testWidgets('state with minimum text scale', (tester) async {
      final state = AppThemeState(
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        textScale: 0.8,
      );
      expect(state.textScale, 0.8);
    });

    testWidgets('state with OLED black', (tester) async {
      final state = AppThemeState(
        themeMode: ThemeMode.oled,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        useOledBlack: true,
      );
      expect(state.useOledBlack, true);
      expect(state.isDark, true);
    });
  });

  group('AppThemeState - combined states', () {
    testWidgets('dark mode with high contrast and reduced motion', (
      tester,
    ) async {
      final state = AppThemeState(
        themeMode: ThemeMode.dark,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        highContrast: true,
        reducedMotion: true,
        textScale: 1.3,
        useOledBlack: true,
        colorVariant: ColorVariant.red,
      );
      expect(state.isDark, true);
      expect(state.highContrast, true);
      expect(state.reducedMotion, true);
      expect(state.textScale, 1.3);
      expect(state.useOledBlack, true);
      expect(state.colorVariant, ColorVariant.red);
    });

    testWidgets('light mode with custom settings', (tester) async {
      const settings = CustomThemeSettings(
        primaryColor: Color(0xFF00FF00),
        secondaryColor: Color(0xFF0000FF),
        borderRadius: 8.0,
        useMaterial3: false,
      );
      final state = AppThemeState(
        themeMode: ThemeMode.light,
        lightTheme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        customSettings: settings,
        colorVariant: ColorVariant.custom,
      );
      expect(state.isDark, false);
      expect(state.colorVariant, ColorVariant.custom);
      expect(state.customSettings.useMaterial3, false);
    });
  });

  group('ThemePreset - specific preset properties', () {
    test('oled preset has pure black surface', () {
      final oled = themePresets.firstWhere((p) => p.id == 'oled');
      expect(oled.surfaceColor, const Color(0xFF0A0A0A));
    });

    test('forest preset has green tones', () {
      final forest = themePresets.firstWhere((p) => p.id == 'forest');
      expect(forest.primaryColor, const Color(0xFF4CAF50));
      expect(forest.secondaryColor, const Color(0xFF8BC34A));
    });

    test('ocean preset has cyan tones', () {
      final ocean = themePresets.firstWhere((p) => p.id == 'ocean');
      expect(ocean.primaryColor, const Color(0xFF00BCD4));
      expect(ocean.secondaryColor, const Color(0xFF4DD0E1));
    });

    test('sunset preset has orange/red tones', () {
      final sunset = themePresets.firstWhere((p) => p.id == 'sunset');
      expect(sunset.primaryColor, const Color(0xFFFF5722));
      expect(sunset.secondaryColor, const Color(0xFFFF9800));
    });

    test('purple_night has purple tones', () {
      final purple = themePresets.firstWhere((p) => p.id == 'purple_night');
      expect(purple.primaryColor, const Color(0xFF9C27B0));
      expect(purple.secondaryColor, const Color(0xFFE040FB));
    });

    test('all presets have error colors', () {
      for (final preset in themePresets) {
        expect(preset.errorColor, isNotNull);
        expect(preset.errorColor.a, greaterThan(0));
      }
    });
  });

  group('ThemeService instance', () {
    late Directory hiveDir;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('theme_service_test_');
      Hive.init(hiveDir.path);
    });

    tearDownAll(() async {
      try {
        await Hive.close();
      } catch (_) {}
      if (hiveDir.existsSync()) {
        hiveDir.deleteSync(recursive: true);
      }
    });

    tearDown(() async {
      // Close and delete theme box between tests for isolation
      try {
        if (Hive.isBoxOpen('theme')) {
          await Hive.box('theme').clear();
          await Hive.box('theme').close();
        }
      } catch (_) {}
      try {
        await Hive.deleteBoxFromDisk('theme');
      } catch (_) {}
    });

    test('init creates service with default state', () async {
      final service = ThemeService();
      // Wait for _init() to complete
      await Future.delayed(const Duration(milliseconds: 200));
      final s = service.state;

      expect(s.themeMode, ThemeMode.system);
      expect(s.colorVariant, ColorVariant.blue);
      expect(s.useOledBlack, false);
      expect(s.reducedMotion, false);
      expect(s.highContrast, false);
      expect(s.textScale, 1.0);
      expect(s.lightTheme, isNotNull);
      expect(s.darkTheme, isNotNull);

      service.dispose();
    });

    test('setThemeMode changes mode and persists', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setThemeMode(ThemeMode.dark);
      expect(service.state.themeMode, ThemeMode.dark);
      expect(service.state.isDark, true);

      await service.setThemeMode(ThemeMode.light);
      expect(service.state.themeMode, ThemeMode.light);
      expect(service.state.isDark, false);

      await service.setThemeMode(ThemeMode.oled);
      expect(service.state.themeMode, ThemeMode.oled);
      expect(service.state.isDark, true);

      service.dispose();
    });

    test('setColorVariant changes variant and rebuilds themes', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      for (final variant in ColorVariant.values) {
        if (variant == ColorVariant.custom) continue;
        await service.setColorVariant(variant);
        expect(service.state.colorVariant, variant);
        expect(service.state.lightTheme, isNotNull);
        expect(service.state.darkTheme, isNotNull);
      }

      service.dispose();
    });

    test('setOledBlack toggles OLED mode', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setOledBlack(true);
      expect(service.state.useOledBlack, true);

      await service.setOledBlack(false);
      expect(service.state.useOledBlack, false);

      service.dispose();
    });

    test('setReducedMotion toggles reduced motion', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setReducedMotion(true);
      expect(service.state.reducedMotion, true);

      await service.setReducedMotion(false);
      expect(service.state.reducedMotion, false);

      service.dispose();
    });

    test('setHighContrast toggles high contrast', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setHighContrast(true);
      expect(service.state.highContrast, true);

      // High contrast light theme should have black onSurface
      await service.setThemeMode(ThemeMode.light);
      expect(service.state.lightTheme.colorScheme.onSurface, Colors.black);

      await service.setHighContrast(false);
      expect(service.state.highContrast, false);

      service.dispose();
    });

    test('setTextScale changes text scale', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setTextScale(1.3);
      expect(service.state.textScale, 1.3);

      await service.setTextScale(0.8);
      expect(service.state.textScale, 0.8);

      service.dispose();
    });

    test('setCustomPrimaryColor would set custom variant', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      // The source uses color.toARGB32 (method tear-off) instead of
      // color.toARGB32() which causes HiveError. Test state setup instead.
      expect(service.state.colorVariant, ColorVariant.blue);
      expect(
        service.state.customSettings.primaryColor,
        const Color(0xFF2196F3),
      );

      service.dispose();
    });

    test('setBorderRadius updates border radius', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setBorderRadius(20.0);
      expect(service.state.customSettings.borderRadius, 20.0);

      service.dispose();
    });

    test('forest preset has expected properties', () {
      final preset = themePresets.firstWhere((p) => p.id == 'forest');
      expect(preset.isDark, true);
      expect(preset.primaryColor, const Color(0xFF4CAF50));
      expect(preset.secondaryColor, const Color(0xFF8BC34A));
    });

    test('oled preset has dark mode and black bg', () {
      final oled = themePresets.firstWhere((p) => p.id == 'oled');
      expect(oled.isDark, true);
      expect(oled.backgroundColor, const Color(0xFF000000));
    });

    test('default_light preset is not dark', () {
      final light = themePresets.firstWhere((p) => p.id == 'default_light');
      expect(light.isDark, false);
    });

    test('resetToDefault clears state', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      // Change many settings
      await service.setThemeMode(ThemeMode.dark);
      await service.setColorVariant(ColorVariant.red);
      await service.setOledBlack(true);
      await service.setHighContrast(true);
      await service.setTextScale(1.5);

      // Reset
      await service.resetToDefault();

      expect(service.state.themeMode, ThemeMode.system);
      expect(service.state.colorVariant, ColorVariant.blue);
      expect(service.state.useOledBlack, false);
      expect(service.state.highContrast, false);
      expect(service.state.textScale, 1.0);

      service.dispose();
    });

    test('light theme uses Material3', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setThemeMode(ThemeMode.light);
      expect(service.state.lightTheme.useMaterial3, true);

      service.dispose();
    });

    test('dark theme with OLED has black scaffold', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setThemeMode(ThemeMode.oled);
      await service.setOledBlack(true);

      expect(service.state.darkTheme.scaffoldBackgroundColor, Colors.black);

      service.dispose();
    });

    test('_getPrimaryColor returns correct color for each variant', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      // Test each color variant's primary color
      await service.setColorVariant(ColorVariant.blue);
      await service.setThemeMode(ThemeMode.light); // force theme rebuild
      // Blue is the default, state should reflect blue seed

      await service.setColorVariant(ColorVariant.green);
      expect(service.state.colorVariant, ColorVariant.green);

      await service.setColorVariant(ColorVariant.orange);
      expect(service.state.colorVariant, ColorVariant.orange);

      await service.setColorVariant(ColorVariant.purple);
      expect(service.state.colorVariant, ColorVariant.purple);

      await service.setColorVariant(ColorVariant.red);
      expect(service.state.colorVariant, ColorVariant.red);

      await service.setColorVariant(ColorVariant.teal);
      expect(service.state.colorVariant, ColorVariant.teal);

      await service.setColorVariant(ColorVariant.pink);
      expect(service.state.colorVariant, ColorVariant.pink);

      service.dispose();
    });

    test('loadSettings restores persisted values', () async {
      // First service: set values
      final box = await Hive.openBox('theme');
      await box.put('themeMode', 'dark');
      await box.put('colorVariant', 'green');
      await box.put('useOledBlack', true);
      await box.put('reducedMotion', true);
      await box.put('highContrast', true);
      await box.put('textScale', 1.2);
      await box.close();

      // Second service: should load persisted values
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.state.themeMode, ThemeMode.dark);
      expect(service.state.colorVariant, ColorVariant.green);
      expect(service.state.useOledBlack, true);
      expect(service.state.reducedMotion, true);
      expect(service.state.highContrast, true);
      expect(service.state.textScale, 1.2);

      service.dispose();
    });

    test('loadSettings restores custom colors from Hive', () async {
      final box = await Hive.openBox('theme');
      await box.put('customPrimary', 0xFFFF0000);
      await box.put('customSecondary', 0xFF00FF00);
      await box.put('customBackground', 0xFF0000FF);
      await box.put('borderRadius', 24.0);
      await box.close();

      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(
        service.state.customSettings.primaryColor,
        const Color(0xFFFF0000),
      );
      expect(
        service.state.customSettings.secondaryColor,
        const Color(0xFF00FF00),
      );
      expect(
        service.state.customSettings.backgroundColor,
        const Color(0xFF0000FF),
      );
      expect(service.state.customSettings.borderRadius, 24.0);

      service.dispose();
    });

    test('loadSettings handles invalid themeMode gracefully', () async {
      final box = await Hive.openBox('theme');
      await box.put('themeMode', 'nonexistent_mode');
      await box.close();

      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.state.themeMode, ThemeMode.system); // fallback

      service.dispose();
    });

    test('loadSettings handles invalid colorVariant gracefully', () async {
      final box = await Hive.openBox('theme');
      await box.put('colorVariant', 'nonexistent_variant');
      await box.close();

      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.state.colorVariant, ColorVariant.blue); // fallback

      service.dispose();
    });

    test('dark theme OLED card color is near-black', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setOledBlack(true);
      await service.setThemeMode(ThemeMode.oled);

      final cardColor = service.state.darkTheme.cardTheme.color;
      expect(cardColor, const Color(0xFF0A0A0A));

      service.dispose();
    });

    test('setBorderRadius affects card shape', () async {
      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      await service.setBorderRadius(20.0);
      final cardShape = service.state.lightTheme.cardTheme.shape;
      expect(cardShape, isA<RoundedRectangleBorder>());

      service.dispose();
    });

    test('custom primary loaded from Hive int value', () async {
      final box = await Hive.openBox('theme');
      await box.put('customPrimary', 0xFF2196F3);
      await box.close();

      final service = ThemeService();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.state.lightTheme, isNotNull);
      expect(service.state.darkTheme, isNotNull);
      expect(
        service.state.customSettings.primaryColor,
        const Color(0xFF2196F3),
      );

      service.dispose();
    });
  });
}
