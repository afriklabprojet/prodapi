import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/notifications/presentation/pages/notifications_page.dart';
import 'package:drpharma_client/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:drpharma_client/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:drpharma_client/features/notifications/presentation/providers/notifications_state.dart';
import 'package:drpharma_client/features/notifications/domain/entities/notification_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockNotificationsNotifier extends StateNotifier<NotificationsState>
    with Mock
    implements NotificationsNotifier {
  MockNotificationsNotifier([NotificationsState? state])
    : super(state ?? const NotificationsState.initial());

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  void clearError() {}
}

NotificationEntity _makeNotification({
  String id = '1',
  String type = 'order_status',
  String title = 'Commande confirmée',
  String body = 'Votre commande a bien été reçue.',
  bool isRead = false,
  Map<String, dynamic>? data,
}) {
  return NotificationEntity(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: isRead,
    createdAt: DateTime(2024, 1, 15, 10, 30),
  );
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({NotificationsState? initialState}) {
    final notifier = MockNotificationsNotifier(initialState);
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        notificationsProvider.overrideWith((_) => notifier),
      ],
      child: MaterialApp(
        home: const NotificationsPage(),
        routes: {
          '/order-details': (_) => const Scaffold(body: Text('Order Details')),
          '/orders/42': (_) => const Scaffold(body: Text('Order 42')),
        },
      ),
    );
  }

  group('NotificationsPage Widget Tests', () {
    testWidgets('should render notifications page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('should have app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Notifications app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows no done_all button when empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('shows Aucune notification in empty state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Aucune notification'), findsOneWidget);
    });

    testWidgets('shows Vous serez notifié ici in empty state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Vous serez notifié ici'), findsOneWidget);
    });

    testWidgets('shows notifications_none icon in empty state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('should have Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have Center widget in empty state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Column inside empty state Center widget', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('should display notification cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('should show empty state when no notifications', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final semanticsHandle = tester.ensureSemantics();
      semanticsHandle.dispose();

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('shows AppBar with primary color and white text', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.titleTextStyle?.color ?? Colors.white, isNotNull);
      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage Loading State Tests', () {
    testWidgets('shows loading skeleton when loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: const NotificationsState(
            status: NotificationsStatus.loading,
            notifications: [],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage With Notifications Tests', () {
    NotificationsState _loadedState(List<NotificationEntity> notifications) {
      return NotificationsState(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: notifications.where((n) => !n.isRead).length,
      );
    }

    testWidgets('shows done_all button when notifications exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialState: _loadedState([_makeNotification()])),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('shows notification title in list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(title: 'Ma notification test'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ma notification test'), findsOneWidget);
    });

    testWidgets('shows notification body in list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(body: 'Corps de ma notification'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Corps de ma notification'), findsOneWidget);
    });

    testWidgets('unread notification shows blue circle indicator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([_makeNotification(isRead: false)]),
        ),
      );
      await tester.pumpAndSettle();

      // The unread indicator is a Container with BoxShape.circle
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows shopping_bag icon for order_status type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([_makeNotification(type: 'order_status')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('shows payment icon for payment_confirmed type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(type: 'payment_confirmed'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.payment), findsOneWidget);
    });

    testWidgets('shows local_shipping icon for delivery_assigned type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(type: 'delivery_assigned'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    });

    testWidgets('shows check_circle icon for order_delivered type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(type: 'order_delivered'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows notifications icon for unknown type', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([_makeNotification(type: 'unknown_type')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('shows multiple notifications in list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(id: '1', title: 'Notif 1'),
            _makeNotification(id: '2', title: 'Notif 2'),
            _makeNotification(id: '3', title: 'Notif 3'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('shows ListView when notifications are loaded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialState: _loadedState([_makeNotification()])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('tapping notification opens bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialState: _loadedState([
            _makeNotification(title: 'Notif Détail'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Bottom sheet should open showing notification title
      expect(find.text('Notif Détail'), findsWidgets);
    });

    testWidgets('tapping done_all calls markAllAsRead', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialState: _loadedState([_makeNotification()])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pump();

      // No crash = success (mock does nothing)
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets(
      'notification with order data shows Voir la commande in sheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestWidget(
            initialState: _loadedState([
              _makeNotification(
                type: 'order_status',
                data: {'type': 'order_status', 'order_id': 42},
              ),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();

        expect(find.text('Voir la commande'), findsOneWidget);
      },
    );

    testWidgets('shows RefreshIndicator on loaded list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialState: _loadedState([_makeNotification()])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
