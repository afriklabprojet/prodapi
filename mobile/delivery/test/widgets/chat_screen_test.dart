import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/enhanced_chat_screen.dart';
import 'package:courier/core/services/enhanced_chat_service.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
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

  final testMessages = [
    EnhancedChatMessage(
      id: '1',
      content: 'Bonjour, je suis en route',
      senderId: 1,
      senderName: 'Livreur',
      senderRole: SenderRole.courier,
      type: MessageType.text,
      status: MessageStatus.sent,
      target: 'customer',
      createdAt: DateTime(2025, 2, 13, 10, 30),
    ),
    EnhancedChatMessage(
      id: '2',
      content: 'Ok merci, je vous attends',
      senderId: 2,
      senderName: 'Client',
      senderRole: SenderRole.customer,
      type: MessageType.text,
      status: MessageStatus.delivered,
      target: 'courier',
      createdAt: DateTime(2025, 2, 13, 10, 32),
    ),
    EnhancedChatMessage(
      id: '3',
      content: 'Je suis arrivé',
      senderId: 1,
      senderName: 'Livreur',
      senderRole: SenderRole.courier,
      type: MessageType.text,
      status: MessageStatus.sent,
      target: 'customer',
      createdAt: DateTime(2025, 2, 13, 10, 45),
    ),
  ];

  Widget buildScreen({
    List<EnhancedChatMessage>? messages,
    String target = 'customer',
    String targetName = 'John Doe',
  }) {
    final List<EnhancedChatMessage> msgs = messages ?? testMessages;
    return ProviderScope(
      overrides: commonWidgetTestOverrides(
        extra: [
          enhancedMessagesProvider.overrideWith(
            (ref, args) => Stream.value(msgs),
          ),
          enhancedChatServiceProvider.overrideWithValue(
            _FakeEnhancedChatService(),
          ),
          typingStatusProvider.overrideWith((ref, args) => Stream.value(null)),
          courierProfileProvider.overrideWith(
            (ref) => Future.value(
              const CourierProfile(
                id: 1,
                name: 'Test Courier',
                email: 'test@test.com',
                status: 'active',
                vehicleType: 'moto',
                plateNumber: 'AB-1234',
                rating: 4.5,
                completedDeliveries: 10,
                earnings: 50000,
                kycStatus: 'verified',
              ),
            ),
          ),
          activeConversationsProvider.overrideWith((ref) => Stream.value([])),
        ],
      ),
      child: MaterialApp(
        home: EnhancedChatScreen(
          orderId: 1,
          target: target,
          targetName: targetName,
        ),
      ),
    );
  }

  group('EnhancedChatScreen - App Bar', () {
    testWidgets('displays target name', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays pharmacy target name', (tester) async {
      await tester.pumpWidget(
        buildScreen(target: 'pharmacy', targetName: 'Pharmacie Centrale'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pharmacie Centrale'), findsOneWidget);
    });
  });

  group('EnhancedChatScreen - Messages', () {
    testWidgets('displays message content', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Bonjour, je suis en route'), findsOneWidget);
      expect(find.text('Ok merci, je vous attends'), findsOneWidget);
      expect(find.text('Je suis arrivé'), findsOneWidget);
    });

    testWidgets('displays empty state when no messages', (tester) async {
      await tester.pumpWidget(buildScreen(messages: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });

  group('EnhancedChatScreen - Input', () {
    testWidgets('displays message input area', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The chat screen uses a custom ChatInputBar with a TextField inside
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });
  });

  group('EnhancedChatScreen - Loading', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(
            extra: [
              enhancedMessagesProvider.overrideWith(
                (ref, args) => Stream.fromFuture(
                  Completer<List<EnhancedChatMessage>>().future,
                ),
              ),
              enhancedChatServiceProvider.overrideWithValue(
                _FakeEnhancedChatService(),
              ),
              typingStatusProvider.overrideWith(
                (ref, args) => Stream.value(null),
              ),
              courierProfileProvider.overrideWith(
                (ref) => Future.value(
                  const CourierProfile(
                    id: 1,
                    name: 'Test Courier',
                    email: 'test@test.com',
                    status: 'active',
                    vehicleType: 'moto',
                    plateNumber: 'AB-1234',
                    rating: 4.5,
                    completedDeliveries: 10,
                    earnings: 50000,
                    kycStatus: 'verified',
                  ),
                ),
              ),
              activeConversationsProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
            ],
          ),
          child: const MaterialApp(
            home: EnhancedChatScreen(
              orderId: 1,
              target: 'customer',
              targetName: 'Test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// Fake EnhancedChatService for testing without Firebase
class _FakeEnhancedChatService implements EnhancedChatService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return Future<void> for async methods to avoid null type errors
    if (invocation.memberName == #markMessagesAsRead ||
        invocation.memberName == #sendTextMessage ||
        invocation.memberName == #sendLocationMessage ||
        invocation.memberName == #startTyping ||
        invocation.memberName == #stopTyping ||
        invocation.memberName == #dispose) {
      return Future<void>.value();
    }
    return null;
  }
}
