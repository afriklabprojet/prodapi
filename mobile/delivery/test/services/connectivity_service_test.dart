import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:courier/core/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityStatus', () {
    test('has all expected values', () {
      expect(ConnectivityStatus.values.length, 3);
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.checking));
    });
  });

  group('ConnectivityState', () {
    test('default constructor has correct defaults', () {
      const state = ConnectivityState();
      expect(state.status, ConnectivityStatus.checking);
      expect(state.connectionTypes, isEmpty);
      expect(state.lastOnlineTime, isNull);
      expect(state.pendingSyncCount, 0);
      expect(state.isSyncing, false);
    });

    test('copyWith preserves values when null', () {
      final state = ConnectivityState(
        status: ConnectivityStatus.online,
        connectionTypes: [ConnectivityResult.wifi],
        lastOnlineTime: DateTime(2024, 1, 1),
        pendingSyncCount: 5,
        isSyncing: true,
      );
      final copy = state.copyWith();
      expect(copy.status, ConnectivityStatus.online);
      expect(copy.connectionTypes, [ConnectivityResult.wifi]);
      expect(copy.lastOnlineTime, DateTime(2024, 1, 1));
      expect(copy.pendingSyncCount, 5);
      expect(copy.isSyncing, true);
    });

    test('copyWith overrides values', () {
      const state = ConnectivityState();
      final copy = state.copyWith(
        status: ConnectivityStatus.online,
        pendingSyncCount: 3,
        isSyncing: true,
      );
      expect(copy.status, ConnectivityStatus.online);
      expect(copy.pendingSyncCount, 3);
      expect(copy.isSyncing, true);
    });

    test('isOnline returns true only when online', () {
      const online = ConnectivityState(status: ConnectivityStatus.online);
      const offline = ConnectivityState(status: ConnectivityStatus.offline);
      const checking = ConnectivityState(status: ConnectivityStatus.checking);
      expect(online.isOnline, true);
      expect(offline.isOnline, false);
      expect(checking.isOnline, false);
    });

    test('isOffline returns true only when offline', () {
      const online = ConnectivityState(status: ConnectivityStatus.online);
      const offline = ConnectivityState(status: ConnectivityStatus.offline);
      const checking = ConnectivityState(status: ConnectivityStatus.checking);
      expect(online.isOffline, false);
      expect(offline.isOffline, true);
      expect(checking.isOffline, false);
    });

    test('connectionTypeLabel returns Aucune when empty', () {
      const state = ConnectivityState(connectionTypes: []);
      expect(state.connectionTypeLabel, 'Aucune');
    });

    test('connectionTypeLabel returns WiFi', () {
      const state = ConnectivityState(
        connectionTypes: [ConnectivityResult.wifi],
      );
      expect(state.connectionTypeLabel, 'WiFi');
    });

    test('connectionTypeLabel returns Données mobiles', () {
      const state = ConnectivityState(
        connectionTypes: [ConnectivityResult.mobile],
      );
      expect(state.connectionTypeLabel, 'Données mobiles');
    });

    test('connectionTypeLabel returns Ethernet', () {
      const state = ConnectivityState(
        connectionTypes: [ConnectivityResult.ethernet],
      );
      expect(state.connectionTypeLabel, 'Ethernet');
    });

    test('connectionTypeLabel returns Autre for unknown types', () {
      const state = ConnectivityState(
        connectionTypes: [ConnectivityResult.bluetooth],
      );
      expect(state.connectionTypeLabel, 'Autre');
    });

    test('connectionTypeLabel prioritizes WiFi over mobile', () {
      const state = ConnectivityState(
        connectionTypes: [ConnectivityResult.mobile, ConnectivityResult.wifi],
      );
      expect(state.connectionTypeLabel, 'WiFi');
    });

    test('offlineDurationLabel returns empty when online', () {
      const state = ConnectivityState(status: ConnectivityStatus.online);
      expect(state.offlineDurationLabel, '');
    });

    test('offlineDurationLabel returns empty when no lastOnlineTime', () {
      const state = ConnectivityState(status: ConnectivityStatus.offline);
      expect(state.offlineDurationLabel, '');
    });

    test('offlineDurationLabel returns À l\'instant for recent', () {
      final state = ConnectivityState(
        status: ConnectivityStatus.offline,
        lastOnlineTime: DateTime.now(),
      );
      expect(state.offlineDurationLabel, 'À l\'instant');
    });

    test('offlineDurationLabel returns minutes format', () {
      final state = ConnectivityState(
        status: ConnectivityStatus.offline,
        lastOnlineTime: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(state.offlineDurationLabel, contains('10 min'));
    });

    test('offlineDurationLabel returns hours format', () {
      final state = ConnectivityState(
        status: ConnectivityStatus.offline,
        lastOnlineTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(state.offlineDurationLabel, contains('3h'));
    });

    test('offlineDurationLabel returns days format', () {
      final state = ConnectivityState(
        status: ConnectivityStatus.offline,
        lastOnlineTime: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(state.offlineDurationLabel, contains('2j'));
    });
  });

  group('ConnectivityService', () {
    test('starts with checking state and no pending sync', () {
      final service = ConnectivityService();
      addTearDown(service.dispose);

      expect(service.state.status, ConnectivityStatus.checking);
      expect(service.state.pendingSyncCount, 0);
      expect(service.state.isSyncing, isFalse);
    });

    test('updatePendingSyncCount updates the notifier state', () {
      final service = ConnectivityService();
      addTearDown(service.dispose);

      service.updatePendingSyncCount(7);

      expect(service.state.pendingSyncCount, 7);
      expect(service.state.status, ConnectivityStatus.checking);
    });

    test('setSyncing toggles syncing flag', () {
      final service = ConnectivityService();
      addTearDown(service.dispose);

      service.setSyncing(true);
      expect(service.state.isSyncing, isTrue);

      service.setSyncing(false);
      expect(service.state.isSyncing, isFalse);
    });

    test('checkConnectivity completes and leaves a valid state', () async {
      final service = ConnectivityService();
      addTearDown(service.dispose);

      await service.checkConnectivity();

      expect(
        service.state.status,
        anyOf(
          ConnectivityStatus.online,
          ConnectivityStatus.offline,
          ConnectivityStatus.checking,
        ),
      );
      expect(service.state.connectionTypes, isA<List<ConnectivityResult>>());
    });

    test('dispose makes later updates no-ops', () {
      final service = ConnectivityService();
      service.updatePendingSyncCount(2);

      service.dispose();

      expect(() => service.updatePendingSyncCount(9), returnsNormally);
      expect(() => service.setSyncing(true), returnsNormally);
    });
  });

  group('connectivity providers', () {
    test('derived providers follow notifier changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(connectivityProvider.notifier);

      expect(container.read(isConnectedProvider), isFalse);
      expect(container.read(isDisconnectedProvider), isFalse);
      expect(container.read(pendingSyncCountProvider), 0);

      service.updatePendingSyncCount(4);
      service.setSyncing(true);

      expect(container.read(connectivityProvider).pendingSyncCount, 4);
      expect(container.read(connectivityProvider).isSyncing, isTrue);
      expect(container.read(pendingSyncCountProvider), 4);
    });
  });
}
