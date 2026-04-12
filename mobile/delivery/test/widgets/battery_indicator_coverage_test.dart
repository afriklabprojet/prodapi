import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:courier/core/services/battery_saver_service.dart';
import 'package:courier/core/services/biometric_service.dart';
import 'package:courier/core/services/connectivity_service.dart';
import 'package:courier/core/services/enhanced_chat_service.dart';
import 'package:courier/core/services/rich_notification_service.dart';
import 'package:courier/core/services/sync_manager.dart';
import 'package:courier/core/services/theme_service.dart';
import 'package:courier/presentation/widgets/battery/battery_indicator_widget.dart';
import '../helpers/widget_test_helpers.dart';

// Override helpers - batteryStateProvider is already in commonWidgetTestOverrides,
// so we build overrides WITHOUT the common battery override, just theme + our battery
List<Override> _batteryOverrides(BatteryStatus status) {
  return [
    isDarkModeProvider.overrideWithValue(false),
    textScaleProvider.overrideWithValue(1.0),
    reducedMotionProvider.overrideWithValue(false),
    unreadNotificationCountProvider.overrideWithValue(0),
    richNotificationProvider.overrideWith(
      (ref) => FakeRichNotificationService(),
    ),
    notificationPreferencesProvider.overrideWithValue(
      const NotificationPreferences(),
    ),
    batteryStateProvider.overrideWith((ref) => Stream.value(status)),
    totalUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
    connectivityProvider.overrideWith((ref) => FakeConnectivityService()),
    syncManagerProvider.overrideWith((ref) => FakeSyncManager(ref)),
    biometricServiceProvider.overrideWithValue(FakeBiometricService()),
  ];
}

List<Override> _batteryErrorOverrides() {
  return [
    isDarkModeProvider.overrideWithValue(false),
    textScaleProvider.overrideWithValue(1.0),
    reducedMotionProvider.overrideWithValue(false),
    unreadNotificationCountProvider.overrideWithValue(0),
    richNotificationProvider.overrideWith(
      (ref) => FakeRichNotificationService(),
    ),
    notificationPreferencesProvider.overrideWithValue(
      const NotificationPreferences(),
    ),
    batteryStateProvider.overrideWith(
      (ref) => Stream<BatteryStatus>.error('Battery unavailable'),
    ),
    totalUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
    connectivityProvider.overrideWith((ref) => FakeConnectivityService()),
    syncManagerProvider.overrideWith((ref) => FakeSyncManager(ref)),
    biometricServiceProvider.overrideWithValue(FakeBiometricService()),
  ];
}

List<Override> _batteryLoadingOverrides() {
  return [
    isDarkModeProvider.overrideWithValue(false),
    textScaleProvider.overrideWithValue(1.0),
    reducedMotionProvider.overrideWithValue(false),
    unreadNotificationCountProvider.overrideWithValue(0),
    richNotificationProvider.overrideWith(
      (ref) => FakeRichNotificationService(),
    ),
    notificationPreferencesProvider.overrideWithValue(
      const NotificationPreferences(),
    ),
    batteryStateProvider.overrideWith(
      (ref) => const Stream<BatteryStatus>.empty(),
    ),
    totalUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
    connectivityProvider.overrideWith((ref) => FakeConnectivityService()),
    syncManagerProvider.overrideWith((ref) => FakeSyncManager(ref)),
    biometricServiceProvider.overrideWithValue(FakeBiometricService()),
  ];
}

BatteryStatus _status({
  int level = 80,
  BatterySaverMode mode = BatterySaverMode.normal,
  bool isCharging = false,
}) {
  return BatteryStatus(
    level: level,
    mode: mode,
    isCharging: isCharging,
    lastUpdated: DateTime.now(),
  );
}

void main() {
  group('BatteryIndicatorWidget - compact=true (default)', () {
    testWidgets('shows loading spinner when async is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryLoadingOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error icon when async errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryErrorOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.battery_unknown), findsOneWidget);
    });

    testWidgets('compact shows battery level % for normal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(_status(level: 80)),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
      expect(find.byIcon(Icons.battery_full), findsOneWidget);
    });

    testWidgets('compact shows alert icon for low level', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(_status(level: 15)),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15%'), findsOneWidget);
      expect(find.byIcon(Icons.battery_alert), findsOneWidget);
    });

    testWidgets('compact shows charging icon when charging', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(_status(level: 60, isCharging: true)),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.battery_charging_full), findsOneWidget);
    });

    testWidgets('compact shows eco icon for saver mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(
            _status(level: 15, mode: BatterySaverMode.saver),
          ),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('compact shows eco icon for critical mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(
            _status(level: 8, mode: BatterySaverMode.critical),
          ),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('compact shows 3-bar icon for medium level', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(_status(level: 40)),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.battery_3_bar), findsOneWidget);
    });
  });

  group('BatteryIndicatorWidget - compact=false (card)', () {
    testWidgets('shows _LoadingCard when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryLoadingOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('shows _ErrorCard when error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryErrorOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Batterie indisponible'), findsOneWidget);
    });

    testWidgets('shows battery card with level text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(_status(level: 75)),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('GPS précis'), findsOneWidget);
    });

    testWidgets('shows En charge badge when charging', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(
            _status(
              level: 90,
              isCharging: true,
              mode: BatterySaverMode.charging,
            ),
          ),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('charge'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows critical economy message in card mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(
            _status(level: 8, mode: BatterySaverMode.critical),
          ),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Mode économie critique'), findsOneWidget);
    });

    testWidgets('shows saver economy message in card mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _batteryOverrides(
            _status(level: 15, mode: BatterySaverMode.saver),
          ),
          child: const MaterialApp(
            home: Scaffold(body: BatteryIndicatorWidget(compact: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('GPS basse fréquence'), findsOneWidget);
    });
  });
}
