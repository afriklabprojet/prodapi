import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';

void main() {
  final baseDate = DateTime(2024, 6, 15);

  TreatmentEntity makeTreatment({
    DateTime? nextRenewalDate,
    int reminderDaysBefore = 3,
    bool reminderEnabled = true,
    bool isActive = true,
  }) {
    return TreatmentEntity(
      id: 'tx-001',
      productId: 42,
      productName: 'Metformine 1000mg',
      renewalPeriodDays: 30,
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      isActive: isActive,
      nextRenewalDate: nextRenewalDate,
      createdAt: baseDate,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // daysUntilRenewal
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity.daysUntilRenewal', () {
    test('returns null when nextRenewalDate is null', () {
      expect(makeTreatment().daysUntilRenewal, isNull);
    });

    test('returns positive days for future date', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final days = makeTreatment(nextRenewalDate: future).daysUntilRenewal;
      expect(days, greaterThanOrEqualTo(9)); // allow 1 day margin
      expect(days, lessThanOrEqualTo(10));
    });

    test('returns negative days for past date', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final days = makeTreatment(nextRenewalDate: past).daysUntilRenewal;
      expect(days, lessThan(0));
    });

    test('returns 0 for today', () {
      final today = DateTime.now();
      final days = makeTreatment(nextRenewalDate: today).daysUntilRenewal;
      expect(days, equals(0));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // needsRenewalSoon
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity.needsRenewalSoon', () {
    test('false when nextRenewalDate is null', () {
      expect(makeTreatment().needsRenewalSoon, isFalse);
    });

    test('true when days until renewal <= reminderDaysBefore', () {
      final soon = DateTime.now().add(const Duration(days: 2));
      expect(
        makeTreatment(
          nextRenewalDate: soon,
          reminderDaysBefore: 3,
        ).needsRenewalSoon,
        isTrue,
      );
    });

    test('false when days until renewal > reminderDaysBefore', () {
      final later = DateTime.now().add(const Duration(days: 10));
      expect(
        makeTreatment(
          nextRenewalDate: later,
          reminderDaysBefore: 3,
        ).needsRenewalSoon,
        isFalse,
      );
    });

    test('true when overdue (negative days)', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(makeTreatment(nextRenewalDate: past).needsRenewalSoon, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // isOverdue
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity.isOverdue', () {
    test('false when nextRenewalDate is null', () {
      expect(makeTreatment().isOverdue, isFalse);
    });

    test('true when renewal date is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(makeTreatment(nextRenewalDate: past).isOverdue, isTrue);
    });

    test('false when renewal date is today', () {
      final today = DateTime.now();
      expect(makeTreatment(nextRenewalDate: today).isOverdue, isFalse);
    });

    test('false when renewal date is in the future', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(makeTreatment(nextRenewalDate: future).isOverdue, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // copyWith
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity.copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = makeTreatment(reminderDaysBefore: 5);
      final copy = original.copyWith(productName: 'Aspirine 250mg');
      expect(copy.productName, 'Aspirine 250mg');
      expect(copy.reminderDaysBefore, 5);
      expect(copy.id, 'tx-001');
    });

    test('copyWith updates reminderEnabled', () {
      final original = makeTreatment(reminderEnabled: true);
      final copy = original.copyWith(reminderEnabled: false);
      expect(copy.reminderEnabled, isFalse);
    });

    test('copyWith updates isActive', () {
      final original = makeTreatment(isActive: true);
      final copy = original.copyWith(isActive: false);
      expect(copy.isActive, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // props equality
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity props', () {
    test('same entity data → equal', () {
      final a = makeTreatment();
      final b = makeTreatment();
      expect(a, equals(b));
    });

    test('different productId → not equal', () {
      final a = makeTreatment();
      final b = a.copyWith(productId: 999);
      expect(a, isNot(equals(b)));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // TreatmentFrequency
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentFrequency', () {
    test('onceDaily label', () {
      expect(TreatmentFrequency.onceDaily.label, '1 fois par jour');
    });
    test('twiceDaily label', () {
      expect(TreatmentFrequency.twiceDaily.label, '2 fois par jour');
    });
    test('thriceDaily label', () {
      expect(TreatmentFrequency.thriceDaily.label, '3 fois par jour');
    });
    test('fourTimesDaily label', () {
      expect(TreatmentFrequency.fourTimesDaily.label, '4 fois par jour');
    });
    test('onceWeekly label', () {
      expect(TreatmentFrequency.onceWeekly.label, '1 fois par semaine');
    });
    test('asNeeded label', () {
      expect(TreatmentFrequency.asNeeded.label, 'Au besoin');
    });
    test('custom label', () {
      expect(TreatmentFrequency.custom.label, 'Personnalisé');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // RenewalPeriod
  // ────────────────────────────────────────────────────────────────────────────
  group('RenewalPeriod', () {
    test('oneWeek has correct days and label', () {
      expect(RenewalPeriod.oneWeek.days, 7);
      expect(RenewalPeriod.oneWeek.label, '1 semaine');
    });
    test('twoWeeks has correct days and label', () {
      expect(RenewalPeriod.twoWeeks.days, 14);
      expect(RenewalPeriod.twoWeeks.label, '2 semaines');
    });
    test('oneMonth has correct days and label', () {
      expect(RenewalPeriod.oneMonth.days, 30);
      expect(RenewalPeriod.oneMonth.label, '1 mois');
    });
    test('twoMonths has correct days and label', () {
      expect(RenewalPeriod.twoMonths.days, 60);
    });
    test('threeMonths has correct days and label', () {
      expect(RenewalPeriod.threeMonths.days, 90);
      expect(RenewalPeriod.threeMonths.label, '3 mois');
    });
    test('sixMonths has correct days and label', () {
      expect(RenewalPeriod.sixMonths.days, 180);
      expect(RenewalPeriod.sixMonths.label, '6 mois');
    });
    test('custom has days=0', () {
      expect(RenewalPeriod.custom.days, 0);
      expect(RenewalPeriod.custom.label, 'Personnalisé');
    });
  });
}
