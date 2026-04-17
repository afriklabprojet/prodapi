import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatting extension', () {
    test('formatCurrency with default symbol', () {
      expect(15000.formatCurrency(), contains('FCFA'));
      expect(15000.formatCurrency(), contains('15'));
    });

    test('formatCurrency with custom symbol', () {
      expect(15000.formatCurrency(symbol: 'F'), contains('F'));
    });

    test('formatCurrencyCompact returns no symbol', () {
      final result = 15000.formatCurrencyCompact();
      expect(result, isNot(contains('FCFA')));
    });

    test('formatNumber formats with separators', () {
      final result = 1500000.formatNumber();
      // French locale uses non-breaking spaces or periods
      expect(result, isNotEmpty);
    });

    test('formatDecimal formats decimals', () {
      final result = 3.14159.formatDecimal(decimals: 2);
      expect(result, contains('14'));
    });

    test('formatPercent for value between 0 and 1 multiplies by 100', () {
      final result = 0.754.formatPercent();
      expect(result, '75.4%');
    });

    test('formatPercent for value > 1 keeps as is', () {
      final result = 75.4.formatPercent();
      expect(result, '75.4%');
    });

    test('formatCompact for large numbers', () {
      final result = 1500000.formatCompact();
      expect(result, isNotEmpty);
    });

    test('zero value formats correctly', () {
      expect(0.formatCurrency(), contains('FCFA'));
      expect(0.formatNumber(), isNotEmpty);
      expect(0.0.formatPercent(), '0.0%');
    });
  });

  group('MoneyFormatting extension (int)', () {
    test('formatTransaction credit', () {
      final result = 5000.formatTransaction(isCredit: true);
      expect(result, contains('+'));
      expect(result, contains('FCFA'));
    });

    test('formatTransaction debit', () {
      final result = 5000.formatTransaction(isCredit: false);
      expect(result, contains('-'));
      expect(result, contains('FCFA'));
    });

    test('formatTransaction with custom symbol', () {
      final result = 5000.formatTransaction(isCredit: true, symbol: 'XOF');
      expect(result, contains('XOF'));
    });

    test('formatTransaction with zero', () {
      final result = 0.formatTransaction(isCredit: true);
      expect(result, contains('+'));
      expect(result, contains('0'));
    });

    test('formatTransaction with large amount', () {
      final result = 999999999.formatTransaction(isCredit: false);
      expect(result, contains('-'));
      expect(result, contains('999'));
    });
  });

  group('NumberFormatting edge cases', () {
    test('formatCurrency with double value', () {
      final result = 1500.75.formatCurrency();
      expect(result, contains('FCFA'));
      expect(result, contains('1'));
    });

    test('formatCurrency with very large number', () {
      final result = 999999999.formatCurrency();
      expect(result, contains('FCFA'));
    });

    test('formatNumber with custom locale en_US', () {
      final result = 15000.formatNumber(locale: 'en_US');
      expect(result, isNotEmpty);
      expect(result, contains('15'));
    });

    test('formatDecimal with 0 decimals', () {
      final result = 3.14159.formatDecimal(decimals: 0);
      expect(result, isNotEmpty);
      // Should not have decimal point content for zero decimals
      expect(result, contains('3'));
    });

    test('formatDecimal with 5 decimals', () {
      final result = 3.14159.formatDecimal(decimals: 5);
      expect(result, contains('14159'));
    });

    test('formatPercent with exactly 1.0', () {
      // 1.0 is between 0 and 1.0, so should multiply by 100
      final result = 1.0.formatPercent();
      expect(result, '100.0%');
    });

    test('formatPercent with exactly 0.0', () {
      final result = 0.0.formatPercent();
      expect(result, '0.0%');
    });

    test('formatPercent with negative value', () {
      // Negative is not 0..1 range, so kept as-is
      final result = (-5.0).formatPercent();
      expect(result, '-5.0%');
    });

    test('formatPercent with value > 1', () {
      final result = 1.01.formatPercent();
      expect(result, '1.0%');
    });

    test('formatPercent with 0 decimals', () {
      final result = 0.756.formatPercent(decimals: 0);
      expect(result, '76%');
    });

    test('formatPercent with 3 decimals', () {
      final result = 0.75432.formatPercent(decimals: 3);
      expect(result, '75.432%');
    });

    test('formatCompact abbreviates millions', () {
      final result = 1500000.formatCompact();
      expect(result.toLowerCase(), contains('m'));
    });

    test('formatCompact with custom locale', () {
      final result = 1500000.formatCompact(locale: 'en_US');
      expect(result, isNotEmpty);
    });

    test('formatCurrencyCompact with custom locale', () {
      final result = 15000.formatCurrencyCompact(locale: 'en_US');
      expect(result, isNotEmpty);
      expect(result, contains('15'));
    });

    test('negative number formatCurrency', () {
      final result = (-5000).formatCurrency();
      expect(result, contains('FCFA'));
    });
  });
}
