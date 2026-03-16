import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:state_notifier/state_notifier.dart';

import 'package:courier/core/services/battery_saver_service.dart';
import 'package:courier/core/services/rich_notification_service.dart';
import 'package:courier/core/services/enhanced_chat_service.dart';
import 'package:courier/core/services/connectivity_service.dart';
import 'package:courier/core/services/sync_manager.dart';
import 'package:courier/core/services/biometric_service.dart';
import 'package:courier/core/services/theme_service.dart';

/// Directory for Hive in tests
Directory? _hiveTestDir;

/// Initialize Hive for tests (call in setUpAll)
Future<void> initHiveForTests() async {
  _hiveTestDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(_hiveTestDir!.path);
}

/// Cleanup Hive after tests (call in tearDownAll)
Future<void> cleanupHiveForTests() async {
  try {
    await Hive.close();
  } catch (_) {}
  if (_hiveTestDir != null && _hiveTestDir!.existsSync()) {
    _hiveTestDir!.deleteSync(recursive: true);
  }
}

/// Common provider overrides for widget tests that need to avoid
/// platform channel calls (Hive, Notifications, Firebase, Battery, etc.)
///
/// Usage:
/// ```dart
/// ProviderScope(
///   overrides: commonWidgetTestOverrides(),
///   child: const MaterialApp(home: MyScreen()),
/// )
/// ```
List<Override> commonWidgetTestOverrides({
  List<Override> extra = const [],
}) {
  return [
    // Avoid Hive initialization in ThemeService
    isDarkModeProvider.overrideWithValue(false),
    textScaleProvider.overrideWithValue(1.0),
    reducedMotionProvider.overrideWithValue(false),

    // Avoid FlutterLocalNotifications platform channel
    unreadNotificationCountProvider.overrideWithValue(0),

    // Avoid RichNotificationService (uses FlutterLocalNotificationsPlugin)
    richNotificationProvider.overrideWith((ref) {
      return FakeRichNotificationService();
    }),

    // Override dependent notification providers
    notificationPreferencesProvider.overrideWithValue(
      const NotificationPreferences(),
    ),

    // Avoid Battery platform channel
    batteryStateProvider.overrideWith((ref) => Stream.value(
      BatteryStatus(
        level: 80,
        mode: BatterySaverMode.normal,
        isCharging: false,
        lastUpdated: DateTime.now(),
      ),
    )),

    // Avoid Firebase Firestore - enhanced chat
    totalUnreadCountProvider.overrideWith((ref) => Stream.value(0)),

    // Avoid Connectivity platform channel
    connectivityProvider.overrideWith((ref) {
      return FakeConnectivityService();
    }),

    // Avoid SyncManager (depends on connectivity)
    syncManagerProvider.overrideWith((ref) {
      return FakeSyncManager(ref);
    }),

    // Avoid biometric platform channel
    biometricServiceProvider.overrideWithValue(FakeBiometricService()),

    ...extra,
  ];
}

// ── Fake services (public for reuse) ─────────────────

class FakeConnectivityService extends StateNotifier<ConnectivityState>
    implements ConnectivityService {
  FakeConnectivityService()
      : super(const ConnectivityState(status: ConnectivityStatus.online));

  @override
  Future<void> checkConnectivity() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeSyncManager extends StateNotifier<SyncState> implements SyncManager {
  FakeSyncManager(dynamic ref) : super(const SyncState());

  @override
  Future<void> forceSync() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeBiometricService implements BiometricService {
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({String? reason}) async => false;

  @override
  Future<bool> canCheckBiometrics() async => false;

  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<bool> hasBiometrics() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeRichNotificationService extends StateNotifier<List<RichNotification>>
    implements RichNotificationService {
  FakeRichNotificationService() : super([]);

  @override
  NotificationPreferences get preferences => const NotificationPreferences();

  @override
  Stream<NotificationActionEvent> get actionStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
