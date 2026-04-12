import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/treatments/data/repositories/treatments_repository_impl.dart';
import 'package:drpharma_client/features/treatments/data/datasources/treatments_local_datasource.dart';
import 'package:drpharma_client/features/treatments/data/models/treatment_model.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/core/errors/failures.dart';

// ─── Mock ──────────────────────────────────────────────────

class MockTreatmentsLocalDatasource extends Mock
    implements TreatmentsLocalDatasource {}

class _FakeTreatmentModel extends Fake implements TreatmentModel {}

// ─── Helpers ───────────────────────────────────────────────

TreatmentModel _makeTreatmentModel({String id = 'T001'}) => TreatmentModel(
  id: id,
  productId: 1,
  productName: 'Paracetamol',
  renewalPeriodDays: 30,
  createdAt: DateTime(2024, 1, 1),
);

TreatmentEntity _makeTreatmentEntity({String id = 'T001'}) => TreatmentEntity(
  id: id,
  productId: 1,
  productName: 'Paracetamol',
  renewalPeriodDays: 30,
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTreatmentModel());
  });

  late MockTreatmentsLocalDatasource mockDatasource;
  late TreatmentsRepositoryImpl repo;

  setUp(() {
    mockDatasource = MockTreatmentsLocalDatasource();
    repo = TreatmentsRepositoryImpl(mockDatasource);
  });

  // ── getTreatments ──────────────────────────────────────
  group('getTreatments', () {
    test('returns list of entities on success', () async {
      when(() => mockDatasource.getAllTreatments()).thenAnswer(
        (_) async => [
          _makeTreatmentModel(id: 'T001'),
          _makeTreatmentModel(id: 'T002'),
        ],
      );

      final result = await repo.getTreatments();
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) {
        expect(list.length, 2);
        expect(list[0].id, 'T001');
      });
    });

    test('returns empty list on success', () async {
      when(() => mockDatasource.getAllTreatments()).thenAnswer((_) async => []);

      final result = await repo.getTreatments();
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list, isEmpty));
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.getAllTreatments(),
      ).thenThrow(Exception('Hive error'));

      final result = await repo.getTreatments();
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  // ── getTreatmentsNeedingRenewal ────────────────────────
  group('getTreatmentsNeedingRenewal', () {
    test('returns list on success', () async {
      when(
        () => mockDatasource.getTreatmentsNeedingRenewal(),
      ).thenAnswer((_) async => [_makeTreatmentModel()]);

      final result = await repo.getTreatmentsNeedingRenewal();
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.length, 1));
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.getTreatmentsNeedingRenewal(),
      ).thenThrow(Exception('error'));

      final result = await repo.getTreatmentsNeedingRenewal();
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  // ── addTreatment ───────────────────────────────────────
  group('addTreatment', () {
    test('returns saved entity on success', () async {
      final saved = _makeTreatmentModel(id: 'T-SAVED');
      when(
        () => mockDatasource.addTreatment(any()),
      ).thenAnswer((_) async => saved);

      final result = await repo.addTreatment(_makeTreatmentEntity());
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (e) => expect(e.id, 'T-SAVED'));
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.addTreatment(any()),
      ).thenThrow(Exception('write error'));

      final result = await repo.addTreatment(_makeTreatmentEntity());
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  // ── updateTreatment ────────────────────────────────────
  group('updateTreatment', () {
    test('returns updated entity on success', () async {
      final updated = _makeTreatmentModel(id: 'T-UPD');
      when(
        () => mockDatasource.updateTreatment(any()),
      ).thenAnswer((_) async => updated);

      final result = await repo.updateTreatment(
        _makeTreatmentEntity(id: 'T-UPD'),
      );
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (e) => expect(e.id, 'T-UPD'));
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.updateTreatment(any()),
      ).thenThrow(Exception('update error'));

      final result = await repo.updateTreatment(_makeTreatmentEntity());
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail(''));
    });
  });

  // ── deleteTreatment ────────────────────────────────────
  group('deleteTreatment', () {
    test('completes successfully', () async {
      when(
        () => mockDatasource.deleteTreatment(any()),
      ).thenAnswer((_) async {});

      final result = await repo.deleteTreatment('T001');
      expect(result.isRight(), isTrue);
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.deleteTreatment(any()),
      ).thenThrow(Exception('delete error'));

      final result = await repo.deleteTreatment('T001');
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail(''));
    });
  });

  // ── markAsOrdered ──────────────────────────────────────
  group('markAsOrdered', () {
    test('returns updated entity on success', () async {
      when(
        () => mockDatasource.markAsOrdered(any()),
      ).thenAnswer((_) async => _makeTreatmentModel(id: 'T001'));

      final result = await repo.markAsOrdered('T001');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (e) => expect(e.id, 'T001'));
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.markAsOrdered(any()),
      ).thenThrow(Exception('error'));

      final result = await repo.markAsOrdered('T001');
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail(''));
    });
  });

  // ── toggleReminder ─────────────────────────────────────
  group('toggleReminder', () {
    test('returns entity with reminder toggled on success', () async {
      when(
        () => mockDatasource.toggleReminder(any(), any()),
      ).thenAnswer((_) async => _makeTreatmentModel(id: 'T001'));

      final result = await repo.toggleReminder('T001', true);
      expect(result.isRight(), isTrue);
    });

    test('returns CacheFailure on exception', () async {
      when(
        () => mockDatasource.toggleReminder(any(), any()),
      ).thenThrow(Exception('error'));

      final result = await repo.toggleReminder('T001', false);
      result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail(''));
    });
  });
}
