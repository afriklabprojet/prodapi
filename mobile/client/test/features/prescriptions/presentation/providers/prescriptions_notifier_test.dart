import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/prescriptions/data/datasources/prescriptions_remote_datasource.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_notifier.dart';
import 'package:drpharma_client/features/prescriptions/presentation/providers/prescriptions_state.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────

class MockPrescriptionsRemoteDataSource extends Mock
    implements PrescriptionsRemoteDataSource {}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

Map<String, dynamic> _prescriptionJson({
  int id = 1,
  String status = 'pending',
}) => {
  'id': id,
  'status': status,
  'images': <dynamic>[],
  'created_at': '2024-01-01T00:00:00.000Z',
  'fulfillment_status': 'none',
};

void main() {
  late MockPrescriptionsRemoteDataSource mockDataSource;
  late PrescriptionsNotifier notifier;

  setUp(() {
    mockDataSource = MockPrescriptionsRemoteDataSource();
    notifier = PrescriptionsNotifier(remoteDataSource: mockDataSource);
  });

  group('PrescriptionsNotifier', () {
    // ── initial state ──────────────────────────────────────
    test('initial state is initial with empty prescriptions', () {
      expect(notifier.state.status, PrescriptionsStatus.initial);
      expect(notifier.state.prescriptions, isEmpty);
      expect(notifier.state.selectedPrescription, isNull);
    });

    // ── loadPrescriptions ──────────────────────────────────
    group('loadPrescriptions', () {
      test('success — emits loaded with prescriptions', () async {
        when(() => mockDataSource.getPrescriptions()).thenAnswer(
          (_) async => [
            _prescriptionJson(id: 1),
            _prescriptionJson(id: 2, status: 'validated'),
          ],
        );

        await notifier.loadPrescriptions();

        expect(notifier.state.status, PrescriptionsStatus.loaded);
        expect(notifier.state.prescriptions.length, 2);
        expect(notifier.state.prescriptions[0].id, 1);
        expect(notifier.state.prescriptions[1].status, 'validated');
      });

      test('success — empty list results in empty prescriptions', () async {
        when(
          () => mockDataSource.getPrescriptions(),
        ).thenAnswer((_) async => []);

        await notifier.loadPrescriptions();

        expect(notifier.state.status, PrescriptionsStatus.loaded);
        expect(notifier.state.prescriptions, isEmpty);
      });

      test('error — emits error status with message', () async {
        when(
          () => mockDataSource.getPrescriptions(),
        ).thenThrow(Exception('Network error'));

        await notifier.loadPrescriptions();

        expect(notifier.state.status, PrescriptionsStatus.error);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.errorMessage, contains('Network error'));
      });

      test('transitions through loading', () async {
        when(
          () => mockDataSource.getPrescriptions(),
        ).thenAnswer((_) async => []);

        final statuses = <PrescriptionsStatus>[];
        notifier.addListener((s) => statuses.add(s.status));

        await notifier.loadPrescriptions();

        expect(statuses, contains(PrescriptionsStatus.loading));
        expect(statuses.last, PrescriptionsStatus.loaded);
      });
    });

    // ── getPrescriptionDetails ─────────────────────────────
    group('getPrescriptionDetails', () {
      test('success — emits loaded with selectedPrescription', () async {
        when(
          () => mockDataSource.getPrescriptionDetails(42),
        ).thenAnswer((_) async => _prescriptionJson(id: 42));

        await notifier.getPrescriptionDetails(42);

        expect(notifier.state.status, PrescriptionsStatus.loaded);
        expect(notifier.state.selectedPrescription, isNotNull);
        expect(notifier.state.selectedPrescription!.id, 42);
      });

      test('error — emits error status', () async {
        when(
          () => mockDataSource.getPrescriptionDetails(99),
        ).thenThrow(Exception('Not found'));

        await notifier.getPrescriptionDetails(99);

        expect(notifier.state.status, PrescriptionsStatus.error);
        expect(notifier.state.errorMessage, contains('Not found'));
      });
    });

    // ── uploadPrescription ─────────────────────────────────
    group('uploadPrescription', () {
      test('success — returns entity and emits loaded', () async {
        when(
          () => mockDataSource.uploadPrescription(
            images: any(named: 'images'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => {
            'data': _prescriptionJson(id: 10),
            'is_duplicate': false,
          },
        );

        final result = await notifier.uploadPrescription(images: []);

        expect(result, isNotNull);
        expect(result!.id, 10);
        expect(notifier.state.status, PrescriptionsStatus.loaded);
        expect(notifier.state.uploadedPrescription, isNotNull);
        expect(notifier.state.lastUploadIsDuplicate, isFalse);
      });

      test('success — detects duplicate', () async {
        when(
          () => mockDataSource.uploadPrescription(
            images: any(named: 'images'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => {
            'data': _prescriptionJson(id: 5),
            'is_duplicate': true,
            'existing_prescription_id': 3,
            'existing_status': 'pending',
          },
        );

        await notifier.uploadPrescription(images: []);

        expect(notifier.state.lastUploadIsDuplicate, isTrue);
        expect(notifier.state.lastUploadExistingId, 3);
        expect(notifier.state.lastUploadExistingStatus, 'pending');
      });

      test('error — returns null and emits error', () async {
        when(
          () => mockDataSource.uploadPrescription(
            images: any(named: 'images'),
            notes: any(named: 'notes'),
          ),
        ).thenThrow(Exception('Upload failed'));

        final result = await notifier.uploadPrescription(images: []);

        expect(result, isNull);
        expect(notifier.state.status, PrescriptionsStatus.error);
      });

      test('transitions through uploading state', () async {
        when(
          () => mockDataSource.uploadPrescription(
            images: any(named: 'images'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => {'data': _prescriptionJson(), 'is_duplicate': false},
        );

        final statuses = <PrescriptionsStatus>[];
        notifier.addListener((s) => statuses.add(s.status));

        await notifier.uploadPrescription(images: []);

        expect(statuses, contains(PrescriptionsStatus.uploading));
      });
    });

    // ── payPrescription ────────────────────────────────────
    group('payPrescription', () {
      test('success — emits loaded with selected prescription', () async {
        when(
          () => mockDataSource.payPrescription(7, 'jeko'),
        ).thenAnswer((_) async => _prescriptionJson(id: 7, status: 'paid'));

        await notifier.payPrescription(7);

        expect(notifier.state.status, PrescriptionsStatus.loaded);
        expect(notifier.state.selectedPrescription!.id, 7);
        expect(notifier.state.selectedPrescription!.status, 'paid');
      });

      test('error — emits error status', () async {
        when(
          () => mockDataSource.payPrescription(9, 'jeko'),
        ).thenThrow(Exception('Payment failed'));

        await notifier.payPrescription(9);

        expect(notifier.state.status, PrescriptionsStatus.error);
        expect(notifier.state.errorMessage, contains('Payment failed'));
      });
    });
  });
}
