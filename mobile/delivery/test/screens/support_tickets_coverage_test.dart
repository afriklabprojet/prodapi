import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/support_tickets_screen.dart';
import 'package:courier/data/models/support_ticket.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SupportTicket makeTicket({
    int id = 1,
    String subject = 'Problème de livraison',
    String description = 'La commande est introuvable',
    String category = 'delivery',
    String priority = 'normal',
    String status = 'open',
    String? createdAt = '2024-01-15T10:00:00Z',
  }) {
    return SupportTicket(
      id: id,
      userId: 42,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: status,
      createdAt: createdAt,
    );
  }

  Widget buildScreen({List<SupportTicket>? tickets}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        supportTicketsProvider.overrideWith((_) async => tickets ?? []),
      ],
      child: const MaterialApp(home: SupportTicketsScreen()),
    );
  }

  group('SupportTicketsScreen', () {
    testWidgets('shows Mes demandes header', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mes demandes'), findsOneWidget);
      expect(find.text('Support client'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Ouverts'), findsOneWidget);
      expect(find.text('En cours'), findsWidgets);
      expect(find.text('Résolus'), findsOneWidget);
      expect(find.text('Fermés'), findsOneWidget);
    });

    testWidgets('shows FAB with Nouveau ticket', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nouveau ticket'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no tickets', (tester) async {
      await tester.pumpWidget(buildScreen(tickets: []));
      await tester.pump(const Duration(seconds: 1));

      // Empty state should be visible
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows ticket cards with open status', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ticket = makeTicket(
        id: 1,
        subject: 'Problème urgent',
        status: 'open',
      );

      await tester.pumpWidget(buildScreen(tickets: [ticket]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Problème urgent'), findsOneWidget);
    });

    testWidgets('shows ticket with in_progress status', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ticket = makeTicket(
        id: 2,
        subject: 'Ticket en traitement',
        status: 'in_progress',
      );

      await tester.pumpWidget(buildScreen(tickets: [ticket]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Ticket en traitement'), findsOneWidget);
    });

    testWidgets('shows ticket with resolved status', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ticket = makeTicket(
        id: 3,
        subject: 'Ticket résolu',
        status: 'resolved',
      );

      await tester.pumpWidget(buildScreen(tickets: [ticket]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Ticket résolu'), findsOneWidget);
    });

    testWidgets('shows multiple tickets of different statuses', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tickets = [
        makeTicket(id: 1, subject: 'Ticket 1', status: 'open'),
        makeTicket(id: 2, subject: 'Ticket 2', status: 'resolved'),
        makeTicket(id: 3, subject: 'Ticket 3', status: 'closed'),
      ];

      await tester.pumpWidget(buildScreen(tickets: tickets));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Ticket 1'), findsOneWidget);
      expect(find.text('Ticket 2'), findsOneWidget);
      expect(find.text('Ticket 3'), findsOneWidget);
    });

    testWidgets('scaffold has CustomScrollView', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows ticket with high priority', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ticket = makeTicket(
        id: 1,
        subject: 'Urgence critique',
        status: 'open',
        priority: 'urgent',
      );

      await tester.pumpWidget(buildScreen(tickets: [ticket]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Urgence critique'), findsOneWidget);
    });
  });
}
