import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/products/presentation/providers/price_comparison_provider.dart';

void main() {
  group('PriceAlternative.fromJson', () {
    test('parses all fields from valid JSON', () {
      final json = {
        'id': 42,
        'name': 'Paracétamol 1000mg',
        'price': '3500.0',
        'original_price': '4000.0',
        'has_promo': true,
        'stock': 10,
        'pharmacy': {
          'id': 7,
          'name': 'Pharmacie Centrale',
          'address': 'Rue des Fleurs',
        },
      };

      final alt = PriceAlternative.fromJson(json);

      expect(alt.id, 42);
      expect(alt.name, 'Paracétamol 1000mg');
      expect(alt.price, closeTo(3500.0, 0.01));
      expect(alt.originalPrice, closeTo(4000.0, 0.01));
      expect(alt.hasPromo, isTrue);
      expect(alt.stock, 10);
      expect(alt.pharmacyId, 7);
      expect(alt.pharmacyName, 'Pharmacie Centrale');
      expect(alt.pharmacyAddress, 'Rue des Fleurs');
    });

    test('handles integer price values', () {
      final json = {
        'id': 1,
        'name': 'Ibuprofène',
        'price': 2500,
        'has_promo': false,
        'stock': 5,
        'pharmacy': {'id': 1, 'name': 'Pharmacie du Marché'},
      };

      final alt = PriceAlternative.fromJson(json);
      expect(alt.price, closeTo(2500.0, 0.01));
      expect(alt.originalPrice, isNull);
    });

    test('handles has_promo as string "true"', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'price': 1000,
        'has_promo': 'true',
        'stock': 3,
        'pharmacy': {'id': 2, 'name': 'PharmaCie'},
      };
      expect(PriceAlternative.fromJson(json).hasPromo, isTrue);
    });

    test('handles has_promo as false', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'price': 1000,
        'has_promo': false,
        'stock': 0,
        'pharmacy': {'id': 2, 'name': 'PharmaCie'},
      };
      expect(PriceAlternative.fromJson(json).hasPromo, isFalse);
    });

    test('handles null values gracefully', () {
      final json = {
        'id': null,
        'name': null,
        'price': null,
        'has_promo': null,
        'stock': null,
        'pharmacy': <String, dynamic>{},
      };

      final alt = PriceAlternative.fromJson(json);
      expect(alt.id, 0);
      expect(alt.name, '');
      expect(alt.price, 0.0);
      expect(alt.stock, 0);
      expect(alt.pharmacyName, 'Pharmacie'); // default
    });

    test('handles missing pharmacy field', () {
      final json = {
        'id': 1,
        'name': 'Med',
        'price': 1000,
        'has_promo': false,
        'stock': 1,
      };
      final alt = PriceAlternative.fromJson(json);
      expect(alt.pharmacyId, 0);
    });
  });

  group('PriceComparisonState — defaults', () {
    test('isLoading false by default', () {
      const s = PriceComparisonState();
      expect(s.isLoading, isFalse);
    });

    test('alternatives is empty by default', () {
      const s = PriceComparisonState();
      expect(s.alternatives, isEmpty);
    });

    test('error is null by default', () {
      const s = PriceComparisonState();
      expect(s.error, isNull);
    });

    test('currentPrice is null by default', () {
      const s = PriceComparisonState();
      expect(s.currentPrice, isNull);
    });
  });

  group('PriceComparisonState — hasAlternatives', () {
    test('false when no alternatives', () {
      const s = PriceComparisonState();
      expect(s.hasAlternatives, isFalse);
    });

    test('true when alternatives present', () {
      const alt = PriceAlternative(
        id: 1,
        name: 'Med',
        price: 1000,
        hasPromo: false,
        stock: 1,
        pharmacyId: 1,
        pharmacyName: 'Ph',
      );
      const s = PriceComparisonState(alternatives: [alt]);
      expect(s.hasAlternatives, isTrue);
    });
  });

  group('PriceComparisonState — bestPrice', () {
    test('null when no alternatives', () {
      const s = PriceComparisonState();
      expect(s.bestPrice, isNull);
    });

    test('returns cheapest alternative', () {
      const a1 = PriceAlternative(
        id: 1,
        name: 'Med',
        price: 3000,
        hasPromo: false,
        stock: 1,
        pharmacyId: 1,
        pharmacyName: 'Ph1',
      );
      const a2 = PriceAlternative(
        id: 2,
        name: 'Med',
        price: 2000,
        hasPromo: false,
        stock: 5,
        pharmacyId: 2,
        pharmacyName: 'Ph2',
      );
      const a3 = PriceAlternative(
        id: 3,
        name: 'Med',
        price: 4000,
        hasPromo: false,
        stock: 2,
        pharmacyId: 3,
        pharmacyName: 'Ph3',
      );
      const s = PriceComparisonState(alternatives: [a1, a2, a3]);
      expect(s.bestPrice!.price, 2000.0);
    });
  });

  group('PriceComparisonState — potentialSavings', () {
    test('null when currentPrice is null', () {
      const alt = PriceAlternative(
        id: 1,
        name: 'Med',
        price: 2000,
        hasPromo: false,
        stock: 1,
        pharmacyId: 1,
        pharmacyName: 'Ph',
      );
      const s = PriceComparisonState(alternatives: [alt]);
      expect(s.potentialSavings, isNull);
    });

    test('null when no alternatives', () {
      const s = PriceComparisonState(currentPrice: 3000);
      expect(s.potentialSavings, isNull);
    });

    test('returns positive savings when best price < current', () {
      const alt = PriceAlternative(
        id: 1,
        name: 'Med',
        price: 2500,
        hasPromo: false,
        stock: 1,
        pharmacyId: 1,
        pharmacyName: 'Ph',
      );
      const s = PriceComparisonState(alternatives: [alt], currentPrice: 3000);
      expect(s.potentialSavings, closeTo(500.0, 0.01));
    });

    test('null when best price >= current price (no savings)', () {
      const alt = PriceAlternative(
        id: 1,
        name: 'Med',
        price: 3500,
        hasPromo: false,
        stock: 1,
        pharmacyId: 1,
        pharmacyName: 'Ph',
      );
      const s = PriceComparisonState(alternatives: [alt], currentPrice: 3000);
      expect(s.potentialSavings, isNull);
    });
  });

  group('PriceComparisonState — copyWith', () {
    test('updates isLoading', () {
      const s = PriceComparisonState();
      expect(s.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('null error clears error (by design of copyWith)', () {
      final s = const PriceComparisonState(error: 'Erreur');
      // copyWith with no error arg sets error to null (design choice)
      expect(s.copyWith(isLoading: false).error, isNull);
    });

    test('updates currentPrice', () {
      const s = PriceComparisonState();
      expect(s.copyWith(currentPrice: 5000).currentPrice, 5000);
    });
  });
}
