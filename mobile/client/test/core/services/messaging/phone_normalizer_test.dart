import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/services/messaging/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer', () {
    group('normalize', () {
      test('returns empty string for empty input', () {
        expect(PhoneNormalizer.normalize(''), '');
      });

      test('returns empty string for whitespace-only input', () {
        expect(PhoneNormalizer.normalize('   '), '');
      });

      test('returns empty string for non-digit input', () {
        expect(PhoneNormalizer.normalize('abc'), '');
      });

      test('preserves international format with +', () {
        expect(PhoneNormalizer.normalize('+22507070707'), '+22507070707');
      });

      test('strips spaces and dashes from international number', () {
        expect(PhoneNormalizer.normalize('+225 07 07 07 07'), '+22507070707');
      });

      test('converts 00 prefix to + prefix', () {
        expect(PhoneNormalizer.normalize('0022507070707'), '+22507070707');
      });

      test('converts local 0-prefix to country code', () {
        expect(PhoneNormalizer.normalize('07070707'), '+2257070707');
      });

      test('strips 0 prefix and adds country code for 00-prefixed numbers', () {
        expect(PhoneNormalizer.normalize('007070707'), '+7070707');
      });

      test('adds country code for raw digits without prefix', () {
        expect(PhoneNormalizer.normalize('707070707'), '+225707070707');
      });

      test('respects custom country code', () {
        expect(
          PhoneNormalizer.normalize('612345678', countryCode: '+33'),
          '+33612345678',
        );
      });

      test('handles number with parentheses and dots', () {
        expect(PhoneNormalizer.normalize('+225 (07) 07.07.07'), '+22507070707');
      });
    });

    group('digitsOnly', () {
      test('strips plus sign', () {
        expect(PhoneNormalizer.digitsOnly('+22507070707'), '22507070707');
      });

      test('returns digits for plain digits', () {
        expect(PhoneNormalizer.digitsOnly('22507070707'), '22507070707');
      });
    });
  });
}
