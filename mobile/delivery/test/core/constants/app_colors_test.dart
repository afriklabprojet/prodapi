import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/constants/app_colors.dart';

void main() {
  group('AppColors (constants)', () {
    test('primary is blue', () {
      expect(AppColors.primary, const Color(0xFF1E88E5));
    });

    test('secondary is teal', () {
      expect(AppColors.secondary, const Color(0xFF26A69A));
    });

    test('background is light grey', () {
      expect(AppColors.background, const Color(0xFFF5F5F5));
    });

    test('textDark is dark', () {
      expect(AppColors.textDark, const Color(0xFF212121));
    });

    test('textLight is grey', () {
      expect(AppColors.textLight, const Color(0xFF757575));
    });

    test('error is red', () {
      expect(AppColors.error, const Color(0xFFD32F2F));
    });

    test('success is green', () {
      expect(AppColors.success, const Color(0xFF388E3C));
    });
  });
}
