import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/orders/data/models/chat_message.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------
  group('ChatMessage.fromJson', () {
    test('parses all required fields', () {
      final json = <String, dynamic>{
        'id': '1',
        'sender_id': 'u42',
        'sender_type': 'customer',
        'content': 'Bonjour',
        'timestamp': '2025-03-14T10:00:00.000Z',
        'is_read': true,
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.id, '1');
      expect(msg.senderId, 'u42');
      expect(msg.senderType, 'customer');
      expect(msg.content, 'Bonjour');
      expect(msg.isRead, isTrue);
      expect(msg.timestamp.year, 2025);
    });

    test('converts int id to string', () {
      final json = <String, dynamic>{
        'id': 99,
        'sender_id': '1',
        'sender_type': 'courier',
        'content': 'OK',
        'timestamp': '2025-01-01T00:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.id, '99');
    });

    test('defaults senderType to customer when absent', () {
      final json = <String, dynamic>{
        'id': '1',
        'sender_id': '1',
        'content': 'text',
        'timestamp': '2025-01-01T00:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.senderType, 'customer');
    });

    test('defaults isRead to false when absent', () {
      final json = <String, dynamic>{
        'id': '1',
        'sender_id': '1',
        'sender_type': 'courier',
        'content': 'text',
        'timestamp': '2025-01-01T00:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.isRead, isFalse);
    });

    test('falls back to DateTime.now for invalid timestamp', () {
      final before = DateTime.now();
      final json = <String, dynamic>{
        'id': '1',
        'sender_id': '1',
        'sender_type': 'customer',
        'content': 'text',
        'timestamp': 'invalid-date',
      };
      final msg = ChatMessage.fromJson(json);
      final after = DateTime.now();
      expect(
        msg.timestamp.isAfter(before) || msg.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        msg.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('falls back to DateTime.now when timestamp is null', () {
      final json = <String, dynamic>{
        'id': '1',
        'sender_id': '1',
        'sender_type': 'customer',
        'content': 'text',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.timestamp, isA<DateTime>());
    });
  });

  // ---------------------------------------------------------------------------
  // fromFirestore
  // ---------------------------------------------------------------------------
  group('ChatMessage.fromFirestore', () {
    test('parses Firestore document', () {
      final data = <String, dynamic>{
        'sender_id': 'courier42',
        'sender_role': 'courier',
        'content': 'En route',
        'created_at': '2025-03-14T12:00:00.000Z',
        'is_read': false,
      };
      final msg = ChatMessage.fromFirestore(data, 'doc123');
      expect(msg.id, 'doc123');
      expect(msg.senderId, 'courier42');
      expect(msg.senderType, 'courier');
      expect(msg.content, 'En route');
      expect(msg.isRead, isFalse);
    });

    test('maps sender_role=customer to senderType=customer', () {
      final data = <String, dynamic>{
        'sender_id': 'u1',
        'sender_role': 'customer',
        'content': 'Merci',
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final msg = ChatMessage.fromFirestore(data, 'doc456');
      expect(msg.senderType, 'customer');
    });

    test('accepts DateTime directly as created_at', () {
      final dt = DateTime(2025, 6, 15, 8, 0);
      final data = <String, dynamic>{
        'sender_id': 'u1',
        'sender_role': 'customer',
        'content': 'text',
        'created_at': dt,
      };
      final msg = ChatMessage.fromFirestore(data, 'docX');
      expect(msg.timestamp, dt);
    });

    test('falls back to DateTime.now when created_at absent', () {
      final data = <String, dynamic>{
        'sender_id': 'u1',
        'sender_role': 'courier',
        'content': 'text',
      };
      final msg = ChatMessage.fromFirestore(data, 'docY');
      expect(msg.timestamp, isA<DateTime>());
    });
  });

  // ---------------------------------------------------------------------------
  // toJson
  // ---------------------------------------------------------------------------
  group('ChatMessage.toJson', () {
    test('serializes all fields', () {
      final msg = ChatMessage(
        id: 'abc',
        senderId: 'u7',
        senderType: 'customer',
        content: 'Salut',
        timestamp: DateTime(2025, 1, 2, 3, 4, 5),
        isRead: true,
      );
      final json = msg.toJson();
      expect(json['id'], 'abc');
      expect(json['sender_id'], 'u7');
      expect(json['sender_type'], 'customer');
      expect(json['content'], 'Salut');
      expect(json['is_read'], isTrue);
      expect(json['timestamp'], '2025-01-02T03:04:05.000');
    });
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------
  group('ChatMessage computed properties', () {
    test('isFromCustomer returns true for customer sender', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'text',
        timestamp: DateTime.now(),
      );
      expect(msg.isFromCustomer, isTrue);
      expect(msg.isFromCourier, isFalse);
    });

    test('isFromCourier returns true for courier sender', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'c1',
        senderType: 'courier',
        content: 'text',
        timestamp: DateTime.now(),
      );
      expect(msg.isFromCourier, isTrue);
      expect(msg.isFromCustomer, isFalse);
    });

    test('isMine is alias for isFromCustomer', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'text',
        timestamp: DateTime.now(),
      );
      expect(msg.isMine, msg.isFromCustomer);
    });

    test('message is alias for content', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'Hello',
        timestamp: DateTime.now(),
      );
      expect(msg.message, 'Hello');
    });

    test('createdAt is alias for timestamp', () {
      final dt = DateTime(2025, 3, 1);
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'Hi',
        timestamp: dt,
      );
      expect(msg.createdAt, dt);
    });

    test('readAt returns timestamp when isRead=true', () {
      final dt = DateTime(2025, 3, 1);
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'Hi',
        timestamp: dt,
        isRead: true,
      );
      expect(msg.readAt, dt);
    });

    test('readAt returns null when isRead=false', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'u1',
        senderType: 'customer',
        content: 'Hi',
        timestamp: DateTime.now(),
        isRead: false,
      );
      expect(msg.readAt, isNull);
    });
  });
}
