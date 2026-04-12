import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/theme/app_colors.dart' as theme;

void main() {
  group('AppColors (theme)', () {
    group('Background colors', () {
      test('lightBackground is defined', () {
        expect(theme.AppColors.lightBackground, const Color(0xFFF8F9FD));
      });

      test('darkBackground is defined', () {
        expect(theme.AppColors.darkBackground, const Color(0xFF121212));
      });

      test('lightCard is white', () {
        expect(theme.AppColors.lightCard, Colors.white);
      });

      test('darkCard is dark grey', () {
        expect(theme.AppColors.darkCard, const Color(0xFF1E1E1E));
      });

      test('darkSurface is defined', () {
        expect(theme.AppColors.darkSurface, const Color(0xFF2A2A2A));
      });

      test('darkSurfaceVariant is defined', () {
        expect(theme.AppColors.darkSurfaceVariant, const Color(0xFF2C2C2C));
      });
    });

    group('Brand colors', () {
      test('brandPrimary is green', () {
        expect(theme.AppColors.brandPrimary, const Color(0xFF54AB70));
      });

      test('brandPrimaryDark is darker green', () {
        expect(theme.AppColors.brandPrimaryDark, const Color(0xFF3D8C57));
      });

      test('brandAccent is defined', () {
        expect(theme.AppColors.brandAccent, const Color(0xFF2E7D32));
      });

      test('brandDark is very dark green', () {
        expect(theme.AppColors.brandDark, const Color(0xFF1B5E20));
      });

      test('brandMedium is medium green', () {
        expect(theme.AppColors.brandMedium, const Color(0xFF43A047));
      });
    });

    group('Status colors', () {
      test('success is green', () {
        expect(theme.AppColors.success, const Color(0xFF4CAF50));
      });

      test('error is red', () {
        expect(theme.AppColors.error, const Color(0xFFE53935));
      });

      test('warning is orange', () {
        expect(theme.AppColors.warning, const Color(0xFFFF9800));
      });

      test('info is blue', () {
        expect(theme.AppColors.info, const Color(0xFF2196F3));
      });
    });

    group('Text colors', () {
      test('textDark is white (for dark mode)', () {
        expect(theme.AppColors.textDark, Colors.white);
      });

      test('textLight is dark (for light mode)', () {
        expect(theme.AppColors.textLight, const Color(0xFF212121));
      });
    });

    group('Helper methods', () {
      test('background returns darkBackground when isDark', () {
        expect(
          theme.AppColors.background(true),
          theme.AppColors.darkBackground,
        );
      });

      test('background returns lightBackground when not isDark', () {
        expect(
          theme.AppColors.background(false),
          theme.AppColors.lightBackground,
        );
      });

      test('card returns darkCard when isDark', () {
        expect(theme.AppColors.card(true), theme.AppColors.darkCard);
      });

      test('card returns lightCard when not isDark', () {
        expect(theme.AppColors.card(false), theme.AppColors.lightCard);
      });

      test('surface returns darkSurface when isDark', () {
        expect(theme.AppColors.surface(true), theme.AppColors.darkSurface);
      });

      test('surface returns grey shade when not isDark', () {
        expect(theme.AppColors.surface(false), Colors.grey.shade50);
      });
    });
  });
}
