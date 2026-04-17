import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';

void main() {
  // ════════════════════════════════════════════
  // MessageType extension
  // ════════════════════════════════════════════
  group('MessageType extension', () {
    test('value for all types', () {
      expect(MessageType.text.value, 'text');
      expect(MessageType.image.value, 'image');
      expect(MessageType.voice.value, 'voice');
      expect(MessageType.location.value, 'location');
      expect(MessageType.quickReply.value, 'quick_reply');
      expect(MessageType.system.value, 'system');
    });

    test('fromString for all types', () {
      expect(MessageTypeExtension.fromString('text'), MessageType.text);
      expect(MessageTypeExtension.fromString('image'), MessageType.image);
      expect(MessageTypeExtension.fromString('voice'), MessageType.voice);
      expect(MessageTypeExtension.fromString('location'), MessageType.location);
      expect(
        MessageTypeExtension.fromString('quick_reply'),
        MessageType.quickReply,
      );
      expect(MessageTypeExtension.fromString('system'), MessageType.system);
      expect(MessageTypeExtension.fromString('unknown'), MessageType.text);
    });
  });

  // ════════════════════════════════════════════
  // MessageStatus extension
  // ════════════════════════════════════════════
  group('MessageStatus extension', () {
    test('value for all statuses', () {
      expect(MessageStatus.sending.value, 'sending');
      expect(MessageStatus.sent.value, 'sent');
      expect(MessageStatus.delivered.value, 'delivered');
      expect(MessageStatus.read.value, 'read');
      expect(MessageStatus.failed.value, 'failed');
    });

    test('fromString for all statuses', () {
      expect(MessageStatusExtension.fromString('sent'), MessageStatus.sent);
      expect(
        MessageStatusExtension.fromString('delivered'),
        MessageStatus.delivered,
      );
      expect(MessageStatusExtension.fromString('read'), MessageStatus.read);
      expect(MessageStatusExtension.fromString('failed'), MessageStatus.failed);
      expect(
        MessageStatusExtension.fromString('unknown'),
        MessageStatus.sending,
      );
    });

    test('icon for all statuses', () {
      expect(MessageStatus.sending.icon, Icons.schedule);
      expect(MessageStatus.sent.icon, Icons.check);
      expect(MessageStatus.delivered.icon, Icons.done_all);
      expect(MessageStatus.read.icon, Icons.done_all);
      expect(MessageStatus.failed.icon, Icons.error_outline);
    });

    test('color for all statuses', () {
      expect(MessageStatus.sending.color, Colors.grey);
      expect(MessageStatus.sent.color, Colors.grey);
      expect(MessageStatus.delivered.color, Colors.grey);
      expect(MessageStatus.read.color, Colors.blue);
      expect(MessageStatus.failed.color, Colors.red);
    });
  });

  // ════════════════════════════════════════════
  // SenderRole extension
  // ════════════════════════════════════════════
  group('SenderRole extension', () {
    test('value for all roles', () {
      expect(SenderRole.courier.value, 'courier');
      expect(SenderRole.customer.value, 'customer');
      expect(SenderRole.pharmacy.value, 'pharmacy');
      expect(SenderRole.system.value, 'system');
    });

    test('fromString for all roles', () {
      expect(SenderRoleExtension.fromString('courier'), SenderRole.courier);
      expect(SenderRoleExtension.fromString('customer'), SenderRole.customer);
      expect(SenderRoleExtension.fromString('pharmacy'), SenderRole.pharmacy);
      expect(SenderRoleExtension.fromString('system'), SenderRole.system);
      expect(SenderRoleExtension.fromString('unknown'), SenderRole.courier);
    });

    test('label for all roles', () {
      expect(SenderRole.courier.label, 'Livreur');
      expect(SenderRole.customer.label, 'Client');
      expect(SenderRole.pharmacy.label, 'Pharmacie');
      expect(SenderRole.system.label, 'Système');
    });

    test('color for all roles', () {
      expect(SenderRole.courier.color, Colors.blue);
      expect(SenderRole.customer.color, Colors.green);
      expect(SenderRole.pharmacy.color, Colors.orange);
      expect(SenderRole.system.color, Colors.grey);
    });

    test('icon for all roles', () {
      expect(SenderRole.courier.icon, Icons.delivery_dining);
      expect(SenderRole.customer.icon, Icons.person);
      expect(SenderRole.pharmacy.icon, Icons.local_pharmacy);
      expect(SenderRole.system.icon, Icons.info);
    });
  });

  // ════════════════════════════════════════════
  // EnhancedChatMessage
  // ════════════════════════════════════════════
  group('EnhancedChatMessage', () {
    final now = DateTime(2024, 6, 15, 10, 30);

    test('constructor', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hello',
        type: MessageType.text,
        senderRole: SenderRole.courier,
        senderId: 1,
        senderName: 'Ali',
        target: 'customer',
        status: MessageStatus.sent,
        createdAt: now,
      );
      expect(msg.id, 'msg1');
      expect(msg.content, 'Hello');
      expect(msg.type, MessageType.text);
      expect(msg.senderRole, SenderRole.courier);
      expect(msg.senderId, 1);
      expect(msg.senderName, 'Ali');
      expect(msg.target, 'customer');
      expect(msg.status, MessageStatus.sent);
      expect(msg.createdAt, now);
    });

    test('isFromCourier returns true for matching courier', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hi',
        type: MessageType.text,
        senderRole: SenderRole.courier,
        senderId: 5,
        senderName: 'Ali',
        target: 'customer',
        status: MessageStatus.sent,
        createdAt: now,
      );
      expect(msg.isFromCourier(5), true);
      expect(msg.isFromCourier(6), false);
    });

    test('isFromCourier returns false for non-courier', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hi',
        type: MessageType.text,
        senderRole: SenderRole.customer,
        senderId: 5,
        senderName: 'Client',
        target: 'courier',
        status: MessageStatus.sent,
        createdAt: now,
      );
      expect(msg.isFromCourier(5), false);
    });

    test('copyWith preserves values', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hello',
        type: MessageType.text,
        senderRole: SenderRole.courier,
        senderId: 1,
        senderName: 'Ali',
        target: 'customer',
        status: MessageStatus.sent,
        createdAt: now,
      );
      final copy = msg.copyWith();
      expect(copy.id, 'msg1');
      expect(copy.content, 'Hello');
      expect(copy.senderName, 'Ali');
    });

    test('copyWith updates specific fields', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hello',
        type: MessageType.text,
        senderRole: SenderRole.courier,
        senderId: 1,
        senderName: 'Ali',
        target: 'customer',
        status: MessageStatus.sent,
        createdAt: now,
      );
      final readAt = DateTime(2024, 6, 15, 10, 31);
      final copy = msg.copyWith(status: MessageStatus.read, readAt: readAt);
      expect(copy.status, MessageStatus.read);
      expect(copy.readAt, readAt);
      expect(copy.content, 'Hello');
    });

    test('fromJson with string date', () {
      final msg = EnhancedChatMessage.fromJson({
        'content': 'Test message',
        'type': 'image',
        'sender_type': 'customer',
        'sender_id': 10,
        'sender_name': 'Jean',
        'sender_avatar': 'https://example.com/avatar.png',
        'target': 'courier',
        'status': 'delivered',
        'created_at': '2024-06-15T10:30:00.000',
        'image_url': 'https://example.com/img.jpg',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'audio_duration': 5000,
        'latitude': 48.8566,
        'longitude': 2.3522,
        'location_address': 'Paris',
        'reply_to_id': 'prev1',
        'reply_to_content': 'Earlier msg',
      }, 'doc123');
      expect(msg.id, 'doc123');
      expect(msg.content, 'Test message');
      expect(msg.type, MessageType.image);
      expect(msg.senderRole, SenderRole.customer);
      expect(msg.senderId, 10);
      expect(msg.senderName, 'Jean');
      expect(msg.senderAvatar, 'https://example.com/avatar.png');
      expect(msg.target, 'courier');
      expect(msg.status, MessageStatus.delivered);
      expect(msg.imageUrl, 'https://example.com/img.jpg');
      expect(msg.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(msg.audioDuration, const Duration(milliseconds: 5000));
      expect(msg.latitude, 48.8566);
      expect(msg.longitude, 2.3522);
      expect(msg.locationAddress, 'Paris');
      expect(msg.replyToId, 'prev1');
      expect(msg.replyToContent, 'Earlier msg');
    });

    test('fromJson with defaults', () {
      final msg = EnhancedChatMessage.fromJson({}, 'id1');
      expect(msg.content, '');
      expect(msg.type, MessageType.text);
      expect(msg.senderRole, SenderRole.courier);
      expect(msg.senderId, 0);
      expect(msg.senderName, 'Inconnu');
      expect(msg.target, 'customer');
      expect(msg.status, MessageStatus.sent);
      expect(msg.audioUrl, null);
      expect(msg.imageUrl, null);
    });

    test('toJson serializes fields', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Bonjour',
        type: MessageType.voice,
        senderRole: SenderRole.pharmacy,
        senderId: 3,
        senderName: 'Pharmacie X',
        senderAvatar: 'url',
        target: 'courier',
        status: MessageStatus.sent,
        createdAt: now,
        audioUrl: 'audio.mp3',
        audioDuration: const Duration(seconds: 30),
        latitude: 5.3,
        longitude: -3.9,
        locationAddress: 'Abidjan',
        replyToId: 'r1',
        replyToContent: 'prev',
      );
      final json = msg.toJson();
      expect(json['content'], 'Bonjour');
      expect(json['type'], 'voice');
      expect(json['sender_type'], 'pharmacy');
      expect(json['sender_id'], 3);
      expect(json['sender_name'], 'Pharmacie X');
      expect(json['sender_avatar'], 'url');
      expect(json['target'], 'courier');
      expect(json['status'], 'sent');
      expect(json['audio_url'], 'audio.mp3');
      expect(json['audio_duration'], 30000);
      expect(json['latitude'], 5.3);
      expect(json['longitude'], -3.9);
      expect(json['location_address'], 'Abidjan');
      expect(json['reply_to_id'], 'r1');
      expect(json['reply_to_content'], 'prev');
    });

    test('toJson excludes null optional fields', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hi',
        type: MessageType.text,
        senderRole: SenderRole.courier,
        senderId: 1,
        senderName: 'Ali',
        target: 'customer',
        status: MessageStatus.sent,
        createdAt: now,
      );
      final json = msg.toJson();
      expect(json.containsKey('sender_avatar'), false);
      expect(json.containsKey('audio_url'), false);
      expect(json.containsKey('image_url'), false);
      expect(json.containsKey('latitude'), false);
    });
  });

  // ════════════════════════════════════════════
  // ChatConversation
  // ════════════════════════════════════════════
  group('ChatConversation', () {
    test('constructor', () {
      final conv = ChatConversation(
        orderId: 42,
        target: 'customer',
        targetName: 'Jean',
        unreadCount: 3,
        updatedAt: DateTime(2024, 6, 15),
      );
      expect(conv.orderId, 42);
      expect(conv.target, 'customer');
      expect(conv.targetName, 'Jean');
      expect(conv.targetAvatar, null);
      expect(conv.lastMessage, null);
      expect(conv.unreadCount, 3);
      expect(conv.isTyping, false);
    });

    test('copyWith preserves values', () {
      final conv = ChatConversation(
        orderId: 1,
        target: 'pharmacy',
        targetName: 'Pharma X',
        unreadCount: 0,
        updatedAt: DateTime(2024, 6, 15),
        isTyping: true,
      );
      final copy = conv.copyWith();
      expect(copy.orderId, 1);
      expect(copy.targetName, 'Pharma X');
      expect(copy.isTyping, true);
    });

    test('copyWith updates fields', () {
      final conv = ChatConversation(
        orderId: 1,
        target: 'customer',
        targetName: 'Jean',
        unreadCount: 5,
        updatedAt: DateTime(2024, 6, 15),
      );
      final copy = conv.copyWith(
        unreadCount: 0,
        isTyping: true,
        targetAvatar: 'avatar.png',
      );
      expect(copy.unreadCount, 0);
      expect(copy.isTyping, true);
      expect(copy.targetAvatar, 'avatar.png');
    });
  });

  // ════════════════════════════════════════════
  // QuickReply
  // ════════════════════════════════════════════
  group('QuickReply', () {
    test('defaults returns 8 replies', () {
      expect(QuickReply.defaults.length, 8);
    });

    test('defaults have ids and text', () {
      for (final reply in QuickReply.defaults) {
        expect(reply.id, isNotEmpty);
        expect(reply.text, isNotEmpty);
        expect(reply.icon, isNotNull);
        expect(reply.category, isNotNull);
      }
    });

    test('defaults contain expected ids', () {
      final ids = QuickReply.defaults.map((r) => r.id).toList();
      expect(ids, contains('arriving'));
      expect(ids, contains('arrived'));
      expect(ids, contains('waiting'));
      expect(ids, contains('traffic'));
      expect(ids, contains('calling'));
      expect(ids, contains('address'));
      expect(ids, contains('thanks'));
      expect(ids, contains('cant_find'));
    });

    test('byCategory groups correctly', () {
      final categories = QuickReply.byCategory;
      expect(categories.containsKey('status'), true);
      expect(categories.containsKey('delay'), true);
      expect(categories.containsKey('contact'), true);
      expect(categories.containsKey('question'), true);
      expect(categories.containsKey('closing'), true);
      expect(categories.containsKey('problem'), true);
    });

    test('byCategory status has 3 replies', () {
      final statusReplies = QuickReply.byCategory['status']!;
      expect(statusReplies.length, 3);
    });

    test('constructor', () {
      const reply = QuickReply(
        id: 'test',
        text: 'Test reply',
        icon: Icons.star,
        category: 'test_cat',
      );
      expect(reply.id, 'test');
      expect(reply.text, 'Test reply');
      expect(reply.icon, Icons.star);
      expect(reply.category, 'test_cat');
    });
  });

  // ════════════════════════════════════════════
  // TypingStatus
  // ════════════════════════════════════════════
  group('TypingStatus', () {
    test('constructor', () {
      final now = DateTime.now();
      final status = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 5,
        senderName: 'Ali',
        startedAt: now,
      );
      expect(status.orderId, 1);
      expect(status.target, 'customer');
      expect(status.senderRole, SenderRole.courier);
      expect(status.senderId, 5);
      expect(status.senderName, 'Ali');
      expect(status.startedAt, now);
    });

    test('isExpired returns false for recent', () {
      final status = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 5,
        senderName: 'Ali',
        startedAt: DateTime.now(),
      );
      expect(status.isExpired, false);
    });

    test('isExpired returns true for old', () {
      final status = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 5,
        senderName: 'Ali',
        startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(status.isExpired, true);
    });
  });
}
