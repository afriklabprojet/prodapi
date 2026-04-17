import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/on_call/domain/entities/on_call_entity.dart';

void main() {
  group('OnCallEntity', () {
    late OnCallEntity onCall;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      onCall = OnCallEntity(
        id: 1,
        pharmacyId: 100,
        dutyZoneId: 10,
        startAt: now.subtract(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 6)),
        type: OnCallType.day,
        isActive: true,
      );
    });

    test('should create OnCallEntity with all fields', () {
      expect(onCall.id, 1);
      expect(onCall.pharmacyId, 100);
      expect(onCall.dutyZoneId, 10);
      expect(onCall.type, OnCallType.day);
      expect(onCall.isActive, true);
    });

    test('isOngoing should return true for active ongoing guard', () {
      expect(onCall.isOngoing, true);
    });

    test('isOngoing should return false for inactive guard', () {
      final inactiveGuard = onCall.copyWith(isActive: false);
      expect(inactiveGuard.isOngoing, false);
    });

    test('isUpcoming should return true for future guard', () {
      final futureGuard = OnCallEntity(
        id: 2,
        pharmacyId: 100,
        dutyZoneId: 10,
        startAt: now.add(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 1, hours: 8)),
        type: OnCallType.night,
        isActive: true,
      );
      expect(futureGuard.isUpcoming, true);
    });

    test('isPast should return true for past guard', () {
      final pastGuard = OnCallEntity(
        id: 3,
        pharmacyId: 100,
        dutyZoneId: 10,
        startAt: now.subtract(const Duration(days: 2)),
        endAt: now.subtract(const Duration(days: 1)),
        type: OnCallType.weekend,
        isActive: false,
      );
      expect(pastGuard.isPast, true);
    });

    test('duration should return correct duration', () {
      expect(onCall.duration, const Duration(hours: 8));
    });

    group('typeLabel', () {
      test('should return "Garde de jour" for day type', () {
        expect(onCall.typeLabel, 'Garde de jour');
      });

      test('should return "Garde de nuit" for night type', () {
        final nightGuard = onCall.copyWith(type: OnCallType.night);
        expect(nightGuard.typeLabel, 'Garde de nuit');
      });

      test('should return "Garde week-end" for weekend type', () {
        final weekendGuard = onCall.copyWith(type: OnCallType.weekend);
        expect(weekendGuard.typeLabel, 'Garde week-end');
      });

      test('should return "Garde jour férié" for holiday type', () {
        final holidayGuard = onCall.copyWith(type: OnCallType.holiday);
        expect(holidayGuard.typeLabel, 'Garde jour férié');
      });
    });

    test('copyWith should create a new entity with modified fields', () {
      final modified = onCall.copyWith(
        type: OnCallType.night,
        isActive: false,
      );

      expect(modified.id, onCall.id);
      expect(modified.type, OnCallType.night);
      expect(modified.isActive, false);
      expect(modified.pharmacyId, onCall.pharmacyId);
    });
  });

  group('OnCallType', () {
    test('should have all expected values', () {
      expect(OnCallType.values.length, 4);
      expect(OnCallType.values, contains(OnCallType.day));
      expect(OnCallType.values, contains(OnCallType.night));
      expect(OnCallType.values, contains(OnCallType.weekend));
      expect(OnCallType.values, contains(OnCallType.holiday));
    });
  });

  group('OnCallType Extension toOnCallType', () {
    test('should convert string to OnCallType', () {
      expect('day'.toOnCallType(), OnCallType.day);
      expect('night'.toOnCallType(), OnCallType.night);
      expect('weekend'.toOnCallType(), OnCallType.weekend);
      expect('holiday'.toOnCallType(), OnCallType.holiday);
    });

    test('should be case insensitive', () {
      expect('DAY'.toOnCallType(), OnCallType.day);
      expect('Night'.toOnCallType(), OnCallType.night);
    });

    test('should return day for invalid string', () {
      expect('invalid'.toOnCallType(), OnCallType.day);
      expect(''.toOnCallType(), OnCallType.day);
    });
  });

  group('OnCallType Extension toApiString', () {
    test('should convert OnCallType to API string', () {
      expect(OnCallType.day.toApiString(), 'day');
      expect(OnCallType.night.toApiString(), 'night');
      expect(OnCallType.weekend.toApiString(), 'weekend');
      expect(OnCallType.holiday.toApiString(), 'holiday');
    });
  });
}
