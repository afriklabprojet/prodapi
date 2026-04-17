import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/providers/promo_code_provider.dart';

void main() {
  group('PromoCodeState — defaults', () {
    test('default constructor has neutral state', () {
      const s = PromoCodeState();
      expect(s.code, isNull);
      expect(s.discount, 0);
      expect(s.description, isNull);
      expect(s.isValidating, isFalse);
      expect(s.error, isNull);
    });

    test('hasDiscount false when code is null', () {
      const s = PromoCodeState(discount: 500);
      expect(s.hasDiscount, isFalse);
    });

    test('hasDiscount false when discount is 0', () {
      const s = PromoCodeState(code: 'PROMO10', discount: 0);
      expect(s.hasDiscount, isFalse);
    });

    test('hasDiscount true when code present and discount > 0', () {
      const s = PromoCodeState(code: 'PROMO10', discount: 1000);
      expect(s.hasDiscount, isTrue);
    });
  });

  group('PromoCodeState — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      const original = PromoCodeState(code: 'ABC', discount: 500);
      final copy = original.copyWith(isValidating: true);
      expect(copy.code, 'ABC');
      expect(copy.discount, 500);
      expect(copy.isValidating, isTrue);
      expect(copy.error, isNull);
    });

    test('copyWith can clear error by passing null', () {
      const original = PromoCodeState(error: 'Code invalide');
      final copy = original.copyWith(error: null);
      expect(copy.error, isNull);
    });

    test('copyWith updates code and discount', () {
      const s = PromoCodeState();
      final copy = s.copyWith(
        code: 'FLASH20',
        discount: 2000,
        description: 'Flash sale',
      );
      expect(copy.code, 'FLASH20');
      expect(copy.discount, 2000);
      expect(copy.description, 'Flash sale');
    });

    test('copyWith with isValidating=false clears loading state', () {
      const loading = PromoCodeState(isValidating: true);
      final done = loading.copyWith(isValidating: false);
      expect(done.isValidating, isFalse);
    });
  });
}
