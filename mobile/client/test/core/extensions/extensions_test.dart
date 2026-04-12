import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/extensions/extensions.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PhoneFormatExtension
  // ---------------------------------------------------------------------------
  group('PhoneFormatExtension.toInternationalPhone', () {
    test('already international format (+ prefix) is returned as-is', () {
      expect('+2250574535472'.toInternationalPhone, '+2250574535472');
    });

    test('00-prefix format is converted', () {
      expect('002250574535472'.toInternationalPhone, '+2250574535472');
    });

    test('local CI format (10 digits starting with 0) is converted', () {
      expect('0574535472'.toInternationalPhone, '+2250574535472');
    });

    test('number starting with 225 and 12+ digits is converted', () {
      expect('22507123456789'.toInternationalPhone, '+22507123456789');
    });

    test('10-digit number without leading 0 gets +225 prefix', () {
      // 10 digits not starting with 0: goes to fallback "+225..."
      expect(
        '5745354720'.toInternationalPhone,
        '+225225' == '+2255745354720' ? '+2255745354720' : '+2255745354720',
      );
    });

    test('number with spaces/dashes is cleaned before formatting', () {
      expect('+225 05 74 53 54 72'.toInternationalPhone, '+2250574535472');
    });

    test('throws FormatException for invalid number', () {
      expect(() => 'abc'.toInternationalPhone, throwsA(isA<FormatException>()));
    });

    test('throws FormatException for empty +prefix', () {
      expect(() => '+'.toInternationalPhone, throwsA(isA<FormatException>()));
    });
  });

  // ---------------------------------------------------------------------------
  // PriceFormatExtension
  // ---------------------------------------------------------------------------
  group('PriceFormatExtension.formatPrice', () {
    test('formats 2500 as "2 500 FCFA"', () {
      expect(2500.formatPrice, '2 500 FCFA');
    });

    test('formats 1000000 as "1 000 000 FCFA"', () {
      expect(1000000.formatPrice, '1 000 000 FCFA');
    });

    test('formats 0 as "0 FCFA"', () {
      expect(0.formatPrice, '0 FCFA');
    });

    test('formats 100 as "100 FCFA"', () {
      expect(100.formatPrice, '100 FCFA');
    });

    test('double is formatted without decimal', () {
      expect(1250.5.formatPrice, '1 251 FCFA');
    });
  });

  group('PriceFormatExtension.formatNumber', () {
    test('formats 1000 as "1 000"', () {
      expect(1000.formatNumber, '1 000');
    });

    test('formats 5000 as "5 000"', () {
      expect(5000.formatNumber, '5 000');
    });
  });

  // ---------------------------------------------------------------------------
  // DateExtension
  // ---------------------------------------------------------------------------
  group('DateExtension.formatDateFr', () {
    test('formats date correctly in French', () {
      final date = DateTime(2025, 3, 14);
      expect(date.formatDateFr, '14 mars 2025');
    });

    test('formats January correctly', () {
      final date = DateTime(2024, 1, 1);
      expect(date.formatDateFr, '1 janv. 2024');
    });

    test('formats December correctly', () {
      final date = DateTime(2023, 12, 31);
      expect(date.formatDateFr, '31 déc. 2023');
    });

    test('formats all months correctly', () {
      const monthNames = [
        '',
        'janv.',
        'févr.',
        'mars',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sept.',
        'oct.',
        'nov.',
        'déc.',
      ];
      for (int m = 1; m <= 12; m++) {
        final date = DateTime(2025, m, 1);
        expect(date.formatDateFr, contains(monthNames[m]));
      }
    });
  });

  group('DateExtension.formatDateTimeFr', () {
    test('includes date and time', () {
      final date = DateTime(2025, 3, 14, 9, 5);
      final result = date.formatDateTimeFr;
      expect(result, contains('14 mars 2025'));
      expect(result, contains('09:05'));
    });

    test('pads single-digit hours and minutes', () {
      final date = DateTime(2025, 6, 1, 8, 3);
      expect(date.formatDateTimeFr, contains('08:03'));
    });
  });

  group('DateExtension.timeAgo', () {
    test('"À l\'instant" for < 1 min ago', () {
      final now = DateTime.now();
      expect(now.timeAgo, 'À l\'instant');
    });

    test('"Il y a X min" for few minutes ago', () {
      final ago = DateTime.now().subtract(const Duration(minutes: 5));
      expect(ago.timeAgo, contains('5 min'));
    });

    test('"Il y a Xh" for hours ago', () {
      final ago = DateTime.now().subtract(const Duration(hours: 3));
      expect(ago.timeAgo, contains('3h'));
    });

    test('"Il y a Xj" for days ago (within week)', () {
      final ago = DateTime.now().subtract(const Duration(days: 3));
      expect(ago.timeAgo, contains('3j'));
    });

    test('date format for > 7 days', () {
      final ago = DateTime.now().subtract(const Duration(days: 10));
      // Should return formatDateFr — contains year
      expect(ago.timeAgo, matches(RegExp(r'\d{4}')));
    });
  });

  // ---------------------------------------------------------------------------
  // StringExtension
  // ---------------------------------------------------------------------------
  group('StringExtension.capitalize', () {
    test('capitalizes first letter', () {
      expect('hello'.capitalize, 'Hello');
    });

    test('returns empty string unchanged', () {
      expect(''.capitalize, '');
    });

    test('does not change rest of string', () {
      expect('hELLO'.capitalize, 'HELLO');
    });
  });

  group('StringExtension.truncate', () {
    test('does not truncate short strings', () {
      expect('hello'.truncate(10), 'hello');
    });

    test('truncates long strings with ellipsis', () {
      expect('hello world'.truncate(5), 'hello...');
    });

    test('exact length is not truncated', () {
      expect('hello'.truncate(5), 'hello');
    });
  });
}
