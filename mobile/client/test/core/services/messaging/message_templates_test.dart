import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/services/messaging/message_templates.dart';

void main() {
  group('MessageTemplates', () {
    group('support', () {
      test('returns default message when no custom message', () {
        expect(
          MessageTemplates.support(),
          'Bonjour, j\'ai besoin d\'aide avec mon compte DR-PHARMA.',
        );
      });

      test('returns custom message when provided', () {
        expect(MessageTemplates.support(customMessage: 'Aide SVP'), 'Aide SVP');
      });
    });

    group('courier', () {
      test('generates minimal message without name or reference', () {
        expect(
          MessageTemplates.courier(),
          'Bonjour, je vous contacte concernant ma livraison.',
        );
      });

      test('includes courier name', () {
        expect(
          MessageTemplates.courier(courierName: 'Moussa'),
          'Bonjour Moussa, je vous contacte concernant ma livraison.',
        );
      });

      test('includes order reference', () {
        expect(
          MessageTemplates.courier(orderReference: 'CMD-001'),
          'Bonjour, je vous contacte concernant ma livraison (commande CMD-001).',
        );
      });

      test('includes both name and reference', () {
        expect(
          MessageTemplates.courier(
            courierName: 'Moussa',
            orderReference: 'CMD-001',
          ),
          'Bonjour Moussa, je vous contacte concernant ma livraison (commande CMD-001).',
        );
      });

      test('ignores empty courier name', () {
        expect(
          MessageTemplates.courier(courierName: ''),
          'Bonjour, je vous contacte concernant ma livraison.',
        );
      });

      test('ignores empty order reference', () {
        expect(
          MessageTemplates.courier(orderReference: ''),
          'Bonjour, je vous contacte concernant ma livraison.',
        );
      });
    });

    group('pharmacy', () {
      test('generates minimal message without name or reference', () {
        expect(
          MessageTemplates.pharmacy(),
          'Bonjour, je vous contacte concernant ma commande.',
        );
      });

      test('includes pharmacy name', () {
        expect(
          MessageTemplates.pharmacy(pharmacyName: 'Pharmacie du Plateau'),
          'Bonjour Pharmacie du Plateau, je vous contacte concernant ma commande.',
        );
      });

      test('includes order reference', () {
        expect(
          MessageTemplates.pharmacy(orderReference: 'CMD-042'),
          'Bonjour, je vous contacte concernant ma commande CMD-042.',
        );
      });

      test('includes both name and reference', () {
        expect(
          MessageTemplates.pharmacy(
            pharmacyName: 'Pharmacie Centrale',
            orderReference: 'CMD-042',
          ),
          'Bonjour Pharmacie Centrale, je vous contacte concernant ma commande CMD-042.',
        );
      });
    });
  });
}
