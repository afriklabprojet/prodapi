import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/sync_manager.dart';

void main() {
  // ════════════════════════════════════════════
  // SyncState
  // ════════════════════════════════════════════
  group('SyncState', () {
    test('default constructor', () {
      const state = SyncState();
      expect(state.isSyncing, false);
      expect(state.totalPending, 0);
      expect(state.synced, 0);
      expect(state.currentAction, null);
      expect(state.results, isEmpty);
      expect(state.lastSyncTime, null);
    });

    test('progress is 0 when totalPending is 0', () {
      const state = SyncState(totalPending: 0, synced: 0);
      expect(state.progress, 0);
    });

    test('progress calculates correctly', () {
      const state = SyncState(totalPending: 10, synced: 5);
      expect(state.progress, 0.5);
    });

    test('progress is 1 when all synced', () {
      const state = SyncState(totalPending: 8, synced: 8);
      expect(state.progress, 1.0);
    });

    test('hasFailures is false when no results', () {
      const state = SyncState();
      expect(state.hasFailures, false);
    });

    test('hasFailures is true when failure exists', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'delivery', itemId: 1, success: true),
          SyncResult(
            type: 'delivery',
            itemId: 2,
            success: false,
            errorMessage: 'err',
          ),
        ],
      );
      expect(state.hasFailures, true);
    });

    test('hasFailures is false when all success', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'delivery', itemId: 1, success: true),
          SyncResult(type: 'delivery', itemId: 2, success: true),
        ],
      );
      expect(state.hasFailures, false);
    });

    test('failureCount returns correct count', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'delivery', itemId: 1, success: false),
          SyncResult(type: 'delivery', itemId: 2, success: true),
          SyncResult(type: 'proof', itemId: 3, success: false),
        ],
      );
      expect(state.failureCount, 2);
    });

    test('successCount returns correct count', () {
      final state = SyncState(
        results: [
          SyncResult(type: 'delivery', itemId: 1, success: false),
          SyncResult(type: 'delivery', itemId: 2, success: true),
          SyncResult(type: 'proof', itemId: 3, success: true),
        ],
      );
      expect(state.successCount, 2);
    });

    test('copyWith preserves values', () {
      final now = DateTime.now();
      final state = SyncState(
        isSyncing: true,
        totalPending: 5,
        synced: 3,
        currentAction: 'uploading',
        lastSyncTime: now,
      );
      final copy = state.copyWith();
      expect(copy.isSyncing, true);
      expect(copy.totalPending, 5);
      expect(copy.synced, 3);
      expect(copy.currentAction, 'uploading');
      expect(copy.lastSyncTime, now);
    });

    test('copyWith updates specific fields', () {
      const state = SyncState(isSyncing: true, totalPending: 5);
      final copy = state.copyWith(synced: 2, currentAction: 'proof');
      expect(copy.isSyncing, true);
      expect(copy.totalPending, 5);
      expect(copy.synced, 2);
      expect(copy.currentAction, 'proof');
    });
  });

  // ════════════════════════════════════════════
  // SyncResult
  // ════════════════════════════════════════════
  group('SyncResult', () {
    test('constructor sets fields', () {
      final result = SyncResult(type: 'delivery', itemId: 42, success: true);
      expect(result.type, 'delivery');
      expect(result.itemId, 42);
      expect(result.success, true);
      expect(result.errorMessage, null);
      expect(result.timestamp, isA<DateTime>());
    });

    test('constructor with error', () {
      final result = SyncResult(
        type: 'proof',
        itemId: 7,
        success: false,
        errorMessage: 'network error',
      );
      expect(result.success, false);
      expect(result.errorMessage, 'network error');
    });
  });
}
