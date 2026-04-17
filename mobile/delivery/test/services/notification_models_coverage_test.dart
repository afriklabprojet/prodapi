import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/notification_service.dart';
import 'package:courier/data/models/support_ticket.dart';

void main() {
  // ════════════════════════════════════════════
  // NotificationActions constants
  // ════════════════════════════════════════════
  group('NotificationActions', () {
    test(
      'acceptOrder',
      () => expect(NotificationActions.acceptOrder, 'ACCEPT_ORDER'),
    );
    test(
      'declineOrder',
      () => expect(NotificationActions.declineOrder, 'DECLINE_ORDER'),
    );
    test(
      'viewDetails',
      () => expect(NotificationActions.viewDetails, 'VIEW_DETAILS'),
    );
  });

  // ════════════════════════════════════════════
  // NotificationActionResult
  // ════════════════════════════════════════════
  group('NotificationActionResult', () {
    test('constructor with required only', () {
      final result = NotificationActionResult(actionId: 'ACCEPT_ORDER');
      expect(result.actionId, 'ACCEPT_ORDER');
      expect(result.orderId, null);
      expect(result.payload, null);
    });

    test('constructor with all fields', () {
      final result = NotificationActionResult(
        actionId: 'VIEW_DETAILS',
        orderId: '42',
        payload: {'type': 'new_order', 'priority': 'high'},
      );
      expect(result.actionId, 'VIEW_DETAILS');
      expect(result.orderId, '42');
      expect(result.payload!['type'], 'new_order');
      expect(result.payload!['priority'], 'high');
    });
  });

  // ════════════════════════════════════════════
  // FAQItem
  // ════════════════════════════════════════════
  group('FAQItem', () {
    test('constructor', () {
      const item = FAQItem(
        question: 'How to deliver?',
        answer: 'Follow the steps...',
        icon: 'delivery',
      );
      expect(item.question, 'How to deliver?');
      expect(item.answer, 'Follow the steps...');
      expect(item.icon, 'delivery');
    });

    test('fromJson with all fields', () {
      final item = FAQItem.fromJson({
        'question': 'Comment livrer?',
        'answer': 'Suivre les etapes',
        'icon': 'truck',
      });
      expect(item.question, 'Comment livrer?');
      expect(item.answer, 'Suivre les etapes');
      expect(item.icon, 'truck');
    });

    test('fromJson with defaults', () {
      final item = FAQItem.fromJson({});
      expect(item.question, '');
      expect(item.answer, '');
      expect(item.icon, 'help');
    });
  });
}
