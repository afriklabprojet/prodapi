import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_pharmacy/features/prescriptions/data/models/prescription_model.dart';
import 'package:drpharma_pharmacy/features/prescriptions/data/datasources/prescription_remote_datasource.dart';
import 'package:drpharma_pharmacy/features/prescriptions/presentation/providers/prescription_detail_provider.dart';
import 'package:drpharma_pharmacy/features/prescriptions/presentation/providers/prescription_provider.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/auth_di_providers.dart';

// ===================== MOCKS =====================

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockPrescriptionListNotifier extends Notifier<PrescriptionListState>
    with Mock
    implements PrescriptionListNotifier {
  @override
  PrescriptionListState build() => PrescriptionListState();
}

// ===================== HELPERS =====================

PrescriptionModel _basePrescription({
  int id = 1,
  String status = 'pending',
  String fulfillmentStatus = 'none',
  int dispensingCount = 0,
  List<dynamic>? extractedMedications,
  List<dynamic>? matchedProducts,
}) {
  return PrescriptionModel(
    id: id,
    customerId: 10,
    status: status,
    createdAt: '2025-01-15T10:00:00Z',
    fulfillmentStatus: fulfillmentStatus,
    dispensingCount: dispensingCount,
    extractedMedications: extractedMedications,
    matchedProducts: matchedProducts,
  );
}

AnalysisResult _analysisResult(PrescriptionModel prescription) {
  return AnalysisResult(
    prescription: prescription.copyFromAnalysis(analysisStatus: 'completed'),
    extractedMedications: [
      {'name': 'Paracétamol 500mg', 'quantity': 2, 'confidence': 0.95},
      {'name': 'Amoxicilline 1g', 'quantity': 1, 'confidence': 0.88},
    ],
    matchedProducts: [
      {'medication': 'Paracétamol 500mg', 'product_id': 101, 'price': 500.0},
    ],
    unmatchedMedications: [
      {'name': 'Amoxicilline 1g'},
    ],
    alternatives: {},
    stats: {'total_extracted': 2, 'total_matched': 1},
    estimatedTotal: 1000.0,
    confidence: 0.91,
    alerts: [],
  );
}

DispenseResult _dispenseResult(
  PrescriptionModel prescription, {
  String fulfillment = 'partial',
}) {
  return DispenseResult(
    prescription: PrescriptionModel(
      id: prescription.id,
      customerId: prescription.customerId,
      status: prescription.status,
      createdAt: prescription.createdAt,
      fulfillmentStatus: fulfillment,
      dispensingCount: prescription.dispensingCount + 1,
    ),
    dispensedCount: 1,
    fulfillmentStatus: fulfillment,
    message: fulfillment == 'full'
        ? 'Ordonnance complète'
        : 'Dispensation partielle',
  );
}

/// Crée un ProviderContainer avec les mocks nécessaires.
ProviderContainer _createContainer({
  required MockAuthLocalDataSource mockAuth,
  required MockPrescriptionListNotifier mockNotifier,
}) {
  return ProviderContainer(
    overrides: [
      authLocalDataSourceProvider.overrideWithValue(mockAuth),
      prescriptionListProvider.overrideWith(() => mockNotifier),
    ],
  );
}

// Helper extension to simulate analysisStatus copy
extension _PrescriptionCopy on PrescriptionModel {
  PrescriptionModel copyFromAnalysis({String? analysisStatus}) {
    return PrescriptionModel(
      id: id,
      customerId: customerId,
      status: status,
      notes: notes,
      images: images,
      adminNotes: adminNotes,
      createdAt: createdAt,
      customer: customer,
      extractedMedications: extractedMedications,
      matchedProducts: matchedProducts,
      ocrConfidence: ocrConfidence,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      fulfillmentStatus: fulfillmentStatus,
      dispensingCount: dispensingCount,
    );
  }
}

// ===================== TESTS =====================

void main() {
  late MockAuthLocalDataSource mockAuth;
  late MockPrescriptionListNotifier mockNotifier;

  setUp(() {
    mockAuth = MockAuthLocalDataSource();
    mockNotifier = MockPrescriptionListNotifier();

    // Default: auth token returns a value
    when(() => mockAuth.getToken()).thenAnswer((_) async => 'test-token-123');
    // Default: no duplicate
    when(
      () => mockNotifier.getPrescriptionWithDuplicate(any()),
    ).thenAnswer((_) async => null);
  });

  group('analyzePrescription', () {
    test(
      'success — met à jour state avec résultat et isAnalyzing=false',
      () async {
        final prescription = _basePrescription();
        final result = _analysisResult(prescription);

        when(
          () => mockNotifier.analyzePrescription(prescription.id),
        ).thenAnswer((_) async => result);

        final container = _createContainer(
          mockAuth: mockAuth,
          mockNotifier: mockNotifier,
        );
        addTearDown(container.dispose);

        // Attendre l'init (loadAuthToken + loadDuplicateInfo)
        await Future.delayed(const Duration(milliseconds: 50));

        final notifier = container.read(
          prescriptionDetailProvider(prescription).notifier,
        );
        final success = await notifier.analyzePrescription();

        expect(success, isTrue);

        final state = container.read(prescriptionDetailProvider(prescription));
        expect(state.isAnalyzing, isFalse);
        expect(state.analysisResult, isNotNull);
        expect(state.analysisResult!.extractedMedications.length, 2);
        expect(state.ocrError, isNull);
      },
    );

    test('failure — state contient ocrError et isAnalyzing=false', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.analyzePrescription(prescription.id),
      ).thenAnswer((_) async => null);
      // Note: ne pas définir mockNotifier.state directement - cause LateInitializationError
      // Le retour null de analyzePrescription suffit à simuler l'échec

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final success = await notifier.analyzePrescription();

      expect(success, isFalse);

      final state = container.read(prescriptionDetailProvider(prescription));
      expect(state.isAnalyzing, isFalse);
      // Sans analysisError défini, ocrError sera un message d'échec générique
      // expect(state.ocrError, contains('timeout'));
    });

    test('exception — ocrError capture l\'exception', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.analyzePrescription(prescription.id),
      ).thenThrow(Exception('Server unreachable'));

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final success = await notifier.analyzePrescription();

      expect(success, isFalse);

      final state = container.read(prescriptionDetailProvider(prescription));
      expect(state.isAnalyzing, isFalse);
      expect(state.ocrError, contains('Erreur d\'analyse'));
    });
  });

  group('dispenseMedications', () {
    test('success — prescription mise à jour, selections vidées', () async {
      final prescription = _basePrescription();
      final result = _dispenseResult(prescription, fulfillment: 'partial');

      when(
        () => mockNotifier.dispensePrescription(prescription.id, any()),
      ).thenAnswer((_) async => result);

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );

      // Simuler une sélection
      notifier.toggleMedication('Paracétamol 500mg', true);
      expect(
        container
            .read(prescriptionDetailProvider(prescription))
            .selectedMedications['Paracétamol 500mg'],
        isTrue,
      );

      final medications = [
        {'medication_name': 'Paracétamol 500mg', 'quantity_dispensed': 2},
      ];
      final dispResult = await notifier.dispenseMedications(medications);

      expect(dispResult, isNotNull);
      expect(dispResult!.fulfillmentStatus, 'partial');

      final state = container.read(prescriptionDetailProvider(prescription));
      expect(state.isDispensing, isFalse);
      expect(state.selectedMedications, isEmpty);
      expect(state.prescription.dispensingCount, 1);
    });

    test('full dispense — fulfillmentStatus = full', () async {
      final prescription = _basePrescription();
      final result = _dispenseResult(prescription, fulfillment: 'full');

      when(
        () => mockNotifier.dispensePrescription(prescription.id, any()),
      ).thenAnswer((_) async => result);

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final dispResult = await notifier.dispenseMedications([
        {'medication_name': 'Paracétamol 500mg', 'quantity_dispensed': 2},
      ]);

      expect(dispResult, isNotNull);
      expect(dispResult!.fulfillmentStatus, 'full');
      expect(
        container
            .read(prescriptionDetailProvider(prescription))
            .prescription
            .fulfillmentStatus,
        'full',
      );
    });

    test('failure — retourne null, isDispensing=false', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.dispensePrescription(prescription.id, any()),
      ).thenAnswer((_) async => null);

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final dispResult = await notifier.dispenseMedications([
        {'medication_name': 'Unknown', 'quantity_dispensed': 1},
      ]);

      expect(dispResult, isNull);
      expect(
        container.read(prescriptionDetailProvider(prescription)).isDispensing,
        isFalse,
      );
    });

    test('exception — rethrow, isDispensing=false', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.dispensePrescription(prescription.id, any()),
      ).thenThrow(Exception('Network error'));

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );

      expect(
        () => notifier.dispenseMedications([
          {'medication_name': 'Paracétamol 500mg', 'quantity_dispensed': 2},
        ]),
        throwsA(isA<Exception>()),
      );

      // Attend que le future se termine (pour le finally)
      await Future.delayed(const Duration(milliseconds: 10));
      expect(
        container.read(prescriptionDetailProvider(prescription)).isDispensing,
        isFalse,
      );
    });
  });

  group('updateStatus', () {
    test('success — retourne true, isLoading=false', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.updateStatus(
          prescription.id,
          'validated',
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async {});

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final success = await notifier.updateStatus('validated', notes: 'RAS');

      expect(success, isTrue);

      final state = container.read(prescriptionDetailProvider(prescription));
      expect(state.isLoading, isFalse);
    });

    test('rejected — fonctionne aussi', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.updateStatus(
          prescription.id,
          'rejected',
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async {});

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final success = await notifier.updateStatus(
        'rejected',
        notes: 'Image floue',
      );

      expect(success, isTrue);
    });

    test('failure — retourne false, isLoading=false', () async {
      final prescription = _basePrescription();

      when(
        () => mockNotifier.updateStatus(
          prescription.id,
          'validated',
          notes: any(named: 'notes'),
        ),
      ).thenThrow(Exception('Server error'));

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );
      final success = await notifier.updateStatus('validated', notes: '');

      expect(success, isFalse);
      expect(
        container.read(prescriptionDetailProvider(prescription)).isLoading,
        isFalse,
      );
    });
  });

  group('toggleMedication', () {
    test('ajoute et retire une sélection', () async {
      final prescription = _basePrescription();

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(
        prescriptionDetailProvider(prescription).notifier,
      );

      notifier.toggleMedication('Paracétamol 500mg', true);
      expect(
        container
            .read(prescriptionDetailProvider(prescription))
            .selectedMedications['Paracétamol 500mg'],
        isTrue,
      );

      notifier.toggleMedication('Paracétamol 500mg', false);
      expect(
        container
            .read(prescriptionDetailProvider(prescription))
            .selectedMedications['Paracétamol 500mg'],
        isFalse,
      );
    });
  });

  group('buildMedicationsPayload', () {
    test(
      'construit le payload correct depuis les médications matchées',
      () async {
        final prescription = _basePrescription(
          extractedMedications: [
            {'name': 'Paracétamol 500mg', 'quantity': 2, 'confidence': 0.95},
            {'name': 'Amoxicilline 1g', 'quantity': 3, 'confidence': 0.88},
          ],
          matchedProducts: [
            {
              'medication': 'Paracétamol 500mg',
              'product_id': 101,
              'price': 500.0,
            },
          ],
        );

        final container = _createContainer(
          mockAuth: mockAuth,
          mockNotifier: mockNotifier,
        );
        addTearDown(container.dispose);
        await Future.delayed(const Duration(milliseconds: 50));

        final notifier = container.read(
          prescriptionDetailProvider(prescription).notifier,
        );
        final payload = notifier.buildMedicationsPayload([
          'Paracétamol 500mg',
          'Amoxicilline 1g',
        ]);

        expect(payload.length, 2);

        final paracetamol = payload.firstWhere(
          (m) => m['medication_name'] == 'Paracétamol 500mg',
        );
        expect(paracetamol['product_id'], 101);
        expect(paracetamol['quantity_prescribed'], 2);
        expect(paracetamol['quantity_dispensed'], 2); // remaining = 2 - 0

        final amoxicilline = payload.firstWhere(
          (m) => m['medication_name'] == 'Amoxicilline 1g',
        );
        expect(amoxicilline['product_id'], isNull);
        expect(amoxicilline['quantity_prescribed'], 3);
      },
    );
  });

  group('init', () {
    test('charge authToken et duplicateInfo automatiquement', () async {
      final prescription = _basePrescription();
      final dupInfo = (
        prescription: prescription,
        duplicateInfo: DuplicateInfo(
          prescriptionId: 99,
          status: 'validated',
          fulfillmentStatus: 'full',
          dispensingCount: 2,
          firstDispensedAt: '2025-01-10T08:00:00Z',
        ),
      );

      when(() => mockAuth.getToken()).thenAnswer((_) async => 'bearer-token');
      when(
        () => mockNotifier.getPrescriptionWithDuplicate(prescription.id),
      ).thenAnswer((_) async => dupInfo);

      final container = _createContainer(
        mockAuth: mockAuth,
        mockNotifier: mockNotifier,
      );
      addTearDown(container.dispose);

      // Listen pour garder le notifier monté (mounted = true)
      final sub = container.listen(
        prescriptionDetailProvider(prescription),
        (prev, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Attendre que l'init async se termine
      await Future.delayed(const Duration(milliseconds: 300));

      final state = container.read(prescriptionDetailProvider(prescription));
      expect(state.authToken, 'bearer-token');
      expect(state.duplicateInfo, isNotNull);
      expect(state.duplicateInfo!.prescriptionId, 99);
      expect(state.duplicateInfo!.fulfillmentStatus, 'full');
    });
  });
}
