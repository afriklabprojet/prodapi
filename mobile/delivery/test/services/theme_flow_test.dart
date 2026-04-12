import 'dart:io';

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:courier/core/services/theme_service.dart';

/// Tests du flux thème — widget tests, aucun simulateur requis.
/// Vérifie que ThemeService + ProviderScope + MaterialApp fonctionnent de bout en bout.
void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('theme_flow_test_');
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

  // ---------------------------------------------------------------------------
  // Group 1: Provider wiring
  // ---------------------------------------------------------------------------

  group('ThemeService provider', () {
    testWidgets('themeServiceProvider is accessible from widget tree', (
      tester,
    ) async {
      late AppThemeState capturedState;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              capturedState = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedState, isNotNull);
      expect(capturedState.lightTheme, isNotNull);
      expect(capturedState.darkTheme, isNotNull);
    });

    testWidgets('default state has system theme mode', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.themeMode, ThemeMode.system);
      expect(state.colorVariant, ColorVariant.blue);
      expect(state.useOledBlack, false);
      expect(state.reducedMotion, false);
      expect(state.highContrast, false);
      expect(state.textScale, 1.0);
    });

    testWidgets('activeThemeProvider returns same theme as state.activeTheme', (
      tester,
    ) async {
      late ThemeData activeTheme;
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              activeTheme = ref.watch(activeThemeProvider);
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(activeTheme, state.activeTheme);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2: Theme mode switching
  // ---------------------------------------------------------------------------

  group('Theme mode switching', () {
    testWidgets('switching to dark mode updates isDarkModeProvider', (
      tester,
    ) async {
      late bool isDark;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              isDark = ref.watch(isDarkModeProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container
          .read(themeServiceProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pump();

      expect(isDark, true);
    });

    testWidgets('switching to light mode makes isDark false', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container
          .read(themeServiceProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await tester.pump();

      expect(state.themeMode, ThemeMode.light);
      expect(state.isDark, false);
    });

    testWidgets('OLED mode sets both themeMode and isDark', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container
          .read(themeServiceProvider.notifier)
          .setThemeMode(ThemeMode.oled);
      await tester.pump();

      expect(state.themeMode, ThemeMode.oled);
      expect(state.isDark, true);
    });

    testWidgets('all ThemeMode values can be set without error', (
      tester,
    ) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      final notifier = container.read(themeServiceProvider.notifier);

      for (final mode in ThemeMode.values) {
        await notifier.setThemeMode(mode);
        await tester.pump();
        expect(state.themeMode, mode);
        expect(state.lightTheme, isNotNull);
        expect(state.darkTheme, isNotNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3: Color variant switching
  // ---------------------------------------------------------------------------

  group('Color variant switching', () {
    testWidgets('switching to green variant rebuilds themes', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container
          .read(themeServiceProvider.notifier)
          .setColorVariant(ColorVariant.green);
      await tester.pump();

      expect(state.colorVariant, ColorVariant.green);
      expect(state.lightTheme, isNotNull);
      expect(state.darkTheme, isNotNull);
    });

    testWidgets('all color variants round-trip without error', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      final notifier = container.read(themeServiceProvider.notifier);

      for (final variant in ColorVariant.values) {
        if (variant == ColorVariant.custom) continue;
        await notifier.setColorVariant(variant);
        await tester.pump();
        expect(state.colorVariant, variant);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 4: Accessibility features
  // ---------------------------------------------------------------------------

  group('Accessibility', () {
    testWidgets(
      'high contrast mode updates onSurface to black in light theme',
      (tester) async {
        late AppThemeState state;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                state = ref.watch(themeServiceProvider);
                return const MaterialApp(home: Scaffold());
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer).first),
        );
        final notifier = container.read(themeServiceProvider.notifier);

        await notifier.setHighContrast(true);
        await notifier.setThemeMode(ThemeMode.light);
        await tester.pump();

        expect(state.highContrast, true);
        expect(state.lightTheme.colorScheme.onSurface, Colors.black);
      },
    );

    testWidgets('textScaleProvider reflects setTextScale changes', (
      tester,
    ) async {
      late double textScale;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              textScale = ref.watch(textScaleProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container.read(themeServiceProvider.notifier).setTextScale(1.4);
      await tester.pump();

      expect(textScale, 1.4);
    });

    testWidgets('reducedMotionProvider reflects setReducedMotion changes', (
      tester,
    ) async {
      late bool reducedMotion;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              reducedMotion = ref.watch(reducedMotionProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container
          .read(themeServiceProvider.notifier)
          .setReducedMotion(true);
      await tester.pump();

      expect(reducedMotion, true);
    });

    testWidgets('OLED + useOledBlack produces black scaffold', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      final notifier = container.read(themeServiceProvider.notifier);

      await notifier.setThemeMode(ThemeMode.oled);
      await notifier.setOledBlack(true);
      await tester.pump();

      expect(state.darkTheme.scaffoldBackgroundColor, Colors.black);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 5: Preset application
  // ---------------------------------------------------------------------------

  group('Preset application', () {
    testWidgets('applyPreset(forest) sets dark mode and green primary', (
      tester,
    ) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final forest = themePresets.firstWhere((p) => p.id == 'forest');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container.read(themeServiceProvider.notifier).applyPreset(forest);
      await tester.pump();

      expect(state.themeMode, ThemeMode.dark);
      expect(state.colorVariant, ColorVariant.custom);
      expect(state.customSettings.primaryColor, const Color(0xFF4CAF50));
    });

    testWidgets('applyPreset(default_light) sets light mode', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final light = themePresets.firstWhere((p) => p.id == 'default_light');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container.read(themeServiceProvider.notifier).applyPreset(light);
      await tester.pump();

      expect(state.themeMode, ThemeMode.light);
      expect(state.isDark, false);
    });

    testWidgets('applyPreset(oled) enables OLED black', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final oled = themePresets.firstWhere((p) => p.id == 'oled');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container.read(themeServiceProvider.notifier).applyPreset(oled);
      await tester.pump();

      expect(state.useOledBlack, true);
      expect(state.darkTheme.scaffoldBackgroundColor, Colors.black);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 6: Border radius
  // ---------------------------------------------------------------------------

  group('Border radius', () {
    testWidgets('setBorderRadius updates card theme shape', (tester) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      await container.read(themeServiceProvider.notifier).setBorderRadius(24.0);
      await tester.pump();

      expect(state.customSettings.borderRadius, 24.0);
      expect(state.lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });

  // ---------------------------------------------------------------------------
  // Group 7: Reset
  // ---------------------------------------------------------------------------

  group('Reset to default', () {
    testWidgets('resetToDefault restores all fields to defaults', (
      tester,
    ) async {
      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer).first),
      );
      final notifier = container.read(themeServiceProvider.notifier);

      await notifier.setThemeMode(ThemeMode.oled);
      await notifier.setColorVariant(ColorVariant.red);
      await notifier.setHighContrast(true);
      await notifier.setTextScale(1.5);
      await tester.pump();

      await notifier.resetToDefault();
      await tester.pump();

      expect(state.themeMode, ThemeMode.system);
      expect(state.colorVariant, ColorVariant.blue);
      expect(state.highContrast, false);
      expect(state.textScale, 1.0);
      expect(state.useOledBlack, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 8: Persistence via Hive
  // ---------------------------------------------------------------------------

  group('Persistence', () {
    testWidgets('settings written to Hive are loaded on next service init', (
      tester,
    ) async {
      final box = await Hive.openBox('theme');
      await box.put('themeMode', 'dark');
      await box.put('colorVariant', 'purple');
      await box.put('useOledBlack', true);
      await box.put('textScale', 1.3);
      await box.close();

      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.themeMode, ThemeMode.dark);
      expect(state.colorVariant, ColorVariant.purple);
      expect(state.useOledBlack, true);
      expect(state.textScale, 1.3);
    });

    testWidgets('invalid persisted values fall back to defaults', (
      tester,
    ) async {
      final box = await Hive.openBox('theme');
      await box.put('themeMode', 'not_a_real_mode');
      await box.put('colorVariant', 'not_a_real_variant');
      await box.close();

      late AppThemeState state;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              state = ref.watch(themeServiceProvider);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.themeMode, ThemeMode.system);
      expect(state.colorVariant, ColorVariant.blue);
    });
  });
}
