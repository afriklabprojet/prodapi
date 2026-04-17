import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/support_ticket.dart';

void main() {
  group('SupportTicket', () {
    test('fromJson with full data', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'subject': 'Commande retardée',
        'description': 'Ma livraison n\'arrive pas',
        'category': 'delivery',
        'priority': 'high',
        'status': 'open',
        'reference': 'TK-001',
        'resolved_at': null,
        'created_at': '2026-02-13T10:00:00Z',
        'updated_at': '2026-02-13T10:00:00Z',
        'messages_count': 3,
        'unread_count': 1,
        'latest_message': {
          'id': 5,
          'support_ticket_id': 1,
          'user_id': 10,
          'message': 'Dernier message',
          'is_from_support': false,
          'created_at': '2026-02-13T10:30:00Z',
        },
      };
      final ticket = SupportTicket.fromJson(json);
      expect(ticket.id, 1);
      expect(ticket.userId, 10);
      expect(ticket.subject, 'Commande retardée');
      expect(ticket.category, 'delivery');
      expect(ticket.priority, 'high');
      expect(ticket.status, 'open');
      expect(ticket.reference, 'TK-001');
      expect(ticket.messagesCount, 3);
      expect(ticket.unreadCount, 1);
      expect(ticket.latestMessage, isNotNull);
      expect(ticket.latestMessage!.message, 'Dernier message');
    });

    test('fromJson with minimal data', () {
      final json = {
        'id': 2,
        'user_id': 10,
        'subject': 'Test',
        'description': 'Desc',
        'category': 'other',
        'priority': 'low',
        'status': 'closed',
      };
      final ticket = SupportTicket.fromJson(json);
      expect(ticket.reference, isNull);
      expect(ticket.latestMessage, isNull);
      expect(ticket.messages, isNull);
    });

    test('copyWith creates modified copy', () {
      final ticket = SupportTicket.fromJson({
        'id': 1,
        'user_id': 10,
        'subject': 'Test',
        'description': 'Desc',
        'category': 'other',
        'priority': 'low',
        'status': 'open',
      });
      final resolved = ticket.copyWith(status: 'resolved');
      expect(resolved.status, 'resolved');
      expect(resolved.subject, 'Test');
    });
  });

  group('SupportMessage', () {
    test('fromJson with full data', () {
      final json = {
        'id': 5,
        'support_ticket_id': 1,
        'user_id': 10,
        'message': 'Bonjour, j\'ai un problème',
        'attachment': 'https://example.com/file.pdf',
        'is_from_support': true,
        'read_at': '2026-02-13T10:30:00Z',
        'created_at': '2026-02-13T10:00:00Z',
        'updated_at': '2026-02-13T10:00:00Z',
        'user': {'id': 10, 'name': 'Ali'},
      };
      final msg = SupportMessage.fromJson(json);
      expect(msg.id, 5);
      expect(msg.supportTicketId, 1);
      expect(msg.message, contains('problème'));
      expect(msg.attachment, isNotNull);
      expect(msg.isFromSupport, true);
      expect(msg.user, isNotNull);
      expect(msg.user!.name, 'Ali');
    });

    test('fromJson defaults is_from_support to false', () {
      final json = {
        'id': 6,
        'support_ticket_id': 1,
        'user_id': 10,
        'message': 'Test',
      };
      final msg = SupportMessage.fromJson(json);
      expect(msg.isFromSupport, false);
    });
  });

  group('SupportUser', () {
    test('fromJson works', () {
      final user = SupportUser.fromJson({'id': 1, 'name': 'Admin'});
      expect(user.id, 1);
      expect(user.name, 'Admin');
    });
  });

  group('SupportStats', () {
    test('fromJson with data', () {
      final stats = SupportStats.fromJson({
        'total': 10,
        'open': 3,
        'resolved': 5,
        'closed': 2,
      });
      expect(stats.total, 10);
      expect(stats.open, 3);
      expect(stats.resolved, 5);
      expect(stats.closed, 2);
    });

    test('fromJson defaults to zero', () {
      final stats = SupportStats.fromJson(<String, dynamic>{});
      expect(stats.total, 0);
      expect(stats.open, 0);
    });
  });

  group('TicketCategory', () {
    test('fromValue returns correct category', () {
      expect(TicketCategory.fromValue('order'), TicketCategory.order);
      expect(TicketCategory.fromValue('delivery'), TicketCategory.delivery);
      expect(TicketCategory.fromValue('payment'), TicketCategory.payment);
      expect(TicketCategory.fromValue('account'), TicketCategory.account);
      expect(TicketCategory.fromValue('app_bug'), TicketCategory.appBug);
    });

    test('fromValue defaults to other for unknown', () {
      expect(TicketCategory.fromValue('unknown'), TicketCategory.other);
    });

    test('has correct value and label', () {
      expect(TicketCategory.order.value, 'order');
      expect(TicketCategory.order.label, 'Commande');
    });
  });

  group('TicketPriority', () {
    test('fromValue returns correct priority', () {
      expect(TicketPriority.fromValue('low'), TicketPriority.low);
      expect(TicketPriority.fromValue('medium'), TicketPriority.medium);
      expect(TicketPriority.fromValue('high'), TicketPriority.high);
    });

    test('fromValue defaults to medium for unknown', () {
      expect(TicketPriority.fromValue('urgent'), TicketPriority.medium);
    });
  });

  group('TicketStatus', () {
    test('fromValue returns correct status', () {
      expect(TicketStatus.fromValue('open'), TicketStatus.open);
      expect(TicketStatus.fromValue('in_progress'), TicketStatus.inProgress);
      expect(TicketStatus.fromValue('resolved'), TicketStatus.resolved);
      expect(TicketStatus.fromValue('closed'), TicketStatus.closed);
    });

    test('fromValue defaults to open for unknown', () {
      expect(TicketStatus.fromValue('deleted'), TicketStatus.open);
    });

    test('has correct value and label', () {
      expect(TicketStatus.resolved.value, 'resolved');
      expect(TicketStatus.resolved.label, 'Résolu');
    });
  });

  // --- toJson tests ---

  group('SupportTicket toJson', () {
    test('toJson serializes all fields', () {
      const ticket = SupportTicket(
        id: 1,
        userId: 10,
        subject: 'Test Subject',
        description: 'Test Description',
        category: 'delivery',
        priority: 'high',
        status: 'open',
        reference: 'TK-001',
        resolvedAt: '2026-02-14T10:00:00Z',
        createdAt: '2026-02-13T10:00:00Z',
        updatedAt: '2026-02-13T12:00:00Z',
        messagesCount: 5,
        unreadCount: 2,
      );
      final json = ticket.toJson();
      expect(json['id'], 1);
      expect(json['user_id'], 10);
      expect(json['subject'], 'Test Subject');
      expect(json['description'], 'Test Description');
      expect(json['category'], 'delivery');
      expect(json['priority'], 'high');
      expect(json['status'], 'open');
      expect(json['reference'], 'TK-001');
      expect(json['resolved_at'], '2026-02-14T10:00:00Z');
      expect(json['created_at'], '2026-02-13T10:00:00Z');
      expect(json['updated_at'], '2026-02-13T12:00:00Z');
      expect(json['messages_count'], 5);
      expect(json['unread_count'], 2);
      expect(json['latest_message'], isNull);
      expect(json['messages'], isNull);
    });

    test('toJson with latestMessage and messages', () {
      const ticket = SupportTicket(
        id: 2,
        userId: 20,
        subject: 'With Messages',
        description: 'Has messages',
        category: 'payment',
        priority: 'medium',
        status: 'in_progress',
        latestMessage: SupportMessage(
          id: 10,
          supportTicketId: 2,
          userId: 20,
          message: 'Latest',
        ),
        messages: [
          SupportMessage(
            id: 10,
            supportTicketId: 2,
            userId: 20,
            message: 'First',
          ),
          SupportMessage(
            id: 11,
            supportTicketId: 2,
            userId: 30,
            message: 'Second',
            isFromSupport: true,
          ),
        ],
      );
      final json = ticket.toJson();
      expect(json['latest_message'], isNotNull);
      expect(json['messages'], isA<List>());
      expect((json['messages'] as List).length, 2);
    });

    test('toJson fromJson roundtrip', () {
      final original = SupportTicket.fromJson({
        'id': 3,
        'user_id': 30,
        'subject': 'Roundtrip',
        'description': 'Test roundtrip',
        'category': 'account',
        'priority': 'low',
        'status': 'resolved',
        'reference': 'TK-003',
        'messages_count': 2,
        'unread_count': 0,
      });
      final json = original.toJson();
      final restored = SupportTicket.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.subject, original.subject);
      expect(restored.category, original.category);
      expect(restored.reference, original.reference);
    });
  });

  group('SupportMessage toJson', () {
    test('toJson serializes all fields', () {
      const msg = SupportMessage(
        id: 5,
        supportTicketId: 1,
        userId: 10,
        message: 'Hello support',
        attachment: 'https://example.com/img.png',
        isFromSupport: true,
        readAt: '2026-02-13T11:00:00Z',
        createdAt: '2026-02-13T10:00:00Z',
        updatedAt: '2026-02-13T10:30:00Z',
        user: SupportUser(id: 10, name: 'Jean'),
      );
      final json = msg.toJson();
      expect(json['id'], 5);
      expect(json['support_ticket_id'], 1);
      expect(json['user_id'], 10);
      expect(json['message'], 'Hello support');
      expect(json['attachment'], 'https://example.com/img.png');
      expect(json['is_from_support'], true);
      expect(json['read_at'], '2026-02-13T11:00:00Z');
      expect(json['created_at'], '2026-02-13T10:00:00Z');
      expect(json['updated_at'], '2026-02-13T10:30:00Z');
      expect(json['user'], isNotNull);
    });

    test('toJson with minimal data', () {
      const msg = SupportMessage(
        id: 6,
        supportTicketId: 2,
        userId: 20,
        message: 'Minimal',
      );
      final json = msg.toJson();
      expect(json['attachment'], isNull);
      expect(json['is_from_support'], false);
      expect(json['read_at'], isNull);
      expect(json['user'], isNull);
    });
  });

  group('SupportUser toJson', () {
    test('toJson serializes correctly', () {
      const user = SupportUser(id: 1, name: 'Admin');
      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Admin');
    });

    test('toJson fromJson roundtrip', () {
      const original = SupportUser(id: 42, name: 'Support Agent');
      final json = original.toJson();
      final restored = SupportUser.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });
  });

  group('SupportStats toJson', () {
    test('toJson serializes all fields', () {
      const stats = SupportStats(total: 15, open: 5, resolved: 8, closed: 2);
      final json = stats.toJson();
      expect(json['total'], 15);
      expect(json['open'], 5);
      expect(json['resolved'], 8);
      expect(json['closed'], 2);
    });

    test('toJson fromJson roundtrip', () {
      const original = SupportStats(total: 30, open: 10, resolved: 15, closed: 5);
      final json = original.toJson();
      final restored = SupportStats.fromJson(json);
      expect(restored.total, original.total);
      expect(restored.open, original.open);
      expect(restored.resolved, original.resolved);
      expect(restored.closed, original.closed);
    });
  });
}
