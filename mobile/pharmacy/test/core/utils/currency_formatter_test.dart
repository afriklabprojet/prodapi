import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.compact', () {
    test('formats millions with one decimal', () {
      expect(CurrencyFormatter.compact(1000000), '1.0M');
      expect(CurrencyFormatter.compact(1500000), '1.5M');
      expect(CurrencyFormatter.compact(2345678), '2.3M');
      expect(CurrencyFormatter.compact(10000000), '10.0M');
    });

    test('formats thousands without decimals', () {
      expect(CurrencyFormatter.compact(1000), '1K');
      expect(CurrencyFormatter.compact(5000), '5K');
      expect(CurrencyFormatter.compact(15500), '16K');
      expect(CurrencyFormatter.compact(999999), '1000K');
    });

    test('formats small amounts as integers', () {
      expect(CurrencyFormatter.compact(0), '0');
      expect(CurrencyFormatter.compact(1), '1');
      expect(CurrencyFormatter.compact(500), '500');
      expect(CurrencyFormatter.compact(999), '999');
    });

    test('handles fractional amounts', () {
      expect(CurrencyFormatter.compact(0.5), '1');
      expect(CurrencyFormatter.compact(999.9), '1000');
    });

    test('handles negative amounts gracefully', () {
      // Negative values below threshold go through toStringAsFixed
      expect(CurrencyFormatter.compact(-500), '-500');
    });

    test('handles boundary values', () {
      expect(CurrencyFormatter.compact(999), '999');
      expect(CurrencyFormatter.compact(1000), '1K');
      expect(CurrencyFormatter.compact(999999), '1000K');
      expect(CurrencyFormatter.compact(1000000), '1.0M');
    });
  });
}
