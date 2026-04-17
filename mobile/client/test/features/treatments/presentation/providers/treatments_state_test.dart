import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_state.dart';

TreatmentEntity _makeTreatment({
  String id = '1',
  String productName = 'Paracétamol 500mg',
}) => TreatmentEntity(
  id: id,
  productId: 1,
  productName: productName,
  renewalPeriodDays: 30,
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  group('TreatmentsState — defaults', () {
    test('initial status is TreatmentsStatus.initial', () {
      const s = TreatmentsState();
      expect(s.status, TreatmentsStatus.initial);
    });

    test('treatments list is empty by default', () {
      const s = TreatmentsState();
      expect(s.treatments, isEmpty);
    });

    test('treatmentsNeedingRenewal is empty by default', () {
      const s = TreatmentsState();
      expect(s.treatmentsNeedingRenewal, isEmpty);
    });

    test('errorMessage is null by default', () {
      const s = TreatmentsState();
      expect(s.errorMessage, isNull);
    });
  });

  group('TreatmentsState — copyWith', () {
    test('updates status', () {
      const s = TreatmentsState();
      expect(
        s.copyWith(status: TreatmentsStatus.loading).status,
        TreatmentsStatus.loading,
      );
    });

    test('updates treatments list', () {
      const s = TreatmentsState();
      final t = _makeTreatment();
      final copy = s.copyWith(treatments: [t]);
      expect(copy.treatments.length, 1);
    });

    test('updates treatmentsNeedingRenewal', () {
      const s = TreatmentsState();
      final t = _makeTreatment();
      final copy = s.copyWith(treatmentsNeedingRenewal: [t]);
      expect(copy.treatmentsNeedingRenewal.length, 1);
    });

    test('null errorMessage clears error (by design)', () {
      const s = TreatmentsState(errorMessage: 'err');
      final copy = s.copyWith(status: TreatmentsStatus.loaded);
      // copyWith always passes errorMessage (null clears it)
      expect(copy.errorMessage, isNull);
    });

    test('sets errorMessage when provided', () {
      const s = TreatmentsState();
      expect(s.copyWith(errorMessage: 'Oops').errorMessage, 'Oops');
    });
  });

  group('TreatmentsState — props equality', () {
    test('two default states are equal', () {
      const a = TreatmentsState();
      const b = TreatmentsState();
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = TreatmentsState(status: TreatmentsStatus.loading);
      const b = TreatmentsState(status: TreatmentsStatus.loaded);
      expect(a, isNot(equals(b)));
    });

    test('same treatments list — equal', () {
      final t = _makeTreatment();
      final a = TreatmentsState(treatments: [t]);
      final b = TreatmentsState(treatments: [t]);
      expect(a, equals(b));
    });
  });
}
