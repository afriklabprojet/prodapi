import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/prescriptions/presentation/providers/prescription_ocr_provider.dart';

void main() {
  // ──────────────────────────────────────────────────────
  // PrescriptionOcrState
  // ──────────────────────────────────────────────────────
  group('PrescriptionOcrState', () {
    test('defaults', () {
      const s = PrescriptionOcrState();
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
      expect(s.matchedProducts, isEmpty);
      expect(s.unmatchedMedications, isEmpty);
      expect(s.confidence, 0);
      expect(s.rawText, isNull);
    });

    test('hasResults — false when both lists empty', () {
      const s = PrescriptionOcrState();
      expect(s.hasResults, isFalse);
    });

    test('hasResults — true when matchedProducts is non-empty', () {
      final s = PrescriptionOcrState(
        matchedProducts: [const ExtractedMedication(name: 'Paracétamol')],
      );
      expect(s.hasResults, isTrue);
    });

    test('hasResults — true when unmatchedMedications is non-empty', () {
      const s = PrescriptionOcrState(unmatchedMedications: ['Ibuprofen']);
      expect(s.hasResults, isTrue);
    });

    test('copyWith — updates isLoading', () {
      const s = PrescriptionOcrState();
      final next = s.copyWith(isLoading: true);
      expect(next.isLoading, isTrue);
      expect(next.error, isNull); // other fields unchanged
    });

    test('copyWith — setting error explicitly', () {
      const s = PrescriptionOcrState();
      final next = s.copyWith(error: 'Erreur réseau');
      expect(next.error, 'Erreur réseau');
    });

    test('copyWith — clearing error by passing null', () {
      const s = PrescriptionOcrState(error: 'E');
      final next = s.copyWith(error: null);
      expect(next.error, isNull);
    });

    test('copyWith — updates matchedProducts', () {
      const s = PrescriptionOcrState();
      final med = const ExtractedMedication(name: 'Doliprane');
      final next = s.copyWith(matchedProducts: [med]);
      expect(next.matchedProducts, [med]);
    });

    test('copyWith — updates unmatchedMedications', () {
      const s = PrescriptionOcrState();
      final next = s.copyWith(unmatchedMedications: ['Drug A', 'Drug B']);
      expect(next.unmatchedMedications, ['Drug A', 'Drug B']);
    });

    test('copyWith — updates confidence', () {
      const s = PrescriptionOcrState();
      final next = s.copyWith(confidence: 87.5);
      expect(next.confidence, 87.5);
    });

    test('copyWith — updates rawText', () {
      const s = PrescriptionOcrState();
      final next = s.copyWith(rawText: 'Prendre 2 comprimés');
      expect(next.rawText, 'Prendre 2 comprimés');
    });

    test('copyWith — preserves unset fields', () {
      final med = const ExtractedMedication(name: 'Ibuprofène');
      final s = PrescriptionOcrState(
        matchedProducts: [med],
        confidence: 0.9,
        rawText: 'texte',
      );
      final next = s.copyWith(isLoading: false);
      expect(next.matchedProducts, [med]);
      expect(next.confidence, 0.9);
      expect(next.rawText, 'texte');
    });
  });

  // ──────────────────────────────────────────────────────
  // ExtractedMedication
  // ──────────────────────────────────────────────────────
  group('ExtractedMedication', () {
    test('constructor defaults', () {
      const m = ExtractedMedication(name: 'Aspirine');
      expect(m.name, 'Aspirine');
      expect(m.dosage, isNull);
      expect(m.frequency, isNull);
      expect(m.quantity, isNull);
      expect(m.confidence, 0);
      expect(m.productId, isNull);
      expect(m.product, isNull);
    });

    test('fromJson — complete', () {
      final json = {
        'name': 'Doliprane',
        'dosage': '500mg',
        'frequency': '3x/jour',
        'quantity': 2,
        'confidence': 0.85,
        'product_id': 42,
      };
      final m = ExtractedMedication.fromJson(json);
      expect(m.name, 'Doliprane');
      expect(m.dosage, '500mg');
      expect(m.frequency, '3x/jour');
      expect(m.quantity, 2);
      expect(m.confidence, 0.85);
      expect(m.productId, 42);
    });

    test('fromJson — missing optional fields', () {
      final m = ExtractedMedication.fromJson({'name': 'X'});
      expect(m.name, 'X');
      expect(m.dosage, isNull);
      expect(m.frequency, isNull);
      expect(m.quantity, isNull);
      expect(m.confidence, 0);
      expect(m.productId, isNull);
    });

    test('fromJson — null name falls back to empty string', () {
      final m = ExtractedMedication.fromJson({'name': null});
      expect(m.name, '');
    });

    test('fromJson — confidence from int', () {
      final m = ExtractedMedication.fromJson({'name': 'A', 'confidence': 1});
      expect(m.confidence, 1.0);
    });
  });
}
