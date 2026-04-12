import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/kyc_guard_service.dart';

void main() {
  group('KycStatus', () {
    group('fromString', () {
      test('returns verified for "verified"', () {
        expect(KycStatus.fromString('verified'), KycStatus.verified);
      });

      test('returns verified for "approved"', () {
        expect(KycStatus.fromString('approved'), KycStatus.verified);
      });

      test('returns incomplete for "incomplete"', () {
        expect(KycStatus.fromString('incomplete'), KycStatus.incomplete);
      });

      test('returns pendingReview for "pending_review"', () {
        expect(KycStatus.fromString('pending_review'), KycStatus.pendingReview);
      });

      test('returns pendingReview for "pending"', () {
        expect(KycStatus.fromString('pending'), KycStatus.pendingReview);
      });

      test('returns rejected for "rejected"', () {
        expect(KycStatus.fromString('rejected'), KycStatus.rejected);
      });

      test('returns unknown for unrecognized value', () {
        expect(KycStatus.fromString('whatever'), KycStatus.unknown);
      });

      test('is case insensitive', () {
        expect(KycStatus.fromString('VERIFIED'), KycStatus.verified);
        expect(KycStatus.fromString('Incomplete'), KycStatus.incomplete);
        expect(KycStatus.fromString('REJECTED'), KycStatus.rejected);
      });
    });

    group('isVerified', () {
      test('true for verified', () {
        expect(KycStatus.verified.isVerified, isTrue);
      });

      test('false for incomplete', () {
        expect(KycStatus.incomplete.isVerified, isFalse);
      });

      test('false for pendingReview', () {
        expect(KycStatus.pendingReview.isVerified, isFalse);
      });

      test('false for rejected', () {
        expect(KycStatus.rejected.isVerified, isFalse);
      });

      test('false for unknown', () {
        expect(KycStatus.unknown.isVerified, isFalse);
      });
    });

    group('canReceiveOrders', () {
      test('true only for verified', () {
        expect(KycStatus.verified.canReceiveOrders, isTrue);
      });

      test('false for incomplete', () {
        expect(KycStatus.incomplete.canReceiveOrders, isFalse);
      });

      test('false for pendingReview', () {
        expect(KycStatus.pendingReview.canReceiveOrders, isFalse);
      });

      test('false for rejected', () {
        expect(KycStatus.rejected.canReceiveOrders, isFalse);
      });

      test('false for unknown', () {
        expect(KycStatus.unknown.canReceiveOrders, isFalse);
      });
    });

    group('label', () {
      test('returns French labels', () {
        expect(KycStatus.verified.label, 'Vérifié');
        expect(KycStatus.incomplete.label, 'Documents manquants');
        expect(KycStatus.pendingReview.label, 'En cours de vérification');
        expect(KycStatus.rejected.label, 'Documents refusés');
        expect(KycStatus.unknown.label, 'Non vérifié');
      });
    });
  });
}
