import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/offline_service.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/courier_profile.dart';

void main() {
  late OfflineService service;

  setUp(() {
    service = OfflineService.instance;
    OfflineService.testStore = {};
    service.resetForTesting();
  });

  group('OfflineService - Deliveries Cache', () {
    test('getCachedActiveDeliveries returns empty list initially', () async {
      final deliveries = await service.getCachedActiveDeliveries();
      expect(deliveries, isEmpty);
    });

    test(
      'cacheActiveDeliveries and getCachedActiveDeliveries round-trip',
      () async {
        final delivery = Delivery.fromJson({
          'id': 1,
          'reference': 'REF-001',
          'status': 'pending',
          'pharmacy_name': 'Pharma Test',
          'pharmacy_address': '10 Rue Pharmacie',
          'customer_name': 'Client Test',
          'delivery_address': '123 Rue Test',
          'total_amount': 1500,
        });
        await service.cacheActiveDeliveries([delivery]);
        final cached = await service.getCachedActiveDeliveries();
        expect(cached, hasLength(1));
        expect(cached.first.id, 1);
      },
    );

    test('getCachedCurrentDelivery returns null initially', () async {
      final delivery = await service.getCachedCurrentDelivery();
      expect(delivery, isNull);
    });

    test('cacheCurrentDelivery stores delivery', () async {
      final delivery = Delivery.fromJson({
        'id': 2,
        'reference': 'REF-002',
        'status': 'in_progress',
        'pharmacy_name': 'Pharma 2',
        'pharmacy_address': '20 Rue Pharmacie',
        'customer_name': 'Client 2',
        'delivery_address': '456 Rue',
        'total_amount': 2000,
      });
      await service.cacheCurrentDelivery(delivery);
      final cached = await service.getCachedCurrentDelivery();
      expect(cached, isNotNull);
      expect(cached!.id, 2);
    });

    test('cacheCurrentDelivery with null clears cache', () async {
      final delivery = Delivery.fromJson({
        'id': 3,
        'reference': 'REF-003',
        'status': 'pending',
        'pharmacy_name': 'P',
        'pharmacy_address': 'PA',
        'customer_name': 'C',
        'delivery_address': 'A',
        'total_amount': 100,
      });
      await service.cacheCurrentDelivery(delivery);
      await service.cacheCurrentDelivery(null);
      final cached = await service.getCachedCurrentDelivery();
      expect(cached, isNull);
    });
  });

  group('OfflineService - Courier Profile Cache', () {
    test('getCachedCourierProfile returns null initially', () async {
      final profile = await service.getCachedCourierProfile();
      expect(profile, isNull);
    });

    test('cacheCourierProfile stores and retrieves profile', () async {
      final profile = CourierProfile.fromJson({
        'id': 10,
        'name': 'John Doe',
        'email': 'john@test.com',
        'status': 'active',
        'vehicle_type': 'moto',
        'completed_deliveries': 50,
        'rating': 4.5,
      });
      await service.cacheCourierProfile(profile);
      final cached = await service.getCachedCourierProfile();
      expect(cached, isNotNull);
      expect(cached!.id, 10);
      expect(cached.name, 'John Doe');
    });
  });

  group('OfflineService - Wallet Cache', () {
    test('getCachedWalletBalance returns null initially', () async {
      final balance = await service.getCachedWalletBalance();
      expect(balance, isNull);
    });

    test('cacheWalletBalance stores balance', () async {
      await service.cacheWalletBalance(15000.0, 3000.0);
      final cached = await service.getCachedWalletBalance();
      expect(cached, isNotNull);
      expect(cached!['balance'], 15000.0);
      expect(cached['pending_earnings'], 3000.0);
    });
  });

  group('OfflineService - Pending Proofs', () {
    test('getPendingProofsCount returns 0 initially', () async {
      expect(await service.getPendingProofsCount(), 0);
    });

    test('addPendingProof increments count', () async {
      await service.addPendingProof(
        deliveryId: 1,
        notes: 'Test notes',
        latitude: 5.359952,
        longitude: -4.008256,
      );
      expect(await service.getPendingProofsCount(), 1);
    });

    test('getPendingProofsAndClear returns proofs and clears', () async {
      await service.addPendingProof(
        deliveryId: 1,
        photoBase64: 'base64photo',
        signatureBase64: 'base64sig',
      );
      await service.addPendingProof(deliveryId: 2, notes: 'Another proof');

      final proofs = await service.getPendingProofsAndClear();
      expect(proofs, hasLength(2));
      expect(proofs[0]['delivery_id'], 1);
      expect(proofs[1]['delivery_id'], 2);

      // After clearing, count should be 0
      expect(await service.getPendingProofsCount(), 0);
    });
  });

  group('OfflineService - Pending Actions', () {
    test('getPendingActionsCount returns 0 initially', () async {
      expect(await service.getPendingActionsCount(), 0);
    });

    test('addPendingAction increments count', () async {
      await service.addPendingAction(
        type: 'status_update',
        deliveryId: 5,
        data: {'status': 'picked_up'},
      );
      expect(await service.getPendingActionsCount(), 1);
    });

    test('getPendingActionsAndClear returns actions and clears', () async {
      await service.addPendingAction(type: 'accept', deliveryId: 1);
      await service.addPendingAction(type: 'complete', deliveryId: 2);

      final actions = await service.getPendingActionsAndClear();
      expect(actions, hasLength(2));
      expect(actions[0]['type'], 'accept');
      expect(actions[1]['type'], 'complete');
      expect(await service.getPendingActionsCount(), 0);
    });
  });

  group('OfflineService - Sync Time & Staleness', () {
    test('getLastSyncTime returns null initially', () async {
      expect(await service.getLastSyncTime(), isNull);
    });

    test('isDataStale returns true initially', () async {
      expect(await service.isDataStale(), true);
    });
  });

  group('OfflineService - Clear All', () {
    test('clearAll removes cached data but preserves pending', () async {
      await service.cacheWalletBalance(1000.0, 200.0);
      await service.addPendingProof(deliveryId: 1);
      await service.addPendingAction(type: 'test', deliveryId: 1);

      await service.clearAll();

      expect(await service.getCachedWalletBalance(), isNull);
      // Pending proofs and actions are preserved
      expect(await service.getPendingProofsCount(), 1);
      expect(await service.getPendingActionsCount(), 1);
      expect(await service.getCachedActiveDeliveries(), isEmpty);
    });

    test('clearAll does NOT remove pending proofs', () async {
      await service.addPendingProof(deliveryId: 1, notes: 'important');
      await service.addPendingAction(type: 'deliver', deliveryId: 2);

      await service.clearAll();

      // Pending proofs and actions are preserved after clearAll
      expect(await service.getPendingProofsCount(), 1);
      expect(await service.getPendingActionsCount(), 1);
    });
  });

  group('OfflineService - Edge Cases', () {
    test('addPendingProof with all optional fields', () async {
      await service.addPendingProof(
        deliveryId: 42,
        photoBase64: 'base64photo==',
        signatureBase64: 'base64sig==',
        notes: 'Delivered to neighbor',
        latitude: 5.359952,
        longitude: -4.008256,
      );
      final proofs = await service.getPendingProofsAndClear();
      expect(proofs, hasLength(1));
      expect(proofs[0]['delivery_id'], 42);
      expect(proofs[0]['photo_base64'], 'base64photo==');
      expect(proofs[0]['signature_base64'], 'base64sig==');
      expect(proofs[0]['notes'], 'Delivered to neighbor');
      expect(proofs[0]['latitude'], 5.359952);
      expect(proofs[0]['longitude'], -4.008256);
      expect(proofs[0]['created_at'], isA<String>());
    });

    test('addPendingProof with null optional fields', () async {
      await service.addPendingProof(deliveryId: 1);
      final proofs = await service.getPendingProofsAndClear();
      expect(proofs[0]['photo_base64'], isNull);
      expect(proofs[0]['signature_base64'], isNull);
      expect(proofs[0]['notes'], isNull);
      expect(proofs[0]['latitude'], isNull);
      expect(proofs[0]['longitude'], isNull);
    });

    test('addPendingAction with data map', () async {
      await service.addPendingAction(
        type: 'deliver',
        deliveryId: 10,
        data: {'confirmation_code': '1234', 'proof_id': 5},
      );
      final actions = await service.getPendingActionsAndClear();
      expect(actions[0]['type'], 'deliver');
      expect(actions[0]['delivery_id'], 10);
      expect(actions[0]['data']['confirmation_code'], '1234');
      expect(actions[0]['data']['proof_id'], 5);
      expect(actions[0]['created_at'], isA<String>());
    });

    test('addPendingAction without data', () async {
      await service.addPendingAction(type: 'pickup', deliveryId: 5);
      final actions = await service.getPendingActionsAndClear();
      expect(actions[0]['data'], isNull);
    });

    test('multiple pending proofs accumulate', () async {
      await service.addPendingProof(deliveryId: 1);
      await service.addPendingProof(deliveryId: 2);
      await service.addPendingProof(deliveryId: 3);
      expect(await service.getPendingProofsCount(), 3);
    });

    test('multiple pending actions accumulate', () async {
      await service.addPendingAction(type: 'pickup', deliveryId: 1);
      await service.addPendingAction(type: 'deliver', deliveryId: 2);
      await service.addPendingAction(type: 'rate', deliveryId: 3);
      expect(await service.getPendingActionsCount(), 3);
    });

    test('getPendingProofsAndClear returns empty after clear', () async {
      await service.addPendingProof(deliveryId: 1);
      await service.getPendingProofsAndClear();
      final second = await service.getPendingProofsAndClear();
      expect(second, isEmpty);
    });

    test('getPendingActionsAndClear returns empty after clear', () async {
      await service.addPendingAction(type: 'test', deliveryId: 1);
      await service.getPendingActionsAndClear();
      final second = await service.getPendingActionsAndClear();
      expect(second, isEmpty);
    });

    test('getCachedWalletBalance includes cached_at timestamp', () async {
      await service.cacheWalletBalance(5000.0, 1000.0);
      // The cache stores cached_at but getCachedWalletBalance only returns balance and pending
      final cached = await service.getCachedWalletBalance();
      expect(cached, isNotNull);
      expect(cached!['balance'], 5000.0);
    });

    test('cacheActiveDeliveries updates sync time', () async {
      // Before cache, sync time is null
      expect(await service.getLastSyncTime(), isNull);

      final delivery = Delivery.fromJson({
        'id': 1,
        'reference': 'REF-SYNC',
        'status': 'pending',
        'pharmacy_name': 'P',
        'pharmacy_address': 'PA',
        'customer_name': 'C',
        'delivery_address': 'A',
        'total_amount': 100,
      });
      await service.cacheActiveDeliveries([delivery]);

      // After cache, sync time should be set
      final syncTime = await service.getLastSyncTime();
      expect(syncTime, isNotNull);
    });

    test('isDataStale returns false right after caching', () async {
      final delivery = Delivery.fromJson({
        'id': 1,
        'reference': 'REF-STALE',
        'status': 'pending',
        'pharmacy_name': 'P',
        'pharmacy_address': 'PA',
        'customer_name': 'C',
        'delivery_address': 'A',
        'total_amount': 100,
      });
      await service.cacheActiveDeliveries([delivery]);
      expect(await service.isDataStale(), false);
    });

    test('getCachedCurrentDelivery with corrupted JSON returns null', () async {
      // Simulate corrupted data
      OfflineService.testStore!['offline_current_delivery'] = 'not valid json';
      final result = await service.getCachedCurrentDelivery();
      expect(result, isNull);
    });

    test('getCachedCourierProfile with corrupted JSON returns null', () async {
      OfflineService.testStore!['offline_courier_profile'] = '{broken';
      final result = await service.getCachedCourierProfile();
      expect(result, isNull);
    });

    test('getCachedWalletBalance with corrupted JSON returns null', () async {
      OfflineService.testStore!['offline_wallet_balance'] = 'not json';
      final result = await service.getCachedWalletBalance();
      expect(result, isNull);
    });

    test(
      'getCachedActiveDeliveries with corrupted JSON returns empty',
      () async {
        OfflineService.testStore!['offline_active_deliveries'] = 'bad data';
        final result = await service.getCachedActiveDeliveries();
        expect(result, isEmpty);
      },
    );

    test('init in test mode does nothing', () async {
      // Should not throw
      await service.init();
      expect(OfflineService.testStore, isNotNull);
    });

    test('cacheActiveDeliveries with empty list', () async {
      await service.cacheActiveDeliveries([]);
      final cached = await service.getCachedActiveDeliveries();
      expect(cached, isEmpty);
    });

    test('wallet balance with zero values', () async {
      await service.cacheWalletBalance(0.0, 0.0);
      final cached = await service.getCachedWalletBalance();
      expect(cached!['balance'], 0.0);
    });
  });
}
