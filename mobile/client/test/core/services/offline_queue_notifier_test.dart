import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/core/services/offline_queue_service.dart';

// ─────────────────────────────────────────────────────────
// Helper builder
// ─────────────────────────────────────────────────────────

ProviderContainer _makeContainer({required SharedPreferences prefs}) {
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = _makeContainer(prefs: prefs);
  });

  tearDown(() {
    container.dispose();
  });

  group('OfflineQueueNotifier', () {
    // ── initial state ──────────────────────────────────────
    group('initial state', () {
      test('pendingActions is empty on first launch', () {
        final state = container.read(offlineQueueProvider);
        expect(state.pendingActions, isEmpty);
        expect(state.hasPending, isFalse);
        expect(state.pendingCount, 0);
        expect(state.isSyncing, isFalse);
      });
    });

    // ── enqueue ────────────────────────────────────────────
    group('enqueue', () {
      test('adds an action to state', () async {
        await container.read(offlineQueueProvider.notifier).enqueue(
          QueuedActionType.submitPrescription,
          {'note': 'urgent'},
        );

        final state = container.read(offlineQueueProvider);
        expect(state.pendingCount, 1);
        expect(state.hasPending, isTrue);
        expect(
          state.pendingActions[0].type,
          QueuedActionType.submitPrescription,
        );
        expect(state.pendingActions[0].payload, {'note': 'urgent'});
      });

      test('persists action to SharedPreferences', () async {
        await container.read(offlineQueueProvider.notifier).enqueue(
          QueuedActionType.updateProfile,
          {'name': 'John'},
        );

        final jsonStr = prefs.getString('offline_queue');
        expect(jsonStr, isNotNull);
        final list = jsonDecode(jsonStr!) as List<dynamic>;
        expect(list.length, 1);
        expect(list[0]['type'], 'updateProfile');
      });

      test('multiple enqueues accumulates actions', () async {
        final notifier = container.read(offlineQueueProvider.notifier);
        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'a',
        });
        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'b',
        });

        expect(container.read(offlineQueueProvider).pendingCount, 2);
      });

      test('clears lastError on enqueue', () async {
        // Set up a state with a lastError by manually inspecting state
        final notifier = container.read(offlineQueueProvider.notifier);
        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'x',
        });

        // lastError should be null (cleared on enqueue)
        expect(container.read(offlineQueueProvider).lastError, isNull);
      });
    });

    // ── removeAction ───────────────────────────────────────
    group('removeAction', () {
      test('removes the action with the given id', () async {
        final notifier = container.read(offlineQueueProvider.notifier);

        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'x',
        });
        final state1 = container.read(offlineQueueProvider);
        final actionId = state1.pendingActions[0].id;

        await notifier.removeAction(actionId);

        expect(container.read(offlineQueueProvider).pendingCount, 0);
      });

      test('removing non-existent id does not throw', () async {
        final notifier = container.read(offlineQueueProvider.notifier);

        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'y',
        });
        await notifier.removeAction('non-existent-id');

        // Original action still present
        expect(container.read(offlineQueueProvider).pendingCount, 1);
      });

      test('persists removal to SharedPreferences', () async {
        final notifier = container.read(offlineQueueProvider.notifier);

        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': '1',
        });
        final actionId = container
            .read(offlineQueueProvider)
            .pendingActions[0]
            .id;

        await notifier.removeAction(actionId);

        final jsonStr = prefs.getString('offline_queue');
        expect(jsonStr, isNotNull);
        final list = jsonDecode(jsonStr!) as List<dynamic>;
        expect(list, isEmpty);
      });
    });

    // ── clearQueue ─────────────────────────────────────────
    group('clearQueue', () {
      test('empties all pending actions', () async {
        final notifier = container.read(offlineQueueProvider.notifier);
        await notifier.enqueue(QueuedActionType.submitPrescription, {'a': '1'});
        await notifier.enqueue(QueuedActionType.submitPrescription, {'b': '2'});

        expect(container.read(offlineQueueProvider).pendingCount, 2);

        await notifier.clearQueue();

        expect(container.read(offlineQueueProvider).pendingCount, 0);
        expect(container.read(offlineQueueProvider).hasPending, isFalse);
      });

      test('removes storage key from SharedPreferences', () async {
        final notifier = container.read(offlineQueueProvider.notifier);
        await notifier.enqueue(QueuedActionType.submitPrescription, {'a': '1'});
        expect(prefs.getString('offline_queue'), isNotNull);

        await notifier.clearQueue();

        expect(prefs.getString('offline_queue'), isNull);
      });
    });

    // ── syncPendingActions ─────────────────────────────────
    group('syncPendingActions', () {
      test('no-op when queue is empty', () async {
        await container
            .read(offlineQueueProvider.notifier)
            .syncPendingActions();

        expect(container.read(offlineQueueProvider).isSyncing, isFalse);
        expect(container.read(offlineQueueProvider).pendingCount, 0);
      });

      test('processes submitPrescription actions (discards them)', () async {
        final notifier = container.read(offlineQueueProvider.notifier);

        // submitPrescription actions are silently discarded (not supported offline)
        await notifier.enqueue(QueuedActionType.submitPrescription, {
          'note': 'test',
        });
        expect(container.read(offlineQueueProvider).pendingCount, 1);

        await notifier.syncPendingActions();

        // After sync, action should be completed (removed from queue)
        expect(container.read(offlineQueueProvider).isSyncing, isFalse);
        expect(container.read(offlineQueueProvider).pendingCount, 0);
      });
    });

    // ── _loadQueue (restore on init) ───────────────────────
    group('restore on init', () {
      test('loads persisted actions from SharedPreferences', () async {
        // Pre-seed SharedPreferences with a serialized queue
        final existingAction = QueuedAction(
          id: 'seeded-id',
          type: QueuedActionType.submitPrescription,
          payload: {'note': 'persisted'},
          queuedAt: DateTime(2024, 1, 1),
        );
        await prefs.setString(
          'offline_queue',
          jsonEncode([existingAction.toJson()]),
        );

        // Create a new container to trigger _loadQueue
        final newContainer = _makeContainer(prefs: prefs);
        addTearDown(newContainer.dispose);
        await Future.delayed(const Duration(milliseconds: 10));

        final state = newContainer.read(offlineQueueProvider);
        expect(state.pendingCount, 1);
        expect(state.pendingActions[0].id, 'seeded-id');
        expect(
          state.pendingActions[0].type,
          QueuedActionType.submitPrescription,
        );
      });

      test('handles corrupted SharedPreferences gracefully', () async {
        await prefs.setString('offline_queue', 'INVALID JSON {{{');

        final newContainer = _makeContainer(prefs: prefs);
        addTearDown(newContainer.dispose);

        await Future.delayed(const Duration(milliseconds: 10));

        // Should not throw — state should be empty
        expect(newContainer.read(offlineQueueProvider).pendingActions, isEmpty);
      });
    });

    // ── QueuedAction model ─────────────────────────────────
    group('QueuedAction model', () {
      test('copyWith updates retryCount', () {
        final action = QueuedAction(
          id: 'a1',
          type: QueuedActionType.createOrder,
          payload: {},
          queuedAt: DateTime(2024),
        );
        final updated = action.copyWith(retryCount: 2);
        expect(updated.retryCount, 2);
        expect(updated.id, 'a1');
      });

      test('all QueuedActionType values are unique', () {
        final names = QueuedActionType.values.map((e) => e.name).toList();
        expect(names.toSet().length, names.length);
      });
    });
  });
}
