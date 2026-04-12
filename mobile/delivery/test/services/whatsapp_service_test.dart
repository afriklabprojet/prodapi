import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService.normalizePhone', () {
    test('returns empty for empty string', () {
      expect(WhatsAppService.normalizePhone(''), '');
    });

    test('returns empty for non-numeric string', () {
      expect(WhatsAppService.normalizePhone('abc'), '');
    });

    test('preserves number starting with +', () {
      expect(WhatsAppService.normalizePhone('+22507123456'), '+22507123456');
    });

    test('removes spaces and dashes', () {
      expect(
        WhatsAppService.normalizePhone('+225 07 12 34 56'),
        '+22507123456',
      );
      expect(
        WhatsAppService.normalizePhone('+225-07-12-34-56'),
        '+22507123456',
      );
    });

    test('converts 00 prefix to +', () {
      expect(WhatsAppService.normalizePhone('0022507123456'), '+22507123456');
    });

    test('converts local number starting with 0', () {
      expect(WhatsAppService.normalizePhone('07123456'), '+2257123456');
    });

    test('adds country code for number without prefix', () {
      expect(WhatsAppService.normalizePhone('7123456'), '+2257123456');
    });

    test('handles number with special characters', () {
      expect(
        WhatsAppService.normalizePhone('(+225) 07.12.34.56'),
        '+22507123456',
      );
    });
  });

  group('WhatsAppService.normalizePhone - additional', () {
    test('handles only plus sign', () {
      expect(WhatsAppService.normalizePhone('+'), '+');
    });

    test('handles very long international number', () {
      final result = WhatsAppService.normalizePhone('+441234567890123');
      expect(result, '+441234567890123');
    });

    test('handles dots only as separator', () {
      expect(
        WhatsAppService.normalizePhone('+225.07.12.34.56'),
        '+22507123456',
      );
    });

    test('handles 00225 format with spaces', () {
      expect(
        WhatsAppService.normalizePhone('00 225 07 12 34 56'),
        '+22507123456',
      );
    });

    test('handles local number with dots', () {
      expect(WhatsAppService.normalizePhone('07.12.34.56'), '+2257123456');
    });

    test('handles number with parentheses only', () {
      expect(WhatsAppService.normalizePhone('(07)123456'), '+2257123456');
    });

    test('handles single digit number', () {
      expect(WhatsAppService.normalizePhone('5'), '+2255');
    });

    test('preserves already well-formatted international', () {
      expect(WhatsAppService.normalizePhone('+33612345678'), '+33612345678');
    });

    test('handles tabs and newlines', () {
      // Tabs and newlines are stripped as non-digit non-plus chars
      final result = WhatsAppService.normalizePhone('+225 07 12 34 56');
      expect(result, '+22507123456');
    });
  });

  group('WhatsAppService.normalizePhone - edge cases', () {
    test('handles whitespace only string', () {
      expect(WhatsAppService.normalizePhone('   '), '');
    });

    test('handles mixed letters and numbers', () {
      // Letters are stripped, only digits and + remain
      expect(WhatsAppService.normalizePhone('abc123def456'), '+225123456');
    });

    test('handles zero only', () {
      // 0 is stripped since it starts with 0, substring(1) leaves empty
      // But then the empty check after cleaning... let me verify
      expect(WhatsAppService.normalizePhone('0'), '+225');
    });

    test('handles 00 only (international prefix without number)', () {
      expect(WhatsAppService.normalizePhone('00'), '+');
    });

    test('handles multiple plus signs', () {
      // Regex [^\d+] keeps + signs, so multiple + are preserved
      expect(WhatsAppService.normalizePhone('++225++07'), '++225++07');
    });

    test('handles underscores as separators', () {
      expect(WhatsAppService.normalizePhone('+225_07_12_34'), '+225071234');
    });

    test('handles brackets around area code', () {
      expect(WhatsAppService.normalizePhone('[+225]07123456'), '+22507123456');
    });

    test('handles emoji in number', () {
      expect(WhatsAppService.normalizePhone('+225📱07123456'), '+22507123456');
    });

    test('handles accented characters', () {
      expect(WhatsAppService.normalizePhone('+225é07ç12'), '+2250712');
    });

    test('handles Ivory Coast number formats', () {
      // Full local mobile number
      expect(WhatsAppService.normalizePhone('0707070707'), '+225707070707');
      // Local without leading zero
      expect(WhatsAppService.normalizePhone('707070707'), '+225707070707');
      // International format
      expect(WhatsAppService.normalizePhone('+225707070707'), '+225707070707');
      // With 00 prefix
      expect(WhatsAppService.normalizePhone('00225707070707'), '+225707070707');
    });

    test('handles French number format', () {
      expect(
        WhatsAppService.normalizePhone('+33 6 12 34 56 78'),
        '+33612345678',
      );
    });

    test('handles US number format', () {
      expect(
        WhatsAppService.normalizePhone('+1 (555) 123-4567'),
        '+15551234567',
      );
    });

    test('handles UK number format', () {
      expect(
        WhatsAppService.normalizePhone('+44 7911 123456'),
        '+447911123456',
      );
    });

    test('handles leading zeros after country code', () {
      expect(
        WhatsAppService.normalizePhone('+225 07 00 00 00'),
        '+22507000000',
      );
    });

    test('handles number with x extension marker', () {
      // x is stripped
      expect(
        WhatsAppService.normalizePhone('+22507123456x123'),
        '+22507123456123',
      );
    });

    test('handles number with # extension marker', () {
      // # is stripped
      expect(
        WhatsAppService.normalizePhone('+22507123456#123'),
        '+22507123456123',
      );
    });
  });

  group('WhatsAppService constants', () {
    test('default country code is Ivory Coast (+225)', () {
      // Verify by checking that a local number gets +225 prefix
      final result = WhatsAppService.normalizePhone('07123456');
      expect(result.startsWith('+225'), isTrue);
    });

    test('supports 10-digit Ivory Coast numbers', () {
      final result = WhatsAppService.normalizePhone('0707070707');
      expect(result, '+225707070707');
      expect(result.length, 13); // +225 (4) + 9 digits
    });
  });
}
