import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/support_ticket_chat_screen.dart';
import 'package:courier/data/models/support_ticket.dart';
import 'package:courier/data/repositories/support_repository.dart';

class MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late MockSupportRepository mockSupportRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSupportRepo = MockSupportRepository();
  });

  final testMessages = [
    const SupportMessage(
      id: 1,
      supportTicketId: 1,
      userId: 99,
      message: 'Bonjour, j\'ai un problème avec ma livraison',
      isFromSupport: false,
      createdAt: '2025-02-13T10:00:00Z',
    ),
    const SupportMessage(
      id: 2,
      supportTicketId: 1,
      userId: 1,
      message: 'Bonjour, pouvez-vous préciser le numéro de commande ?',
      isFromSupport: true,
      createdAt: '2025-02-13T10:05:00Z',
    ),
    const SupportMessage(
      id: 3,
      supportTicketId: 1,
      userId: 99,
      message: 'C\'est la commande #456',
      isFromSupport: false,
      createdAt: '2025-02-13T10:10:00Z',
    ),
  ];

  final testTicket = SupportTicket(
    id: 1,
    userId: 99,
    subject: 'Problème de livraison',
    description: 'Ma livraison est en retard',
    category: 'delivery',
    priority: 'medium',
    status: 'open',
    reference: '#TK-001',
    messages: testMessages,
  );

  final closedTicket = SupportTicket(
    id: 2,
    userId: 99,
    subject: 'Ticket fermé',
    description: 'Ancien problème',
    category: 'payment',
    priority: 'low',
    status: 'closed',
    reference: '#TK-002',
    messages: testMessages,
  );

  final resolvedTicket = SupportTicket(
    id: 3,
    userId: 99,
    subject: 'Ticket résolu',
    description: 'Problème résolu',
    category: 'account',
    priority: 'high',
    status: 'resolved',
    reference: '#TK-003',
    messages: [],
  );

  final emptyMessagesTicket = SupportTicket(
    id: 4,
    userId: 99,
    subject: 'Nouveau ticket',
    description: 'Description',
    category: 'order',
    priority: 'medium',
    status: 'open',
    reference: '#TK-004',
    messages: [],
  );

  Widget buildScreen({SupportTicket? ticket, int ticketId = 1, bool withMockRepo = false}) {
    final t = ticket ?? testTicket;
    return ProviderScope(
      overrides: [
        ticketDetailsProvider.overrideWith(
          (ref, id) => Future.value(t),
        ),
        if (withMockRepo)
          supportRepositoryProvider.overrideWithValue(mockSupportRepo),
      ],
      child: MaterialApp(
        home: SupportTicketChatScreen(ticketId: ticketId),
      ),
    );
  }

  group('SupportTicketChatScreen', () {
    testWidgets('displays ticket reference in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('#TK-001'), findsOneWidget);
    });

    testWidgets('displays status label in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open status shows "🟠 Ouvert"
      expect(find.textContaining('Ouvert'), findsOneWidget);
    });

    testWidgets('displays ticket subject in info header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Problème de livraison'), findsOneWidget);
    });

    testWidgets('displays category chip', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Category 'delivery' => label 'Livraison'
      expect(find.text('Livraison'), findsOneWidget);
    });

    testWidgets('displays priority chip', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Priority 'medium' => label 'Moyenne'
      expect(find.text('Moyenne'), findsOneWidget);
    });

    testWidgets('displays message bubbles', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // User messages
      expect(find.text('Bonjour, j\'ai un problème avec ma livraison'), findsOneWidget);
      expect(find.text('C\'est la commande #456'), findsOneWidget);

      // Support message
      expect(find.text('Bonjour, pouvez-vous préciser le numéro de commande ?'), findsOneWidget);
    });

    testWidgets('displays Support DR-PHARMA label on support messages', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Support DR-PHARMA'), findsOneWidget);
    });

    testWidgets('displays support agent avatar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('displays message input field for open ticket', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Écrivez votre message...'), findsOneWidget);
    });

    testWidgets('displays send icon button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('displays popup menu button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('popup menu shows resolve and close for open ticket', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marquer résolu'), findsOneWidget);
      expect(find.text('Fermer le ticket'), findsOneWidget);
    });

    testWidgets('hides message input for closed ticket', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: closedTicket, ticketId: 2));
      await tester.pumpAndSettle();

      // No TextField for closed ticket
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('displays closed status label', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: closedTicket, ticketId: 2));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fermé'), findsOneWidget);
    });

    testWidgets('displays empty state when no messages', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: emptyMessagesTicket, ticketId: 4));
      await tester.pumpAndSettle();

      expect(find.text('Aucun message'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ticketDetailsProvider.overrideWith(
              (ref, id) => Completer<SupportTicket>().future,
            ),
          ],
          child: const MaterialApp(
            home: SupportTicketChatScreen(ticketId: 1),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('resolved ticket shows only close option in menu', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(buildScreen(ticket: resolvedTicket, ticketId: 3));
      await tester.pumpAndSettle();

      // Tap menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Resolved ticket should not show "Marquer résolu" but should show "Fermer le ticket"
      expect(find.text('Marquer résolu'), findsNothing);
      expect(find.text('Fermer le ticket'), findsOneWidget);
    });

    testWidgets('displays resolved status label', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: resolvedTicket, ticketId: 3));
      await tester.pumpAndSettle();

      expect(find.textContaining('Résolu'), findsOneWidget);
    });

    testWidgets('displays user avatar for user messages', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsAtLeastNWidgets(1));
    });

    testWidgets('displays high priority chip color', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: resolvedTicket, ticketId: 3));
      await tester.pumpAndSettle();

      // 'high' priority => label 'Haute'
      expect(find.text('Haute'), findsOneWidget);
    });

    testWidgets('displays account category chip', (tester) async {
      await tester.pumpWidget(buildScreen(ticket: resolvedTicket, ticketId: 3));
      await tester.pumpAndSettle();

      // 'account' category => label 'Compte'
      expect(find.text('Compte'), findsOneWidget);
    });

    testWidgets('send message clears input field on success', (tester) async {
      when(() => mockSupportRepo.sendMessage(any(), any()))
          .thenAnswer((_) async => const SupportMessage(
                id: 10,
                supportTicketId: 1,
                userId: 99,
                message: 'test',
                isFromSupport: false,
                createdAt: '2025-02-13T12:00:00Z',
              ));

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      // Type a message
      await tester.enterText(find.byType(TextField), 'Mon nouveau message');
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Input should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('send message shows error snackbar on failure', (tester) async {
      when(() => mockSupportRepo.sendMessage(any(), any()))
          .thenThrow(Exception('Erreur réseau'));

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });

    testWidgets('resolve action shows success snackbar', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      when(() => mockSupportRepo.resolveTicket(any()))
          .thenAnswer((_) async => testTicket.copyWith(status: 'resolved'));

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap resolve
      await tester.tap(find.text('Marquer résolu'));
      await tester.pumpAndSettle();

      expect(find.text('Ticket marqué comme résolu'), findsOneWidget);
    });

    testWidgets('close action shows confirmation dialog', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fermer le ticket'));
      await tester.pumpAndSettle();

      expect(find.text('Fermer le ticket ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('close confirmation cancelled does not close ticket', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fermer le ticket'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog should be gone
      expect(find.text('Fermer le ticket ?'), findsNothing);
      verifyNever(() => mockSupportRepo.closeTicket(any()));
    });

    testWidgets('close confirmation accepted closes ticket', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      when(() => mockSupportRepo.closeTicket(any()))
          .thenAnswer((_) async => testTicket.copyWith(status: 'closed'));

      await tester.pumpWidget(buildScreen(withMockRepo: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fermer le ticket'));
      await tester.pumpAndSettle();

      // Confirm close
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();

      expect(find.text('Ticket fermé'), findsOneWidget);
      verify(() => mockSupportRepo.closeTicket(1)).called(1);
    });
  });
}
