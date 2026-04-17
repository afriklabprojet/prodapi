import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/treatments/data/services/smart_refill_service.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';

TreatmentEntity _makeTreatment({
  String id = 't1',
  int productId = 1,
  String productName = 'Paracétamol',
  DateTime? nextRenewalDate,
}) {
  return TreatmentEntity(
    id: id,
    productId: productId,
    productName: productName,
    renewalPeriodDays: 30,
    nextRenewalDate:
        nextRenewalDate ?? DateTime.now().add(const Duration(days: 5)),
    reminderEnabled: true,
    reminderDaysBefore: 3,
    isActive: true,
    createdAt: DateTime(2024),
  );
}

RefillSuggestion _makeSuggestion({
  RefillUrgency urgency = RefillUrgency.upcoming,
  int daysRemaining = 5,
  bool wasDismissed = false,
}) {
  return RefillSuggestion(
    treatment: _makeTreatment(),
    daysRemaining: daysRemaining,
    urgency: urgency,
    message: 'Renouveler bientôt',
    wasDismissed: wasDismissed,
  );
}

void main() {
  // ──────────────────────────────────────────────────────
  // SmartRefillState
  // ──────────────────────────────────────────────────────
  group('SmartRefillState', () {
    test('defaults', () {
      const s = SmartRefillState();
      expect(s.suggestions, isEmpty);
      expect(s.isLoading, isFalse);
      expect(s.lastChecked, isNull);
    });

    test('copyWith — updates suggestions', () {
      const s = SmartRefillState();
      final sug = _makeSuggestion();
      final next = s.copyWith(suggestions: [sug]);
      expect(next.suggestions, [sug]);
    });

    test('copyWith — updates isLoading', () {
      const s = SmartRefillState();
      expect(s.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('copyWith — updates lastChecked', () {
      const s = SmartRefillState();
      final t = DateTime(2024, 6, 1);
      expect(s.copyWith(lastChecked: t).lastChecked, t);
    });

    test('copyWith — preserves unset fields', () {
      final sug = _makeSuggestion();
      final s = SmartRefillState(suggestions: [sug], isLoading: true);
      final next = s.copyWith(isLoading: false);
      expect(next.suggestions, [sug]);
    });

    test('urgentSuggestions — only urgent', () {
      final urgent = _makeSuggestion(
        urgency: RefillUrgency.urgent,
        daysRemaining: 1,
      );
      final upcoming = _makeSuggestion(
        urgency: RefillUrgency.upcoming,
        daysRemaining: 5,
      );
      final s = SmartRefillState(suggestions: [urgent, upcoming]);
      expect(s.urgentSuggestions, [urgent]);
      expect(s.upcomingSuggestions, [upcoming]);
    });

    test('urgentSuggestions — empty when no urgent', () {
      final s = SmartRefillState(
        suggestions: [_makeSuggestion(urgency: RefillUrgency.upcoming)],
      );
      expect(s.urgentSuggestions, isEmpty);
    });

    test('upcomingSuggestions — empty when no upcoming', () {
      const s = SmartRefillState();
      expect(s.upcomingSuggestions, isEmpty);
    });

    test('hasUrgent — false when empty', () {
      const s = SmartRefillState();
      expect(s.hasUrgent, isFalse);
    });

    test('hasUrgent — true when urgent suggestion exists', () {
      final s = SmartRefillState(
        suggestions: [_makeSuggestion(urgency: RefillUrgency.urgent)],
      );
      expect(s.hasUrgent, isTrue);
    });

    test('hasAny — false when empty', () {
      const s = SmartRefillState();
      expect(s.hasAny, isFalse);
    });

    test('hasAny — true when any suggestion exists', () {
      final s = SmartRefillState(suggestions: [_makeSuggestion()]);
      expect(s.hasAny, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // RefillSuggestion
  // ──────────────────────────────────────────────────────
  group('RefillSuggestion', () {
    test('defaults', () {
      final s = _makeSuggestion();
      expect(s.wasDismissed, isFalse);
      expect(s.urgency, RefillUrgency.upcoming);
      expect(s.message, isNotEmpty);
    });

    test('copyWith — marks as dismissed', () {
      final s = _makeSuggestion();
      final dismissed = s.copyWith(wasDismissed: true);
      expect(dismissed.wasDismissed, isTrue);
      // Other fields preserved
      expect(dismissed.treatment.id, s.treatment.id);
      expect(dismissed.daysRemaining, s.daysRemaining);
      expect(dismissed.urgency, s.urgency);
      expect(dismissed.message, s.message);
    });

    test('copyWith — no change when wasDismissed omitted', () {
      final s = _makeSuggestion(wasDismissed: true);
      final copy = s.copyWith();
      expect(copy.wasDismissed, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // RefillUrgency enum values
  // ──────────────────────────────────────────────────────
  group('RefillUrgency', () {
    test('all values exist', () {
      expect(
        RefillUrgency.values,
        containsAll([
          RefillUrgency.urgent,
          RefillUrgency.upcoming,
          RefillUrgency.normal,
        ]),
      );
    });
  });
}
