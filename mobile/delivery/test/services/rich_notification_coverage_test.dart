import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:courier/core/services/rich_notification_service.dart';

void main() {
  // ════════════════════════════════════════════
  // NotificationType enum
  // ════════════════════════════════════════════
  group('NotificationType', () {
    test('has 8 values', () {
      expect(NotificationType.values.length, 8);
    });

    test('channelId for all types', () {
      expect(NotificationType.newOrder.channelId, 'new_orders_high');
      expect(NotificationType.orderAssigned.channelId, 'order_assigned');
      expect(NotificationType.urgent.channelId, 'urgent_alerts');
      expect(NotificationType.reminder.channelId, 'reminders');
      expect(NotificationType.earnings.channelId, 'earnings');
      expect(NotificationType.system.channelId, 'system');
      expect(NotificationType.chat.channelId, 'chat_messages');
      expect(NotificationType.promo.channelId, 'promotions');
    });

    test('channelName for all types', () {
      expect(NotificationType.newOrder.channelName, 'Nouvelles commandes');
      expect(NotificationType.orderAssigned.channelName, 'Commandes assignées');
      expect(NotificationType.urgent.channelName, 'Alertes urgentes');
      expect(NotificationType.reminder.channelName, 'Rappels');
      expect(NotificationType.earnings.channelName, 'Gains & revenus');
      expect(NotificationType.system.channelName, 'Système');
      expect(NotificationType.chat.channelName, 'Messages');
      expect(NotificationType.promo.channelName, 'Promotions');
    });

    test('channelDescription for all types', () {
      expect(
        NotificationType.newOrder.channelDescription,
        contains('nouvelles livraisons'),
      );
      expect(
        NotificationType.orderAssigned.channelDescription,
        contains('attribuée'),
      );
      expect(
        NotificationType.urgent.channelDescription,
        contains('importantes'),
      );
      expect(NotificationType.reminder.channelDescription, contains('Rappels'));
      expect(NotificationType.earnings.channelDescription, contains('gains'));
      expect(
        NotificationType.system.channelDescription,
        contains('mises à jour'),
      );
      expect(NotificationType.chat.channelDescription, contains('pharmacies'));
      expect(NotificationType.promo.channelDescription, contains('promotions'));
    });

    test('importance for all types', () {
      expect(NotificationType.newOrder.importance, Importance.max);
      expect(NotificationType.urgent.importance, Importance.max);
      expect(NotificationType.orderAssigned.importance, Importance.high);
      expect(NotificationType.chat.importance, Importance.high);
      expect(
        NotificationType.reminder.importance,
        Importance.defaultImportance,
      );
      expect(
        NotificationType.earnings.importance,
        Importance.defaultImportance,
      );
      expect(NotificationType.system.importance, Importance.low);
      expect(NotificationType.promo.importance, Importance.low);
    });

    test('priority for all types', () {
      expect(NotificationType.newOrder.priority, Priority.max);
      expect(NotificationType.urgent.priority, Priority.max);
      expect(NotificationType.orderAssigned.priority, Priority.high);
      expect(NotificationType.chat.priority, Priority.high);
      expect(NotificationType.reminder.priority, Priority.defaultPriority);
      expect(NotificationType.earnings.priority, Priority.defaultPriority);
      expect(NotificationType.system.priority, Priority.defaultPriority);
      expect(NotificationType.promo.priority, Priority.defaultPriority);
    });

    test('soundName for all types', () {
      expect(NotificationType.newOrder.soundName, 'notification_new_order');
      expect(NotificationType.urgent.soundName, 'notification_urgent');
      expect(NotificationType.earnings.soundName, 'notification_cash');
      expect(NotificationType.chat.soundName, 'notification_chat');
      expect(NotificationType.orderAssigned.soundName, 'default');
      expect(NotificationType.reminder.soundName, 'default');
      expect(NotificationType.system.soundName, 'default');
      expect(NotificationType.promo.soundName, 'default');
    });

    test('emoji for all types', () {
      expect(NotificationType.newOrder.emoji, '🚚');
      expect(NotificationType.orderAssigned.emoji, '✅');
      expect(NotificationType.urgent.emoji, '🚨');
      expect(NotificationType.reminder.emoji, '⏰');
      expect(NotificationType.earnings.emoji, '💰');
      expect(NotificationType.system.emoji, 'ℹ️');
      expect(NotificationType.chat.emoji, '💬');
      expect(NotificationType.promo.emoji, '🎁');
    });

    test('vibrationPattern for all types', () {
      expect(NotificationType.newOrder.vibrationPattern, isNotEmpty);
      expect(NotificationType.urgent.vibrationPattern, isNotEmpty);
      expect(NotificationType.earnings.vibrationPattern, isNotEmpty);
      expect(NotificationType.reminder.vibrationPattern, isNotEmpty);
      // newOrder is long pattern
      expect(NotificationType.newOrder.vibrationPattern.length, 6);
      // urgent is intense
      expect(NotificationType.urgent.vibrationPattern.length, 4);
    });
  });

  // ════════════════════════════════════════════
  // NotificationPreferences
  // ════════════════════════════════════════════
  group('NotificationPreferences', () {
    test('default constructor', () {
      const prefs = NotificationPreferences();
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.newOrdersEnabled, true);
      expect(prefs.chatEnabled, true);
      expect(prefs.earningsEnabled, true);
      expect(prefs.promosEnabled, false);
      expect(prefs.urgentEnabled, true);
      expect(prefs.selectedSound, 'default');
      expect(prefs.quietHoursEnabled, false);
      expect(prefs.quietHoursStart, 22);
      expect(prefs.quietHoursEnd, 7);
    });

    test('copyWith preserves values', () {
      const prefs = NotificationPreferences(
        soundEnabled: false,
        promosEnabled: true,
        quietHoursEnabled: true,
      );
      final copy = prefs.copyWith();
      expect(copy.soundEnabled, false);
      expect(copy.promosEnabled, true);
      expect(copy.quietHoursEnabled, true);
    });

    test('copyWith updates specific fields', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(
        soundEnabled: false,
        vibrationEnabled: false,
        selectedSound: 'custom',
        quietHoursStart: 20,
        quietHoursEnd: 8,
      );
      expect(copy.soundEnabled, false);
      expect(copy.vibrationEnabled, false);
      expect(copy.selectedSound, 'custom');
      expect(copy.quietHoursStart, 20);
      expect(copy.quietHoursEnd, 8);
      // Unchanged
      expect(copy.newOrdersEnabled, true);
    });

    test('copyWith updates all boolean fields', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(
        newOrdersEnabled: false,
        chatEnabled: false,
        earningsEnabled: false,
        promosEnabled: true,
        urgentEnabled: false,
        quietHoursEnabled: true,
      );
      expect(copy.newOrdersEnabled, false);
      expect(copy.chatEnabled, false);
      expect(copy.earningsEnabled, false);
      expect(copy.promosEnabled, true);
      expect(copy.urgentEnabled, false);
      expect(copy.quietHoursEnabled, true);
    });

    test('isQuietTime returns false when disabled', () {
      const prefs = NotificationPreferences(quietHoursEnabled: false);
      expect(prefs.isQuietTime, false);
    });

    test('toJson serializes all fields', () {
      const prefs = NotificationPreferences(
        soundEnabled: false,
        promosEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 6,
      );
      final json = prefs.toJson();
      expect(json['soundEnabled'], false);
      expect(json['promosEnabled'], true);
      expect(json['quietHoursStart'], 23);
      expect(json['quietHoursEnd'], 6);
      expect(json['vibrationEnabled'], true);
      expect(json['selectedSound'], 'default');
    });

    test('fromJson deserializes all fields', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': false,
        'vibrationEnabled': false,
        'newOrdersEnabled': false,
        'chatEnabled': false,
        'earningsEnabled': false,
        'promosEnabled': true,
        'urgentEnabled': false,
        'selectedSound': 'custom',
        'quietHoursEnabled': true,
        'quietHoursStart': 21,
        'quietHoursEnd': 8,
      });
      expect(prefs.soundEnabled, false);
      expect(prefs.vibrationEnabled, false);
      expect(prefs.newOrdersEnabled, false);
      expect(prefs.chatEnabled, false);
      expect(prefs.earningsEnabled, false);
      expect(prefs.promosEnabled, true);
      expect(prefs.urgentEnabled, false);
      expect(prefs.selectedSound, 'custom');
      expect(prefs.quietHoursEnabled, true);
      expect(prefs.quietHoursStart, 21);
      expect(prefs.quietHoursEnd, 8);
    });

    test('fromJson with defaults', () {
      final prefs = NotificationPreferences.fromJson({});
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.promosEnabled, false);
      expect(prefs.quietHoursStart, 22);
      expect(prefs.quietHoursEnd, 7);
    });
  });
}
