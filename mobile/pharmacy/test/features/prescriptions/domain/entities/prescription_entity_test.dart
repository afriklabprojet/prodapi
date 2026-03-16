import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/prescriptions/domain/entities/prescription_entity.dart';

void main() {
  group('PrescriptionEntity', () {
    late PrescriptionEntity prescription;

    setUp(() {
      prescription = PrescriptionEntity(
        id: 1,
        customerId: 100,
        status: 'pending',
        notes: 'Test notes',
        images: ['image1.jpg', 'image2.jpg'],
        adminNotes: 'Admin notes',
        pharmacyNotes: 'Pharmacy notes',
        quoteAmount: 5000.0,
        createdAt: DateTime(2024, 3, 10, 10, 30),
        customer: const CustomerInfo(
          id: 100,
          name: 'Client Test',
          phone: '+225 01 02 03 04 05',
          email: 'client@test.com',
        ),
        ocrConfidence: 0.85,
        analysisStatus: AnalysisStatus.completed,
      );
    });

    test('should create PrescriptionEntity with all fields', () {
      expect(prescription.id, 1);
      expect(prescription.customerId, 100);
      expect(prescription.status, 'pending');
      expect(prescription.notes, 'Test notes');
      expect(prescription.images.length, 2);
      expect(prescription.quoteAmount, 5000.0);
      expect(prescription.customer?.name, 'Client Test');
    });

    test('isAnalyzed should return true when status is completed', () {
      expect(prescription.isAnalyzed, true);
    });

    test('needsManualReview should return true when status is manualReview', () {
      final reviewPrescription = prescription.copyWith(
        analysisStatus: AnalysisStatus.manualReview,
      );
      expect(reviewPrescription.needsManualReview, true);
    });

    test('analysisFailed should return true when status is failed', () {
      final failedPrescription = prescription.copyWith(
        analysisStatus: AnalysisStatus.failed,
      );
      expect(failedPrescription.analysisFailed, true);
    });

    test('isPendingAnalysis should return true when status is pending', () {
      final pendingPrescription = prescription.copyWith(
        analysisStatus: AnalysisStatus.pending,
      );
      expect(pendingPrescription.isPendingAnalysis, true);
    });

    group('statusLabel', () {
      test('should return "En attente" for pending status', () {
        final p = prescription.copyWith(status: 'pending');
        expect(p.statusLabel, 'En attente');
      });

      test('should return "En traitement" for processing status', () {
        final p = prescription.copyWith(status: 'processing');
        expect(p.statusLabel, 'En traitement');
      });

      test('should return "Devis envoyé" for quoted status', () {
        final p = prescription.copyWith(status: 'quoted');
        expect(p.statusLabel, 'Devis envoyé');
      });

      test('should return "Approuvée" for approved status', () {
        final p = prescription.copyWith(status: 'approved');
        expect(p.statusLabel, 'Approuvée');
      });

      test('should return "Refusée" for rejected status', () {
        final p = prescription.copyWith(status: 'rejected');
        expect(p.statusLabel, 'Refusée');
      });

      test('should return "Terminée" for completed status', () {
        final p = prescription.copyWith(status: 'completed');
        expect(p.statusLabel, 'Terminée');
      });

      test('should return raw status for unknown status', () {
        final p = prescription.copyWith(status: 'unknown_status');
        expect(p.statusLabel, 'unknown_status');
      });
    });

    test('copyWith should create a new entity with modified fields', () {
      final modified = prescription.copyWith(
        status: 'approved',
        quoteAmount: 7500.0,
      );

      expect(modified.id, prescription.id);
      expect(modified.status, 'approved');
      expect(modified.quoteAmount, 7500.0);
      expect(modified.notes, prescription.notes);
    });
  });

  group('CustomerInfo', () {
    test('should create CustomerInfo with required fields', () {
      const customer = CustomerInfo(
        id: 1,
        name: 'Test Customer',
      );

      expect(customer.id, 1);
      expect(customer.name, 'Test Customer');
      expect(customer.phone, isNull);
      expect(customer.email, isNull);
    });

    test('should create CustomerInfo with all fields', () {
      const customer = CustomerInfo(
        id: 1,
        name: 'Test Customer',
        phone: '+225 01 02 03 04 05',
        email: 'customer@test.com',
      );

      expect(customer.phone, '+225 01 02 03 04 05');
      expect(customer.email, 'customer@test.com');
    });
  });

  group('AnalysisStatus Extension', () {
    test('should convert string to AnalysisStatus', () {
      expect('completed'.toAnalysisStatus(), AnalysisStatus.completed);
      expect('manual_review'.toAnalysisStatus(), AnalysisStatus.manualReview);
      expect('failed'.toAnalysisStatus(), AnalysisStatus.failed);
      expect('pending'.toAnalysisStatus(), AnalysisStatus.pending);
      expect('unknown'.toAnalysisStatus(), AnalysisStatus.pending);
    });

    test('should handle null string', () {
      String? nullString;
      expect(nullString.toAnalysisStatus(), AnalysisStatus.pending);
    });
  });
}
