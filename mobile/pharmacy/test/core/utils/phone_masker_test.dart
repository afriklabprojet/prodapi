import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/core/utils/phone_masker.dart';

void main() {
  group('PhoneMasker.mask', () {
    test('masks international phone number with default settings', () {
      expect(PhoneMasker.mask('+22507070707'), '+2250•••••07');
    });

    test('masks local phone number', () {
      expect(PhoneMasker.mask('0707070707'), '0707••••07');
    });

    test('returns mask chars for empty input', () {
      expect(PhoneMasker.mask(''), '••••');
    });

    test('handles very short numbers gracefully', () {
      // '07' → hasPlus=false, raw='07', len=2 ≤ 2 → returns '07'
      expect(PhoneMasker.mask('07'), '07');
    });

    test('handles number with + and short digits', () {
      expect(PhoneMasker.mask('+07'), '+07');
    });

    test('handles number with spaces and dashes', () {
      // Strips to digits+
      expect(PhoneMasker.mask('+225 07 07 07 07'), '+2250•••••07');
    });

    test('respects custom visibleStart and visibleEnd', () {
      // '+22507070707' → raw='22507070707' (11 digits), start=2 ('22'), end=4 ('0707'), masked=5
      expect(
        PhoneMasker.mask('+22507070707', visibleStart: 2, visibleEnd: 4),
        '+22•••••0707',
      );
    });

    test('respects custom maskChar', () {
      expect(PhoneMasker.mask('+22507070707', maskChar: '*'), '+2250*****07');
    });

    test('masks number where digits equal visibleStart + visibleEnd', () {
      // '070707' → 6 digits, visibleStart=4, visibleEnd=2 → 0 masked
      // raw.length <= visibleStart + visibleEnd → uses short path
      expect(PhoneMasker.mask('070707'), '0••••7');
    });

    test('masks 3-digit number', () {
      // raw='070', len=3 > 2 → start='0', end='0', middle='•'
      expect(PhoneMasker.mask('070'), '0•0');
    });
  });

  group('PhoneMasker.maskForDisplay', () {
    test('formats masked international number with spaces', () {
      final result = PhoneMasker.maskForDisplay('+22507070707');
      // Should contain spaces for readability
      expect(result.contains(' '), isTrue);
      // Should still contain mask chars
      expect(result.contains('•'), isTrue);
    });

    test('returns mask chars for empty input', () {
      final result = PhoneMasker.maskForDisplay('');
      expect(result, contains('•'));
    });

    test('formats local number with spaces', () {
      final result = PhoneMasker.maskForDisplay('0707070707');
      expect(result.contains(' '), isTrue);
      expect(result.contains('•'), isTrue);
    });

    test('preserves + prefix', () {
      final result = PhoneMasker.maskForDisplay('+22507070707');
      expect(result.startsWith('+'), isTrue);
    });
  });
}
