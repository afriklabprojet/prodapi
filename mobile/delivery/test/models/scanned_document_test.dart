import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/scanned_document.dart';

void main() {
  group('DocumentType', () {
    test('enum has correct labels', () {
      expect(DocumentType.prescription.label, 'Ordonnance');
      expect(DocumentType.receipt.label, 'Reçu de commande');
      expect(DocumentType.idCard.label, "Pièce d'identité");
      expect(DocumentType.deliveryProof.label, 'Preuve de livraison');
      expect(DocumentType.insurance.label, "Carte d'assurance");
      expect(DocumentType.other.label, 'Autre document');
    });

    test('each type has an icon and color', () {
      for (final t in DocumentType.values) {
        expect(t.icon, isA<IconData>());
        expect(t.color, isA<Color>());
      }
    });
  });

  group('OcrStatus', () {
    test('enum has correct labels', () {
      expect(OcrStatus.pending.label, 'En attente');
      expect(OcrStatus.processing.label, 'Traitement...');
      expect(OcrStatus.success.label, 'Terminé');
      expect(OcrStatus.failed.label, 'Échec');
      expect(OcrStatus.skipped.label, 'Ignoré');
    });

    test('each status has an icon', () {
      for (final s in OcrStatus.values) {
        expect(s.icon, isA<IconData>());
      }
    });
  });

  group('ScanQuality', () {
    test('fromScore returns correct quality', () {
      expect(ScanQuality.fromScore(0.95), ScanQuality.excellent);
      expect(ScanQuality.fromScore(0.9), ScanQuality.excellent);
      expect(ScanQuality.fromScore(0.75), ScanQuality.good);
      expect(ScanQuality.fromScore(0.7), ScanQuality.good);
      expect(ScanQuality.fromScore(0.55), ScanQuality.fair);
      expect(ScanQuality.fromScore(0.5), ScanQuality.fair);
      expect(ScanQuality.fromScore(0.3), ScanQuality.poor);
    });

    test('has stars, label and color', () {
      for (final q in ScanQuality.values) {
        expect(q.stars, isA<int>());
        expect(q.label, isNotEmpty);
        expect(q.color, isA<Color>());
      }
    });
  });

  group('OcrResult', () {
    test('empty factory', () {
      final r = OcrResult.empty();
      expect(r.rawText, '');
      expect(r.status, OcrStatus.pending);
      expect(r.isSuccess, isFalse);
      expect(r.hasExtractedData, isFalse);
    });

    test('error factory', () {
      final r = OcrResult.error('timeout');
      expect(r.status, OcrStatus.failed);
      expect(r.errorMessage, 'timeout');
    });

    test('isSuccess checks status', () {
      final r = OcrResult(rawText: 'test', status: OcrStatus.success);
      expect(r.isSuccess, isTrue);
    });

    test('extracted fields accessors', () {
      final r = OcrResult(
        rawText: 'raw',
        status: OcrStatus.success,
        extractedFields: {
          'patient_name': 'John',
          'doctor_name': 'Dr. Smith',
          'medications': 'Aspirin',
          'date': '2024-01-01',
          'order_number': 'ORD-123',
          'total_amount': '5000',
          'pharmacy_name': 'Pharma X',
        },
      );
      expect(r.patientName, 'John');
      expect(r.doctorName, 'Dr. Smith');
      expect(r.medicationList, 'Aspirin');
      expect(r.prescriptionDate, '2024-01-01');
      expect(r.orderNumber, 'ORD-123');
      expect(r.totalAmount, '5000');
      expect(r.pharmacyName, 'Pharma X');
    });

    test('null extracted fields', () {
      final r = OcrResult.empty();
      expect(r.patientName, isNull);
      expect(r.orderNumber, isNull);
    });
  });

  group('DocumentRegion', () {
    test('constructor works', () {
      final region = DocumentRegion(
        label: 'Name',
        bounds: const Rect.fromLTWH(10, 20, 100, 50),
        value: 'John',
        confidence: 0.95,
      );
      expect(region.label, 'Name');
      expect(region.value, 'John');
      expect(region.confidence, 0.95);
    });
  });

  group('ScannedDocument', () {
    final tempFile = File('/tmp/test.jpg');

    test('constructor with defaults', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      expect(doc.id, 'doc1');
      expect(doc.type, DocumentType.prescription);
      expect(doc.quality, ScanQuality.good);
      expect(doc.isUploaded, isFalse);
      expect(doc.scannedAt, isNotNull);
    });

    test('copyWith changes fields', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      final updated = doc.copyWith(
        type: DocumentType.receipt,
        isUploaded: true,
        notes: 'Important',
      );
      expect(updated.type, DocumentType.receipt);
      expect(updated.isUploaded, isTrue);
      expect(updated.notes, 'Important');
      expect(updated.id, 'doc1'); // unchanged
    });

    test('displayImage returns processedImage when available', () {
      final processed = File('/tmp/processed.jpg');
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        processedImage: processed,
      );
      expect(doc.displayImage.path, '/tmp/processed.jpg');
    });

    test('displayImage returns originalImage when no processed', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      expect(doc.displayImage.path, tempFile.path);
    });

    test('hasOcr false when ocrResult is null', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      expect(doc.hasOcr, isFalse);
    });

    test('hasOcr false when ocrResult is not success', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        ocrResult: OcrResult.error('failed'),
      );
      expect(doc.hasOcr, isFalse);
    });

    test('hasOcr true when ocrResult is success', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: 'test', status: OcrStatus.success),
      );
      expect(doc.hasOcr, isTrue);
    });

    test('contentSummary returns Non analysé when no OCR', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      expect(doc.contentSummary, 'Non analysé');
    });

    test('contentSummary returns Analyse échouée when OCR failed', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        ocrResult: OcrResult.error('timeout'),
      );
      expect(doc.contentSummary, 'Analyse échouée');
    });

    test('contentSummary for prescription type with patient & meds', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        ocrResult: OcrResult(
          rawText: 'rx',
          status: OcrStatus.success,
          extractedFields: {
            'patient_name': 'Jean Doe',
            'medications': 'Aspirine 500mg',
          },
        ),
      );
      expect(doc.contentSummary, contains('Jean Doe'));
      expect(doc.contentSummary, contains('Aspirine 500mg'));
    });

    test('contentSummary for prescription with missing fields', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: 'rx', status: OcrStatus.success),
      );
      expect(doc.contentSummary, contains('Patient inconnu'));
      expect(doc.contentSummary, contains('Médicaments non détectés'));
    });

    test('contentSummary for receipt type', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.receipt,
        originalImage: tempFile,
        ocrResult: OcrResult(
          rawText: 'receipt',
          status: OcrStatus.success,
          extractedFields: {'order_number': 'ORD-456', 'total_amount': '15000'},
        ),
      );
      expect(doc.contentSummary, contains('ORD-456'));
      expect(doc.contentSummary, contains('15000'));
    });

    test('contentSummary for receipt with missing fields', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.receipt,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: 'receipt', status: OcrStatus.success),
      );
      expect(doc.contentSummary, contains('N° inconnu'));
      expect(doc.contentSummary, contains('0'));
    });

    test('contentSummary for idCard type with name', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.idCard,
        originalImage: tempFile,
        ocrResult: OcrResult(
          rawText: 'id',
          status: OcrStatus.success,
          extractedFields: {'name': 'Ali Koné'},
        ),
      );
      expect(doc.contentSummary, 'Ali Koné');
    });

    test('contentSummary for idCard without name', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.idCard,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: 'id', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Identité non détectée');
    });

    test('contentSummary for other type truncates rawText at 50 chars', () {
      final longText = 'A' * 100;
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.other,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: longText, status: OcrStatus.success),
      );
      expect(doc.contentSummary.length, 50);
    });

    test('contentSummary for other type with short rawText', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.other,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: 'Short text', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Short text');
    });

    test('contentSummary for other type with empty rawText', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.other,
        originalImage: tempFile,
        ocrResult: OcrResult(rawText: '', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Contenu non détecté');
    });

    test('toJson includes all fields', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
        deliveryId: 42,
        notes: 'Test note',
        isUploaded: true,
        cloudUrl: 'https://storage.example.com/doc1',
        ocrResult: OcrResult(
          rawText: 'raw',
          status: OcrStatus.success,
          confidence: 0.95,
          extractedFields: {'patient_name': 'Jean'},
        ),
      );
      final json = doc.toJson();
      expect(json['id'], 'doc1');
      expect(json['type'], 'prescription');
      expect(json['quality'], 'good');
      expect(json['delivery_id'], 42);
      expect(json['notes'], 'Test note');
      expect(json['is_uploaded'], true);
      expect(json['cloud_url'], 'https://storage.example.com/doc1');
      expect(json['ocr_result'], isNotNull);
      expect(json['ocr_result']['raw_text'], 'raw');
      expect(json['ocr_result']['confidence'], 0.95);
      expect(json['ocr_result']['status'], 'success');
      expect(json['ocr_result']['extracted_fields']['patient_name'], 'Jean');
    });

    test('toJson with null ocrResult', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      final json = doc.toJson();
      expect(json['ocr_result'], isNull);
    });

    test('copyWith preserves all when no changes', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.insurance,
        originalImage: tempFile,
        quality: ScanQuality.excellent,
        deliveryId: 10,
        notes: 'Note',
        isUploaded: true,
        cloudUrl: 'https://cloud.com/doc1',
      );
      final copy = doc.copyWith();
      expect(copy.id, 'doc1');
      expect(copy.type, DocumentType.insurance);
      expect(copy.quality, ScanQuality.excellent);
      expect(copy.deliveryId, 10);
      expect(copy.notes, 'Note');
      expect(copy.isUploaded, true);
      expect(copy.cloudUrl, 'https://cloud.com/doc1');
    });

    test('copyWith updates quality only', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      final copy = doc.copyWith(quality: ScanQuality.poor);
      expect(copy.quality, ScanQuality.poor);
      expect(copy.id, 'doc1');
    });

    test('copyWith updates cloudUrl only', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      final copy = doc.copyWith(cloudUrl: 'https://new.com/doc');
      expect(copy.cloudUrl, 'https://new.com/doc');
    });

    test('copyWith updates deliveryId only', () {
      final doc = ScannedDocument(
        id: 'doc1',
        type: DocumentType.prescription,
        originalImage: tempFile,
      );
      final copy = doc.copyWith(deliveryId: 999);
      expect(copy.deliveryId, 999);
    });
  });

  // ── DocumentScannerState ────────────────────────────
  group('DocumentScannerState additional', () {
    test('defaults are correct', () {
      const state = DocumentScannerState();
      expect(state.isInitialized, false);
      expect(state.isProcessing, false);
      expect(state.hasFlash, true);
      expect(state.flashEnabled, false);
      expect(state.scannedDocuments, isEmpty);
      expect(state.selectedType, isNull);
      expect(state.error, isNull);
      expect(state.documentCount, 0);
    });

    test('copyWith clears error with null', () {
      const state = DocumentScannerState(error: 'old error');
      final copy = state.copyWith(error: null);
      expect(copy.error, isNull);
    });

    test('copyWith sets error', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(error: 'something bad');
      expect(copy.error, 'something bad');
    });

    test('documentCount reflects scannedDocuments length', () {
      final state = DocumentScannerState(
        scannedDocuments: [
          ScannedDocument(
            id: 'a',
            type: DocumentType.prescription,
            originalImage: File('/tmp/a.jpg'),
          ),
          ScannedDocument(
            id: 'b',
            type: DocumentType.receipt,
            originalImage: File('/tmp/b.jpg'),
          ),
        ],
      );
      expect(state.documentCount, 2);
    });

    test('documentsOfType filters correctly', () {
      final state = DocumentScannerState(
        scannedDocuments: [
          ScannedDocument(
            id: 'a',
            type: DocumentType.prescription,
            originalImage: File('/tmp/a.jpg'),
          ),
          ScannedDocument(
            id: 'b',
            type: DocumentType.receipt,
            originalImage: File('/tmp/b.jpg'),
          ),
          ScannedDocument(
            id: 'c',
            type: DocumentType.prescription,
            originalImage: File('/tmp/c.jpg'),
          ),
        ],
      );
      expect(state.documentsOfType(DocumentType.prescription).length, 2);
      expect(state.documentsOfType(DocumentType.receipt).length, 1);
      expect(state.documentsOfType(DocumentType.idCard).length, 0);
    });

    test('copyWith updates isInitialized only', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(isInitialized: true);
      expect(copy.isInitialized, true);
      expect(copy.isProcessing, false);
    });

    test('copyWith updates isProcessing only', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(isProcessing: true);
      expect(copy.isProcessing, true);
      expect(copy.isInitialized, false);
    });

    test('copyWith updates hasFlash only', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(hasFlash: false);
      expect(copy.hasFlash, false);
    });
  });

  // ── ScanQuality additional ──────────────────────────
  group('ScanQuality additional', () {
    test('stars are in order 1-4', () {
      expect(ScanQuality.poor.stars, 1);
      expect(ScanQuality.fair.stars, 2);
      expect(ScanQuality.good.stars, 3);
      expect(ScanQuality.excellent.stars, 4);
    });

    test('fromScore boundary at 0.9', () {
      expect(ScanQuality.fromScore(0.89), ScanQuality.good);
      expect(ScanQuality.fromScore(0.90), ScanQuality.excellent);
    });

    test('fromScore boundary at 0.7', () {
      expect(ScanQuality.fromScore(0.69), ScanQuality.fair);
      expect(ScanQuality.fromScore(0.70), ScanQuality.good);
    });

    test('fromScore boundary at 0.5', () {
      expect(ScanQuality.fromScore(0.49), ScanQuality.poor);
      expect(ScanQuality.fromScore(0.50), ScanQuality.fair);
    });

    test('fromScore with 0.0', () {
      expect(ScanQuality.fromScore(0.0), ScanQuality.poor);
    });

    test('fromScore with 1.0', () {
      expect(ScanQuality.fromScore(1.0), ScanQuality.excellent);
    });

    test('specific colors', () {
      expect(ScanQuality.poor.color, Colors.red);
      expect(ScanQuality.fair.color, Colors.orange);
      expect(ScanQuality.good.color, Colors.green);
      expect(ScanQuality.excellent.color, Colors.blue);
    });

    test('specific labels', () {
      expect(ScanQuality.poor.label, 'Mauvaise');
      expect(ScanQuality.fair.label, 'Acceptable');
      expect(ScanQuality.good.label, 'Bonne');
      expect(ScanQuality.excellent.label, 'Excellente');
    });
  });

  // ── OcrResult additional ────────────────────────────
  group('OcrResult additional', () {
    test('hasExtractedData true when fields non-empty', () {
      final r = OcrResult(
        rawText: 'test',
        status: OcrStatus.success,
        extractedFields: {'key': 'value'},
      );
      expect(r.hasExtractedData, isTrue);
    });

    test('hasExtractedData false when fields empty', () {
      final r = OcrResult(rawText: 'test', status: OcrStatus.success);
      expect(r.hasExtractedData, isFalse);
    });

    test('processedAt defaults to now', () {
      final before = DateTime.now();
      final r = OcrResult(rawText: 'test');
      expect(
        r.processedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
    });

    test('processedAt uses provided value', () {
      final custom = DateTime(2020, 1, 1);
      final r = OcrResult(rawText: 'test', processedAt: custom);
      expect(r.processedAt, custom);
    });

    test('confidence defaults to 0.0', () {
      final r = OcrResult(rawText: 'test');
      expect(r.confidence, 0.0);
    });

    test('error factory has empty rawText', () {
      final r = OcrResult.error('msg');
      expect(r.rawText, '');
    });
  });

  // ── DocumentType additional ─────────────────────────
  group('DocumentType additional', () {
    test('has 6 values', () {
      expect(DocumentType.values.length, 6);
    });

    test('specific icons', () {
      expect(DocumentType.prescription.icon, Icons.medical_services);
      expect(DocumentType.receipt.icon, Icons.receipt_long);
      expect(DocumentType.idCard.icon, Icons.credit_card);
      expect(DocumentType.deliveryProof.icon, Icons.verified);
      expect(DocumentType.insurance.icon, Icons.health_and_safety);
      expect(DocumentType.other.icon, Icons.description);
    });

    test('specific colors', () {
      expect(DocumentType.prescription.color, Colors.blue);
      expect(DocumentType.receipt.color, Colors.green);
      expect(DocumentType.idCard.color, Colors.orange);
      expect(DocumentType.deliveryProof.color, Colors.purple);
      expect(DocumentType.insurance.color, Colors.teal);
      expect(DocumentType.other.color, Colors.grey);
    });
  });

  // ── OcrStatus additional ────────────────────────────
  group('OcrStatus additional', () {
    test('has 5 values', () {
      expect(OcrStatus.values.length, 5);
    });

    test('specific icons', () {
      expect(OcrStatus.pending.icon, Icons.hourglass_empty);
      expect(OcrStatus.processing.icon, Icons.loop);
      expect(OcrStatus.success.icon, Icons.check_circle);
      expect(OcrStatus.failed.icon, Icons.error);
      expect(OcrStatus.skipped.icon, Icons.skip_next);
    });
  });
}
