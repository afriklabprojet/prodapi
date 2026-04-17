import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:courier/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityStatus', () {
    test('has 3 values', () {
      expect(ConnectivityStatus.values.length, 3);
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.checking));
    });
  });

  group('ConnectivityState', () {
    test('default state', () {
      const state = ConnectivityState();
      expect(state.status, ConnectivityStatus.checking);
      expect(state.connectionTypes, isEmpty);
      expect(state.lastOnlineTime, isNull);
      expect(state.pendingSyncCount, 0);
      expect(state.isSyncing, false);
    });

    test('isOnline when status is online', () {
      const state = ConnectivityState(status: ConnectivityStatus.online);
      expect(state.isOnline, true);
      expect(state.isOffline, false);
    });

    test('isOffline when status is offline', () {
      const state = ConnectivityState(status: ConnectivityStatus.offline);
      expect(state.isOnline, false);
      expect(state.isOffline, true);
    });

    test('checking is neither online nor offline', () {
      const state = ConnectivityState(status: ConnectivityStatus.checking);
      expect(state.isOnline, false);
      expect(state.isOffline, false);
    });

    group('connectionTypeLabel', () {
      test('returns Aucune when empty', () {
        const state = ConnectivityState();
        expect(state.connectionTypeLabel, 'Aucune');
      });

      test('returns WiFi when wifi present', () {
        const state = ConnectivityState(
          connectionTypes: [ConnectivityResult.wifi],
        );
        expect(state.connectionTypeLabel, 'WiFi');
      });

      test('returns WiFi even when mobile also present', () {
        const state = ConnectivityState(
          connectionTypes: [ConnectivityResult.mobile, ConnectivityResult.wifi],
        );
        expect(state.connectionTypeLabel, 'WiFi');
      });

      test('returns Données mobiles for mobile only', () {
        const state = ConnectivityState(
          connectionTypes: [ConnectivityResult.mobile],
        );
        expect(state.connectionTypeLabel, 'Données mobiles');
      });

      test('returns Ethernet for ethernet', () {
        const state = ConnectivityState(
          connectionTypes: [ConnectivityResult.ethernet],
        );
        expect(state.connectionTypeLabel, 'Ethernet');
      });

      test('returns Autre for bluetooth', () {
        const state = ConnectivityState(
          connectionTypes: [ConnectivityResult.bluetooth],
        );
        expect(state.connectionTypeLabel, 'Autre');
      });
    });

    group('offlineDurationLabel', () {
      test('returns empty when online', () {
        const state = ConnectivityState(status: ConnectivityStatus.online);
        expect(state.offlineDurationLabel, '');
      });

      test('returns empty when lastOnlineTime is null', () {
        const state = ConnectivityState(status: ConnectivityStatus.offline);
        expect(state.offlineDurationLabel, '');
      });

      test('returns instant for recent disconnect', () {
        final state = ConnectivityState(
          status: ConnectivityStatus.offline,
          lastOnlineTime: DateTime.now(),
        );
        expect(state.offlineDurationLabel, 'À l\'instant');
      });

      test('returns minutes for recent disconnect', () {
        final state = ConnectivityState(
          status: ConnectivityStatus.offline,
          lastOnlineTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(state.offlineDurationLabel, 'Hors-ligne depuis 5 min');
      });

      test('returns hours for longer disconnect', () {
        final state = ConnectivityState(
          status: ConnectivityStatus.offline,
          lastOnlineTime: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(state.offlineDurationLabel, 'Hors-ligne depuis 3h');
      });

      test('returns days for very long disconnect', () {
        final state = ConnectivityState(
          status: ConnectivityStatus.offline,
          lastOnlineTime: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(state.offlineDurationLabel, 'Hors-ligne depuis 2j');
      });
    });

    group('copyWith', () {
      test('preserves all fields when no args', () {
        final original = ConnectivityState(
          status: ConnectivityStatus.online,
          connectionTypes: const [ConnectivityResult.wifi],
          lastOnlineTime: DateTime(2024, 1, 1),
          pendingSyncCount: 5,
          isSyncing: true,
        );
        final copy = original.copyWith();
        expect(copy.status, ConnectivityStatus.online);
        expect(copy.connectionTypes, [ConnectivityResult.wifi]);
        expect(copy.lastOnlineTime, DateTime(2024, 1, 1));
        expect(copy.pendingSyncCount, 5);
        expect(copy.isSyncing, true);
      });

      test('updates specific fields', () {
        const original = ConnectivityState();
        final updated = original.copyWith(
          status: ConnectivityStatus.online,
          pendingSyncCount: 3,
        );
        expect(updated.status, ConnectivityStatus.online);
        expect(updated.pendingSyncCount, 3);
        expect(updated.isSyncing, false);
      });
    });
  });
}
