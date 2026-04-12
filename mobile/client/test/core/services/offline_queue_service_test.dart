import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/core/services/offline_queue_service.dart';

void main() {
  // ─────────────────────────────────────────────────────────
  // QueuedAction — serialization
  // ─────────────────────────────────────────────────────────

  group('QueuedAction — serialization', () {
    test('toJson round-trip', () {
      final action = QueuedAction(
        id: 'action-001',
        type: QueuedActionType.createOrder,
        payload: {'productId': 1, 'quantity': 2},
        queuedAt: DateTime.parse('2024-01-15T12:00:00Z'),
        retryCount: 0,
      );

      final json = action.toJson();
      final restored = QueuedAction.fromJson(json);

      expect(restored.id, action.id);
      expect(restored.type, action.type);
      expect(restored.payload, action.payload);
      expect(
        restored.queuedAt.toIso8601String(),
        action.queuedAt.toIso8601String(),
      );
      expect(restored.retryCount, action.retryCount);
    });

    test('fromJson with updateProfile type', () {
      final json = {
        'id': 'action-002',
        'type': 'updateProfile',
        'payload': {'name': 'Test User'},
        'queuedAt': '2024-01-15T10:00:00.000Z',
        'retryCount': 1,
      };

      final action = QueuedAction.fromJson(json);

      expect(action.type, QueuedActionType.updateProfile);
      expect(action.retryCount, 1);
    });

    test('fromJson with submitPrescription type', () {
      final json = {
        'id': 'action-003',
        'type': 'submitPrescription',
        'payload': <String, dynamic>{},
        'queuedAt': '2024-01-15T10:00:00.000Z',
        'retryCount': 0,
      };

      final action = QueuedAction.fromJson(json);
      expect(action.type, QueuedActionType.submitPrescription);
    });

    test('fromJson unknown type defaults to createOrder', () {
      final json = {
        'id': 'action-004',
        'type': 'unknownType',
        'payload': <String, dynamic>{},
        'queuedAt': '2024-01-15T10:00:00.000Z',
        'retryCount': 0,
      };

      final action = QueuedAction.fromJson(json);
      expect(action.type, QueuedActionType.createOrder);
    });

    test('fromJson retryCount defaults to 0 when missing', () {
      final json = {
        'id': 'action-005',
        'type': 'createOrder',
        'payload': <String, dynamic>{},
        'queuedAt': '2024-01-15T10:00:00.000Z',
      };

      final action = QueuedAction.fromJson(json);
      expect(action.retryCount, 0);
    });

    test('copyWith increments retryCount', () {
      final action = QueuedAction(
        id: 'action-006',
        type: QueuedActionType.createOrder,
        payload: const {},
        queuedAt: DateTime.now(),
        retryCount: 2,
      );

      final copy = action.copyWith(retryCount: 3);

      expect(copy.retryCount, 3);
      expect(copy.id, action.id);
      expect(copy.type, action.type);
    });
  });

  // ─────────────────────────────────────────────────────────
  // OfflineQueueState — constructors and getters
  // ─────────────────────────────────────────────────────────

  group('OfflineQueueState — constructors', () {
    test('default constructor has empty pending actions', () {
      const state = OfflineQueueState();
      expect(state.pendingActions, isEmpty);
      expect(state.isSyncing, isFalse);
      expect(state.lastError, isNull);
    });

    test('pendingCount returns correct count', () {
      final actions = [
        QueuedAction(
          id: '1',
          type: QueuedActionType.createOrder,
          payload: const {},
          queuedAt: DateTime.now(),
        ),
        QueuedAction(
          id: '2',
          type: QueuedActionType.updateProfile,
          payload: const {},
          queuedAt: DateTime.now(),
        ),
      ];

      final state = OfflineQueueState(pendingActions: actions);

      expect(state.pendingCount, 2);
    });

    test('hasPending is true when there are actions', () {
      final actions = [
        QueuedAction(
          id: '1',
          type: QueuedActionType.createOrder,
          payload: const {},
          queuedAt: DateTime.now(),
        ),
      ];

      final state = OfflineQueueState(pendingActions: actions);
      expect(state.hasPending, isTrue);
    });

    test('hasPending is false when empty', () {
      const state = OfflineQueueState();
      expect(state.hasPending, isFalse);
    });

    test('copyWith updates pendingActions', () {
      const state = OfflineQueueState();
      final newActions = [
        QueuedAction(
          id: '1',
          type: QueuedActionType.createOrder,
          payload: const {},
          queuedAt: DateTime.now(),
        ),
      ];

      final updated = state.copyWith(pendingActions: newActions);
      expect(updated.pendingActions, hasLength(1));
    });

    test('copyWith updates isSyncing', () {
      const state = OfflineQueueState();
      final updated = state.copyWith(isSyncing: true);
      expect(updated.isSyncing, isTrue);
    });

    test('copyWith sets lastError to null when not provided', () {
      const state = OfflineQueueState(lastError: 'some error');
      final updated = state.copyWith();
      expect(updated.lastError, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // OfflineQueueNotifier — enqueue, removeAction, clearQueue
  // ─────────────────────────────────────────────────────────

  group('OfflineQueueNotifier — state management', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state has no pending actions', () {
      // We test only the state/model here
      const state = OfflineQueueState();
      expect(state.pendingActions, isEmpty);
      expect(state.isSyncing, isFalse);
    });

    test(
      'QueuedAction serialization roundtrip via SharedPreferences',
      () async {
        final action = QueuedAction(
          id: '42',
          type: QueuedActionType.updateProfile,
          payload: {'name': 'Alice', 'email': 'alice@example.com'},
          queuedAt: DateTime.parse('2024-06-01T08:00:00Z'),
          retryCount: 1,
        );

        final data = jsonEncode([action.toJson()]);
        await prefs.setString('offline_queue', data);

        final readBack = prefs.getString('offline_queue')!;
        final decoded = (jsonDecode(readBack) as List<dynamic>)
            .map((j) => QueuedAction.fromJson(j as Map<String, dynamic>))
            .toList();

        expect(decoded.length, 1);
        expect(decoded[0].id, '42');
        expect(decoded[0].type, QueuedActionType.updateProfile);
        expect(decoded[0].retryCount, 1);
      },
    );

    test('Multiple actions serialize and restore correctly', () async {
      final now = DateTime.now();
      final actions = [
        QueuedAction(
          id: 'a',
          type: QueuedActionType.createOrder,
          payload: const {'orderId': 1},
          queuedAt: now,
        ),
        QueuedAction(
          id: 'b',
          type: QueuedActionType.submitPrescription,
          payload: const {},
          queuedAt: now,
        ),
      ];

      final data = jsonEncode(actions.map((a) => a.toJson()).toList());
      await prefs.setString('offline_queue', data);

      final restored = (jsonDecode(prefs.getString('offline_queue')!) as List)
          .map((j) => QueuedAction.fromJson(j as Map<String, dynamic>))
          .toList();

      expect(restored.length, 2);
      expect(restored[0].id, 'a');
      expect(restored[1].id, 'b');
    });

    test('QueuedActionType.values contains all expected types', () {
      expect(QueuedActionType.values, hasLength(3));
      expect(
        QueuedActionType.values,
        containsAll([
          QueuedActionType.createOrder,
          QueuedActionType.updateProfile,
          QueuedActionType.submitPrescription,
        ]),
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // OfflineQueueState — copyWith edge cases
  // ─────────────────────────────────────────────────────────

  group('OfflineQueueState — copyWith preserves unchanged values', () {
    test('preserves existing pendingActions when not specified', () {
      final actions = [
        QueuedAction(
          id: '1',
          type: QueuedActionType.createOrder,
          payload: const {},
          queuedAt: DateTime.now(),
        ),
      ];
      final state = OfflineQueueState(pendingActions: actions, isSyncing: true);

      final updated = state.copyWith(isSyncing: false);
      expect(updated.pendingActions, hasLength(1));
      expect(updated.isSyncing, isFalse);
    });

    test('preserves isSyncing when pendingActions updated', () {
      const state = OfflineQueueState(isSyncing: true);
      final updated = state.copyWith(pendingActions: []);
      expect(updated.isSyncing, isTrue);
    });
  });
}
