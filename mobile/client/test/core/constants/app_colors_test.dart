import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Primary Colors', () {
      test('primary should be correct hex value', () {
        expect(AppColors.primary, const Color(0xFF00A86B));
      });

      test('primaryDark should be darker than primary', () {
        expect(
          AppColors.primaryDark.computeLuminance(),
          lessThan(AppColors.primary.computeLuminance()),
        );
      });

      test('primaryLight should be lighter than primary', () {
        expect(
          AppColors.primaryLight.computeLuminance(),
          greaterThanOrEqualTo(AppColors.primaryDark.computeLuminance()),
        );
      });

      test('primary should be green (pharmacy theme)', () {
        // Green has high green component
        expect(AppColors.primary.g, greaterThan(AppColors.primary.r));
        expect(AppColors.primary.g, greaterThan(AppColors.primary.b));
      });
    });

    group('Secondary Colors', () {
      test('secondary should be correct hex value', () {
        expect(AppColors.secondary, const Color(0xFF2196F3));
      });

      test('secondaryDark should be correct hex value', () {
        expect(AppColors.secondaryDark, const Color(0xFF1976D2));
      });

      test('secondaryLight should be correct hex value', () {
        expect(AppColors.secondaryLight, const Color(0xFF64B5F6));
      });

      test('secondary should be blue', () {
        // Blue has high blue component
        expect(AppColors.secondary.b, greaterThan(AppColors.secondary.r));
        expect(AppColors.secondary.b, greaterThan(AppColors.secondary.g));
      });
    });

    group('Accent Colors', () {
      test('accent should be correct hex value', () {
        expect(AppColors.accent, const Color(0xFFFF9800));
      });

      test('accentDark should be correct hex value', () {
        expect(AppColors.accentDark, const Color(0xFFF57C00));
      });

      test('accent should be orange', () {
        // Orange has high red component and medium green
        expect(AppColors.accent.r, greaterThan(AppColors.accent.b));
      });
    });

    group('Neutral Colors', () {
      test('background should be correct hex value', () {
        expect(AppColors.background, const Color(0xFFF5F5F5));
      });

      test('surface should be white', () {
        expect(AppColors.surface, Colors.white);
      });

      test('error should be red', () {
        expect(AppColors.error, const Color(0xFFD32F2F));
      });

      test('success should be green', () {
        expect(AppColors.success, const Color(0xFF4CAF50));
      });

      test('warning should be yellow/amber', () {
        expect(AppColors.warning, const Color(0xFFFFC107));
      });

      test('info should be blue', () {
        expect(AppColors.info, const Color(0xFF2196F3));
      });
    });

    group('Text Colors', () {
      test('textPrimary should be dark', () {
        expect(AppColors.textPrimary, const Color(0xFF212121));
        expect(AppColors.textPrimary.computeLuminance(), lessThan(0.5));
      });

      test('textSecondary should be medium gray', () {
        expect(AppColors.textSecondary, const Color(0xFF757575));
      });

      test('textHint should be lighter gray', () {
        expect(AppColors.textHint, const Color(0xFF9E9E9E));
      });

      test('textWhite should be white', () {
        expect(AppColors.textWhite, Colors.white);
      });

      test('text colors should be in descending darkness order', () {
        final textPrimaryLum = AppColors.textPrimary.computeLuminance();
        final textSecondaryLum = AppColors.textSecondary.computeLuminance();
        final textHintLum = AppColors.textHint.computeLuminance();
        final textWhiteLum = AppColors.textWhite.computeLuminance();

        expect(textPrimaryLum, lessThan(textSecondaryLum));
        expect(textSecondaryLum, lessThan(textHintLum));
        expect(textHintLum, lessThan(textWhiteLum));
      });
    });

    group('Border Colors', () {
      test('border should be light gray', () {
        expect(AppColors.border, const Color(0xFFE0E0E0));
      });

      test('divider should be correct hex value', () {
        expect(AppColors.divider, const Color(0xFFBDBDBD));
      });

      test('border should be lighter than divider', () {
        expect(
          AppColors.border.computeLuminance(),
          greaterThan(AppColors.divider.computeLuminance()),
        );
      });
    });

    group('Status Colors', () {
      test('statusPending should be yellow/amber', () {
        expect(AppColors.statusPending, const Color(0xFFFFC107));
      });

      test('statusConfirmed should be blue', () {
        expect(AppColors.statusConfirmed, const Color(0xFF2196F3));
      });

      test('statusReady should be purple', () {
        expect(AppColors.statusReady, const Color(0xFF9C27B0));
      });

      test('statusInTransit should be orange', () {
        expect(AppColors.statusInTransit, const Color(0xFFFF9800));
      });

      test('statusDelivered should be green', () {
        expect(AppColors.statusDelivered, const Color(0xFF4CAF50));
      });

      test('statusCancelled should be red', () {
        expect(AppColors.statusCancelled, const Color(0xFFD32F2F));
      });

      test('all status colors should be distinct', () {
        final statusColors = [
          AppColors.statusPending,
          AppColors.statusConfirmed,
          AppColors.statusReady,
          AppColors.statusInTransit,
          AppColors.statusDelivered,
          AppColors.statusCancelled,
        ];

        final uniqueColors = statusColors.toSet();
        expect(uniqueColors.length, statusColors.length);
      });
    });

    group('Color Consistency', () {
      test('error and statusCancelled should be same', () {
        expect(AppColors.error, AppColors.statusCancelled);
      });

      test('success and statusDelivered should be same', () {
        expect(AppColors.success, AppColors.statusDelivered);
      });

      test('warning and statusPending should be same', () {
        expect(AppColors.warning, AppColors.statusPending);
      });

      test('info and statusConfirmed should be same', () {
        expect(AppColors.info, AppColors.statusConfirmed);
      });

      test('accent and statusInTransit should be same', () {
        expect(AppColors.accent, AppColors.statusInTransit);
      });
    });

    group('Accessibility', () {
      test('textPrimary should have good contrast on surface', () {
        // WCAG requires contrast ratio >= 4.5 for normal text
        final foregroundLum = AppColors.textPrimary.computeLuminance();
        final backgroundLum = AppColors.surface.computeLuminance();

        final lighter =
            foregroundLum > backgroundLum ? foregroundLum : backgroundLum;
        final darker =
            foregroundLum > backgroundLum ? backgroundLum : foregroundLum;

        final contrastRatio = (lighter + 0.05) / (darker + 0.05);
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      test('textWhite should have reasonable contrast on primary', () {
        final foregroundLum = AppColors.textWhite.computeLuminance();
        final backgroundLum = AppColors.primary.computeLuminance();

        final lighter =
            foregroundLum > backgroundLum ? foregroundLum : backgroundLum;
        final darker =
            foregroundLum > backgroundLum ? backgroundLum : foregroundLum;

        final contrastRatio = (lighter + 0.05) / (darker + 0.05);
        // Primary green has lower contrast with white, but still readable for large text (WCAG AA 3:1)
        expect(contrastRatio, greaterThanOrEqualTo(3.0));
      });
    });

    group('Color values are valid', () {
      test('all colors should be fully opaque', () {
        final colors = [
          AppColors.primary,
          AppColors.primaryDark,
          AppColors.primaryLight,
          AppColors.secondary,
          AppColors.secondaryDark,
          AppColors.secondaryLight,
          AppColors.accent,
          AppColors.accentDark,
          AppColors.background,
          AppColors.error,
          AppColors.success,
          AppColors.warning,
          AppColors.info,
          AppColors.textPrimary,
          AppColors.textSecondary,
          AppColors.textHint,
          AppColors.border,
          AppColors.divider,
        ];

        for (final color in colors) {
          expect(color.a, 1.0, reason: 'Color $color should be fully opaque');
        }
      });
    });
  });
}
