import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/prescriptions/domain/entities/prescription_entity.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_state.dart';

PrescriptionEntity _makePrescription({int id = 1, String status = 'pending'}) =>
    PrescriptionEntity(
      id: id,
      status: status,
      imageUrls: const [],
      createdAt: DateTime(2024, 1, 1),
      fulfillmentStatus: 'none',
      dispensingCount: 0,
    );

void main() {
  group('PrescriptionsStatusX extensions', () {
    test('isLoading true only for loading', () {
      expect(PrescriptionsStatus.loading.isLoading, isTrue);
      expect(PrescriptionsStatus.initial.isLoading, isFalse);
    });

    test('isUploading true only for uploading', () {
      expect(PrescriptionsStatus.uploading.isUploading, isTrue);
      expect(PrescriptionsStatus.loaded.isUploading, isFalse);
    });

    test('isError true only for error', () {
      expect(PrescriptionsStatus.error.isError, isTrue);
      expect(PrescriptionsStatus.loading.isError, isFalse);
    });

    test('isLoaded true only for loaded', () {
      expect(PrescriptionsStatus.loaded.isLoaded, isTrue);
      expect(PrescriptionsStatus.error.isLoaded, isFalse);
    });
  });

  group('PrescriptionsState — defaults', () {
    test('status is initial', () {
      const s = PrescriptionsState();
      expect(s.status, PrescriptionsStatus.initial);
    });

    test('prescriptions list is empty', () {
      const s = PrescriptionsState();
      expect(s.prescriptions, isEmpty);
    });

    test('selectedPrescription is null', () {
      const s = PrescriptionsState();
      expect(s.selectedPrescription, isNull);
    });

    test('uploadedPrescription is null', () {
      const s = PrescriptionsState();
      expect(s.uploadedPrescription, isNull);
    });

    test('errorMessage is null', () {
      const s = PrescriptionsState();
      expect(s.errorMessage, isNull);
    });

    test('lastUploadIsDuplicate defaults to false', () {
      const s = PrescriptionsState();
      expect(s.lastUploadIsDuplicate, isFalse);
    });
  });

  group('PrescriptionsState — copyWith', () {
    test('updates status', () {
      const s = PrescriptionsState();
      expect(
        s.copyWith(status: PrescriptionsStatus.loading).status,
        PrescriptionsStatus.loading,
      );
    });

    test('clearError removes errorMessage', () {
      const s = PrescriptionsState(errorMessage: 'Erreur');
      expect(s.copyWith(clearError: true).errorMessage, isNull);
    });

    test('clearSelected removes selectedPrescription', () {
      final p = _makePrescription();
      final s = PrescriptionsState(selectedPrescription: p);
      expect(s.copyWith(clearSelected: true).selectedPrescription, isNull);
    });

    test('clearUploaded removes uploadedPrescription', () {
      final p = _makePrescription();
      final s = PrescriptionsState(uploadedPrescription: p);
      expect(s.copyWith(clearUploaded: true).uploadedPrescription, isNull);
    });

    test('clearDuplicateInfo resets duplicate fields', () {
      const s = PrescriptionsState(
        lastUploadIsDuplicate: true,
        lastUploadExistingId: 42,
        lastUploadExistingStatus: 'validated',
      );
      final copy = s.copyWith(clearDuplicateInfo: true);
      expect(copy.lastUploadIsDuplicate, isFalse);
      expect(copy.lastUploadExistingId, isNull);
      expect(copy.lastUploadExistingStatus, isNull);
    });

    test('updates prescriptions list', () {
      const s = PrescriptionsState();
      final p = _makePrescription();
      expect(s.copyWith(prescriptions: [p]).prescriptions.length, 1);
    });

    test('errorMessage preserved when not cleared', () {
      const s = PrescriptionsState(errorMessage: 'err');
      expect(
        s.copyWith(status: PrescriptionsStatus.loading).errorMessage,
        'err',
      );
    });
  });

  group('PrescriptionsState — props equality', () {
    test('two default states are equal', () {
      const a = PrescriptionsState();
      const b = PrescriptionsState();
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = PrescriptionsState(status: PrescriptionsStatus.loading);
      const b = PrescriptionsState(status: PrescriptionsStatus.loaded);
      expect(a, isNot(equals(b)));
    });
  });
}
