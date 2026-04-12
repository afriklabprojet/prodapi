import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';

void main() {
  group('MessageType extension', () {
    test('value returns correct strings', () {
      expect(MessageType.text.value, 'text');
      expect(MessageType.image.value, 'image');
      expect(MessageType.voice.value, 'voice');
      expect(MessageType.location.value, 'location');
      expect(MessageType.quickReply.value, 'quick_reply');
      expect(MessageType.system.value, 'system');
    });

    test('fromString parses known types', () {
      expect(MessageTypeExtension.fromString('image'), MessageType.image);
      expect(MessageTypeExtension.fromString('voice'), MessageType.voice);
      expect(MessageTypeExtension.fromString('location'), MessageType.location);
      expect(
        MessageTypeExtension.fromString('quick_reply'),
        MessageType.quickReply,
      );
      expect(MessageTypeExtension.fromString('system'), MessageType.system);
    });

    test('fromString defaults to text', () {
      expect(MessageTypeExtension.fromString('unknown'), MessageType.text);
      expect(MessageTypeExtension.fromString(''), MessageType.text);
    });
  });

  group('MessageStatus extension', () {
    test('value returns correct strings', () {
      expect(MessageStatus.sending.value, 'sending');
      expect(MessageStatus.sent.value, 'sent');
      expect(MessageStatus.delivered.value, 'delivered');
      expect(MessageStatus.read.value, 'read');
      expect(MessageStatus.failed.value, 'failed');
    });

    test('fromString parses known statuses', () {
      expect(MessageStatusExtension.fromString('sent'), MessageStatus.sent);
      expect(
        MessageStatusExtension.fromString('delivered'),
        MessageStatus.delivered,
      );
      expect(MessageStatusExtension.fromString('read'), MessageStatus.read);
      expect(MessageStatusExtension.fromString('failed'), MessageStatus.failed);
    });

    test('fromString defaults to sending', () {
      expect(
        MessageStatusExtension.fromString('unknown'),
        MessageStatus.sending,
      );
    });

    test('icon returns IconData', () {
      for (final s in MessageStatus.values) {
        expect(s.icon, isA<IconData>());
      }
    });

    test('color returns Color', () {
      for (final s in MessageStatus.values) {
        expect(s.color, isA<Color>());
      }
    });
  });

  group('SenderRole extension', () {
    test('value returns correct strings', () {
      expect(SenderRole.courier.value, 'courier');
      expect(SenderRole.customer.value, 'customer');
      expect(SenderRole.pharmacy.value, 'pharmacy');
      expect(SenderRole.system.value, 'system');
    });

    test('fromString parses known roles', () {
      expect(SenderRoleExtension.fromString('customer'), SenderRole.customer);
      expect(SenderRoleExtension.fromString('pharmacy'), SenderRole.pharmacy);
      expect(SenderRoleExtension.fromString('system'), SenderRole.system);
    });

    test('fromString defaults to courier', () {
      expect(SenderRoleExtension.fromString('unknown'), SenderRole.courier);
    });

    test('label returns French names', () {
      expect(SenderRole.courier.label, 'Livreur');
      expect(SenderRole.customer.label, 'Client');
      expect(SenderRole.pharmacy.label, 'Pharmacie');
      expect(SenderRole.system.label, 'Système');
    });

    test('color returns Color', () {
      for (final r in SenderRole.values) {
        expect(r.color, isA<Color>());
      }
    });

    test('icon returns IconData', () {
      for (final r in SenderRole.values) {
        expect(r.icon, isA<IconData>());
      }
    });
  });

  group('EnhancedChatMessage', () {
    final msg = EnhancedChatMessage(
      id: '1',
      content: 'Hello',
      type: MessageType.text,
      senderRole: SenderRole.courier,
      senderId: 10,
      senderName: 'Ali',
      target: 'customer',
      status: MessageStatus.sent,
      createdAt: DateTime(2024, 1, 1),
    );

    test('isFromCourier correctly identifies', () {
      expect(msg.isFromCourier(10), isTrue);
      expect(msg.isFromCourier(99), isFalse);
    });

    test('isFromCourier false for non-courier role', () {
      final customerMsg = msg.copyWith(senderRole: SenderRole.customer);
      expect(customerMsg.isFromCourier(10), isFalse);
    });

    test('copyWith changes fields', () {
      final updated = msg.copyWith(content: 'Bye', status: MessageStatus.read);
      expect(updated.content, 'Bye');
      expect(updated.status, MessageStatus.read);
      expect(updated.id, '1'); // unchanged
    });

    test('toJson round-trips basic fields', () {
      final json = msg.toJson();
      expect(json['content'], 'Hello');
      expect(json['type'], 'text');
      expect(json['sender_type'], 'courier');
      expect(json['sender_id'], 10);
      expect(json['sender_name'], 'Ali');
      expect(json['target'], 'customer');
    });

    test('fromJson parses all required fields', () {
      final json = <String, dynamic>{
        'content': 'Bonjour',
        'type': 'text',
        'sender_type': 'courier',
        'sender_id': 42,
        'sender_name': 'Ahmed',
        'target': 'customer',
        'status': 'sent',
        'created_at': '2025-06-01T10:30:00Z',
      };
      final m = EnhancedChatMessage.fromJson(json, 'doc1');
      expect(m.id, 'doc1');
      expect(m.content, 'Bonjour');
      expect(m.type, MessageType.text);
      expect(m.senderRole, SenderRole.courier);
      expect(m.senderId, 42);
      expect(m.senderName, 'Ahmed');
      expect(m.target, 'customer');
      expect(m.status, MessageStatus.sent);
      expect(m.createdAt.year, 2025);
    });

    test('fromJson handles optional fields', () {
      final json = <String, dynamic>{
        'content': 'Photo',
        'type': 'image',
        'sender_type': 'customer',
        'sender_id': 10,
        'sender_name': 'Client',
        'target': 'courier',
        'status': 'read',
        'created_at': '2025-01-01T00:00:00Z',
        'sender_avatar': 'https://example.com/avatar.jpg',
        'image_url': 'https://example.com/img.jpg',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'audio_url': 'https://example.com/audio.mp3',
        'audio_duration': 5000,
        'latitude': 5.35,
        'longitude': -3.95,
        'location_address': 'Cocody',
        'reply_to_id': 'msg0',
        'reply_to_content': 'Original message',
        'metadata': <String, dynamic>{'key': 'value'},
      };
      final m = EnhancedChatMessage.fromJson(json, 'doc2');
      expect(m.senderAvatar, 'https://example.com/avatar.jpg');
      expect(m.imageUrl, 'https://example.com/img.jpg');
      expect(m.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(m.audioUrl, 'https://example.com/audio.mp3');
      expect(m.audioDuration, const Duration(milliseconds: 5000));
      expect(m.latitude, 5.35);
      expect(m.longitude, -3.95);
      expect(m.locationAddress, 'Cocody');
      expect(m.replyToId, 'msg0');
      expect(m.replyToContent, 'Original message');
      expect(m.metadata, {'key': 'value'});
    });

    test('fromJson defaults missing fields', () {
      final m = EnhancedChatMessage.fromJson(<String, dynamic>{}, 'empty');
      expect(m.content, '');
      expect(m.type, MessageType.text);
      expect(m.senderRole, SenderRole.courier);
      expect(m.senderId, 0);
      expect(m.senderName, 'Inconnu');
      expect(m.target, 'customer');
      expect(m.senderAvatar, isNull);
      expect(m.audioUrl, isNull);
      expect(m.audioDuration, isNull);
      expect(m.imageUrl, isNull);
      expect(m.latitude, isNull);
      expect(m.replyToId, isNull);
    });

    test('fromJson parses string created_at', () {
      final m = EnhancedChatMessage.fromJson(<String, dynamic>{
        'created_at': '2024-12-25T15:00:00Z',
      }, 'id');
      expect(m.createdAt.year, 2024);
      expect(m.createdAt.month, 12);
      expect(m.createdAt.day, 25);
    });

    test('fromJson handles invalid created_at falls back to now', () {
      final before = DateTime.now();
      final m = EnhancedChatMessage.fromJson(<String, dynamic>{
        'created_at': 'not-a-date',
      }, 'id');
      final after = DateTime.now();
      expect(
        m.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(m.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  // ── ChatConversation ────────────────────────────
  group('ChatConversation', () {
    test('creates with required fields and defaults', () {
      final conv = ChatConversation(
        orderId: 100,
        target: 'customer',
        targetName: 'Client Test',
        unreadCount: 3,
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(conv.orderId, 100);
      expect(conv.targetName, 'Client Test');
      expect(conv.unreadCount, 3);
      expect(conv.isTyping, false);
      expect(conv.targetAvatar, isNull);
      expect(conv.lastMessage, isNull);
    });

    test('copyWith updates specific fields', () {
      final original = ChatConversation(
        orderId: 1,
        target: 'customer',
        targetName: 'Client',
        unreadCount: 0,
        updatedAt: DateTime(2025, 1, 1),
      );
      final copy = original.copyWith(unreadCount: 5, isTyping: true);
      expect(copy.unreadCount, 5);
      expect(copy.isTyping, true);
      expect(copy.orderId, 1);
      expect(copy.targetName, 'Client');
    });
  });

  // ── QuickReply ──────────────────────────────────
  group('QuickReply', () {
    test('defaults has 8 entries', () {
      expect(QuickReply.defaults.length, 8);
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

    test('each default has non-empty text and icon', () {
      for (final reply in QuickReply.defaults) {
        expect(reply.text, isNotEmpty);
        expect(reply.icon, isNotNull);
        expect(reply.category, isNotNull);
      }
    });

    test('byCategory groups into correct categories', () {
      final grouped = QuickReply.byCategory;
      expect(
        grouped.keys,
        containsAll([
          'status',
          'delay',
          'contact',
          'question',
          'closing',
          'problem',
        ]),
      );
      expect(grouped['status']!.length, 3);
      expect(grouped['delay']!.length, 1);
      expect(grouped['contact']!.length, 1);
    });

    test('byCategory total matches defaults count', () {
      final grouped = QuickReply.byCategory;
      final total = grouped.values.fold(0, (sum, list) => sum + list.length);
      expect(total, QuickReply.defaults.length);
    });
  });

  // ── TypingStatus ────────────────────────────────
  group('TypingStatus', () {
    test('isExpired false for recent timestamp', () {
      final ts = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 42,
        senderName: 'Test',
        startedAt: DateTime.now(),
      );
      expect(ts.isExpired, false);
    });

    test('isExpired true for old timestamp', () {
      final ts = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 42,
        senderName: 'Test',
        startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(ts.isExpired, true);
    });

    test('fromJson parses fields', () {
      final ts = TypingStatus.fromJson(<String, dynamic>{
        'order_id': 100,
        'target': 'pharmacy',
        'sender_type': 'customer',
        'sender_id': 5,
        'sender_name': 'Client',
      }, 'doc1');
      expect(ts.orderId, 100);
      expect(ts.target, 'pharmacy');
      expect(ts.senderRole, SenderRole.customer);
      expect(ts.senderId, 5);
      expect(ts.senderName, 'Client');
    });

    test('fromJson defaults missing fields', () {
      final ts = TypingStatus.fromJson(<String, dynamic>{}, 'empty');
      expect(ts.orderId, 0);
      expect(ts.target, '');
      expect(ts.senderRole, SenderRole.courier);
      expect(ts.senderId, 0);
      expect(ts.senderName, '');
    });
  });

  // ── MessageStatus specific values ───────────────
  group('MessageStatus specific values', () {
    test(
      'sending icon is schedule',
      () => expect(MessageStatus.sending.icon, Icons.schedule),
    );
    test(
      'sent icon is check',
      () => expect(MessageStatus.sent.icon, Icons.check),
    );
    test(
      'delivered icon is done_all',
      () => expect(MessageStatus.delivered.icon, Icons.done_all),
    );
    test(
      'read icon is done_all',
      () => expect(MessageStatus.read.icon, Icons.done_all),
    );
    test(
      'failed icon is error_outline',
      () => expect(MessageStatus.failed.icon, Icons.error_outline),
    );
    test(
      'read color is blue',
      () => expect(MessageStatus.read.color, Colors.blue),
    );
    test(
      'failed color is red',
      () => expect(MessageStatus.failed.color, Colors.red),
    );
    test(
      'sending color is grey',
      () => expect(MessageStatus.sending.color, Colors.grey),
    );
  });

  // ── SenderRole specific values ──────────────────
  group('SenderRole specific values', () {
    test(
      'courier icon is delivery_dining',
      () => expect(SenderRole.courier.icon, Icons.delivery_dining),
    );
    test(
      'customer icon is person',
      () => expect(SenderRole.customer.icon, Icons.person),
    );
    test(
      'pharmacy icon is local_pharmacy',
      () => expect(SenderRole.pharmacy.icon, Icons.local_pharmacy),
    );
    test(
      'system icon is info',
      () => expect(SenderRole.system.icon, Icons.info),
    );
    test(
      'courier color is blue',
      () => expect(SenderRole.courier.color, Colors.blue),
    );
    test(
      'customer color is green',
      () => expect(SenderRole.customer.color, Colors.green),
    );
    test(
      'pharmacy color is orange',
      () => expect(SenderRole.pharmacy.color, Colors.orange),
    );
    test(
      'system color is grey',
      () => expect(SenderRole.system.color, Colors.grey),
    );
  });

  // ── EnhancedChatMessage copyWith individual fields ──
  group('EnhancedChatMessage copyWith individual fields', () {
    final base = EnhancedChatMessage(
      id: 'base',
      content: 'Hello',
      type: MessageType.text,
      senderRole: SenderRole.courier,
      senderId: 1,
      senderName: 'Ali',
      target: 'customer',
      status: MessageStatus.sent,
      createdAt: DateTime(2024, 1, 1),
    );

    test('copyWith updates id only', () {
      final updated = base.copyWith(id: 'new_id');
      expect(updated.id, 'new_id');
      expect(updated.content, 'Hello');
    });

    test('copyWith updates type only', () {
      final updated = base.copyWith(type: MessageType.image);
      expect(updated.type, MessageType.image);
      expect(updated.content, 'Hello');
    });

    test('copyWith updates senderRole only', () {
      final updated = base.copyWith(senderRole: SenderRole.pharmacy);
      expect(updated.senderRole, SenderRole.pharmacy);
      expect(updated.senderId, 1);
    });

    test('copyWith updates senderId only', () {
      final updated = base.copyWith(senderId: 99);
      expect(updated.senderId, 99);
      expect(updated.senderName, 'Ali');
    });

    test('copyWith updates senderName only', () {
      final updated = base.copyWith(senderName: 'Ahmed');
      expect(updated.senderName, 'Ahmed');
      expect(updated.senderId, 1);
    });

    test('copyWith updates senderAvatar only', () {
      final updated = base.copyWith(senderAvatar: 'https://example.com/a.jpg');
      expect(updated.senderAvatar, 'https://example.com/a.jpg');
    });

    test('copyWith updates target only', () {
      final updated = base.copyWith(target: 'pharmacy');
      expect(updated.target, 'pharmacy');
    });

    test('copyWith updates readAt only', () {
      final now = DateTime.now();
      final updated = base.copyWith(readAt: now);
      expect(updated.readAt, now);
    });

    test('copyWith updates metadata only', () {
      final updated = base.copyWith(metadata: {'key': 'val'});
      expect(updated.metadata, {'key': 'val'});
    });

    test('copyWith updates audioUrl only', () {
      final updated = base.copyWith(audioUrl: 'https://example.com/a.mp3');
      expect(updated.audioUrl, 'https://example.com/a.mp3');
    });

    test('copyWith updates audioDuration only', () {
      final updated = base.copyWith(audioDuration: const Duration(seconds: 30));
      expect(updated.audioDuration, const Duration(seconds: 30));
    });

    test('copyWith updates imageUrl only', () {
      final updated = base.copyWith(imageUrl: 'https://example.com/img.jpg');
      expect(updated.imageUrl, 'https://example.com/img.jpg');
    });

    test('copyWith updates thumbnailUrl only', () {
      final updated = base.copyWith(thumbnailUrl: 'https://example.com/t.jpg');
      expect(updated.thumbnailUrl, 'https://example.com/t.jpg');
    });

    test('copyWith updates latitude only', () {
      final updated = base.copyWith(latitude: 5.35);
      expect(updated.latitude, 5.35);
    });

    test('copyWith updates longitude only', () {
      final updated = base.copyWith(longitude: -3.95);
      expect(updated.longitude, -3.95);
    });

    test('copyWith updates locationAddress only', () {
      final updated = base.copyWith(locationAddress: 'Cocody');
      expect(updated.locationAddress, 'Cocody');
    });

    test('copyWith updates replyToId only', () {
      final updated = base.copyWith(replyToId: 'msg_0');
      expect(updated.replyToId, 'msg_0');
    });

    test('copyWith updates replyToContent only', () {
      final updated = base.copyWith(replyToContent: 'Original msg');
      expect(updated.replyToContent, 'Original msg');
    });

    test('copyWith updates createdAt only', () {
      final newDate = DateTime(2025, 6, 1);
      final updated = base.copyWith(createdAt: newDate);
      expect(updated.createdAt, newDate);
    });

    test('copyWith preserves all when no changes', () {
      final copy = base.copyWith();
      expect(copy.id, 'base');
      expect(copy.content, 'Hello');
      expect(copy.type, MessageType.text);
      expect(copy.senderRole, SenderRole.courier);
      expect(copy.senderId, 1);
      expect(copy.senderName, 'Ali');
      expect(copy.target, 'customer');
      expect(copy.status, MessageStatus.sent);
      expect(copy.createdAt, DateTime(2024, 1, 1));
      expect(copy.senderAvatar, isNull);
      expect(copy.audioUrl, isNull);
      expect(copy.imageUrl, isNull);
      expect(copy.latitude, isNull);
      expect(copy.replyToId, isNull);
    });
  });

  // ── ChatConversation copyWith individual fields ──
  group('ChatConversation copyWith individual fields', () {
    final base = ChatConversation(
      orderId: 1,
      target: 'customer',
      targetName: 'Client',
      unreadCount: 0,
      updatedAt: DateTime(2025, 1, 1),
    );

    test('copyWith updates orderId only', () {
      final copy = base.copyWith(orderId: 99);
      expect(copy.orderId, 99);
      expect(copy.targetName, 'Client');
    });

    test('copyWith updates target only', () {
      final copy = base.copyWith(target: 'pharmacy');
      expect(copy.target, 'pharmacy');
    });

    test('copyWith updates targetName only', () {
      final copy = base.copyWith(targetName: 'Pharmacie');
      expect(copy.targetName, 'Pharmacie');
    });

    test('copyWith updates targetAvatar only', () {
      final copy = base.copyWith(targetAvatar: 'https://avatar.jpg');
      expect(copy.targetAvatar, 'https://avatar.jpg');
    });

    test('copyWith updates lastMessage only', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Hi',
        type: MessageType.text,
        senderRole: SenderRole.customer,
        senderId: 5,
        senderName: 'Client',
        target: 'courier',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
      );
      final copy = base.copyWith(lastMessage: msg);
      expect(copy.lastMessage?.content, 'Hi');
    });

    test('copyWith updates updatedAt only', () {
      final newDate = DateTime(2026, 1, 1);
      final copy = base.copyWith(updatedAt: newDate);
      expect(copy.updatedAt, newDate);
    });

    test('copyWith preserves all when no changes', () {
      final copy = base.copyWith();
      expect(copy.orderId, 1);
      expect(copy.target, 'customer');
      expect(copy.targetName, 'Client');
      expect(copy.unreadCount, 0);
      expect(copy.isTyping, false);
      expect(copy.targetAvatar, isNull);
      expect(copy.lastMessage, isNull);
    });
  });

  // ── MessageType enum values ──────────────────────
  group('MessageType enum', () {
    test('has 6 values', () {
      expect(MessageType.values.length, 6);
    });

    test('text round-trips through fromString', () {
      expect(MessageTypeExtension.fromString('text'), MessageType.text);
    });
  });

  // ── MessageStatus enum values ────────────────────
  group('MessageStatus enum', () {
    test('has 5 values', () {
      expect(MessageStatus.values.length, 5);
    });

    test('delivered color is grey', () {
      expect(MessageStatus.delivered.color, Colors.grey);
    });

    test('sent color is grey', () {
      expect(MessageStatus.sent.color, Colors.grey);
    });
  });

  // ── SenderRole enum values ──────────────────────
  group('SenderRole enum', () {
    test('has 4 values', () {
      expect(SenderRole.values.length, 4);
    });
  });

  // ── TypingStatus isExpired edge cases ───────────
  group('TypingStatus isExpired edge cases', () {
    test('exactly 5 seconds ago is not expired', () {
      final ts = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 42,
        senderName: 'Test',
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      // 5 seconds is NOT > 5, so should be false
      expect(ts.isExpired, false);
    });

    test('6 seconds ago is expired', () {
      final ts = TypingStatus(
        orderId: 1,
        target: 'customer',
        senderRole: SenderRole.courier,
        senderId: 42,
        senderName: 'Test',
        startedAt: DateTime.now().subtract(const Duration(seconds: 6)),
      );
      expect(ts.isExpired, true);
    });
  });

  // ── QuickReply constructor ──────────────────────
  group('QuickReply constructor', () {
    test('creates with all fields', () {
      const reply = QuickReply(
        id: 'custom',
        text: 'Custom reply',
        icon: Icons.message,
        category: 'custom_cat',
      );
      expect(reply.id, 'custom');
      expect(reply.text, 'Custom reply');
      expect(reply.icon, Icons.message);
      expect(reply.category, 'custom_cat');
    });

    test('creates with minimal fields', () {
      const reply = QuickReply(id: 'min', text: 'Min');
      expect(reply.id, 'min');
      expect(reply.text, 'Min');
      expect(reply.icon, isNull);
      expect(reply.category, isNull);
    });
  });

  // ── EnhancedChatMessage toJson conditional fields ──
  group('EnhancedChatMessage toJson conditional fields', () {
    final base = EnhancedChatMessage(
      id: 'msg1',
      content: 'Hello',
      type: MessageType.text,
      senderRole: SenderRole.courier,
      senderId: 1,
      senderName: 'Ali',
      target: 'customer',
      status: MessageStatus.sent,
      createdAt: DateTime(2024, 1, 1),
    );

    test('toJson excludes null senderAvatar', () {
      final json = base.toJson();
      expect(json.containsKey('sender_avatar'), false);
    });

    test('toJson includes senderAvatar when set', () {
      final msg = base.copyWith(senderAvatar: 'https://avatar.jpg');
      final json = msg.toJson();
      expect(json['sender_avatar'], 'https://avatar.jpg');
    });

    test('toJson excludes null metadata', () {
      final json = base.toJson();
      expect(json.containsKey('metadata'), false);
    });

    test('toJson includes metadata when set', () {
      final msg = base.copyWith(metadata: {'key': 'val'});
      final json = msg.toJson();
      expect(json['metadata'], {'key': 'val'});
    });

    test('toJson excludes null audioUrl', () {
      final json = base.toJson();
      expect(json.containsKey('audio_url'), false);
    });

    test('toJson includes audioUrl when set', () {
      final msg = base.copyWith(audioUrl: 'https://audio.mp3');
      final json = msg.toJson();
      expect(json['audio_url'], 'https://audio.mp3');
    });

    test('toJson excludes null audioDuration', () {
      final json = base.toJson();
      expect(json.containsKey('audio_duration'), false);
    });

    test('toJson includes audioDuration in milliseconds', () {
      final msg = base.copyWith(audioDuration: const Duration(seconds: 5));
      final json = msg.toJson();
      expect(json['audio_duration'], 5000);
    });

    test('toJson excludes null imageUrl', () {
      final json = base.toJson();
      expect(json.containsKey('image_url'), false);
    });

    test('toJson includes imageUrl when set', () {
      final msg = base.copyWith(imageUrl: 'https://img.jpg');
      final json = msg.toJson();
      expect(json['image_url'], 'https://img.jpg');
    });

    test('toJson excludes null thumbnailUrl', () {
      final json = base.toJson();
      expect(json.containsKey('thumbnail_url'), false);
    });

    test('toJson includes thumbnailUrl when set', () {
      final msg = base.copyWith(thumbnailUrl: 'https://thumb.jpg');
      final json = msg.toJson();
      expect(json['thumbnail_url'], 'https://thumb.jpg');
    });

    test('toJson excludes null latitude/longitude', () {
      final json = base.toJson();
      expect(json.containsKey('latitude'), false);
      expect(json.containsKey('longitude'), false);
    });

    test('toJson includes latitude/longitude when set', () {
      final msg = base.copyWith(latitude: 5.35, longitude: -3.95);
      final json = msg.toJson();
      expect(json['latitude'], 5.35);
      expect(json['longitude'], -3.95);
    });

    test('toJson excludes null locationAddress', () {
      final json = base.toJson();
      expect(json.containsKey('location_address'), false);
    });

    test('toJson includes locationAddress when set', () {
      final msg = base.copyWith(locationAddress: 'Cocody');
      final json = msg.toJson();
      expect(json['location_address'], 'Cocody');
    });

    test('toJson excludes null replyToId/replyToContent', () {
      final json = base.toJson();
      expect(json.containsKey('reply_to_id'), false);
      expect(json.containsKey('reply_to_content'), false);
    });

    test('toJson includes replyToId/replyToContent when set', () {
      final msg = base.copyWith(replyToId: 'msg0', replyToContent: 'prev');
      final json = msg.toJson();
      expect(json['reply_to_id'], 'msg0');
      expect(json['reply_to_content'], 'prev');
    });

    test('toJson always includes content/type/sender fields', () {
      final json = base.toJson();
      expect(json.containsKey('content'), true);
      expect(json.containsKey('type'), true);
      expect(json.containsKey('sender_type'), true);
      expect(json.containsKey('sender_id'), true);
      expect(json.containsKey('sender_name'), true);
      expect(json.containsKey('target'), true);
      expect(json.containsKey('status'), true);
    });

    test('toJson includes readAt when set', () {
      final readTime = DateTime(2025, 6, 1);
      final msg = base.copyWith(readAt: readTime);
      final json = msg.toJson();
      expect(json.containsKey('read_at'), true);
    });

    test('toJson excludes null readAt', () {
      final json = base.toJson();
      expect(json.containsKey('read_at'), false);
    });
  });

  // ── EnhancedChatMessage fromJson type-specific ──
  group('EnhancedChatMessage fromJson type-specific', () {
    test('fromJson voice message with audio fields', () {
      final json = <String, dynamic>{
        'content': 'Voice message',
        'type': 'voice',
        'sender_type': 'courier',
        'sender_id': 1,
        'sender_name': 'Ali',
        'target': 'customer',
        'status': 'sent',
        'created_at': '2025-01-01T00:00:00Z',
        'audio_url': 'https://audio.mp3',
        'audio_duration': 30000,
      };
      final m = EnhancedChatMessage.fromJson(json, 'voice1');
      expect(m.type, MessageType.voice);
      expect(m.audioUrl, 'https://audio.mp3');
      expect(m.audioDuration, const Duration(seconds: 30));
    });

    test('fromJson location message with coordinates', () {
      final json = <String, dynamic>{
        'content': 'Location shared',
        'type': 'location',
        'sender_type': 'customer',
        'sender_id': 2,
        'sender_name': 'Client',
        'target': 'courier',
        'status': 'delivered',
        'created_at': '2025-01-01T00:00:00Z',
        'latitude': 48.8566,
        'longitude': 2.3522,
        'location_address': 'Paris, France',
      };
      final m = EnhancedChatMessage.fromJson(json, 'loc1');
      expect(m.type, MessageType.location);
      expect(m.latitude, 48.8566);
      expect(m.longitude, 2.3522);
      expect(m.locationAddress, 'Paris, France');
    });

    test('fromJson quick_reply message', () {
      final json = <String, dynamic>{
        'content': 'Je suis en route !',
        'type': 'quick_reply',
        'sender_type': 'courier',
        'sender_id': 1,
        'sender_name': 'Ali',
        'target': 'customer',
        'status': 'sent',
        'created_at': '2025-01-01T00:00:00Z',
      };
      final m = EnhancedChatMessage.fromJson(json, 'qr1');
      expect(m.type, MessageType.quickReply);
    });

    test('fromJson system message', () {
      final m = EnhancedChatMessage.fromJson(<String, dynamic>{
        'type': 'system',
        'sender_type': 'system',
        'content': 'Delivery assigned',
        'created_at': '2025-01-01T00:00:00Z',
      }, 'sys1');
      expect(m.type, MessageType.system);
      expect(m.senderRole, SenderRole.system);
    });

    test('fromJson with reply fields', () {
      final json = <String, dynamic>{
        'content': 'Reply here',
        'type': 'text',
        'sender_type': 'courier',
        'sender_id': 1,
        'sender_name': 'Ali',
        'target': 'customer',
        'status': 'sent',
        'created_at': '2025-01-01T00:00:00Z',
        'reply_to_id': 'original_msg',
        'reply_to_content': 'This was the original message',
      };
      final m = EnhancedChatMessage.fromJson(json, 'reply1');
      expect(m.replyToId, 'original_msg');
      expect(m.replyToContent, 'This was the original message');
    });
  });

  // ── MessageType roundtrip ──
  group('MessageType value/fromString roundtrip', () {
    for (final type in MessageType.values) {
      test('${type.name} round-trips', () {
        final value = type.value;
        final parsed = MessageTypeExtension.fromString(value);
        expect(parsed, type);
      });
    }
  });

  // ── MessageStatus value/fromString roundtrip ──
  group('MessageStatus value/fromString roundtrip', () {
    for (final status in MessageStatus.values) {
      test('${status.name} round-trips', () {
        final value = status.value;
        final parsed = MessageStatusExtension.fromString(value);
        expect(parsed, status);
      });
    }
  });

  // ── SenderRole value/fromString roundtrip ──
  group('SenderRole value/fromString roundtrip', () {
    for (final role in SenderRole.values) {
      test('${role.name} round-trips', () {
        final value = role.value;
        final parsed = SenderRoleExtension.fromString(value);
        expect(parsed, role);
      });
    }
  });

  // ── QuickReply byCategory exhaustive ──
  group('QuickReply byCategory exhaustive', () {
    test('status category has 3 replies', () {
      expect(QuickReply.byCategory['status']!.length, 3);
    });

    test('delay category has 1 reply', () {
      expect(QuickReply.byCategory['delay']!.length, 1);
    });

    test('contact category has 1 reply', () {
      expect(QuickReply.byCategory['contact']!.length, 1);
    });

    test('question category has 1 reply', () {
      expect(QuickReply.byCategory['question']!.length, 1);
    });

    test('closing category has 1 reply', () {
      expect(QuickReply.byCategory['closing']!.length, 1);
    });

    test('problem category has 1 reply', () {
      expect(QuickReply.byCategory['problem']!.length, 1);
    });

    test('all defaults have unique ids', () {
      final ids = QuickReply.defaults.map((r) => r.id).toSet();
      expect(ids.length, QuickReply.defaults.length);
    });

    test('each default has non-empty content', () {
      for (final reply in QuickReply.defaults) {
        expect(reply.id, isNotEmpty);
        expect(reply.text, isNotEmpty);
      }
    });
  });

  // ── ChatConversation additional ──
  group('ChatConversation additional', () {
    test('creates with all optional fields', () {
      final msg = EnhancedChatMessage(
        id: 'msg1',
        content: 'Last',
        type: MessageType.text,
        senderRole: SenderRole.customer,
        senderId: 5,
        senderName: 'Client',
        target: 'courier',
        status: MessageStatus.read,
        createdAt: DateTime.now(),
      );
      final conv = ChatConversation(
        orderId: 100,
        target: 'customer',
        targetName: 'Client Test',
        targetAvatar: 'https://avatar.jpg',
        lastMessage: msg,
        unreadCount: 5,
        updatedAt: DateTime.now(),
        isTyping: true,
      );
      expect(conv.targetAvatar, 'https://avatar.jpg');
      expect(conv.lastMessage?.content, 'Last');
      expect(conv.isTyping, true);
    });

    test('copyWith updates isTyping only', () {
      final conv = ChatConversation(
        orderId: 1,
        target: 'customer',
        targetName: 'Client',
        unreadCount: 0,
        updatedAt: DateTime.now(),
      );
      final copy = conv.copyWith(isTyping: true);
      expect(copy.isTyping, true);
      expect(copy.unreadCount, 0);
    });
  });
}
