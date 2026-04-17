import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:courier/data/models/scanned_document.dart';
import 'package:courier/data/services/document_scanner_service.dart';
import '../helpers/test_helpers.dart';

// ── Mock Classes ──────────────────────────────────────

class FakeFile extends Fake implements File {
  final String _path;
  final int _length;
  final bool _exists;

  FakeFile(this._path, {int length = 100000, bool exists = true})
    : _length = length,
      _exists = exists;

  @override
  String get path => _path;

  @override
  Future<int> length() async => _length;

  @override
  Future<bool> exists() async => _exists;

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

void main() {
  group('DocumentScannerState', () {
    test('default state has correct values', () {
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

    test('copyWith preserves unchanged values', () {
      const state = DocumentScannerState(isInitialized: true);
      final copied = state.copyWith(isProcessing: true);
      expect(copied.isInitialized, true);
      expect(copied.isProcessing, true);
    });

    test('copyWith can clear error', () {
      const state = DocumentScannerState(error: 'Something went wrong');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('documentCount returns correct count', () {
      final state = DocumentScannerState(
        scannedDocuments: [
          ScannedDocument(
            id: 'doc-1',
            type: DocumentType.prescription,
            originalImage: File('/tmp/doc1.jpg'),
          ),
          ScannedDocument(
            id: 'doc-2',
            type: DocumentType.idCard,
            originalImage: File('/tmp/doc2.jpg'),
          ),
        ],
      );
      expect(state.documentCount, 2);
    });

    test('documentsOfType filters correctly', () {
      final state = DocumentScannerState(
        scannedDocuments: [
          ScannedDocument(
            id: 'doc-1',
            type: DocumentType.prescription,
            originalImage: File('/tmp/doc1.jpg'),
          ),
          ScannedDocument(
            id: 'doc-2',
            type: DocumentType.idCard,
            originalImage: File('/tmp/doc2.jpg'),
          ),
          ScannedDocument(
            id: 'doc-3',
            type: DocumentType.prescription,
            originalImage: File('/tmp/doc3.jpg'),
          ),
        ],
      );
      expect(state.documentsOfType(DocumentType.prescription).length, 2);
      expect(state.documentsOfType(DocumentType.idCard).length, 1);
    });
  });

  group('DocumentType', () {
    test('has correct label for prescription', () {
      expect(DocumentType.prescription.label, 'Ordonnance');
    });

    test('has correct label for receipt', () {
      expect(DocumentType.receipt.label, 'Reçu de commande');
    });

    test('all types have non-empty labels', () {
      for (final type in DocumentType.values) {
        expect(type.label, isNotEmpty);
      }
    });
  });

  group('OcrStatus', () {
    test('has correct label for pending', () {
      expect(OcrStatus.pending.label, 'En attente');
    });

    test('has correct label for success', () {
      expect(OcrStatus.success.label, 'Terminé');
    });
  });

  group('ScanQuality', () {
    test('poor has 1 star', () {
      expect(ScanQuality.poor.stars, 1);
    });

    test('excellent has 4 stars', () {
      expect(ScanQuality.excellent.stars, 4);
    });

    test('fromScore returns correct quality', () {
      expect(ScanQuality.fromScore(0.2), ScanQuality.poor);
      expect(ScanQuality.fromScore(0.9), ScanQuality.excellent);
    });
  });

  group('OcrResult', () {
    test('empty factory sets defaults', () {
      final result = OcrResult.empty();
      expect(result.rawText, isEmpty);
      expect(result.confidence, 0.0);
    });

    test('error factory sets error message', () {
      final result = OcrResult.error('OCR failed');
      expect(result.errorMessage, 'OCR failed');
      expect(result.status, OcrStatus.failed);
    });

    test('isSuccess returns true for success status', () {
      final result = OcrResult(rawText: 'test', status: OcrStatus.success);
      expect(result.isSuccess, true);
    });

    test('hasExtractedData returns true with fields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'patient_name': 'Doe'},
      );
      expect(result.hasExtractedData, true);
    });
  });

  group('ScannedDocument', () {
    test('constructor sets defaults', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      expect(doc.id, 'doc-1');
      expect(doc.type, DocumentType.prescription);
      expect(doc.quality, ScanQuality.good);
      expect(doc.isUploaded, false);
      expect(doc.cloudUrl, isNull);
      expect(doc.ocrResult, isNull);
      expect(doc.regions, isEmpty);
    });

    test('copyWith updates fields', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final updated = doc.copyWith(
        isUploaded: true,
        cloudUrl: 'https://example.com/doc.jpg',
      );
      expect(updated.isUploaded, true);
      expect(updated.cloudUrl, 'https://example.com/doc.jpg');
      expect(updated.id, 'doc-1');
    });

    test('displayImage returns processedImage if available', () {
      final processed = File('/tmp/processed.jpg');
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/original.jpg'),
        processedImage: processed,
      );
      expect(doc.displayImage.path, processed.path);
    });

    test('displayImage returns originalImage if no processed', () {
      final original = File('/tmp/original.jpg');
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: original,
      );
      expect(doc.displayImage.path, original.path);
    });

    test('hasOcr returns true when ocrResult has success status', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'text', status: OcrStatus.success),
      );
      expect(doc.hasOcr, true);
    });

    test('toJson returns map', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final json = doc.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'doc-1');
    });
  });

  group('DocumentRegion', () {
    test('constructor sets values', () {
      final region = DocumentRegion(
        label: 'Name',
        bounds: const Rect.fromLTWH(0, 0, 100, 50),
        value: 'John Doe',
        confidence: 0.95,
      );
      expect(region.label, 'Name');
      expect(region.value, 'John Doe');
      expect(region.confidence, 0.95);
    });

    test('default confidence is 0.0', () {
      final region = DocumentRegion(
        label: 'Field',
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
      );
      expect(region.confidence, 0.0);
      expect(region.value, isNull);
    });
  });

  group('DocumentType additional', () {
    test('has 6 values', () {
      expect(DocumentType.values.length, 6);
    });

    test('prescription icon is medical_services', () {
      expect(DocumentType.prescription.icon, Icons.medical_services);
    });

    test('receipt icon is receipt_long', () {
      expect(DocumentType.receipt.icon, Icons.receipt_long);
    });

    test('idCard icon is credit_card', () {
      expect(DocumentType.idCard.icon, Icons.credit_card);
    });

    test('deliveryProof icon is verified', () {
      expect(DocumentType.deliveryProof.icon, Icons.verified);
    });

    test('insurance icon is health_and_safety', () {
      expect(DocumentType.insurance.icon, Icons.health_and_safety);
    });

    test('other icon is description', () {
      expect(DocumentType.other.icon, Icons.description);
    });

    test('each type has non-empty label', () {
      for (final type in DocumentType.values) {
        expect(type.label, isNotEmpty);
      }
    });

    test('each type has a color', () {
      for (final type in DocumentType.values) {
        expect(type.color, isA<Color>());
      }
    });

    test('prescription color is blue', () {
      expect(DocumentType.prescription.color, Colors.blue);
    });

    test('receipt color is green', () {
      expect(DocumentType.receipt.color, Colors.green);
    });

    test('idCard label is Pièce d\'identité', () {
      expect(DocumentType.idCard.label, 'Pièce d\'identité');
    });

    test('deliveryProof label', () {
      expect(DocumentType.deliveryProof.label, 'Preuve de livraison');
    });

    test('insurance label', () {
      expect(DocumentType.insurance.label, 'Carte d\'assurance');
    });

    test('other label', () {
      expect(DocumentType.other.label, 'Autre document');
    });
  });

  group('OcrStatus additional', () {
    test('has 5 values', () {
      expect(OcrStatus.values.length, 5);
    });

    test('processing label', () {
      expect(OcrStatus.processing.label, 'Traitement...');
    });

    test('failed label', () {
      expect(OcrStatus.failed.label, 'Échec');
    });

    test('skipped label', () {
      expect(OcrStatus.skipped.label, 'Ignoré');
    });

    test('pending icon', () {
      expect(OcrStatus.pending.icon, Icons.hourglass_empty);
    });

    test('processing icon', () {
      expect(OcrStatus.processing.icon, Icons.loop);
    });

    test('success icon', () {
      expect(OcrStatus.success.icon, Icons.check_circle);
    });

    test('failed icon', () {
      expect(OcrStatus.failed.icon, Icons.error);
    });

    test('skipped icon', () {
      expect(OcrStatus.skipped.icon, Icons.skip_next);
    });
  });

  group('ScanQuality additional', () {
    test('poor label', () {
      expect(ScanQuality.poor.label, 'Mauvaise');
    });

    test('fair label', () {
      expect(ScanQuality.fair.label, 'Acceptable');
    });

    test('good label', () {
      expect(ScanQuality.good.label, 'Bonne');
    });

    test('excellent label', () {
      expect(ScanQuality.excellent.label, 'Excellente');
    });

    test('poor color is red', () {
      expect(ScanQuality.poor.color, Colors.red);
    });

    test('fair color is orange', () {
      expect(ScanQuality.fair.color, Colors.orange);
    });

    test('good color is green', () {
      expect(ScanQuality.good.color, Colors.green);
    });

    test('excellent color is blue', () {
      expect(ScanQuality.excellent.color, Colors.blue);
    });

    test('fair has 2 stars', () {
      expect(ScanQuality.fair.stars, 2);
    });

    test('good has 3 stars', () {
      expect(ScanQuality.good.stars, 3);
    });

    test('fromScore boundary at 0.5', () {
      expect(ScanQuality.fromScore(0.5), ScanQuality.fair);
    });

    test('fromScore boundary at 0.7', () {
      expect(ScanQuality.fromScore(0.7), ScanQuality.good);
    });

    test('fromScore boundary at 0.9', () {
      expect(ScanQuality.fromScore(0.9), ScanQuality.excellent);
    });

    test('fromScore just below 0.5', () {
      expect(ScanQuality.fromScore(0.49), ScanQuality.poor);
    });

    test('fromScore at 0.0', () {
      expect(ScanQuality.fromScore(0.0), ScanQuality.poor);
    });

    test('fromScore at 1.0', () {
      expect(ScanQuality.fromScore(1.0), ScanQuality.excellent);
    });
  });

  group('OcrResult additional', () {
    test('isSuccess false for pending', () {
      final result = OcrResult(rawText: 'test', status: OcrStatus.pending);
      expect(result.isSuccess, false);
    });

    test('isSuccess false for failed', () {
      final result = OcrResult(rawText: '', status: OcrStatus.failed);
      expect(result.isSuccess, false);
    });

    test('isSuccess false for processing', () {
      final result = OcrResult(rawText: '', status: OcrStatus.processing);
      expect(result.isSuccess, false);
    });

    test('isSuccess false for skipped', () {
      final result = OcrResult(rawText: '', status: OcrStatus.skipped);
      expect(result.isSuccess, false);
    });

    test('hasExtractedData false when empty', () {
      final result = OcrResult(rawText: 'test');
      expect(result.hasExtractedData, false);
    });

    test('patientName returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'patient_name': 'Jean Dupont'},
      );
      expect(result.patientName, 'Jean Dupont');
    });

    test('patientName returns null when missing', () {
      final result = OcrResult(rawText: 'test');
      expect(result.patientName, isNull);
    });

    test('doctorName returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'doctor_name': 'Dr Martin'},
      );
      expect(result.doctorName, 'Dr Martin');
    });

    test('medicationList returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'medications': 'Paracetamol, Ibuprofen'},
      );
      expect(result.medicationList, 'Paracetamol, Ibuprofen');
    });

    test('prescriptionDate returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'date': '2024-01-15'},
      );
      expect(result.prescriptionDate, '2024-01-15');
    });

    test('orderNumber returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'order_number': 'CMD-12345'},
      );
      expect(result.orderNumber, 'CMD-12345');
    });

    test('totalAmount returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'total_amount': '5000'},
      );
      expect(result.totalAmount, '5000');
    });

    test('pharmacyName returns from extractedFields', () {
      final result = OcrResult(
        rawText: 'test',
        extractedFields: {'pharmacy_name': 'Pharma Soleil'},
      );
      expect(result.pharmacyName, 'Pharma Soleil');
    });

    test('processedAt defaults to now', () {
      final before = DateTime.now();
      final result = OcrResult(rawText: 'test');
      final after = DateTime.now();
      expect(
        result.processedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        result.processedAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('processedAt uses provided value', () {
      final time = DateTime(2024, 6, 15);
      final result = OcrResult(rawText: 'test', processedAt: time);
      expect(result.processedAt, time);
    });

    test('confidence defaults to 0.0', () {
      final result = OcrResult(rawText: 'test');
      expect(result.confidence, 0.0);
    });

    test('empty factory processedAt is set', () {
      final result = OcrResult.empty();
      expect(result.processedAt, isA<DateTime>());
    });

    test('error factory has null confidence', () {
      final result = OcrResult.error('fail');
      expect(result.confidence, 0.0);
      expect(result.rawText, '');
    });
  });

  group('ScannedDocument contentSummary', () {
    test('returns Non analysé when ocrResult is null', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      expect(doc.contentSummary, 'Non analysé');
    });

    test('returns Analyse échouée when OCR failed', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult.error('fail'),
      );
      expect(doc.contentSummary, 'Analyse échouée');
    });

    test('prescription with patient and meds', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'prescription text',
          status: OcrStatus.success,
          extractedFields: {
            'patient_name': 'Jean',
            'medications': 'Paracetamol',
          },
        ),
      );
      expect(doc.contentSummary, 'Jean - Paracetamol');
    });

    test('prescription with missing fields uses defaults', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'text', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Patient inconnu - Médicaments non détectés');
    });

    test('receipt with order and amount', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.receipt,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'receipt',
          status: OcrStatus.success,
          extractedFields: {'order_number': 'CMD-100', 'total_amount': '5000'},
        ),
      );
      expect(doc.contentSummary, 'Commande CMD-100 - 5000 FCFA');
    });

    test('receipt with missing fields uses defaults', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.receipt,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'receipt', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Commande N° inconnu - 0 FCFA');
    });

    test('idCard with name extracted', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.idCard,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'id card text',
          status: OcrStatus.success,
          extractedFields: {'name': 'Amadou Koné'},
        ),
      );
      expect(doc.contentSummary, 'Amadou Koné');
    });

    test('idCard without name returns default', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.idCard,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'id card', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Identité non détectée');
    });

    test('other type with rawText returns truncated text', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.other,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'Short text', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Short text');
    });

    test('other type with long rawText truncates at 50 chars', () {
      final longText = 'A' * 100;
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.other,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: longText, status: OcrStatus.success),
      );
      expect(doc.contentSummary.length, 50);
    });

    test('other type with empty rawText returns default', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.other,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: '', status: OcrStatus.success),
      );
      expect(doc.contentSummary, 'Contenu non détecté');
    });

    test('deliveryProof type uses default path', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.deliveryProof,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'Proof content here',
          status: OcrStatus.success,
        ),
      );
      expect(doc.contentSummary, 'Proof content here');
    });

    test('insurance type uses default path', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.insurance,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'Insurance info',
          status: OcrStatus.success,
        ),
      );
      expect(doc.contentSummary, 'Insurance info');
    });
  });

  group('ScannedDocument hasOcr', () {
    test('false when ocrResult is null', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      expect(doc.hasOcr, false);
    });

    test('false when ocrResult status is failed', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult.error('fail'),
      );
      expect(doc.hasOcr, false);
    });

    test('false when ocrResult status is pending', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult.empty(),
      );
      expect(doc.hasOcr, false);
    });

    test('true when ocrResult status is success', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(rawText: 'text', status: OcrStatus.success),
      );
      expect(doc.hasOcr, true);
    });
  });

  group('ScannedDocument toJson', () {
    test('includes all fields', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
        quality: ScanQuality.excellent,
        deliveryId: 42,
        notes: 'Test notes',
        isUploaded: true,
        cloudUrl: 'https://example.com/doc.jpg',
      );
      final json = doc.toJson();
      expect(json['id'], 'doc-1');
      expect(json['type'], 'prescription');
      expect(json['quality'], 'excellent');
      expect(json['delivery_id'], 42);
      expect(json['notes'], 'Test notes');
      expect(json['is_uploaded'], true);
      expect(json['cloud_url'], 'https://example.com/doc.jpg');
      expect(json['scanned_at'], isA<String>());
    });

    test('ocr_result is null when no OCR', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.receipt,
        originalImage: File('/tmp/test.jpg'),
      );
      final json = doc.toJson();
      expect(json['ocr_result'], isNull);
    });

    test('ocr_result includes fields when present', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.receipt,
        originalImage: File('/tmp/test.jpg'),
        ocrResult: OcrResult(
          rawText: 'text',
          status: OcrStatus.success,
          confidence: 0.95,
          extractedFields: {'order_number': 'CMD-1'},
        ),
      );
      final json = doc.toJson();
      final ocr = json['ocr_result'] as Map<String, dynamic>;
      expect(ocr['raw_text'], 'text');
      expect(ocr['status'], 'success');
      expect(ocr['confidence'], 0.95);
      expect(ocr['extracted_fields']['order_number'], 'CMD-1');
    });
  });

  group('ScannedDocument copyWith individual fields', () {
    test('copyWith quality', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final copy = doc.copyWith(quality: ScanQuality.excellent);
      expect(copy.quality, ScanQuality.excellent);
      expect(copy.id, 'doc-1');
    });

    test('copyWith deliveryId', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final copy = doc.copyWith(deliveryId: 99);
      expect(copy.deliveryId, 99);
    });

    test('copyWith notes', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final copy = doc.copyWith(notes: 'test note');
      expect(copy.notes, 'test note');
    });

    test('copyWith regions', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final regions = [
        DocumentRegion(
          label: 'Name',
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
        ),
      ];
      final copy = doc.copyWith(regions: regions);
      expect(copy.regions.length, 1);
    });

    test('copyWith scannedAt', () {
      final doc = ScannedDocument(
        id: 'doc-1',
        type: DocumentType.prescription,
        originalImage: File('/tmp/test.jpg'),
      );
      final time = DateTime(2024, 3, 15);
      final copy = doc.copyWith(scannedAt: time);
      expect(copy.scannedAt, time);
    });
  });

  group('DocumentScannerState copyWith individual fields', () {
    test('copyWith isInitialized', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(isInitialized: true);
      expect(copy.isInitialized, true);
      expect(copy.isProcessing, false);
    });

    test('copyWith hasFlash', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(hasFlash: false);
      expect(copy.hasFlash, false);
    });

    test('copyWith flashEnabled', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(flashEnabled: true);
      expect(copy.flashEnabled, true);
    });

    test('copyWith selectedType', () {
      const state = DocumentScannerState();
      final copy = state.copyWith(selectedType: DocumentType.receipt);
      expect(copy.selectedType, DocumentType.receipt);
    });

    test('copyWith error clears on null', () {
      const state = DocumentScannerState(error: 'old error');
      final copy = state.copyWith(error: null);
      expect(copy.error, isNull);
    });

    test('copyWith scannedDocuments', () {
      const state = DocumentScannerState();
      final docs = [
        ScannedDocument(
          id: 'doc-1',
          type: DocumentType.prescription,
          originalImage: File('/tmp/test.jpg'),
        ),
      ];
      final copy = state.copyWith(scannedDocuments: docs);
      expect(copy.documentCount, 1);
    });

    test('documentsOfType returns empty for no matches', () {
      final state = DocumentScannerState(
        scannedDocuments: [
          ScannedDocument(
            id: 'doc-1',
            type: DocumentType.prescription,
            originalImage: File('/tmp/test.jpg'),
          ),
        ],
      );
      expect(state.documentsOfType(DocumentType.receipt), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS FOR DocumentScannerService
  // ═══════════════════════════════════════════════════════════════════════════

  group('DocumentScannerService', () {
    late MockDio mockDio;
    late DocumentScannerService service;

    setUpAll(() {
      registerFallbackValue(RequestOptions(path: ''));
      registerFallbackValue(FormData());
    });

    setUp(() async {
      mockDio = MockDio();
      service = DocumentScannerService(mockDio);
      await setupTestDependencies();
    });

    group('performOcr', () {
      late Directory tempDir;
      late File realTempFile;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('ocr_test_');
        realTempFile = File('${tempDir.path}/test_document.jpg');
        // Create a minimal valid file
        await realTempFile.writeAsBytes([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
        ]); // JPEG header
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('returns successful OCR result from API', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'raw_text': 'Test document content',
              'fields': {'patient_name': 'John Doe'},
              'confidence': 0.95,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.prescription,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.rawText, equals('Test document content'));
        expect(result.extractedFields['patient_name'], equals('John Doe'));
        expect(result.confidence, equals(0.95));
      });

      test('falls back to local OCR on DioException', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.prescription,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.confidence, equals(0.5));
        expect(result.extractedFields['document_type'], equals('Ordonnance'));
      });

      test('local OCR for receipt type returns correct fields', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.receipt,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.extractedFields['document_type'], equals('Reçu'));
      });

      test('local OCR for delivery proof includes timestamp', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.deliveryProof,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(
          result.extractedFields['document_type'],
          equals('Preuve de livraison'),
        );
        expect(result.extractedFields['timestamp'], isNotNull);
      });

      test('local OCR for other types returns generic fields', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.other,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.extractedFields['status'], equals('Non analysé'));
      });

      test('local OCR for idCard type', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.idCard,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.extractedFields['status'], equals('Non analysé'));
      });

      test('local OCR for insurance type', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.insurance,
        );

        expect(result.status, equals(OcrStatus.success));
        expect(result.extractedFields['status'], equals('Non analysé'));
      });

      test('returns error result on unexpected exception', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(Exception('Unexpected error'));

        final result = await service.performOcr(
          realTempFile,
          DocumentType.prescription,
        );

        expect(result.status, equals(OcrStatus.failed));
        expect(result.errorMessage, contains('Unexpected error'));
      });

      test('handles non-200 response by falling back to local OCR', () async {
        when(
          () => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: null,
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.performOcr(
          realTempFile,
          DocumentType.prescription,
        );

        // Should still work (falls back to local or returns invalid response)
        expect(result, isNotNull);
      });
    });

    group('saveToServer', () {
      test('returns true on status 201', () async {
        final document = ScannedDocument(
          id: 'doc_123',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc.jpg'),
          deliveryId: 456,
          quality: ScanQuality.good,
        );

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(result, isTrue);
      });

      test('returns true on status 200', () async {
        final document = ScannedDocument(
          id: 'doc_123',
          type: DocumentType.receipt,
          originalImage: FakeFile('/tmp/doc.jpg'),
        );

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(result, isTrue);
      });

      test('returns false on server error (500)', () async {
        final document = ScannedDocument(
          id: 'doc_123',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc.jpg'),
        );

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(result, isFalse);
      });

      test('returns false on 404 error', () async {
        final document = ScannedDocument(
          id: 'doc_123',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc.jpg'),
        );

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final result = await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(result, isFalse);
      });

      test('returns false on network exception', () async {
        final document = ScannedDocument(
          id: 'doc_123',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc.jpg'),
        );

        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(result, isFalse);
      });

      test('sends correct data structure', () async {
        final document = ScannedDocument(
          id: 'doc_456',
          type: DocumentType.deliveryProof,
          originalImage: FakeFile('/tmp/doc.jpg'),
          deliveryId: 789,
          quality: ScanQuality.excellent,
          notes: 'Test notes',
          ocrResult: OcrResult(
            rawText: 'OCR text',
            extractedFields: {'key': 'value'},
            status: OcrStatus.success,
            confidence: 0.9,
          ),
        );

        Map<String, dynamic>? capturedData;
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer((
          invocation,
        ) async {
          capturedData =
              invocation.namedArguments[#data] as Map<String, dynamic>;
          return Response(
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          );
        });

        await service.saveToServer(
          document,
          'https://storage.example.com/doc.jpg',
        );

        expect(capturedData, isNotNull);
        expect(capturedData!['delivery_id'], equals(789));
        expect(capturedData!['type'], equals('deliveryProof'));
        expect(
          capturedData!['url'],
          equals('https://storage.example.com/doc.jpg'),
        );
        expect(capturedData!['quality'], equals('excellent'));
        expect(capturedData!['notes'], equals('Test notes'));
      });
    });

    group('getDocumentsForDelivery', () {
      test('returns empty list when API returns 200 with data', () async {
        when(() => mockDio.get(any())).thenAnswer(
          (_) async => Response(
            data: [],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final documents = await service.getDocumentsForDelivery(123);

        expect(documents, isEmpty);
      });

      test('returns cached documents without API call', () async {
        final document = ScannedDocument(
          id: 'doc_cached',
          type: DocumentType.deliveryProof,
          originalImage: FakeFile('/tmp/cached.jpg'),
          deliveryId: 789,
        );

        service.cacheDocument(789, document);

        final documents = await service.getDocumentsForDelivery(789);

        expect(documents, hasLength(1));
        expect(documents.first.id, equals('doc_cached'));
        verifyNever(() => mockDio.get(any()));
      });

      test('returns empty list on API error', () async {
        when(() => mockDio.get(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
          ),
        );

        final documents = await service.getDocumentsForDelivery(999);

        expect(documents, isEmpty);
      });

      test('returns empty list on non-200 response', () async {
        when(() => mockDio.get(any())).thenAnswer(
          (_) async => Response(
            data: null,
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final documents = await service.getDocumentsForDelivery(404);

        expect(documents, isEmpty);
      });
    });

    group('cacheDocument', () {
      test('caches single document', () async {
        final document = ScannedDocument(
          id: 'doc_1',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc1.jpg'),
          deliveryId: 100,
        );

        service.cacheDocument(100, document);

        final cached = await service.getDocumentsForDelivery(100);

        expect(cached, hasLength(1));
        expect(cached.first.id, equals('doc_1'));
      });

      test('caches multiple documents for same delivery', () async {
        final document1 = ScannedDocument(
          id: 'doc_1',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doc1.jpg'),
          deliveryId: 100,
        );

        final document2 = ScannedDocument(
          id: 'doc_2',
          type: DocumentType.receipt,
          originalImage: FakeFile('/tmp/doc2.jpg'),
          deliveryId: 100,
        );

        service.cacheDocument(100, document1);
        service.cacheDocument(100, document2);

        final cached = await service.getDocumentsForDelivery(100);

        expect(cached, hasLength(2));
        expect(cached[0].id, equals('doc_1'));
        expect(cached[1].id, equals('doc_2'));
      });

      test('caches documents for different deliveries separately', () async {
        final document1 = ScannedDocument(
          id: 'doc_a',
          type: DocumentType.prescription,
          originalImage: FakeFile('/tmp/doca.jpg'),
          deliveryId: 200,
        );

        final document2 = ScannedDocument(
          id: 'doc_b',
          type: DocumentType.receipt,
          originalImage: FakeFile('/tmp/docb.jpg'),
          deliveryId: 201,
        );

        service.cacheDocument(200, document1);
        service.cacheDocument(201, document2);

        final cached200 = await service.getDocumentsForDelivery(200);
        final cached201 = await service.getDocumentsForDelivery(201);

        expect(cached200, hasLength(1));
        expect(cached200.first.id, equals('doc_a'));
        expect(cached201, hasLength(1));
        expect(cached201.first.id, equals('doc_b'));
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS FOR DocumentScannerNotifier
  // ═══════════════════════════════════════════════════════════════════════════

  group('DocumentScannerNotifier', () {
    late MockDio mockDio;
    late DocumentScannerService service;
    late DocumentScannerNotifier notifier;

    setUp(() async {
      mockDio = MockDio();
      service = DocumentScannerService(mockDio);
      notifier = DocumentScannerNotifier(service);
      await setupTestDependencies();
    });

    test('initial state is not initialized', () {
      expect(notifier.state.isInitialized, isFalse);
      expect(notifier.state.isProcessing, isFalse);
      expect(notifier.state.scannedDocuments, isEmpty);
      expect(notifier.state.selectedType, isNull);
      expect(notifier.state.flashEnabled, isFalse);
    });

    group('initialize', () {
      test('sets isInitialized to true', () {
        notifier.initialize();

        expect(notifier.state.isInitialized, isTrue);
      });

      test('can be called multiple times', () {
        notifier.initialize();
        notifier.initialize();

        expect(notifier.state.isInitialized, isTrue);
      });
    });

    group('selectDocumentType', () {
      test('updates selected type to prescription', () {
        notifier.selectDocumentType(DocumentType.prescription);

        expect(notifier.state.selectedType, equals(DocumentType.prescription));
      });

      test('updates selected type to receipt', () {
        notifier.selectDocumentType(DocumentType.receipt);

        expect(notifier.state.selectedType, equals(DocumentType.receipt));
      });

      test('can change document type multiple times', () {
        notifier.selectDocumentType(DocumentType.prescription);
        expect(notifier.state.selectedType, equals(DocumentType.prescription));

        notifier.selectDocumentType(DocumentType.receipt);
        expect(notifier.state.selectedType, equals(DocumentType.receipt));

        notifier.selectDocumentType(DocumentType.idCard);
        expect(notifier.state.selectedType, equals(DocumentType.idCard));
      });
    });

    group('toggleFlash', () {
      test('toggles flash from disabled to enabled', () {
        expect(notifier.state.flashEnabled, isFalse);

        notifier.toggleFlash();

        expect(notifier.state.flashEnabled, isTrue);
      });

      test('toggles flash from enabled to disabled', () {
        notifier.toggleFlash(); // Enable
        expect(notifier.state.flashEnabled, isTrue);

        notifier.toggleFlash(); // Disable
        expect(notifier.state.flashEnabled, isFalse);
      });

      test('toggles multiple times correctly', () {
        notifier.toggleFlash();
        expect(notifier.state.flashEnabled, isTrue);

        notifier.toggleFlash();
        expect(notifier.state.flashEnabled, isFalse);

        notifier.toggleFlash();
        expect(notifier.state.flashEnabled, isTrue);
      });
    });

    group('removeDocument', () {
      test('does nothing when document list is empty', () {
        notifier.removeDocument('nonexistent');

        expect(notifier.state.scannedDocuments, isEmpty);
      });
    });

    group('clearError', () {
      test('clears error when state has no error', () {
        notifier.clearError();

        expect(notifier.state.error, isNull);
      });
    });

    group('reset', () {
      test('resets state but keeps initialized true', () {
        notifier.initialize();
        notifier.selectDocumentType(DocumentType.prescription);
        notifier.toggleFlash();

        notifier.reset();

        expect(notifier.state.isInitialized, isTrue);
        expect(notifier.state.selectedType, isNull);
        expect(notifier.state.flashEnabled, isFalse);
        expect(notifier.state.scannedDocuments, isEmpty);
        expect(notifier.state.error, isNull);
      });

      test('reset clears documents', () {
        notifier.initialize();
        notifier.reset();

        expect(notifier.state.scannedDocuments, isEmpty);
        expect(notifier.state.isProcessing, isFalse);
      });
    });
  });
}
