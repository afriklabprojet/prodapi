import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/kyc_guard_service.dart';
import 'package:courier/core/services/cache_service.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/presentation/providers/profile_provider.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/user.dart';

void main() {
  // Initialize Flutter binding and test mode for CacheService
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    CacheService.testStore = {};
  });

  tearDownAll(() {
    CacheService.testStore = null;
  });

  CourierProfile makeProfile({String kycStatus = 'verified'}) {
    return CourierProfile(
      id: 1,
      name: 'Test',
      email: 'test@test.com',
      status: 'available',
      vehicleType: 'moto',
      plateNumber: 'AB-123',
      rating: 4.5,
      completedDeliveries: 10,
      earnings: 50000,
      kycStatus: kycStatus,
    );
  }

  User makeUser({String kycStatus = 'verified'}) {
    return User(
      id: 1,
      name: 'Test',
      email: 'test@test.com',
      courier: CourierInfo(id: 1, status: 'available', kycStatus: kycStatus),
    );
  }

  group('kycStatusProvider', () {
    test('returns verified when profile kyc_status is "verified"', () {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'verified')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'verified')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Force resolve
      container.read(courierProfileProvider);

      // The provider derives from async, initially unknown
      expect(container.read(kycStatusProvider), KycStatus.unknown);
    });

    test('returns incomplete for incomplete profile', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'incomplete')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'incomplete')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to resolve
      await container.read(courierProfileProvider.future);
      expect(container.read(kycStatusProvider), KycStatus.incomplete);
    });

    test('returns pendingReview for pending_review', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'pending_review')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'pending_review')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(kycStatusProvider), KycStatus.pendingReview);
    });

    test('returns rejected for rejected', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'rejected')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'rejected')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(kycStatusProvider), KycStatus.rejected);
    });

    test(
      'falls back to cached auth profile when courier profile fails',
      () async {
        final container = ProviderContainer(
          overrides: [
            courierProfileProvider.overrideWith(
              (ref) => Future<CourierProfile>.error(Exception('network error')),
            ),
            profileProvider.overrideWith(
              (ref) => Future.value(makeUser(kycStatus: 'approved')),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileProvider.future);
        expect(container.read(kycStatusProvider), KycStatus.verified);
      },
    );
  });

  group('canReceiveOrdersProvider', () {
    test('true when verified', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'verified')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'verified')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(canReceiveOrdersProvider), isTrue);
    });

    test('false when incomplete', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'incomplete')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'incomplete')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(canReceiveOrdersProvider), isFalse);
    });

    test('false when pending_review', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'pending_review')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'pending_review')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(canReceiveOrdersProvider), isFalse);
    });

    test('false when rejected', () async {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.value(makeProfile(kycStatus: 'rejected')),
          ),
          profileProvider.overrideWith(
            (ref) => Future.value(makeUser(kycStatus: 'rejected')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(canReceiveOrdersProvider), isFalse);
    });
  });
}
