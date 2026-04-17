import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/network/api_client.dart';
import 'package:courier/core/services/connectivity_service.dart';
import 'package:courier/core/services/offline_service.dart';
import 'package:courier/core/services/sync_manager.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/delivery_repository.dart';

class _MockDio extends Mock implements Dio {}

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

class _TestConnectivityService extends ConnectivityService {
  void setTestState(ConnectivityState newState) {
    state = newState;
  }
}

void main() {
  final offlineService = OfflineService.instance;

  setUp(() {
    OfflineService.testStore = {};
    offlineService.resetForTesting();
  });

  group('SyncState', () {
    test('default constructor has correct defaults', () {
      const state = SyncState();
      expect(state.isSyncing, false);
      expect(state.totalPending, 0);
      expect(state.synced, 0);
      expect(state.currentAction, isNull);
      expect(state.results, isEmpty);
      expect(state.lastSyncTime, isNull);
    });

    test('copyWith preserves values when null', () {
      final now = DateTime(2024, 1, 1);
      final results = [SyncResult(type: 'proof', itemId: 1, success: true)];
      final state = SyncState(
        isSyncing: true,
        totalPending: 10,
        synced: 5,
        currentAction: 'uploading',
        results: results,
        lastSyncTime: now,
      );
      final copy = state.copyWith();
      expect(copy.isSyncing, true);
      expect(copy.totalPending, 10);
      expect(copy.synced, 5);
      expect(copy.currentAction, 'uploading');
      expect(copy.results.length, 1);
      expect(copy.lastSyncTime, now);
    });

    test('copyWith overrides values', () {
      const state = SyncState();
      final copy = state.copyWith(
        isSyncing: true,
        totalPending: 8,
        synced: 3,
        currentAction: 'syncing proofs',
      );
      expect(copy.isSyncing, true);
      expect(copy.totalPending, 8);
      expect(copy.synced, 3);
      expect(copy.currentAction, 'syncing proofs');
    });

    test('progress returns 0 when no pending items', () {
      const state = SyncState(totalPending: 0, synced: 0);
      expect(state.progress, 0);
    });

    test('progress returns correct ratio', () {
      const state = SyncState(totalPending: 10, synced: 5);
      expect(state.progress, 0.5);
    });

    test('progress returns 1.0 when all synced', () {
      const state = SyncState(totalPending: 4, synced: 4);
      expect(state.progress, 1.0);
    });

    test('hasFailures returns false when no failures', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'action', itemId: 2, success: true),
        ],
      );
      expect(state.hasFailures, false);
    });

    test('hasFailures returns true when there are failures', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(
            type: 'action',
            itemId: 2,
            success: false,
            errorMessage: 'Network error',
          ),
        ],
      );
      expect(state.hasFailures, true);
    });

    test('failureCount counts failures correctly', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'action', itemId: 2, success: false),
          SyncResult(type: 'action', itemId: 3, success: false),
        ],
      );
      expect(state.failureCount, 2);
    });

    test('successCount counts successes correctly', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'proof', itemId: 2, success: true),
          SyncResult(type: 'action', itemId: 3, success: false),
        ],
      );
      expect(state.successCount, 2);
    });
  });

  group('SyncResult', () {
    test('creates with required fields', () {
      final result = SyncResult(type: 'proof', itemId: 42, success: true);
      expect(result.type, 'proof');
      expect(result.itemId, 42);
      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.timestamp, isA<DateTime>());
    });

    test('creates with error message', () {
      final result = SyncResult(
        type: 'action',
        itemId: 7,
        success: false,
        errorMessage: 'Server error',
      );
      expect(result.success, false);
      expect(result.errorMessage, 'Server error');
    });

    test('timestamp is set to now', () {
      final before = DateTime.now();
      final result = SyncResult(type: 'proof', itemId: 1, success: true);
      final after = DateTime.now();
      expect(
        result.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        result.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  group('SyncState - additional edge cases', () {
    test('progress with large numbers', () {
      const state = SyncState(totalPending: 1000, synced: 750);
      expect(state.progress, 0.75);
    });

    test('hasFailures returns false with empty results', () {
      const state = SyncState(results: []);
      expect(state.hasFailures, false);
    });

    test('failureCount returns 0 with empty results', () {
      const state = SyncState(results: []);
      expect(state.failureCount, 0);
    });

    test('successCount returns 0 with empty results', () {
      const state = SyncState(results: []);
      expect(state.successCount, 0);
    });

    test('copyWith updates lastSyncTime', () {
      const state = SyncState();
      final now = DateTime(2024, 6, 15, 10, 30);
      final updated = state.copyWith(lastSyncTime: now);
      expect(updated.lastSyncTime, now);
      expect(updated.isSyncing, false);
    });

    test('copyWith updates results list', () {
      const state = SyncState();
      final results = [
        SyncResult(type: 'proof', itemId: 1, success: true),
        SyncResult(
          type: 'action',
          itemId: 2,
          success: false,
          errorMessage: 'fail',
        ),
      ];
      final updated = state.copyWith(results: results);
      expect(updated.results.length, 2);
      expect(updated.hasFailures, true);
      expect(updated.failureCount, 1);
      expect(updated.successCount, 1);
    });

    test('all failures counted correctly', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: false),
          SyncResult(type: 'action', itemId: 2, success: false),
          SyncResult(type: 'position', itemId: 3, success: false),
        ],
      );
      expect(state.failureCount, 3);
      expect(state.successCount, 0);
      expect(state.hasFailures, true);
    });

    test('all successes counted correctly', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'action', itemId: 2, success: true),
        ],
      );
      expect(state.failureCount, 0);
      expect(state.successCount, 2);
      expect(state.hasFailures, false);
    });

    test('copyWith with all fields at once', () {
      final now = DateTime(2024, 3, 1);
      final results = [SyncResult(type: 'x', itemId: 1, success: true)];
      const state = SyncState();
      final updated = state.copyWith(
        isSyncing: true,
        totalPending: 20,
        synced: 15,
        currentAction: 'uploading photos',
        results: results,
        lastSyncTime: now,
      );
      expect(updated.isSyncing, true);
      expect(updated.totalPending, 20);
      expect(updated.synced, 15);
      expect(updated.currentAction, 'uploading photos');
      expect(updated.results.length, 1);
      expect(updated.lastSyncTime, now);
      expect(updated.progress, 0.75);
    });
  });

  group('SyncResult - additional', () {
    test('different types are supported', () {
      final proofResult = SyncResult(type: 'proof', itemId: 1, success: true);
      final actionResult = SyncResult(type: 'action', itemId: 2, success: true);
      final positionResult = SyncResult(
        type: 'position',
        itemId: 3,
        success: false,
      );
      expect(proofResult.type, 'proof');
      expect(actionResult.type, 'action');
      expect(positionResult.type, 'position');
    });

    test('errorMessage is null when success', () {
      final result = SyncResult(type: 'proof', itemId: 1, success: true);
      expect(result.errorMessage, isNull);
    });
  });

  group('SyncState copyWith individual fields', () {
    test('copyWith isSyncing only', () {
      const state = SyncState();
      final copy = state.copyWith(isSyncing: true);
      expect(copy.isSyncing, true);
      expect(copy.totalPending, 0);
      expect(copy.synced, 0);
      expect(copy.currentAction, isNull);
    });

    test('copyWith totalPending only', () {
      const state = SyncState();
      final copy = state.copyWith(totalPending: 15);
      expect(copy.totalPending, 15);
      expect(copy.isSyncing, false);
    });

    test('copyWith synced only', () {
      const state = SyncState();
      final copy = state.copyWith(synced: 7);
      expect(copy.synced, 7);
    });

    test('copyWith currentAction only', () {
      const state = SyncState();
      final copy = state.copyWith(currentAction: 'uploading proofs');
      expect(copy.currentAction, 'uploading proofs');
    });

    test('copyWith results only', () {
      const state = SyncState();
      final results = [
        SyncResult(type: 'proof', itemId: 1, success: true),
        SyncResult(
          type: 'action',
          itemId: 2,
          success: false,
          errorMessage: 'timeout',
        ),
      ];
      final copy = state.copyWith(results: results);
      expect(copy.results.length, 2);
      expect(copy.results[1].errorMessage, 'timeout');
    });

    test('copyWith lastSyncTime only', () {
      const state = SyncState();
      final time = DateTime(2025, 1, 15, 14, 30);
      final copy = state.copyWith(lastSyncTime: time);
      expect(copy.lastSyncTime, time);
    });
  });

  group('SyncState progress edge cases', () {
    test('progress with synced > totalPending', () {
      const state = SyncState(totalPending: 5, synced: 10);
      expect(state.progress, 2.0);
    });

    test('progress with 1 of 1', () {
      const state = SyncState(totalPending: 1, synced: 1);
      expect(state.progress, 1.0);
    });

    test('progress with very large numbers', () {
      const state = SyncState(totalPending: 100000, synced: 50000);
      expect(state.progress, 0.5);
    });
  });

  group('SyncResult additional', () {
    test('different itemIds', () {
      final r1 = SyncResult(type: 'proof', itemId: 0, success: true);
      final r2 = SyncResult(type: 'proof', itemId: -1, success: true);
      final r3 = SyncResult(type: 'proof', itemId: 999999, success: true);
      expect(r1.itemId, 0);
      expect(r2.itemId, -1);
      expect(r3.itemId, 999999);
    });

    test('long error message', () {
      final result = SyncResult(
        type: 'action',
        itemId: 1,
        success: false,
        errorMessage: 'A' * 500,
      );
      expect(result.errorMessage!.length, 500);
    });
  });

  group('SyncManager runtime flows', () {
    test('providers start idle and expose syncing state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(syncManagerProvider);

      expect(state.isSyncing, isFalse);
      expect(state.totalPending, 0);
      expect(container.read(isSyncingProvider), isFalse);
    });

    test('queueAction stores an offline action and updates pending counters', () async {
      final connectivity = _TestConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity),
        ],
      );
      addTearDown(container.dispose);

      final manager = container.read(syncManagerProvider.notifier);
      await manager.queueAction(
        type: 'pickup',
        deliveryId: 7,
        data: {'status': 'picked_up'},
      );

      expect(await offlineService.getPendingActionsCount(), 1);
      expect(container.read(syncManagerProvider).totalPending, 1);
      expect(container.read(pendingSyncCountProvider), 1);
    });

    test('forceSync exits immediately when connectivity is offline', () async {
      final connectivity = _TestConnectivityService()
        ..setTestState(
          const ConnectivityState(status: ConnectivityStatus.offline),
        );
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity),
        ],
      );
      addTearDown(container.dispose);

      final manager = container.read(syncManagerProvider.notifier);
      await manager.forceSync();

      final state = container.read(syncManagerProvider);
      expect(state.isSyncing, isFalse);
      expect(state.results, isEmpty);
      expect(state.lastSyncTime, isNull);
    });

    test('syncAll uploads queued proofs and actions when online', () async {
      final connectivity = _TestConnectivityService()
        ..setTestState(
          const ConnectivityState(
            status: ConnectivityStatus.online,
            connectionTypes: [ConnectivityResult.wifi],
          ),
        );
      final dio = _MockDio();
      final repo = _MockDeliveryRepository();

      when(() => dio.post(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/ok'),
          data: const {},
        ),
      );
      when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/ok'),
          data: const {},
        ),
      );
      when(() => repo.getDeliveries(status: any(named: 'status'))).thenAnswer(
        (_) async => <Delivery>[],
      );
      when(() => repo.getProfile()).thenAnswer(
        (_) async => CourierProfile(
          id: 1,
          name: 'Sync Test',
          email: 'sync@test.com',
          status: 'available',
          vehicleType: 'moto',
          plateNumber: 'AB-1234',
          rating: 4.5,
          completedDeliveries: 10,
          earnings: 5000,
          kycStatus: 'approved',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity),
          dioProvider.overrideWith((ref) => dio),
          deliveryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final manager = container.read(syncManagerProvider.notifier);
      await offlineService.addPendingProof(deliveryId: 11, notes: 'preuve');
      await manager.queueAction(type: 'pickup', deliveryId: 12);

      await manager.syncAll();

      final state = container.read(syncManagerProvider);
      expect(state.isSyncing, isFalse);
      expect(state.successCount, 2);
      expect(state.failureCount, 0);
      expect(state.lastSyncTime, isNotNull);
      expect(container.read(pendingSyncCountProvider), 0);
      verify(() => dio.post('/courier/deliveries/11/proof', data: any(named: 'data'))).called(1);
      verify(() => dio.post('/courier/deliveries/12/pickup')).called(1);
      verify(() => repo.getDeliveries(status: 'active')).called(1);
      verify(() => repo.getProfile()).called(1);
    });

    test('syncAll records failures and requeues proofs when upload fails', () async {
      final connectivity = _TestConnectivityService()
        ..setTestState(
          const ConnectivityState(
            status: ConnectivityStatus.online,
            connectionTypes: [ConnectivityResult.wifi],
          ),
        );
      final dio = _MockDio();
      final repo = _MockDeliveryRepository();

      when(() => dio.post(any(), data: any(named: 'data'))).thenThrow(Exception('upload failed'));
      when(() => repo.getDeliveries(status: any(named: 'status'))).thenAnswer((_) async => <Delivery>[]);
      when(() => repo.getProfile()).thenAnswer(
        (_) async => CourierProfile(
          id: 2,
          name: 'Retry Test',
          email: 'retry@test.com',
          status: 'available',
          vehicleType: 'moto',
          plateNumber: 'CD-5678',
          rating: 4.0,
          completedDeliveries: 5,
          earnings: 2500,
          kycStatus: 'approved',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity),
          dioProvider.overrideWith((ref) => dio),
          deliveryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final manager = container.read(syncManagerProvider.notifier);
      await offlineService.addPendingProof(deliveryId: 77, notes: 'retry later');

      await manager.syncAll();

      final state = container.read(syncManagerProvider);
      expect(state.failureCount, 1);
      expect(state.results.single.success, isFalse);
      expect(await offlineService.getPendingProofsCount(), 1);
    });
  });

  group('SyncState comprehensive state checking', () {
    test('mixed results: 3 success, 2 failure', () {
      final state = SyncState(
        totalPending: 5,
        synced: 5,
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'proof', itemId: 2, success: true),
          SyncResult(type: 'action', itemId: 3, success: true),
          SyncResult(
            type: 'action',
            itemId: 4,
            success: false,
            errorMessage: 'timeout',
          ),
          SyncResult(
            type: 'proof',
            itemId: 5,
            success: false,
            errorMessage: 'server error',
          ),
        ],
      );
      expect(state.successCount, 3);
      expect(state.failureCount, 2);
      expect(state.hasFailures, true);
      expect(state.progress, 1.0);
    });

    test('single result success', () {
      final state = SyncState(
        totalPending: 1,
        synced: 1,
        results: [SyncResult(type: 'proof', itemId: 1, success: true)],
      );
      expect(state.successCount, 1);
      expect(state.failureCount, 0);
      expect(state.hasFailures, false);
      expect(state.progress, 1.0);
    });

    test('single result failure', () {
      final state = SyncState(
        totalPending: 1,
        synced: 1,
        results: [
          SyncResult(
            type: 'action',
            itemId: 1,
            success: false,
            errorMessage: 'err',
          ),
        ],
      );
      expect(state.successCount, 0);
      expect(state.failureCount, 1);
      expect(state.hasFailures, true);
    });

    test('state with currentAction set', () {
      const state = SyncState(
        isSyncing: true,
        currentAction: 'Envoi des preuves de livraison...',
        totalPending: 3,
        synced: 1,
      );
      expect(state.isSyncing, true);
      expect(state.currentAction, contains('preuves'));
      expect(state.progress, closeTo(0.333, 0.01));
    });

    test('progress with 1 of 3', () {
      const state = SyncState(totalPending: 3, synced: 1);
      expect(state.progress, closeTo(0.333, 0.01));
    });

    test('progress with 2 of 3', () {
      const state = SyncState(totalPending: 3, synced: 2);
      expect(state.progress, closeTo(0.666, 0.01));
    });

    test('progress with 99 of 100', () {
      const state = SyncState(totalPending: 100, synced: 99);
      expect(state.progress, 0.99);
    });
  });

  group('SyncResult - various types', () {
    test('proof type', () {
      final r = SyncResult(type: 'proof', itemId: 10, success: true);
      expect(r.type, 'proof');
    });

    test('action type', () {
      final r = SyncResult(type: 'action', itemId: 20, success: true);
      expect(r.type, 'action');
    });

    test('pickup type', () {
      final r = SyncResult(type: 'pickup', itemId: 30, success: true);
      expect(r.type, 'pickup');
    });

    test('deliver type', () {
      final r = SyncResult(
        type: 'deliver',
        itemId: 40,
        success: false,
        errorMessage: 'err',
      );
      expect(r.type, 'deliver');
      expect(r.success, false);
    });

    test('location_update type', () {
      final r = SyncResult(type: 'location_update', itemId: 50, success: true);
      expect(r.type, 'location_update');
    });

    test('rate_customer type', () {
      final r = SyncResult(type: 'rate_customer', itemId: 60, success: true);
      expect(r.type, 'rate_customer');
    });
  });

  group('SyncState - copyWith transitions', () {
    test('transition: idle → syncing', () {
      const idle = SyncState();
      final syncing = idle.copyWith(
        isSyncing: true,
        totalPending: 5,
        synced: 0,
        results: [],
      );
      expect(syncing.isSyncing, true);
      expect(syncing.totalPending, 5);
      expect(syncing.synced, 0);
    });

    test('transition: syncing → progress', () {
      final syncing = SyncState(
        isSyncing: true,
        totalPending: 5,
        synced: 0,
        results: [],
      );
      final progress = syncing.copyWith(
        synced: 3,
        currentAction: 'Syncing actions...',
      );
      expect(progress.synced, 3);
      expect(progress.progress, 0.6);
      expect(progress.currentAction, 'Syncing actions...');
    });

    test('transition: syncing → done', () {
      final syncing = SyncState(
        isSyncing: true,
        totalPending: 5,
        synced: 5,
        results: [
          SyncResult(type: 'proof', itemId: 1, success: true),
          SyncResult(type: 'proof', itemId: 2, success: true),
          SyncResult(type: 'action', itemId: 3, success: true),
          SyncResult(type: 'action', itemId: 4, success: true),
          SyncResult(type: 'action', itemId: 5, success: true),
        ],
      );
      final done = syncing.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime(2025, 1, 1),
      );
      expect(done.isSyncing, false);
      expect(done.lastSyncTime, isNotNull);
      expect(done.successCount, 5);
      expect(done.failureCount, 0);
      expect(done.progress, 1.0);
    });
  });

  group('SyncResult timestamp ordering', () {
    test('sequential results have non-decreasing timestamps', () {
      final r1 = SyncResult(type: 'proof', itemId: 1, success: true);
      final r2 = SyncResult(type: 'proof', itemId: 2, success: true);
      expect(
        r2.timestamp.isAfter(r1.timestamp) ||
            r2.timestamp.isAtSameMomentAs(r1.timestamp),
        true,
      );
    });
  });
}
