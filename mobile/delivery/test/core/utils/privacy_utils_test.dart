import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/privacy_utils.dart';

void main() {
  group('maskPhoneNumber', () {
    test('masks standard international number', () {
      expect(maskPhoneNumber('+2250707070707'), '+225****07');
    });

    test('masks number with spaces', () {
      expect(maskPhoneNumber('+225 07 07 07 07 07'), '+225****07');
    });

    test('masks number with dashes', () {
      expect(maskPhoneNumber('+225-07-07-07-07-07'), '+225****07');
    });

    test('masks number with parentheses', () {
      expect(maskPhoneNumber('(+225)0707070707'), '+225****07');
    });

    test('masks local number without +', () {
      final result = maskPhoneNumber('0707070707');
      expect(result, '070****07');
    });

    test('returns **** for null', () {
      expect(maskPhoneNumber(null), '****');
    });

    test('returns **** for empty string', () {
      expect(maskPhoneNumber(''), '****');
    });

    test('returns **** for very short number', () {
      expect(maskPhoneNumber('123'), '****');
    });

    test('handles exact 4-char number', () {
      expect(maskPhoneNumber('1234'), '****');
    });

    test('handles 5-char number', () {
      final result = maskPhoneNumber('12345');
      expect(result.contains('****'), isTrue);
    });

    test('preserves country code prefix', () {
      final result = maskPhoneNumber('+2250707070707');
      expect(result.startsWith('+225'), isTrue);
    });

    test('ends with last 2 digits', () {
      final result = maskPhoneNumber('+2250707070789');
      expect(result.endsWith('89'), isTrue);
    });

    test('contains mask in the middle', () {
      final result = maskPhoneNumber('+2250707070707');
      expect(result.contains('****'), isTrue);
    });
  });

  group('maskFullName', () {
    test('masks first and last name', () {
      expect(maskFullName('Jean Dupont'), 'Jean D.');
    });

    test('masks with multiple name parts', () {
      expect(maskFullName('Jean Pierre Dupont'), 'Jean D.');
    });

    test('returns single name unchanged', () {
      expect(maskFullName('Jean'), 'Jean');
    });

    test('returns *** for null', () {
      expect(maskFullName(null), '***');
    });

    test('returns *** for empty string', () {
      expect(maskFullName(''), '***');
    });

    test('handles extra whitespace', () {
      expect(maskFullName('  Jean Dupont  '), 'Jean D.');
    });

    test('uses initial of last part with period', () {
      final result = maskFullName('Marie Claire');
      expect(result, 'Marie C.');
    });
  });
}
