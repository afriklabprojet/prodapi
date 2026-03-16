import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/offline_mode_service.dart';

void main() {
  group('NetworkStatus', () {
    test('should have all expected values', () {
      expect(NetworkStatus.values.length, 4);
      expect(NetworkStatus.online.index, 0);
      expect(NetworkStatus.offline.index, 1);
      expect(NetworkStatus.weak.index, 2);
      expect(NetworkStatus.unknown.index, 3);
    });
  });

  group('SyncPriority', () {
    test('should have all expected values', () {
      expect(SyncPriority.values.length, 4);
      expect(SyncPriority.critical.index, 0);
      expect(SyncPriority.high.index, 1);
      expect(SyncPriority.normal.index, 2);
      expect(SyncPriority.low.index, 3);
    });
  });

  group('PendingSyncAction', () {
    test('should create with required properties', () {
      final action = PendingSyncAction(
        id: 'action_001',
        type: 'delivery_complete',
        endpoint: '/api/deliveries/123/complete',
        method: 'POST',
      );

      expect(action.id, 'action_001');
      expect(action.type, 'delivery_complete');
      expect(action.endpoint, '/api/deliveries/123/complete');
      expect(action.method, 'POST');
      expect(action.priority, SyncPriority.normal);
      expect(action.retryCount, 0);
      expect(action.maxRetries, 3);
    });

    test('should create with all optional properties', () {
      final now = DateTime.now();
      final action = PendingSyncAction(
        id: 'action_002',
        type: 'accept_order',
        endpoint: '/api/orders/456/accept',
        method: 'POST',
        body: {'courier_id': 'courier_123'},
        headers: {'Authorization': 'Bearer token'},
        priority: SyncPriority.high,
        createdAt: now,
        retryCount: 2,
        maxRetries: 5,
        lastAttempt: now,
        errorMessage: 'Network error',
      );

      expect(action.body, {'courier_id': 'courier_123'});
      expect(action.headers, {'Authorization': 'Bearer token'});
      expect(action.priority, SyncPriority.high);
      expect(action.createdAt, now);
      expect(action.retryCount, 2);
      expect(action.maxRetries, 5);
      expect(action.lastAttempt, now);
      expect(action.errorMessage, 'Network error');
    });

    test('canRetry should return true when retryCount < maxRetries', () {
      final action = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 2,
        maxRetries: 3,
      );

      expect(action.canRetry, true);
    });

    test('canRetry should return false when retryCount >= maxRetries', () {
      final action = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 3,
        maxRetries: 3,
      );

      expect(action.canRetry, false);
    });

    test('retryDelay should use exponential backoff', () {
      final action0 = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 0,
      );
      expect(action0.retryDelay, const Duration(seconds: 1));

      final action1 = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 1,
      );
      expect(action1.retryDelay, const Duration(seconds: 2));

      final action2 = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 2,
      );
      expect(action2.retryDelay, const Duration(seconds: 4));

      final action3 = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 3,
      );
      expect(action3.retryDelay, const Duration(seconds: 8));
    });

    test('retryDelay should be capped at 60 seconds', () {
      final action = PendingSyncAction(
        id: 'test',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 10,
      );
      expect(action.retryDelay, const Duration(seconds: 60));
    });

    test('copyWith should update specified fields', () {
      final action = PendingSyncAction(
        id: 'original',
        type: 'test',
        endpoint: '/test',
        method: 'GET',
        retryCount: 0,
      );

      final updated = action.copyWith(
        retryCount: 1,
        errorMessage: 'Failed',
      );

      expect(updated.id, 'original');
      expect(updated.retryCount, 1);
      expect(updated.errorMessage, 'Failed');
    });

    test('toJson should serialize correctly', () {
      final action = PendingSyncAction(
        id: 'action_json',
        type: 'test_type',
        endpoint: '/api/test',
        method: 'POST',
        body: {'key': 'value'},
        headers: {'X-Test': 'header'},
        priority: SyncPriority.critical,
      );

      final json = action.toJson();

      expect(json['id'], 'action_json');
      expect(json['type'], 'test_type');
      expect(json['endpoint'], '/api/test');
      expect(json['method'], 'POST');
      expect(json['body'], {'key': 'value'});
      expect(json['headers'], {'X-Test': 'header'});
      expect(json['priority'], 'critical');
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'id': 'json_action',
        'type': 'from_json',
        'endpoint': '/api/from_json',
        'method': 'PUT',
        'body': {'data': 123},
        'headers': {'Auth': 'Bearer xyz'},
        'priority': 'high',
        'createdAt': '2024-01-15T10:30:00.000',
        'retryCount': 2,
        'maxRetries': 5,
        'lastAttempt': '2024-01-15T10:35:00.000',
        'errorMessage': 'Previous error',
      };

      final action = PendingSyncAction.fromJson(json);

      expect(action.id, 'json_action');
      expect(action.type, 'from_json');
      expect(action.endpoint, '/api/from_json');
      expect(action.method, 'PUT');
      expect(action.body, {'data': 123});
      expect(action.headers, {'Auth': 'Bearer xyz'});
      expect(action.priority, SyncPriority.high);
      expect(action.retryCount, 2);
      expect(action.maxRetries, 5);
      expect(action.errorMessage, 'Previous error');
    });
  });

  group('CachedData', () {
    test('should create with required properties', () {
      final cached = CachedData(
        key: 'profile',
        data: {'name': 'Test User'},
      );

      expect(cached.key, 'profile');
      expect(cached.data, {'name': 'Test User'});
      expect(cached.isDirty, false);
    });

    test('should create with all optional properties', () {
      final now = DateTime(2024, 1, 15, 12, 0);
      final cached = CachedData(
        key: 'deliveries',
        data: [1, 2, 3],
        cachedAt: now,
        ttl: const Duration(hours: 1),
        etag: 'abc123',
        isDirty: true,
      );

      expect(cached.cachedAt, now);
      expect(cached.ttl, const Duration(hours: 1));
      expect(cached.etag, 'abc123');
      expect(cached.isDirty, true);
    });

    test('isExpired should return false when ttl is null', () {
      final cached = CachedData(
        key: 'test',
        data: 'data',
      );

      expect(cached.isExpired, false);
    });

    test('isExpired should return false when within ttl', () {
      final cached = CachedData(
        key: 'test',
        data: 'data',
        cachedAt: DateTime.now(),
        ttl: const Duration(hours: 1),
      );

      expect(cached.isExpired, false);
    });

    test('isExpired should return true when past ttl', () {
      final expiredTime = DateTime.now().subtract(const Duration(hours: 2));
      final cached = CachedData(
        key: 'test',
        data: 'data',
        cachedAt: expiredTime,
        ttl: const Duration(hours: 1),
      );

      expect(cached.isExpired, true);
    });

    test('toJson should serialize correctly', () {
      final now = DateTime(2024, 1, 15, 14, 0);
      final cached = CachedData(
        key: 'test_key',
        data: {'value': 42},
        cachedAt: now,
        ttl: const Duration(seconds: 3600),
        etag: 'etag123',
        isDirty: true,
      );

      final json = cached.toJson();

      expect(json['key'], 'test_key');
      expect(json['data'], {'value': 42});
      expect(json['ttl'], 3600);
      expect(json['etag'], 'etag123');
      expect(json['isDirty'], true);
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'key': 'from_json_key',
        'data': {'test': 'value'},
        'cachedAt': '2024-01-15T10:00:00.000',
        'ttl': 7200,
        'etag': 'etag456',
        'isDirty': false,
      };

      final cached = CachedData.fromJson(json);

      expect(cached.key, 'from_json_key');
      expect(cached.data, {'test': 'value'});
      expect(cached.ttl, const Duration(seconds: 7200));
      expect(cached.etag, 'etag456');
      expect(cached.isDirty, false);
    });
  });

  group('OfflineState', () {
    test('should create with default values', () {
      const state = OfflineState();

      expect(state.networkStatus, NetworkStatus.unknown);
      expect(state.pendingActionsCount, 0);
      expect(state.cachedItemsCount, 0);
      expect(state.lastSyncAt, isNull);
      expect(state.isSyncing, false);
      expect(state.syncProgress, 0.0);
      expect(state.syncError, isNull);
    });

    test('isOnline should return true when networkStatus is online', () {
      const state = OfflineState(networkStatus: NetworkStatus.online);
      expect(state.isOnline, true);
      expect(state.isOffline, false);
    });

    test('isOffline should return true when networkStatus is offline', () {
      const state = OfflineState(networkStatus: NetworkStatus.offline);
      expect(state.isOnline, false);
      expect(state.isOffline, true);
    });

    test('hasPendingActions should return true when count > 0', () {
      const state = OfflineState(pendingActionsCount: 5);
      expect(state.hasPendingActions, true);
    });

    test('hasPendingActions should return false when count is 0', () {
      const state = OfflineState(pendingActionsCount: 0);
      expect(state.hasPendingActions, false);
    });

    test('copyWith should update specified fields', () {
      const state = OfflineState();
      final now = DateTime.now();

      final updated = state.copyWith(
        networkStatus: NetworkStatus.online,
        pendingActionsCount: 3,
        lastSyncAt: now,
        isSyncing: true,
        syncProgress: 0.5,
      );

      expect(updated.networkStatus, NetworkStatus.online);
      expect(updated.pendingActionsCount, 3);
      expect(updated.lastSyncAt, now);
      expect(updated.isSyncing, true);
      expect(updated.syncProgress, 0.5);
    });

    test('copyWith should clear syncError when passed null', () {
      const state = OfflineState(syncError: 'Previous error');

      final updated = state.copyWith(syncError: null);

      expect(updated.syncError, isNull);
    });
  });
}
