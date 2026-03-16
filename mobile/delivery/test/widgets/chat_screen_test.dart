import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/chat_screen.dart';
import 'package:courier/presentation/providers/chat_provider.dart';
import 'package:courier/core/services/realtime_chat_service.dart';
import 'package:courier/data/models/chat_message.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testMessages = [
    ChatMessage(
      id: 1,
      content: 'Bonjour, je suis en route',
      isMe: true,
      senderName: 'Livreur',
      createdAt: DateTime(2025, 2, 13, 10, 30),
    ),
    ChatMessage(
      id: 2,
      content: 'Ok merci, je vous attends',
      isMe: false,
      senderName: 'Client',
      createdAt: DateTime(2025, 2, 13, 10, 32),
    ),
    ChatMessage(
      id: 3,
      content: 'Je suis arrivé',
      isMe: true,
      senderName: 'Livreur',
      createdAt: DateTime(2025, 2, 13, 10, 45),
    ),
  ];

  Widget buildScreen({
    List<ChatMessage>? messages,
    String target = 'customer',
    String title = 'John Doe',
  }) {
    final msgs = messages ?? testMessages;
    return ProviderScope(
      overrides: [
        chatMessagesProvider.overrideWith(
          (ref, args) => Future.value(msgs),
        ),
        // Override realtime providers (ChatScreen defaults to realtime mode)
        realtimeMessagesProvider.overrideWith(
          (ref, args) => Stream.value(msgs),
        ),
        realtimeChatServiceProvider.overrideWithValue(_FakeRealtimeChatService()),
      ],
      child: MaterialApp(
        home: ChatScreen(
          orderId: 1,
          target: target,
          title: title,
        ),
      ),
    );
  }

  group('ChatScreen - App Bar', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays Client subtitle for customer target', (tester) async {
      await tester.pumpWidget(buildScreen(target: 'customer'));
      await tester.pumpAndSettle();

      expect(find.text('Client'), findsOneWidget);
    });

    testWidgets('displays Pharmacie subtitle for pharmacy target', (tester) async {
      await tester.pumpWidget(buildScreen(target: 'pharmacy'));
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie'), findsOneWidget);
    });
  });

  group('ChatScreen - Messages', () {
    testWidgets('displays message content', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Bonjour, je suis en route'), findsOneWidget);
      expect(find.text('Ok merci, je vous attends'), findsOneWidget);
      expect(find.text('Je suis arrivé'), findsOneWidget);
    });

    testWidgets('displays message timestamps', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('10:32'), findsOneWidget);
      expect(find.text('10:45'), findsOneWidget);
    });

    testWidgets('displays empty state when no messages', (tester) async {
      await tester.pumpWidget(buildScreen(messages: []));
      await tester.pumpAndSettle();

      expect(find.text('Aucun message'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });

  group('ChatScreen - Input', () {
    testWidgets('displays message input field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Votre message...'), findsOneWidget);
    });

    testWidgets('displays send button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('can type in message field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test message');
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('displays FAB for send', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('ChatScreen - Loading', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith(
              (ref, args) => Completer<List<ChatMessage>>().future,
            ),
            realtimeMessagesProvider.overrideWith(
              (ref, args) => Stream.fromFuture(Completer<List<ChatMessage>>().future),
            ),
            realtimeChatServiceProvider.overrideWithValue(_FakeRealtimeChatService()),
          ],
          child: const MaterialApp(
            home: ChatScreen(orderId: 1, target: 'customer', title: 'Test'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// Fake RealtimeChatService that doesn't require Firebase
class _FakeRealtimeChatService implements RealtimeChatService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
