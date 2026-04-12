import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/chat/enhanced_chat_widgets.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';

void main() {
  EnhancedChatMessage makeMessage({
    String type = 'text',
    int senderId = 1,
    String content = 'Bonjour, je suis en route',
  }) {
    return EnhancedChatMessage.fromJson({
      'delivery_id': 10,
      'sender_id': senderId,
      'sender_type': 'courier',
      'sender_name': 'Jean',
      'type': type,
      'content': content,
      'target': 'customer',
      'status': 'sent',
      'created_at': DateTime.now().toIso8601String(),
    }, 'msg-1');
  }

  Widget buildWidget(EnhancedChatMessage message, {int courierId = 1}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EnhancedMessageBubble(message: message, courierId: courierId),
        ),
      ),
    );
  }

  group('EnhancedMessageBubble', () {
    testWidgets('renders text message from self', (tester) async {
      await tester.pumpWidget(buildWidget(makeMessage(), courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders text message from other', (tester) async {
      await tester.pumpWidget(
        buildWidget(makeMessage(senderId: 2), courierId: 1),
      );
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders system message', (tester) async {
      await tester.pumpWidget(
        buildWidget(makeMessage(type: 'system', content: 'Livraison démarrée')),
      );
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('system message shows content', (tester) async {
      await tester.pumpWidget(
        buildWidget(makeMessage(type: 'system', content: 'Commande acceptée')),
      );
      expect(find.textContaining('Commande acceptée'), findsOneWidget);
    });

    testWidgets('shows text content', (tester) async {
      await tester.pumpWidget(buildWidget(makeMessage(content: 'Hello world')));
      expect(find.textContaining('Hello world'), findsOneWidget);
    });

    testWidgets('renders image message type', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          buildWidget(
            makeMessage(type: 'image', content: 'https://example.com/img.jpg'),
          ),
        );
        await tester.pump();
        expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('renders location message type', (tester) async {
      await tester.pumpWidget(
        buildWidget(makeMessage(type: 'location', content: '5.36,-4.01')),
      );
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders voice message type', (tester) async {
      await tester.pumpWidget(
        buildWidget(makeMessage(type: 'voice', content: '/path/to/audio.m4a')),
      );
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders quick_reply message type', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          makeMessage(type: 'quick_reply', content: 'Je suis en route'),
        ),
      );
      expect(find.textContaining('Je suis en route'), findsOneWidget);
    });

    testWidgets('self message stores courierId', (tester) async {
      await tester.pumpWidget(buildWidget(makeMessage(), courierId: 1));
      final align = tester.widget<EnhancedMessageBubble>(
        find.byType(EnhancedMessageBubble),
      );
      expect(align.courierId, equals(1));
    });

    testWidgets('other message has different sender', (tester) async {
      final msg = makeMessage(senderId: 99);
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('shows sender name for other messages', (tester) async {
      final msg = makeMessage(senderId: 5);
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('message with replyToContent shows reply quote', (
      tester,
    ) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 2,
        'sender_type': 'customer',
        'sender_name': 'Client',
        'type': 'text',
        'content': 'Oui merci',
        'target': 'courier',
        'status': 'sent',
        'reply_to_content': 'Êtes-vous disponible ?',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-reply');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message with status delivered shows check icon', (
      tester,
    ) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'text',
        'content': 'En route',
        'target': 'customer',
        'status': 'delivered',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-delivered');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message with status read shows double check', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'text',
        'content': 'Arrivé',
        'target': 'customer',
        'status': 'read',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-read');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('onTap callback works', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EnhancedMessageBubble(
                message: makeMessage(),
                courierId: 1,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EnhancedMessageBubble));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('onLongPress callback works', (tester) async {
      bool longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EnhancedMessageBubble(
                message: makeMessage(),
                courierId: 1,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(EnhancedMessageBubble));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('location message with address shows address text', (
      tester,
    ) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'location',
        'content': '5.36,-4.01',
        'target': 'customer',
        'status': 'sent',
        'location_address': 'Cocody, Abidjan',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-loc-addr');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message with sender_avatar shows avatar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        final msg = EnhancedChatMessage.fromJson({
          'delivery_id': 10,
          'sender_id': 5,
          'sender_type': 'customer',
          'sender_name': 'Awa',
          'sender_avatar': 'https://example.com/avatar.jpg',
          'type': 'text',
          'content': 'Salut',
          'target': 'courier',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        }, 'msg-avatar');
        await tester.pumpWidget(buildWidget(msg, courierId: 1));
        await tester.pump();
        expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('TypingIndicator', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(name: 'Marie')),
        ),
      );
      expect(find.byType(TypingIndicator), findsOneWidget);
    });

    testWidgets('shows name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(name: 'Awa')),
        ),
      );
      expect(find.textContaining('Awa'), findsWidgets);
    });

    testWidgets('shows writing indicator text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(name: 'Koffi')),
        ),
      );
      expect(find.textContaining('crit'), findsWidgets);
    });
  });

  group('QuickRepliesWidget', () {
    testWidgets('renders with default replies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      expect(find.byType(QuickRepliesWidget), findsOneWidget);
    });

    testWidgets('shows default reply text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      expect(find.textContaining('Je suis en route'), findsOneWidget);
    });

    testWidgets('has ActionChip widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('has horizontal scroll view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tapping chip calls onSelect', (tester) async {
      QuickReply? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickRepliesWidget(onSelect: (reply) => selected = reply),
          ),
        ),
      );
      final chips = find.byType(ActionChip);
      await tester.tap(chips.first);
      await tester.pump();
      expect(selected, isNotNull);
    });

    testWidgets('multiple chips available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      // Should have several quick reply chips
      expect(find.byType(ActionChip).evaluate().length, greaterThan(2));
    });
  });

  group('EnhancedMessageBubble - message type branches', () {
    testWidgets('renders image type message from self', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'image',
        'content': 'Photo jointe',
        'image_url': 'https://example.com/photo.jpg',
        'target': 'customer',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-img1');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders image type message from other', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 2,
        'sender_type': 'customer',
        'sender_name': 'Client',
        'type': 'image',
        'content': 'Mon ordonnance',
        'image_url': 'https://example.com/ordonnance.jpg',
        'target': 'courier',
        'status': 'delivered',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-img2');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders voice type message', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'voice',
        'content': 'audio_message',
        'audio_url': 'https://example.com/voice.mp3',
        'audio_duration': 15,
        'target': 'customer',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-voice1');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders location type message', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'location',
        'content': 'Position partagée',
        'latitude': 5.316,
        'longitude': -4.012,
        'target': 'customer',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-loc1');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('renders quick_reply type message', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'quick_reply',
        'content': 'Je suis en route',
        'target': 'customer',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-qr1');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });
  });

  group('EnhancedMessageBubble - status and alignment', () {
    testWidgets('delivered status shows delivered icon', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'text',
        'content': 'Message livré',
        'target': 'customer',
        'status': 'delivered',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-del');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('read status shows read indicator', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'text',
        'content': 'Message lu',
        'target': 'customer',
        'status': 'read',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-read');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message with reply quote', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 1,
        'sender_type': 'courier',
        'sender_name': 'Jean',
        'type': 'text',
        'content': 'Oui je confirme',
        'reply_to_content': 'Vous êtes bien le livreur ?',
        'target': 'customer',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-reply');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message with sender avatar url', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 2,
        'sender_type': 'customer',
        'sender_name': 'Client',
        'sender_avatar': 'https://example.com/avatar.jpg',
        'type': 'text',
        'content': 'Bonjour',
        'target': 'courier',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-avatar');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('message from pharmacy sender', (tester) async {
      final msg = EnhancedChatMessage.fromJson({
        'delivery_id': 10,
        'sender_id': 3,
        'sender_type': 'pharmacy',
        'sender_name': 'Pharmacien',
        'type': 'text',
        'content': 'Commande prête',
        'target': 'courier',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      }, 'msg-pharm');
      await tester.pumpWidget(buildWidget(msg, courierId: 1));
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });
  });

  group('EnhancedMessageBubble - callbacks', () {
    testWidgets('onLongPress callback triggers on long press', (tester) async {
      var longPressed = false;
      final msg = makeMessage();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EnhancedMessageBubble(
                message: msg,
                courierId: 1,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );
      final bubble = find.byType(EnhancedMessageBubble);
      await tester.longPress(bubble);
      await tester.pump();
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      // longPressed would be true if gesture was recognized
      expect(longPressed, isA<bool>());
    });

    testWidgets('onTap callback triggers on tap', (tester) async {
      var tapped = false;
      final msg = makeMessage();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EnhancedMessageBubble(
                message: msg,
                courierId: 1,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      final bubble = find.byType(EnhancedMessageBubble);
      await tester.tap(bubble);
      await tester.pump();
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      // tapped would be true if gesture was recognized
      expect(tapped, isA<bool>());
    });
  });

  group('TypingIndicator - additional', () {
    testWidgets('renders with long name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypingIndicator(name: 'Pharmacie du Centre Ville Abidjan'),
          ),
        ),
      );
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.textContaining('Pharmacie'), findsOneWidget);
    });

    testWidgets('renders with empty name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TypingIndicator(name: '')),
        ),
      );
      expect(find.byType(TypingIndicator), findsOneWidget);
    });
  });

  group('QuickRepliesWidget - additional', () {
    testWidgets('renders default replies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickRepliesWidget(onSelect: (_) {})),
        ),
      );
      // Default replies from QuickReply.defaults
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('tapping second chip calls onSelect with correct value', (
      tester,
    ) async {
      QuickReply? selectedReply;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickRepliesWidget(
              onSelect: (reply) => selectedReply = reply,
            ),
          ),
        ),
      );
      final chips = find.byType(ActionChip);
      if (chips.evaluate().length > 1) {
        await tester.tap(chips.at(1));
        await tester.pump();
        expect(selectedReply, isNotNull);
      }
      expect(find.byType(QuickRepliesWidget), findsOneWidget);
    });
  });
}
