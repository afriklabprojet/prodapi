import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService.normalizePhone', () {
    test('returns empty for empty string', () {
      expect(WhatsAppService.normalizePhone(''), '');
    });

    test('returns empty for non-digit string', () {
      expect(WhatsAppService.normalizePhone('abc'), '');
    });

    test('preserves international format with +', () {
      expect(WhatsAppService.normalizePhone('+22507123456'), '+22507123456');
    });

    test('strips spaces from number', () {
      expect(
        WhatsAppService.normalizePhone('+225 07 12 34 56'),
        '+22507123456',
      );
    });

    test('strips dashes from number', () {
      expect(
        WhatsAppService.normalizePhone('+225-07-12-34-56'),
        '+22507123456',
      );
    });

    test('strips parentheses and dots', () {
      expect(
        WhatsAppService.normalizePhone('(+225) 07.12.34.56'),
        '+22507123456',
      );
    });

    test('adds country code for local number starting with 0', () {
      expect(WhatsAppService.normalizePhone('07123456'), '+2257123456');
    });

    test('converts 00 prefix to + international', () {
      expect(WhatsAppService.normalizePhone('0022507123456'), '+22507123456');
    });

    test('adds country code when no prefix', () {
      expect(WhatsAppService.normalizePhone('7123456'), '+2257123456');
    });

    test('handles number with leading 0 correctly', () {
      // 0 is removed and country code added
      expect(WhatsAppService.normalizePhone('0712345678'), '+225712345678');
    });

    test('handles number with leading 0 short', () {
      final result = WhatsAppService.normalizePhone('07123456');
      expect(result.startsWith('+225'), true);
      expect(result.contains('7123456'), true);
    });

    test('handles mixed special characters', () {
      expect(
        WhatsAppService.normalizePhone('+225 (07) 12-34.56'),
        '+22507123456',
      );
    });

    test('preserves already correct format', () {
      expect(WhatsAppService.normalizePhone('+33612345678'), '+33612345678');
    });
  });
}
