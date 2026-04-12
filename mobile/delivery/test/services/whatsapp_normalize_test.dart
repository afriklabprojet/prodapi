import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService.normalizePhone', () {
    test('empty string returns empty', () {
      expect(WhatsAppService.normalizePhone(''), '');
    });

    test('already normalized with + prefix', () {
      expect(
        WhatsAppService.normalizePhone('+2250700000000'),
        '+2250700000000',
      );
    });

    test('strips spaces and dashes', () {
      expect(
        WhatsAppService.normalizePhone('+225 07 00 00 00 00'),
        '+2250700000000',
      );
    });

    test('strips parentheses and dots', () {
      expect(
        WhatsAppService.normalizePhone('+225.07.00.00.00.00'),
        '+2250700000000',
      );
    });

    test('00 prefix becomes + prefix', () {
      expect(
        WhatsAppService.normalizePhone('002250700000000'),
        '+2250700000000',
      );
    });

    test('0 prefix replaced with country code', () {
      expect(WhatsAppService.normalizePhone('0700000000'), '+225700000000');
    });

    test('no prefix adds country code', () {
      expect(WhatsAppService.normalizePhone('700000000'), '+225700000000');
    });

    test('strips non-digit non-plus characters', () {
      expect(
        WhatsAppService.normalizePhone('abc+225xyz0700000000'),
        '+2250700000000',
      );
    });

    test('only non-digit characters returns empty', () {
      expect(WhatsAppService.normalizePhone('abc'), '');
    });

    test('only spaces returns empty', () {
      expect(WhatsAppService.normalizePhone('   '), '');
    });

    test('handles dashes in number', () {
      expect(WhatsAppService.normalizePhone('07-00-00-00-00'), '+225700000000');
    });

    test('handles number with mixed separators', () {
      expect(
        WhatsAppService.normalizePhone('(+225) 07-00.00 00 00'),
        '+2250700000000',
      );
    });
  });
}
