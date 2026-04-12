import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/services/enhanced_chat_service.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;
  late EnhancedChatService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    service = EnhancedChatService(
      firestore: fakeFirestore,
      storage: mockStorage,
    );
  });

  group('EnhancedChatService - initialization', () {
    test('creates without errors', () {
      expect(service, isNotNull);
    });

    test('initialize sets courier info', () {
      service.initialize(
        courierId: 42,
        courierName: 'Jean Test',
        courierAvatar: 'https://example.com/avatar.jpg',
      );
      // Should not throw after initialization
      expect(() => service.watchMessages(1, 'customer'), returnsNormally);
    });

    test('initialize without avatar', () {
      service.initialize(courierId: 10, courierName: 'Pierre');
      expect(() => service.watchMessages(1, 'customer'), returnsNormally);
    });

    test('throws when calling _ensureInitialized without init', () {
      expect(
        () async => await service.sendTextMessage(
          orderId: 1,
          content: 'Hello',
          target: 'customer',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('dispose does not throw', () {
      service.initialize(courierId: 1, courierName: 'Test');
      expect(() => service.dispose(), returnsNormally);
    });

    test('dispose before initialize does not throw', () {
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('EnhancedChatService - sendTextMessage', () {
    setUp(() {
      service.initialize(
        courierId: 42,
        courierName: 'Jean Livreur',
        courierAvatar: 'https://example.com/avatar.jpg',
      );
    });

    test('sends text message and returns with id', () async {
      final result = await service.sendTextMessage(
        orderId: 100,
        content: 'Bonjour, je suis devant la porte',
        target: 'customer',
      );

      expect(result, isNotNull);
      expect(result.content, 'Bonjour, je suis devant la porte');
      expect(result.type, MessageType.text);
      expect(result.senderRole, SenderRole.courier);
      expect(result.senderId, 42);
      expect(result.senderName, 'Jean Livreur');
      expect(result.target, 'customer');
      expect(result.id, isNotEmpty);
    });

    test('sends message with reply context', () async {
      final result = await service.sendTextMessage(
        orderId: 100,
        content: 'Oui, je suis en route',
        target: 'pharmacy',
        replyToId: 'msg_123',
        replyToContent: 'Vous êtes en route ?',
      );

      expect(result.content, 'Oui, je suis en route');
      expect(result.replyToId, 'msg_123');
      expect(result.replyToContent, 'Vous êtes en route ?');
      expect(result.target, 'pharmacy');
    });

    test('stores message in Firestore', () async {
      await service.sendTextMessage(
        orderId: 200,
        content: 'Test message',
        target: 'customer',
      );

      final snapshot = await fakeFirestore
          .collection('orders')
          .doc('200')
          .collection('messages')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['content'], 'Test message');
      expect(snapshot.docs.first.data()['type'], 'text');
      expect(snapshot.docs.first.data()['sender_type'], 'courier');
    });

    test('sends multiple messages', () async {
      await service.sendTextMessage(
        orderId: 300,
        content: 'First message',
        target: 'customer',
      );
      await service.sendTextMessage(
        orderId: 300,
        content: 'Second message',
        target: 'customer',
      );

      final snapshot = await fakeFirestore
          .collection('orders')
          .doc('300')
          .collection('messages')
          .get();

      expect(snapshot.docs.length, 2);
    });

    test('sends to different targets', () async {
      await service.sendTextMessage(
        orderId: 400,
        content: 'To customer',
        target: 'customer',
      );
      await service.sendTextMessage(
        orderId: 400,
        content: 'To pharmacy',
        target: 'pharmacy',
      );

      final snapshot = await fakeFirestore
          .collection('orders')
          .doc('400')
          .collection('messages')
          .get();

      expect(snapshot.docs.length, 2);
      final targets = snapshot.docs.map((d) => d.data()['target']).toSet();
      expect(targets, {'customer', 'pharmacy'});
    });
  });

  group('EnhancedChatService - sendLocationMessage', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('sends location message', () async {
      final result = await service.sendLocationMessage(
        orderId: 100,
        latitude: 5.3167,
        longitude: -3.9833,
        target: 'customer',
        address: 'Cocody, Abidjan',
      );

      expect(result.type, MessageType.location);
      expect(result.latitude, 5.3167);
      expect(result.longitude, -3.9833);
      expect(result.locationAddress, 'Cocody, Abidjan');
      expect(result.content, 'Cocody, Abidjan');
    });

    test('sends location without address defaults to position text', () async {
      final result = await service.sendLocationMessage(
        orderId: 100,
        latitude: 5.3167,
        longitude: -3.9833,
        target: 'customer',
      );

      expect(result.content, 'Ma position actuelle');
      expect(result.locationAddress, isNull);
    });

    test('stores location in Firestore', () async {
      await service.sendLocationMessage(
        orderId: 500,
        latitude: 5.35,
        longitude: -4.01,
        target: 'pharmacy',
      );

      final snapshot = await fakeFirestore
          .collection('orders')
          .doc('500')
          .collection('messages')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['type'], 'location');
      expect(snapshot.docs.first.data()['latitude'], 5.35);
      expect(snapshot.docs.first.data()['longitude'], -4.01);
    });
  });

  group('EnhancedChatService - sendQuickReply', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('sends quick reply as text message', () async {
      final quickReply = QuickReply(
        id: 'qr1',
        text: 'Je suis en route',
        icon: Icons.directions_bike,
      );

      final result = await service.sendQuickReply(
        orderId: 100,
        quickReply: quickReply,
        target: 'customer',
      );

      expect(result.content, 'Je suis en route');
      expect(result.type, MessageType.text);
    });
  });

  group('EnhancedChatService - typing indicators', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('startTyping writes to Firestore', () async {
      await service.startTyping(100, 'customer');

      final snapshot = await fakeFirestore.collection('typing_status').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['order_id'], 100);
      expect(snapshot.docs.first.data()['target'], 'customer');
      expect(snapshot.docs.first.data()['sender_type'], 'courier');
      expect(snapshot.docs.first.data()['sender_id'], 42);
    });

    test('stopTyping removes from Firestore', () async {
      await service.startTyping(100, 'customer');

      // Verify it was added
      var snapshot = await fakeFirestore.collection('typing_status').get();
      expect(snapshot.docs.length, 1);

      await service.stopTyping(100, 'customer');

      snapshot = await fakeFirestore.collection('typing_status').get();
      expect(snapshot.docs.length, 0);
    });

    test('startTyping twice does not duplicate', () async {
      await service.startTyping(100, 'customer');
      await service.startTyping(100, 'customer');

      final snapshot = await fakeFirestore.collection('typing_status').get();
      // Second call is no-op since _isCurrentlyTyping is true
      expect(snapshot.docs.length, 1);
    });

    test('stopTyping when not typing is no-op', () async {
      await service.stopTyping(100, 'customer');
      // Should not throw
      final snapshot = await fakeFirestore.collection('typing_status').get();
      expect(snapshot.docs.length, 0);
    });
  });

  group('EnhancedChatService - deleteMessage', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('deletes message from Firestore', () async {
      // First add a message
      final result = await service.sendTextMessage(
        orderId: 600,
        content: 'To be deleted',
        target: 'customer',
      );

      // Verify it exists
      var snapshot = await fakeFirestore
          .collection('orders')
          .doc('600')
          .collection('messages')
          .get();
      expect(snapshot.docs.length, 1);

      // Delete it
      await service.deleteMessage(600, 'customer', result.id);

      snapshot = await fakeFirestore
          .collection('orders')
          .doc('600')
          .collection('messages')
          .get();
      expect(snapshot.docs.length, 0);
    });

    test('deleteMessage with empty id is no-op', () async {
      // Should not throw
      await service.deleteMessage(600, 'customer', '');
    });
  });

  group('EnhancedChatService - reportConversation', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('creates report document in Firestore', () async {
      await service.reportConversation(100, 'customer', 'Client Test');

      final snapshot = await fakeFirestore.collection('reports').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'chat_conversation');
      expect(data['order_id'], 100);
      expect(data['target'], 'customer');
      expect(data['target_name'], 'Client Test');
      expect(data['reporter_id'], 42);
      expect(data['reporter_name'], 'Jean');
      expect(data['reporter_role'], 'courier');
      expect(data['status'], 'pending');
    });
  });

  group('EnhancedChatService - watchMessages', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('returns stream', () {
      final stream = service.watchMessages(100, 'customer');
      expect(stream, isA<Stream<List<EnhancedChatMessage>>>());
    });
  });

  group('EnhancedChatService - watchActiveConversations', () {
    test('returns empty stream when not initialized', () async {
      final conversations = await service.watchActiveConversations().first;
      expect(conversations, isEmpty);
    });

    test('returns stream when initialized', () {
      service.initialize(courierId: 42, courierName: 'Jean');
      final stream = service.watchActiveConversations();
      expect(stream, isA<Stream<List<ChatConversation>>>());
    });
  });

  group('EnhancedChatService - watchTotalUnreadCount', () {
    test('returns 0 when not initialized', () async {
      final count = await service.watchTotalUnreadCount().first;
      expect(count, 0);
    });

    test('returns stream when initialized', () {
      service.initialize(courierId: 42, courierName: 'Jean');
      final stream = service.watchTotalUnreadCount();
      expect(stream, isA<Stream<int>>());
    });

    test('returns 0 when no conversations', () async {
      service.initialize(courierId: 42, courierName: 'Jean');
      final count = await service.watchTotalUnreadCount().first;
      expect(count, 0);
    });
  });

  group('EnhancedChatService - conversation tracking', () {
    setUp(() {
      service.initialize(courierId: 42, courierName: 'Jean');
    });

    test('sendTextMessage updates conversation document', () async {
      await service.sendTextMessage(
        orderId: 700,
        content: 'Test message',
        target: 'customer',
      );

      final convDoc = await fakeFirestore
          .collection('courier_conversations')
          .doc('42')
          .collection('conversations')
          .doc('700_customer')
          .get();

      expect(convDoc.exists, isTrue);
      expect(convDoc.data()!['order_id'], 700);
      expect(convDoc.data()!['target'], 'customer');
      expect(convDoc.data()!['last_message_content'], 'Test message');
      expect(convDoc.data()!['last_message_type'], 'text');
    });

    test('sendLocationMessage updates conversation', () async {
      await service.sendLocationMessage(
        orderId: 700,
        latitude: 5.35,
        longitude: -4.01,
        target: 'pharmacy',
        address: 'Plateau',
      );

      final convDoc = await fakeFirestore
          .collection('courier_conversations')
          .doc('42')
          .collection('conversations')
          .doc('700_pharmacy')
          .get();

      expect(convDoc.exists, isTrue);
      expect(convDoc.data()!['last_message_type'], 'location');
    });
  });
}
