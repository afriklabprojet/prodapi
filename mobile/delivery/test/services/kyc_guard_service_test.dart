import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/kyc_guard_service.dart';

void main() {
  group('KycStatus', () {
    test('fromString verified', () {
      expect(KycStatus.fromString('verified'), KycStatus.verified);
      expect(KycStatus.fromString('approved'), KycStatus.verified);
    });

    test('fromString incomplete', () {
      expect(KycStatus.fromString('incomplete'), KycStatus.incomplete);
    });

    test('fromString pendingReview', () {
      expect(KycStatus.fromString('pending_review'), KycStatus.pendingReview);
      expect(KycStatus.fromString('pending'), KycStatus.pendingReview);
    });

    test('fromString rejected', () {
      expect(KycStatus.fromString('rejected'), KycStatus.rejected);
    });

    test('fromString unknown defaults', () {
      expect(KycStatus.fromString('garbage'), KycStatus.unknown);
      expect(KycStatus.fromString(''), KycStatus.unknown);
    });

    test('isVerified', () {
      expect(KycStatus.verified.isVerified, isTrue);
      expect(KycStatus.incomplete.isVerified, isFalse);
    });

    test('canReceiveOrders only when verified', () {
      expect(KycStatus.verified.canReceiveOrders, isTrue);
      expect(KycStatus.pendingReview.canReceiveOrders, isFalse);
      expect(KycStatus.rejected.canReceiveOrders, isFalse);
    });

    test('label returns French names', () {
      expect(KycStatus.verified.label, 'Vérifié');
      expect(KycStatus.incomplete.label, 'Documents manquants');
      expect(KycStatus.pendingReview.label, 'En cours de vérification');
      expect(KycStatus.rejected.label, 'Documents refusés');
      expect(KycStatus.unknown.label, 'Non vérifié');
    });
  });

  group('KycStatus - additional', () {
    test('fromString handles mixed case', () {
      expect(KycStatus.fromString('Verified'), KycStatus.verified);
      expect(KycStatus.fromString('APPROVED'), KycStatus.verified);
      expect(KycStatus.fromString('Pending'), KycStatus.pendingReview);
    });

    test('unknown isVerified is false', () {
      expect(KycStatus.unknown.isVerified, isFalse);
    });

    test('unknown canReceiveOrders is false', () {
      expect(KycStatus.unknown.canReceiveOrders, isFalse);
    });

    test('incomplete canReceiveOrders is false', () {
      expect(KycStatus.incomplete.canReceiveOrders, isFalse);
    });

    test('rejected isVerified is false', () {
      expect(KycStatus.rejected.isVerified, isFalse);
    });

    test('pendingReview isVerified is false', () {
      expect(KycStatus.pendingReview.isVerified, isFalse);
    });

    test('all values have a label', () {
      for (final status in KycStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });

    test('values count is 5', () {
      expect(KycStatus.values.length, 5);
    });

    test('fromString null-like input returns unknown', () {
      expect(KycStatus.fromString('null'), KycStatus.unknown);
      expect(KycStatus.fromString('N/A'), KycStatus.unknown);
    });
  });
}
