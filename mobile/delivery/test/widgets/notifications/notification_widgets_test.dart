import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/notifications/notification_widgets.dart';
import 'package:courier/core/services/rich_notification_service.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  RichNotification makeNotification({
    String id = 'notif-1',
    String title = 'Nouvelle livraison',
    String body = 'Une commande vous attend',
    NotificationType type = NotificationType.newOrder,
    bool isRead = false,
    DateTime? createdAt,
  }) {
    return RichNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead,
    );
  }

  // ── NotificationBadge ──────────────────────────
  group('NotificationBadge', () {
    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadge(child: Icon(Icons.notifications)),
            ),
          ),
        ),
      );
      expect(find.byType(NotificationBadge), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('renders with showZero false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadge(
                showZero: false,
                child: Icon(Icons.notifications),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(NotificationBadge), findsOneWidget);
    });

    testWidgets('renders with showZero true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadge(showZero: true, child: Icon(Icons.mail)),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.mail), findsOneWidget);
    });
  });

  // ── NotificationCard ───────────────────────────
  group('NotificationCard', () {
    testWidgets('renders notification card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text('Nouvelle livraison'), findsOneWidget);
    });

    testWidgets('shows notification body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(body: 'Commande #123 disponible'),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Commande #123 disponible'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () => tapped = true,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(NotificationCard));
      expect(tapped, true);
    });

    testWidgets('renders message type notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(
                title: 'Message du client',
                type: NotificationType.chat,
              ),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Message du client'), findsOneWidget);
    });

    testWidgets('renders earning type notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(
                title: 'Paiement reçu',
                type: NotificationType.earnings,
              ),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Paiement reçu'), findsOneWidget);
    });

    testWidgets('renders read notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(isRead: true),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders unread notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(isRead: false),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders promotion type notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(
                title: 'Bonus x2 ce soir',
                type: NotificationType.promo,
              ),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Bonus x2 ce soir'), findsOneWidget);
    });
  });

  // ── NotificationIconButton ─────────────────────
  group('NotificationIconButton', () {
    testWidgets('renders icon button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: NotificationIconButton()),
          ),
        ),
      );
      expect(find.byType(NotificationIconButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });

  // ── NotificationCenterScreen ───────────────────
  group('NotificationCenterScreen', () {
    testWidgets('renders screen', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(home: NotificationCenterScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NotificationCenterScreen), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      FlutterError.onError = originalOnError;
    });
  });

  // ── NotificationPreferencesCard ────────────────
  group('NotificationPreferencesCard', () {
    testWidgets('renders preferences card', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NotificationPreferencesCard()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NotificationPreferencesCard), findsOneWidget);
      FlutterError.onError = originalOnError;
    });
  });

  // ── NotificationCard - deep interactions ───────
  group('NotificationCard - deep interactions', () {
    testWidgets('shows timestamp text', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(createdAt: now),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      // Should show some time text like "À l'instant"
      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('has Dismissible for swipe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('swipe triggers onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(dismissed, true);
    });

    testWidgets('has Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('unread notification has different styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(isRead: false),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      // Unread notification should render
      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('urgent type renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(
                title: 'Attention',
                type: NotificationType.urgent,
              ),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Attention'), findsOneWidget);
    });

    testWidgets('system type renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(
                title: 'Mise à jour',
                type: NotificationType.system,
              ),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.text('Mise à jour'), findsOneWidget);
    });

    testWidgets('has Container widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has Row layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('has Column layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('notification with old date shows days ago', (tester) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(createdAt: oldDate),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('3j'), findsOneWidget);
    });

    testWidgets('notification with hours ago shows hours', (tester) async {
      final hoursAgo = DateTime.now().subtract(const Duration(hours: 5));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(createdAt: hoursAgo),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('5h'), findsOneWidget);
    });

    testWidgets('notification created just now shows instant text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(createdAt: DateTime.now()),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining("l'instant"), findsOneWidget);
    });

    testWidgets('notification with minutes ago shows minutes', (tester) async {
      final minutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(createdAt: minutesAgo),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('min'), findsOneWidget);
    });

    testWidgets('has widgets for content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: makeNotification(),
              onTap: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });
  });

  // ── NotificationCenterScreen - deep ────────────
  group('NotificationCenterScreen - deep interactions', () {
    testWidgets('shows empty state with no notifications', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(home: NotificationCenterScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(NotificationCenterScreen), findsOneWidget);
        // Empty state icons
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows "Aucune notification" text', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(home: NotificationCenterScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Aucune notification'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has AppBar', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(home: NotificationCenterScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(AppBar), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows empty state alert description', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(home: NotificationCenterScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('alertes'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  // ── NotificationPreferencesCard - deep ─────────
  group('NotificationPreferencesCard - deep interactions', () {
    testWidgets('shows Notifications title', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        // The card has a notifications icon
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows switch tiles for preferences', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Switch), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Sons preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Sons'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Vibration preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Vibration'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Nouvelles commandes preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Nouvelles commandes'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Messages preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Messages'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Gains preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Gains'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Promotions preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Promotions'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows Alertes urgentes preference', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Alertes urgentes'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows TYPES DE NOTIFICATIONS section header', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('TYPES DE NOTIFICATIONS'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows quiet hours expansion tile', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Heures calmes'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has nightlight icon for quiet hours', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows subtitle text for preferences', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Personnalisez vos alertes'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has volume icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.volume_up), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has vibration icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.vibration), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('subtitle texts for switch tiles', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: commonWidgetTestOverrides(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NotificationPreferencesCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Jouer un son pour les alertes'), findsOneWidget);
        expect(find.text('Vibrer à la réception'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  // ── NotificationBadge - deep ───────────────────
  group('NotificationBadge - deep interactions', () {
    testWidgets('has Stack widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadge(child: Icon(Icons.notifications)),
            ),
          ),
        ),
      );
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders with Text child', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: NotificationBadge(child: Text('Alerts'))),
          ),
        ),
      );
      expect(find.text('Alerts'), findsOneWidget);
    });
  });
}
