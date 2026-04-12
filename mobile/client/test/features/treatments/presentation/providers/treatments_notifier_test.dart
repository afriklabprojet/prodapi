import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/treatments/domain/repositories/treatments_repository.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_provider.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_state.dart';

class MockTreatmentsRepository extends Mock implements TreatmentsRepository {}

TreatmentEntity _makeTreatment({
  String id = '1',
  String productName = 'Paracétamol 500mg',
  bool reminderEnabled = true,
}) => TreatmentEntity(
  id: id,
  productId: 1,
  productName: productName,
  renewalPeriodDays: 30,
  reminderEnabled: reminderEnabled,
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  late MockTreatmentsRepository mockRepo;
  late TreatmentsNotifier notifier;

  setUp(() {
    mockRepo = MockTreatmentsRepository();
    notifier = TreatmentsNotifier(mockRepo);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('TreatmentsNotifier — initial state', () {
    test('starts at initial status with empty lists', () {
      expect(notifier.state.status, TreatmentsStatus.initial);
      expect(notifier.state.treatments, isEmpty);
      expect(notifier.state.treatmentsNeedingRenewal, isEmpty);
    });
  });

  group('TreatmentsNotifier — loadTreatments', () {
    test('success loads treatments and renewal list', () async {
      final t1 = _makeTreatment(id: '1');
      final t2 = _makeTreatment(id: '2');

      when(
        () => mockRepo.getTreatments(),
      ).thenAnswer((_) async => Right([t1, t2]));
      when(
        () => mockRepo.getTreatmentsNeedingRenewal(),
      ).thenAnswer((_) async => Right([t1]));

      await notifier.loadTreatments();

      expect(notifier.state.status, TreatmentsStatus.loaded);
      expect(notifier.state.treatments.length, 2);
      expect(notifier.state.treatmentsNeedingRenewal.length, 1);
      expect(notifier.state.errorMessage, isNull);
    });

    test('getTreatments failure sets error status', () async {
      const failure = ServerFailure(message: 'Erreur serveur', statusCode: 500);

      when(
        () => mockRepo.getTreatments(),
      ).thenAnswer((_) async => Left(failure));
      when(
        () => mockRepo.getTreatmentsNeedingRenewal(),
      ).thenAnswer((_) async => Right(const []));

      await notifier.loadTreatments();

      expect(notifier.state.status, TreatmentsStatus.error);
      expect(notifier.state.errorMessage, 'Erreur serveur');
    });

    test('renewal failure still sets loaded with empty renewal list', () async {
      final t1 = _makeTreatment();
      when(() => mockRepo.getTreatments()).thenAnswer((_) async => Right([t1]));
      when(
        () => mockRepo.getTreatmentsNeedingRenewal(),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      await notifier.loadTreatments();

      expect(notifier.state.status, TreatmentsStatus.loaded);
      expect(notifier.state.treatments.length, 1);
      expect(notifier.state.treatmentsNeedingRenewal, isEmpty);
    });
  });

  group('TreatmentsNotifier — addTreatment', () {
    test('success appends treatment and returns true', () async {
      final treatment = _makeTreatment(id: '10');

      when(
        () => mockRepo.addTreatment(treatment),
      ).thenAnswer((_) async => Right(treatment));

      final result = await notifier.addTreatment(treatment);

      expect(result, isTrue);
      expect(notifier.state.treatments.length, 1);
      expect(notifier.state.treatments.first.id, '10');
    });

    test('failure returns false', () async {
      final treatment = _makeTreatment();
      when(
        () => mockRepo.addTreatment(treatment),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      final result = await notifier.addTreatment(treatment);
      expect(result, isFalse);
    });

    test(
      'added treatment that needs renewal appears in needingRenewal',
      () async {
        // Treatment with past renewal date is overdue
        final overdueT = TreatmentEntity(
          id: '99',
          productId: 99,
          productName: 'Ibuprofène',
          renewalPeriodDays: 30,
          nextRenewalDate: DateTime.now().subtract(const Duration(days: 5)),
          createdAt: DateTime(2024),
        );

        when(
          () => mockRepo.addTreatment(overdueT),
        ).thenAnswer((_) async => Right(overdueT));

        await notifier.addTreatment(overdueT);

        expect(notifier.state.treatmentsNeedingRenewal.length, 1);
      },
    );
  });

  group('TreatmentsNotifier — updateTreatment', () {
    test('success replaces treatment and returns true', () async {
      // Pre-populate with t1
      final t1 = _makeTreatment(id: '1', productName: 'Avant');
      when(() => mockRepo.addTreatment(t1)).thenAnswer((_) async => Right(t1));
      await notifier.addTreatment(t1);

      final updated = t1.copyWith(productName: 'Après');
      when(
        () => mockRepo.updateTreatment(updated),
      ).thenAnswer((_) async => Right(updated));

      final result = await notifier.updateTreatment(updated);

      expect(result, isTrue);
      expect(notifier.state.treatments.first.productName, 'Après');
    });

    test('failure returns false', () async {
      final t = _makeTreatment();
      when(
        () => mockRepo.updateTreatment(t),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      final result = await notifier.updateTreatment(t);
      expect(result, isFalse);
    });
  });

  group('TreatmentsNotifier — deleteTreatment', () {
    test('success removes treatment and returns true', () async {
      final t = _makeTreatment(id: '1');
      when(() => mockRepo.addTreatment(t)).thenAnswer((_) async => Right(t));
      await notifier.addTreatment(t);
      expect(notifier.state.treatments.length, 1);

      when(
        () => mockRepo.deleteTreatment('1'),
      ).thenAnswer((_) async => const Right(null));

      final result = await notifier.deleteTreatment('1');
      expect(result, isTrue);
      expect(notifier.state.treatments, isEmpty);
    });

    test('failure returns false', () async {
      when(
        () => mockRepo.deleteTreatment('99'),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      final result = await notifier.deleteTreatment('99');
      expect(result, isFalse);
    });
  });

  group('TreatmentsNotifier — markAsOrdered', () {
    test('success updates treatment and returns true', () async {
      final t = _makeTreatment(id: '1');
      when(() => mockRepo.addTreatment(t)).thenAnswer((_) async => Right(t));
      await notifier.addTreatment(t);

      final ordered = t.copyWith(lastOrderedAt: DateTime.now());
      when(
        () => mockRepo.markAsOrdered('1'),
      ).thenAnswer((_) async => Right(ordered));

      final result = await notifier.markAsOrdered('1');
      expect(result, isTrue);
    });

    test('failure returns false', () async {
      when(
        () => mockRepo.markAsOrdered('99'),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      final result = await notifier.markAsOrdered('99');
      expect(result, isFalse);
    });
  });

  group('TreatmentsNotifier — toggleReminder', () {
    test('success updates reminder and returns true', () async {
      final t = _makeTreatment(id: '1', reminderEnabled: true);
      when(() => mockRepo.addTreatment(t)).thenAnswer((_) async => Right(t));
      await notifier.addTreatment(t);

      final toggled = t.copyWith(reminderEnabled: false);
      when(
        () => mockRepo.toggleReminder('1', false),
      ).thenAnswer((_) async => Right(toggled));

      final result = await notifier.toggleReminder('1', false);
      expect(result, isTrue);
      expect(notifier.state.treatments.first.reminderEnabled, isFalse);
    });

    test('failure returns false', () async {
      when(
        () => mockRepo.toggleReminder('99', true),
      ).thenAnswer((_) async => Left(const ServerFailure(message: 'err')));

      final result = await notifier.toggleReminder('99', true);
      expect(result, isFalse);
    });
  });
}
