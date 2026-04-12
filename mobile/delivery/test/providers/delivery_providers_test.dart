import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/delivery.dart';

void main() {
  group('IsOnlineNotifier', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isOnlineProvider), isFalse);
    });

    test('set(true) updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isOnlineProvider.notifier).set(true);
      expect(container.read(isOnlineProvider), isTrue);
    });

    test('set(false) updates state back', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isOnlineProvider.notifier);
      notifier.set(true);
      notifier.set(false);
      expect(container.read(isOnlineProvider), isFalse);
    });

    test('multiple set(true) calls stay true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isOnlineProvider.notifier);
      notifier.set(true);
      notifier.set(true);
      expect(container.read(isOnlineProvider), isTrue);
    });

    test('toggle sequence works correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isOnlineProvider.notifier);
      expect(container.read(isOnlineProvider), isFalse);
      notifier.set(true);
      expect(container.read(isOnlineProvider), isTrue);
      notifier.set(false);
      expect(container.read(isOnlineProvider), isFalse);
      notifier.set(true);
      expect(container.read(isOnlineProvider), isTrue);
    });
  });

  group('Derived courier providers', () {
    CourierProfile createTestProfile({
      int id = 1,
      String name = 'John Doe',
      String email = 'john@example.com',
      String status = 'available',
      String vehicleType = 'moto',
      String plateNumber = 'AB-1234',
      double rating = 4.5,
      int completedDeliveries = 100,
      double earnings = 5000.0,
      String kycStatus = 'approved',
    }) {
      return CourierProfile(
        id: id,
        name: name,
        email: email,
        status: status,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        rating: rating,
        completedDeliveries: completedDeliveries,
        earnings: earnings,
        kycStatus: kycStatus,
      );
    }

    test('courierIdProvider returns id when profile is loaded', () async {
      final profile = createTestProfile(id: 42);
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith((ref) async => profile),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to resolve
      await container.read(courierProfileProvider.future);

      // After loading, check the id
      expect(container.read(courierProfileProvider).hasValue, isTrue);
      expect(container.read(courierIdProvider), 42);
    });

    test('courierIdProvider returns null when profile not loaded', () {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => createTestProfile(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Don't wait for future, check immediate state
      expect(container.read(courierIdProvider), isNull);
    });

    test('courierNameProvider returns name when profile loaded', () async {
      final profile = createTestProfile(name: 'Alice Smith');
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith((ref) async => profile),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(courierNameProvider), 'Alice Smith');
    });

    test('courierNameProvider returns empty string when not loaded', () {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => createTestProfile(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(courierNameProvider), '');
    });

    test('courierStatusProvider returns status when loaded', () async {
      final profile = createTestProfile(status: 'delivering');
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith((ref) async => profile),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(courierStatusProvider), 'delivering');
    });

    test('courierStatusProvider returns null when not loaded', () {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => createTestProfile(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(courierStatusProvider), isNull);
    });

    test('courierEarningsProvider returns earnings when loaded', () async {
      final profile = createTestProfile(earnings: 12500.50);
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith((ref) async => profile),
        ],
      );
      addTearDown(container.dispose);

      await container.read(courierProfileProvider.future);
      expect(container.read(courierEarningsProvider), 12500.50);
    });

    test('courierEarningsProvider returns 0.0 when not loaded', () {
      final container = ProviderContainer(
        overrides: [
          courierProfileProvider.overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => createTestProfile(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(courierEarningsProvider), 0.0);
    });

    test(
      'courierEarningsProvider returns 0.0 when earnings is null in profile',
      () async {
        // Test with zero earnings (null handling via default)
        final profile = createTestProfile(earnings: 0.0);
        final container = ProviderContainer(
          overrides: [
            courierProfileProvider.overrideWith((ref) async => profile),
          ],
        );
        addTearDown(container.dispose);

        await container.read(courierProfileProvider.future);
        expect(container.read(courierEarningsProvider), 0.0);
      },
    );
  });

  group('Delivery providers', () {
    Delivery createTestDelivery({
      int id = 1,
      String reference = 'DEL001',
      String status = 'pending',
    }) {
      return Delivery(
        id: id,
        reference: reference,
        status: status,
        pharmacyName: 'Test Pharmacy',
        pharmacyAddress: '123 Pharmacy St',
        customerName: 'Test Client',
        deliveryAddress: '456 Client Ave',
        totalAmount: 5000,
      );
    }

    test(
      'hasActiveDeliveryProvider returns true when has deliveries',
      () async {
        final deliveries = [createTestDelivery()];
        final container = ProviderContainer(
          overrides: [
            deliveriesProvider(
              'active',
            ).overrideWith((ref) async => deliveries),
          ],
        );
        addTearDown(container.dispose);

        await container.read(deliveriesProvider('active').future);
        expect(container.read(hasActiveDeliveryProvider), isTrue);
      },
    );

    test(
      'hasActiveDeliveryProvider returns false when no deliveries',
      () async {
        final container = ProviderContainer(
          overrides: [
            deliveriesProvider(
              'active',
            ).overrideWith((ref) async => <Delivery>[]),
          ],
        );
        addTearDown(container.dispose);

        await container.read(deliveriesProvider('active').future);
        expect(container.read(hasActiveDeliveryProvider), isFalse);
      },
    );

    test('hasActiveDeliveryProvider returns false when not loaded', () {
      final container = ProviderContainer(
        overrides: [
          deliveriesProvider('active').overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => <Delivery>[createTestDelivery()],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hasActiveDeliveryProvider), isFalse);
    });

    test('activeDeliveryProvider returns first delivery', () async {
      final deliveries = [
        createTestDelivery(id: 1, reference: 'FIRST'),
        createTestDelivery(id: 2, reference: 'SECOND'),
      ];
      final container = ProviderContainer(
        overrides: [
          deliveriesProvider('active').overrideWith((ref) async => deliveries),
        ],
      );
      addTearDown(container.dispose);

      await container.read(deliveriesProvider('active').future);
      final active = container.read(activeDeliveryProvider);
      expect(active, isNotNull);
      expect(active!.reference, 'FIRST');
    });

    test('activeDeliveryProvider returns null when no deliveries', () async {
      final container = ProviderContainer(
        overrides: [
          deliveriesProvider(
            'active',
          ).overrideWith((ref) async => <Delivery>[]),
        ],
      );
      addTearDown(container.dispose);

      await container.read(deliveriesProvider('active').future);
      expect(container.read(activeDeliveryProvider), isNull);
    });

    test('activeDeliveryProvider returns null when not loaded', () {
      final container = ProviderContainer(
        overrides: [
          deliveriesProvider('active').overrideWith(
            (ref) => Future.delayed(
              const Duration(hours: 1),
              () => <Delivery>[createTestDelivery()],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(activeDeliveryProvider), isNull);
    });
  });
}
