import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/treatments/data/models/treatment_model.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// Test helpers
// ────────────────────────────────────────────────────────────────────────────
TreatmentEntity _entity({
  String id = 'treat-001',
  int productId = 42,
  String productName = 'Doliprane 500mg',
  int renewalDays = 30,
  DateTime? nextRenewal,
  bool isActive = true,
  int reminderDaysBefore = 3,
}) => TreatmentEntity(
  id: id,
  productId: productId,
  productName: productName,
  renewalPeriodDays: renewalDays,
  isActive: isActive,
  reminderDaysBefore: reminderDaysBefore,
  nextRenewalDate: nextRenewal,
  createdAt: DateTime(2024, 1, 1),
);

Map<String, dynamic> _json({
  String id = 'treat-001',
  String? nextRenewalDate,
  String? lastOrderedAt,
}) => {
  'id': id,
  'product_id': 42,
  'product_name': 'Doliprane 500mg',
  'product_image': null,
  'dosage': '500mg',
  'frequency': '2 fois par jour',
  'quantity_per_renewal': 60,
  'renewal_period_days': 30,
  'next_renewal_date': nextRenewalDate,
  'last_ordered_at': lastOrderedAt,
  'reminder_enabled': true,
  'reminder_days_before': 3,
  'notes': 'À prendre avec les repas',
  'is_active': true,
  'created_at': '2024-01-01T00:00:00.000',
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // TreatmentModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentModel.fromJson', () {
    test('parses all fields correctly', () {
      final model = TreatmentModel.fromJson(
        _json(
          nextRenewalDate: '2024-04-01T00:00:00.000',
          lastOrderedAt: '2024-03-01T00:00:00.000',
        ),
      );

      expect(model.id, 'treat-001');
      expect(model.productId, 42);
      expect(model.productName, 'Doliprane 500mg');
      expect(model.dosage, '500mg');
      expect(model.frequency, '2 fois par jour');
      expect(model.quantityPerRenewal, 60);
      expect(model.renewalPeriodDays, 30);
      expect(model.nextRenewalDate, isNotNull);
      expect(model.lastOrderedAt, isNotNull);
      expect(model.reminderEnabled, isTrue);
      expect(model.reminderDaysBefore, 3);
      expect(model.notes, 'À prendre avec les repas');
      expect(model.isActive, isTrue);
    });

    test('handles null nextRenewalDate and lastOrderedAt', () {
      final model = TreatmentModel.fromJson(_json());
      expect(model.nextRenewalDate, isNull);
      expect(model.lastOrderedAt, isNull);
    });

    test('defaults reminderEnabled to true when missing', () {
      final json = _json()..remove('reminder_enabled');
      final model = TreatmentModel.fromJson(json);
      expect(model.reminderEnabled, isTrue);
    });

    test('defaults isActive to true when missing', () {
      final json = _json()..remove('is_active');
      final model = TreatmentModel.fromJson(json);
      expect(model.isActive, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // TreatmentModel.toJson
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentModel.toJson', () {
    test('serializes to JSON round-trip', () {
      final model = TreatmentModel.fromJson(
        _json(nextRenewalDate: '2024-04-01T00:00:00.000'),
      );
      final json = model.toJson();

      expect(json['id'], 'treat-001');
      expect(json['product_id'], 42);
      expect(json['product_name'], 'Doliprane 500mg');
      expect(json['renewal_period_days'], 30);
      expect(json['next_renewal_date'], isNotNull);
      expect(json['is_active'], isTrue);
    });

    test('serializes null dates as null', () {
      final model = TreatmentModel.fromJson(_json());
      final json = model.toJson();
      expect(json['next_renewal_date'], isNull);
      expect(json['last_ordered_at'], isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // TreatmentModel.fromEntity / toEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentModel.fromEntity', () {
    test('constructs model from entity correctly', () {
      final entity = _entity();
      final model = TreatmentModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.productId, entity.productId);
      expect(model.productName, entity.productName);
      expect(model.renewalPeriodDays, entity.renewalPeriodDays);
      expect(model.isActive, entity.isActive);
    });
  });

  group('TreatmentModel.toEntity', () {
    test('converts model to domain entity correctly', () {
      final model = TreatmentModel.fromJson(
        _json(nextRenewalDate: '2024-04-01T12:00:00.000'),
      );
      final entity = model.toEntity();

      expect(entity, isA<TreatmentEntity>());
      expect(entity.id, model.id);
      expect(entity.productId, model.productId);
      expect(entity.productName, model.productName);
      expect(entity.nextRenewalDate, isNotNull);
      expect(entity.dosage, '500mg');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // TreatmentEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('TreatmentEntity.daysUntilRenewal', () {
    test('returns null when nextRenewalDate is null', () {
      expect(_entity().daysUntilRenewal, isNull);
    });

    test('returns positive days when renewal is in the future', () {
      final entity = _entity(
        nextRenewal: DateTime.now().add(const Duration(days: 10)),
      );
      expect(entity.daysUntilRenewal, greaterThan(0));
    });

    test('returns negative days when renewal is overdue', () {
      final entity = _entity(
        nextRenewal: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(entity.daysUntilRenewal, lessThan(0));
    });
  });

  group('TreatmentEntity.needsRenewalSoon', () {
    test('returns false when nextRenewalDate is null', () {
      expect(_entity().needsRenewalSoon, isFalse);
    });

    test('returns true when days <= reminderDaysBefore', () {
      final entity = _entity(
        nextRenewal: DateTime.now().add(const Duration(days: 2)),
        reminderDaysBefore: 3,
      );
      expect(entity.needsRenewalSoon, isTrue);
    });

    test('returns false when days > reminderDaysBefore', () {
      final entity = _entity(
        nextRenewal: DateTime.now().add(const Duration(days: 10)),
        reminderDaysBefore: 3,
      );
      expect(entity.needsRenewalSoon, isFalse);
    });
  });

  group('TreatmentEntity.isOverdue', () {
    test('returns false when nextRenewalDate is null', () {
      expect(_entity().isOverdue, isFalse);
    });

    test('returns true when days < 0', () {
      final entity = _entity(
        nextRenewal: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(entity.isOverdue, isTrue);
    });

    test('returns false when renewal is in the future', () {
      final entity = _entity(
        nextRenewal: DateTime.now().add(const Duration(days: 3)),
      );
      expect(entity.isOverdue, isFalse);
    });
  });

  group('TreatmentEntity.copyWith', () {
    test('returns copy with updated productName', () {
      final original = _entity();
      final copy = original.copyWith(productName: 'Aspirine');
      expect(copy.productName, 'Aspirine');
      expect(copy.id, original.id);
    });

    test('returns copy with updated renewalPeriodDays', () {
      final original = _entity(renewalDays: 30);
      final copy = original.copyWith(renewalPeriodDays: 60);
      expect(copy.renewalPeriodDays, 60);
    });

    test('returns copy with updated isActive false', () {
      final original = _entity(isActive: true);
      final copy = original.copyWith(isActive: false);
      expect(copy.isActive, isFalse);
    });
  });

  group('TreatmentEntity Equatable', () {
    test('two identical entities are equal', () {
      final a = _entity();
      final b = _entity();
      expect(a, b);
    });

    test('different product IDs are not equal', () {
      final a = _entity(productId: 1);
      final b = _entity(productId: 2);
      expect(a, isNot(equals(b)));
    });
  });
}
