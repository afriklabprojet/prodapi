import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/support_tickets_screen.dart';
import 'package:courier/data/models/support_ticket.dart';

// Helper to build test widget
Widget buildTestWidget({
  required List<SupportTicket> tickets,
}) {
  return ProviderScope(
    overrides: [
      supportTicketsProvider.overrideWith((ref) => Future.value(tickets)),
    ],
    child: const MaterialApp(
      home: SupportTicketsScreen(),
    ),
  );
}

SupportTicket _ticket({
  int id = 1,
  String subject = 'Test ticket',
  String status = 'open',
  String category = 'delivery',
  String priority = 'medium',
  String? reference,
  int? unreadCount,
}) {
  return SupportTicket(
    id: id,
    userId: 1,
    subject: subject,
    description: 'Test description',
    status: status,
    category: category,
    priority: priority,
    reference: reference ?? 'TK-$id',
    unreadCount: unreadCount,
    createdAt: '2024-01-01T10:00:00Z',
  );
}

void main() {
  group('SupportTicketsScreen', () {
    testWidgets('shows header title', (tester) async {
      await tester.pumpWidget(buildTestWidget(tickets: []));
      await tester.pumpAndSettle();
      expect(find.text('Mes demandes'), findsOneWidget);
      expect(find.text('Support client'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(tickets: []));
      await tester.pumpAndSettle();
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Ouverts'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('Résolus'), findsOneWidget);
      expect(find.text('Fermés'), findsOneWidget);
    });

    testWidgets('shows empty state when no tickets', (tester) async {
      await tester.pumpWidget(buildTestWidget(tickets: []));
      await tester.pumpAndSettle();
      expect(find.text('Aucune demande'), findsOneWidget);
      expect(find.text('Créer un ticket'), findsOneWidget);
    });

    testWidgets('shows FAB for new ticket', (tester) async {
      await tester.pumpWidget(buildTestWidget(tickets: []));
      await tester.pumpAndSettle();
      expect(find.text('Nouveau ticket'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows ticket cards when data available', (tester) async {
      final tickets = [
        _ticket(id: 1, subject: 'Bug paiement', status: 'open'),
        _ticket(id: 2, subject: 'Problème livraison', status: 'in_progress'),
      ];
      await tester.pumpWidget(buildTestWidget(tickets: tickets));
      await tester.pumpAndSettle();
      expect(find.text('Bug paiement'), findsOneWidget);
      expect(find.text('Problème livraison'), findsOneWidget);
    });

    testWidgets('shows ticket reference', (tester) async {
      final tickets = [_ticket(id: 1, reference: 'TK-001', subject: 'Test')];
      await tester.pumpWidget(buildTestWidget(tickets: tickets));
      await tester.pumpAndSettle();
      expect(find.text('TK-001'), findsOneWidget);
    });

    testWidgets('filter chips filter tickets', (tester) async {
      final tickets = [
        _ticket(id: 1, subject: 'Open ticket', status: 'open'),
        _ticket(id: 2, subject: 'Resolved ticket', status: 'resolved'),
      ];
      await tester.pumpWidget(buildTestWidget(tickets: tickets));
      await tester.pumpAndSettle();

      // Both visible initially
      expect(find.text('Open ticket'), findsOneWidget);
      expect(find.text('Resolved ticket'), findsOneWidget);

      // Tap "Ouverts" filter
      await tester.tap(find.text('Ouverts'));
      await tester.pumpAndSettle();
      expect(find.text('Open ticket'), findsOneWidget);
      expect(find.text('Resolved ticket'), findsNothing);

      // Tap "Résolus" filter
      await tester.tap(find.text('Résolus'));
      await tester.pumpAndSettle();
      expect(find.text('Open ticket'), findsNothing);
      expect(find.text('Resolved ticket'), findsOneWidget);
    });

    testWidgets('shows empty filter state', (tester) async {
      final tickets = [
        _ticket(id: 1, subject: 'Open ticket', status: 'open'),
      ];
      await tester.pumpWidget(buildTestWidget(tickets: tickets));
      await tester.pumpAndSettle();

      // Filter by resolved - should show empty state
      await tester.tap(find.text('Résolus'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucun ticket'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unread count badge', (tester) async {
      final tickets = [_ticket(id: 1, subject: 'Unread', unreadCount: 3)];
      await tester.pumpWidget(buildTestWidget(tickets: tickets));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      late Future<List<SupportTicket>> completer;
      completer = Future(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return <SupportTicket>[];
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportTicketsProvider.overrideWith((ref) => completer),
          ],
          child: const MaterialApp(home: SupportTicketsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
    });

    testWidgets('back button navigates back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportTicketsProvider.overrideWith((ref) => Future.value(<SupportTicket>[])),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Mes demandes'), findsOneWidget);
    });
  });
}
