import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/theme/theme_provider.dart';

void main() {
  group('AppThemeMode', () {
    test('has 4 values', () {
      expect(AppThemeMode.values.length, 4);
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.auto));
    });
  });

  group('ThemeExtension on BuildContext', () {
    testWidgets('isDark is false in light theme', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ctx.isDark, false);
    });

    testWidgets('isDark is true in dark theme', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ctx.isDark, true);
    });

    testWidgets('light theme returns correct colors', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(ctx.scaffoldBackground, const Color(0xFFF8F9FD));
      expect(ctx.cardBackground, Colors.white);
      expect(ctx.surfaceColor, Colors.grey.shade100);
      expect(ctx.primaryText, Colors.black);
      expect(ctx.secondaryText, Colors.grey.shade600);
      expect(ctx.tertiaryText, Colors.grey.shade500);
      expect(ctx.dividerColor, Colors.grey.shade200);
      expect(ctx.iconColor, Colors.grey.shade700);
      expect(ctx.inputFillColor, Colors.grey.shade100);
      expect(ctx.hintColor, Colors.grey.shade400);
      expect(ctx.borderColor, Colors.grey.shade300);
    });

    testWidgets('dark theme returns correct colors', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(ctx.scaffoldBackground, const Color(0xFF121212));
      expect(ctx.cardBackground, const Color(0xFF1E1E1E));
      expect(ctx.surfaceColor, const Color(0xFF2C2C2C));
      expect(ctx.primaryText, Colors.white);
      expect(ctx.secondaryText, Colors.white70);
      expect(ctx.tertiaryText, Colors.white54);
      expect(ctx.dividerColor, const Color(0xFF2C2C2C));
      expect(ctx.iconColor, Colors.white70);
      expect(ctx.inputFillColor, const Color(0xFF2C2C2C));
      expect(ctx.hintColor, Colors.white38);
      expect(ctx.borderColor, Colors.white12);
    });

    testWidgets('shadowColor returns a color in light theme', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ctx.shadowColor, isA<Color>());
    });

    testWidgets('shadowColor returns a color in dark theme', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ctx.shadowColor, isA<Color>());
    });
  });

  group('lightTheme', () {
    test('is Material3', () {
      expect(lightTheme.useMaterial3, true);
    });

    test('has light brightness', () {
      expect(lightTheme.brightness, Brightness.light);
    });

    test('scaffoldBackgroundColor is correct', () {
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8F9FD));
    });

    test('appBarTheme has white background', () {
      expect(lightTheme.appBarTheme.backgroundColor, Colors.white);
    });
  });

  group('darkTheme', () {
    test('is Material3', () {
      expect(darkTheme.useMaterial3, true);
    });

    test('has dark brightness', () {
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('scaffoldBackgroundColor is dark', () {
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF121212));
    });
  });

  group('Theme constants', () {
    test('kPrimaryGreen values', () {
      expect(kPrimaryGreen, const Color(0xFF54AB70));
      expect(kPrimaryGreenDark, const Color(0xFF3D8C57));
      expect(kPrimaryGreenLight, const Color(0xFF6EC889));
    });
  });
}
