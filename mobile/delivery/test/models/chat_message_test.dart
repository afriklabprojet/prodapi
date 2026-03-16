import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('fromJson with standard fields', () {
      final json = {
        'id': 1,
        'content': 'Bonjour',
        'is_me': true,
        'sender_name': 'Jean',
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.id, 1);
      expect(msg.content, 'Bonjour');
      expect(msg.isMe, isTrue);
      expect(msg.senderName, 'Jean');
      expect(msg.createdAt, DateTime.utc(2025, 1, 15, 10, 30));
    });

    test('fromJson normalizes is_mine → isMe', () {
      final json = {
        'id': 2,
        'content': 'Salut',
        'is_mine': true,
        'sender_name': 'Paul',
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.isMe, isTrue);
    });

    test('fromJson normalizes message → content', () {
      final json = {
        'id': 3,
        'message': 'Contenu alternatif',
        'is_me': false,
        'sender_name': 'Marie',
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.content, 'Contenu alternatif');
    });

    test('fromJson handles string id', () {
      final json = {
        'id': '42',
        'content': 'Test',
        'is_me': false,
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 42);
    });

    test('fromJson defaults for missing fields', () {
      final json = <String, dynamic>{
        'id': 1,
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.content, '');
      expect(msg.isMe, isFalse);
      expect(msg.senderName, 'Inconnu');
    });

    test('copyWith creates modified copy', () {
      final original = ChatMessage(
        id: 1,
        content: 'Original',
        isMe: true,
        senderName: 'Jean',
        createdAt: DateTime(2025, 1, 1),
      );

      final modified = original.copyWith(content: 'Modifié');

      expect(modified.id, 1);
      expect(modified.content, 'Modifié');
      expect(original.content, 'Original'); // Original unchanged
    });

    test('equality works for identical values', () {
      final a = ChatMessage(
        id: 1,
        content: 'Hello',
        isMe: true,
        senderName: 'X',
        createdAt: DateTime(2025, 1, 1),
      );
      final b = ChatMessage(
        id: 1,
        content: 'Hello',
        isMe: true,
        senderName: 'X',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
