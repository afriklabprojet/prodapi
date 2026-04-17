import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/kyc_guard_service.dart';

void main() {
  group('KycStatus.fromString', () {
    test('verified from verified', () {
      expect(KycStatus.fromString('verified'), KycStatus.verified);
    });

    test('verified from approved', () {
      expect(KycStatus.fromString('approved'), KycStatus.verified);
    });

    test('incomplete from incomplete', () {
      expect(KycStatus.fromString('incomplete'), KycStatus.incomplete);
    });

    test('pendingReview from pending_review', () {
      expect(KycStatus.fromString('pending_review'), KycStatus.pendingReview);
    });

    test('pendingReview from pending', () {
      expect(KycStatus.fromString('pending'), KycStatus.pendingReview);
    });

    test('rejected from rejected', () {
      expect(KycStatus.fromString('rejected'), KycStatus.rejected);
    });

    test('unknown from arbitrary string', () {
      expect(KycStatus.fromString('something'), KycStatus.unknown);
    });

    test('case insensitive', () {
      expect(KycStatus.fromString('VERIFIED'), KycStatus.verified);
      expect(KycStatus.fromString('Approved'), KycStatus.verified);
      expect(KycStatus.fromString('Incomplete'), KycStatus.incomplete);
      expect(KycStatus.fromString('PENDING_REVIEW'), KycStatus.pendingReview);
      expect(KycStatus.fromString('REJECTED'), KycStatus.rejected);
    });
  });

  group('KycStatus properties', () {
    test('isVerified returns true only for verified', () {
      expect(KycStatus.verified.isVerified, true);
      expect(KycStatus.incomplete.isVerified, false);
      expect(KycStatus.pendingReview.isVerified, false);
      expect(KycStatus.rejected.isVerified, false);
      expect(KycStatus.unknown.isVerified, false);
    });

    test('canReceiveOrders returns true only for verified', () {
      expect(KycStatus.verified.canReceiveOrders, true);
      expect(KycStatus.incomplete.canReceiveOrders, false);
      expect(KycStatus.pendingReview.canReceiveOrders, false);
      expect(KycStatus.rejected.canReceiveOrders, false);
      expect(KycStatus.unknown.canReceiveOrders, false);
    });

    test('label returns correct French labels', () {
      expect(KycStatus.verified.label, 'Vérifié');
      expect(KycStatus.incomplete.label, 'Documents manquants');
      expect(KycStatus.pendingReview.label, 'En cours de vérification');
      expect(KycStatus.rejected.label, 'Documents refusés');
      expect(KycStatus.unknown.label, 'Non vérifié');
    });
  });
}
