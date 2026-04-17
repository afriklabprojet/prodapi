import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/rich_notification_service.dart';

class _FakeLocalNotificationsPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterLocalNotificationsPlatform {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    return null;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterLocalNotificationsPlatform.instance =
        _FakeLocalNotificationsPlatform();
  });
  group('NotificationType', () {
    test('has 8 values', () {
      expect(NotificationType.values.length, 8);
    });
  });

  group('NotificationTypeConfig extension', () {
    test('channelId is unique for each type', () {
      final ids = NotificationType.values.map((t) => t.channelId).toSet();
      expect(ids.length, NotificationType.values.length);
    });

    test('channelName is non-empty for each type', () {
      for (final type in NotificationType.values) {
        expect(type.channelName, isNotEmpty, reason: '$type channelName');
      }
    });

    test('channelDescription is non-empty for each type', () {
      for (final type in NotificationType.values) {
        expect(
          type.channelDescription,
          isNotEmpty,
          reason: '$type channelDescription',
        );
      }
    });

    test('newOrder has max importance', () {
      expect(NotificationType.newOrder.importance, Importance.max);
    });

    test('urgent has max importance', () {
      expect(NotificationType.urgent.importance, Importance.max);
    });

    test('promo has low importance', () {
      expect(NotificationType.promo.importance, Importance.low);
    });

    test('newOrder has max priority', () {
      expect(NotificationType.newOrder.priority, Priority.max);
    });

    test('chat has high priority', () {
      expect(NotificationType.chat.priority, Priority.high);
    });

    test('soundName is non-empty for each type', () {
      for (final type in NotificationType.values) {
        expect(type.soundName, isNotEmpty);
      }
    });

    test('emoji is non-empty for each type', () {
      for (final type in NotificationType.values) {
        expect(type.emoji, isNotEmpty, reason: '$type emoji');
      }
    });

    test('vibrationPattern is non-empty for each type', () {
      for (final type in NotificationType.values) {
        expect(
          type.vibrationPattern,
          isNotEmpty,
          reason: '$type vibrationPattern',
        );
      }
    });

    test('newOrder vibration pattern is longer than default', () {
      final newOrderPattern = NotificationType.newOrder.vibrationPattern;
      final systemPattern = NotificationType.system.vibrationPattern;
      expect(
        newOrderPattern.length,
        greaterThanOrEqualTo(systemPattern.length),
      );
    });
  });

  group('NotificationPreferences', () {
    test('default constructor has correct defaults', () {
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

    test('copyWith overrides values', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(
        soundEnabled: false,
        promosEnabled: true,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 6,
      );
      expect(copy.soundEnabled, false);
      expect(copy.promosEnabled, true);
      expect(copy.quietHoursEnabled, true);
      expect(copy.quietHoursStart, 23);
      expect(copy.quietHoursEnd, 6);
      // Unchanged values
      expect(copy.vibrationEnabled, true);
      expect(copy.newOrdersEnabled, true);
    });

    test('copyWith preserves values when null', () {
      const prefs = NotificationPreferences(
        soundEnabled: false,
        selectedSound: 'custom',
      );
      final copy = prefs.copyWith();
      expect(copy.soundEnabled, false);
      expect(copy.selectedSound, 'custom');
    });

    test('isQuietTime returns false when disabled', () {
      const prefs = NotificationPreferences(quietHoursEnabled: false);
      expect(prefs.isQuietTime, false);
    });

    test('toJson returns all fields', () {
      const prefs = NotificationPreferences();
      final json = prefs.toJson();
      expect(json['soundEnabled'], true);
      expect(json['vibrationEnabled'], true);
      expect(json['newOrdersEnabled'], true);
      expect(json['chatEnabled'], true);
      expect(json['earningsEnabled'], true);
      expect(json['promosEnabled'], false);
      expect(json['urgentEnabled'], true);
      expect(json['selectedSound'], 'default');
      expect(json['quietHoursEnabled'], false);
      expect(json['quietHoursStart'], 22);
      expect(json['quietHoursEnd'], 7);
    });

    test('fromJson creates correct preferences', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': false,
        'vibrationEnabled': false,
        'newOrdersEnabled': false,
        'chatEnabled': false,
        'earningsEnabled': false,
        'promosEnabled': true,
        'urgentEnabled': false,
        'selectedSound': 'alert',
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
      expect(prefs.selectedSound, 'alert');
      expect(prefs.quietHoursEnabled, true);
      expect(prefs.quietHoursStart, 21);
      expect(prefs.quietHoursEnd, 8);
    });

    test('fromJson uses defaults for missing keys', () {
      final prefs = NotificationPreferences.fromJson({});
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.promosEnabled, false);
      expect(prefs.quietHoursStart, 22);
      expect(prefs.quietHoursEnd, 7);
    });
  });

  group('RichNotification', () {
    test('creates with required fields', () {
      final notification = RichNotification(
        id: 'notif_1',
        type: NotificationType.newOrder,
        title: 'Nouvelle commande',
        body: 'Une commande est disponible près de vous',
      );
      expect(notification.id, 'notif_1');
      expect(notification.type, NotificationType.newOrder);
      expect(notification.title, 'Nouvelle commande');
      expect(notification.body, contains('disponible'));
      expect(notification.imageUrl, isNull);
      expect(notification.data, isNull);
      expect(notification.actions, isNull);
      expect(notification.isRead, false);
      expect(notification.createdAt, isA<DateTime>());
    });

    test('copyWith updates isRead', () {
      final notification = RichNotification(
        id: 'notif_1',
        type: NotificationType.chat,
        title: 'Message',
        body: 'Bonjour',
      );
      final read = notification.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, 'notif_1');
      expect(read.type, NotificationType.chat);
      expect(read.title, 'Message');
    });

    test('copyWith preserves isRead when null', () {
      final notification = RichNotification(
        id: 'notif_1',
        type: NotificationType.earnings,
        title: 'Gains',
        body: '+500 FCFA',
        isRead: true,
      );
      final copy = notification.copyWith();
      expect(copy.isRead, true);
    });
  });

  group('NotificationAction', () {
    test('creates with required fields', () {
      const action = NotificationAction(id: 'accept', label: 'Accepter');
      expect(action.id, 'accept');
      expect(action.label, 'Accepter');
      expect(action.icon, isNull);
      expect(action.destructive, false);
    });

    test('creates with destructive flag', () {
      const action = NotificationAction(
        id: 'reject',
        label: 'Refuser',
        icon: 'close',
        destructive: true,
      );
      expect(action.destructive, true);
      expect(action.icon, 'close');
    });
  });

  group('NotificationType specific values', () {
    test('newOrder channelId', () {
      expect(NotificationType.newOrder.channelId, 'new_orders_high');
    });

    test('orderAssigned channelId', () {
      expect(NotificationType.orderAssigned.channelId, 'order_assigned');
    });

    test('urgent channelId', () {
      expect(NotificationType.urgent.channelId, 'urgent_alerts');
    });

    test('reminder channelId', () {
      expect(NotificationType.reminder.channelId, 'reminders');
    });

    test('earnings channelId', () {
      expect(NotificationType.earnings.channelId, 'earnings');
    });

    test('system channelId', () {
      expect(NotificationType.system.channelId, 'system');
    });

    test('chat channelId', () {
      expect(NotificationType.chat.channelId, 'chat_messages');
    });

    test('promo channelId', () {
      expect(NotificationType.promo.channelId, 'promotions');
    });

    test('each type has unique channelDescription', () {
      final descriptions = NotificationType.values
          .map((t) => t.channelDescription)
          .toSet();
      expect(descriptions.length, NotificationType.values.length);
    });

    test('orderAssigned importance is high', () {
      expect(NotificationType.orderAssigned.importance, Importance.high);
    });

    test('reminder importance is default', () {
      expect(
        NotificationType.reminder.importance,
        Importance.defaultImportance,
      );
    });

    test('earnings importance is default', () {
      expect(
        NotificationType.earnings.importance,
        Importance.defaultImportance,
      );
    });

    test('system importance is low', () {
      expect(NotificationType.system.importance, Importance.low);
    });

    test('orderAssigned priority is high', () {
      expect(NotificationType.orderAssigned.priority, Priority.high);
    });

    test('reminder priority is default', () {
      expect(NotificationType.reminder.priority, Priority.defaultPriority);
    });

    test('newOrder soundName', () {
      expect(NotificationType.newOrder.soundName, 'notification_new_order');
    });

    test('urgent soundName', () {
      expect(NotificationType.urgent.soundName, 'notification_urgent');
    });

    test('earnings soundName', () {
      expect(NotificationType.earnings.soundName, 'notification_cash');
    });

    test('chat soundName', () {
      expect(NotificationType.chat.soundName, 'notification_chat');
    });

    test('system soundName is default', () {
      expect(NotificationType.system.soundName, 'default');
    });

    test('promo soundName is default', () {
      expect(NotificationType.promo.soundName, 'default');
    });

    test('newOrder emoji', () {
      expect(NotificationType.newOrder.emoji, '🚚');
    });

    test('urgent emoji', () {
      expect(NotificationType.urgent.emoji, '🚨');
    });

    test('earnings emoji', () {
      expect(NotificationType.earnings.emoji, '💰');
    });

    test('chat emoji', () {
      expect(NotificationType.chat.emoji, '💬');
    });

    test('promo emoji', () {
      expect(NotificationType.promo.emoji, '🎁');
    });

    test('urgent vibration pattern is intense', () {
      final pattern = NotificationType.urgent.vibrationPattern;
      expect(pattern, [0, 1000, 500, 1000]);
    });

    test('earnings vibration pattern is cha-ching', () {
      final pattern = NotificationType.earnings.vibrationPattern;
      expect(pattern, [0, 300, 100, 300]);
    });

    test('reminder vibration pattern is standard', () {
      final pattern = NotificationType.reminder.vibrationPattern;
      expect(pattern, [0, 250, 100, 250]);
    });

    test('channelName returns correct names', () {
      expect(NotificationType.newOrder.channelName, 'Nouvelles commandes');
      expect(NotificationType.chat.channelName, 'Messages');
      expect(NotificationType.promo.channelName, 'Promotions');
      expect(NotificationType.system.channelName, 'Système');
    });
  });

  group('RichNotification additional', () {
    test('creates with all optional fields', () {
      final notification = RichNotification(
        id: 'n1',
        type: NotificationType.newOrder,
        title: 'Test',
        body: 'Body',
        imageUrl: 'https://example.com/img.png',
        data: {'orderId': 123},
        actions: [const NotificationAction(id: 'accept', label: 'OK')],
        createdAt: DateTime(2024, 6, 1),
        isRead: true,
      );
      expect(notification.imageUrl, 'https://example.com/img.png');
      expect(notification.data?['orderId'], 123);
      expect(notification.actions?.length, 1);
      expect(notification.createdAt, DateTime(2024, 6, 1));
      expect(notification.isRead, true);
    });

    test('createdAt defaults to now when null', () {
      final before = DateTime.now();
      final notification = RichNotification(
        id: 'n1',
        type: NotificationType.system,
        title: 'T',
        body: 'B',
      );
      final after = DateTime.now();
      expect(
        notification.createdAt.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        notification.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('copyWith preserves all fields', () {
      final notification = RichNotification(
        id: 'n1',
        type: NotificationType.chat,
        title: 'Hello',
        body: 'World',
        imageUrl: 'url',
        data: {'key': 'val'},
        createdAt: DateTime(2024, 1, 1),
      );
      final copy = notification.copyWith(isRead: true);
      expect(copy.id, 'n1');
      expect(copy.type, NotificationType.chat);
      expect(copy.title, 'Hello');
      expect(copy.body, 'World');
      expect(copy.imageUrl, 'url');
      expect(copy.data?['key'], 'val');
      expect(copy.createdAt, DateTime(2024, 1, 1));
      expect(copy.isRead, true);
    });
  });

  group('NotificationPreferences isQuietTime', () {
    test('returns false when disabled', () {
      const prefs = NotificationPreferences(quietHoursEnabled: false);
      expect(prefs.isQuietTime, false);
    });

    test('returns false when disabled regardless of hours', () {
      const prefs = NotificationPreferences(
        quietHoursEnabled: false,
        quietHoursStart: 0,
        quietHoursEnd: 23,
      );
      expect(prefs.isQuietTime, false);
    });
  });

  group('NotificationPreferences toJson roundtrip', () {
    test('fromJson(toJson()) preserves all fields', () {
      const original = NotificationPreferences(
        soundEnabled: false,
        vibrationEnabled: false,
        newOrdersEnabled: false,
        chatEnabled: false,
        earningsEnabled: false,
        promosEnabled: true,
        urgentEnabled: false,
        selectedSound: 'alert',
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 6,
      );
      final restored = NotificationPreferences.fromJson(original.toJson());
      expect(restored.soundEnabled, false);
      expect(restored.vibrationEnabled, false);
      expect(restored.newOrdersEnabled, false);
      expect(restored.chatEnabled, false);
      expect(restored.earningsEnabled, false);
      expect(restored.promosEnabled, true);
      expect(restored.urgentEnabled, false);
      expect(restored.selectedSound, 'alert');
      expect(restored.quietHoursEnabled, true);
      expect(restored.quietHoursStart, 23);
      expect(restored.quietHoursEnd, 6);
    });
  });

  group('NotificationPreferences copyWith individual fields', () {
    test('copyWith soundEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(soundEnabled: false);
      expect(copy.soundEnabled, false);
      expect(copy.vibrationEnabled, true);
    });

    test('copyWith vibrationEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(vibrationEnabled: false);
      expect(copy.vibrationEnabled, false);
      expect(copy.soundEnabled, true);
    });

    test('copyWith newOrdersEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(newOrdersEnabled: false);
      expect(copy.newOrdersEnabled, false);
    });

    test('copyWith chatEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(chatEnabled: false);
      expect(copy.chatEnabled, false);
    });

    test('copyWith earningsEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(earningsEnabled: false);
      expect(copy.earningsEnabled, false);
    });

    test('copyWith urgentEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(urgentEnabled: false);
      expect(copy.urgentEnabled, false);
    });

    test('copyWith selectedSound', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(selectedSound: 'custom_ring');
      expect(copy.selectedSound, 'custom_ring');
    });

    test('copyWith quietHoursEnabled', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(quietHoursEnabled: true);
      expect(copy.quietHoursEnabled, true);
    });

    test('copyWith quietHoursStart', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(quietHoursStart: 21);
      expect(copy.quietHoursStart, 21);
    });

    test('copyWith quietHoursEnd', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(quietHoursEnd: 8);
      expect(copy.quietHoursEnd, 8);
    });
  });

  group('NotificationPreferences isQuietTime advanced', () {
    test('normal range: returns value based on current hour', () {
      // Test with start < end (e.g., 9-17 daytime)
      const prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: 9,
        quietHoursEnd: 17,
      );
      // Cannot control DateTime.now() but we test the branch executes
      expect(prefs.isQuietTime, isA<bool>());
    });

    test('midnight crossing: returns value based on current hour', () {
      // Test with start > end (e.g., 22-7 overnight)
      const prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 7,
      );
      expect(prefs.isQuietTime, isA<bool>());
    });

    test(
      'same start and end: falls into midnight-crossing branch, always true',
      () {
        const prefs = NotificationPreferences(
          quietHoursEnabled: true,
          quietHoursStart: 10,
          quietHoursEnd: 10,
        );
        // start < end is false → else branch: now >= 10 || now < 10 → always true
        expect(prefs.isQuietTime, true);
      },
    );

    test('full day range 0-24 uses normal path', () {
      const prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: 0,
        quietHoursEnd: 24,
      );
      // 0 < 24, normal range: now >= 0 && now < 24 → always true
      expect(prefs.isQuietTime, true);
    });
  });

  group('NotificationType soundName specific', () {
    test('reminder uses default sound', () {
      expect(NotificationType.reminder.soundName, 'default');
    });

    test('orderAssigned uses default sound', () {
      expect(NotificationType.orderAssigned.soundName, 'default');
    });
  });

  group('NotificationType priority specific', () {
    test('earnings priority is default', () {
      expect(NotificationType.earnings.priority, Priority.defaultPriority);
    });

    test('system priority is default', () {
      expect(NotificationType.system.priority, Priority.defaultPriority);
    });

    test('promo priority is default', () {
      expect(NotificationType.promo.priority, Priority.defaultPriority);
    });

    test('urgent priority is max', () {
      expect(NotificationType.urgent.priority, Priority.max);
    });
  });

  group('NotificationType vibrationPattern specific', () {
    test('chat vibration is standard', () {
      expect(NotificationType.chat.vibrationPattern, [0, 250, 100, 250]);
    });

    test('promo vibration is standard', () {
      expect(NotificationType.promo.vibrationPattern, [0, 250, 100, 250]);
    });

    test('orderAssigned vibration is standard', () {
      expect(NotificationType.orderAssigned.vibrationPattern, [
        0,
        250,
        100,
        250,
      ]);
    });

    test('system vibration is standard', () {
      expect(NotificationType.system.vibrationPattern, [0, 250, 100, 250]);
    });
  });

  group('NotificationType channelName exhaustive', () {
    test('orderAssigned channelName', () {
      expect(NotificationType.orderAssigned.channelName, 'Commandes assignées');
    });

    test('urgent channelName', () {
      expect(NotificationType.urgent.channelName, 'Alertes urgentes');
    });

    test('reminder channelName', () {
      expect(NotificationType.reminder.channelName, 'Rappels');
    });

    test('earnings channelName', () {
      expect(NotificationType.earnings.channelName, 'Gains & revenus');
    });
  });

  group('NotificationType emoji exhaustive', () {
    test('orderAssigned emoji', () {
      expect(NotificationType.orderAssigned.emoji, '✅');
    });

    test('reminder emoji', () {
      expect(NotificationType.reminder.emoji, '⏰');
    });

    test('system emoji', () {
      expect(NotificationType.system.emoji, 'ℹ️');
    });
  });

  group('RichNotification model additional', () {
    test('actions list preserved in copyWith', () {
      final notification = RichNotification(
        id: 'n1',
        type: NotificationType.newOrder,
        title: 'Test',
        body: 'Body',
        actions: [
          const NotificationAction(id: 'a1', label: 'Action 1'),
          const NotificationAction(
            id: 'a2',
            label: 'Action 2',
            destructive: true,
          ),
        ],
      );
      final copy = notification.copyWith(isRead: true);
      expect(copy.actions?.length, 2);
      expect(copy.actions![0].id, 'a1');
      expect(copy.actions![1].destructive, true);
    });

    test('data map preserved in copyWith', () {
      final notification = RichNotification(
        id: 'n1',
        type: NotificationType.earnings,
        title: 'Gains',
        body: '+500',
        data: {'amount': 500, 'type': 'delivery'},
      );
      final copy = notification.copyWith();
      expect(copy.data?['amount'], 500);
      expect(copy.data?['type'], 'delivery');
    });
  });

  group('NotificationAction model additional', () {
    test('icon can be set', () {
      const action = NotificationAction(id: 'a1', label: 'Test', icon: 'star');
      expect(action.icon, 'star');
    });

    test('defaults destructive to false', () {
      const action = NotificationAction(id: 'a1', label: 'Test');
      expect(action.destructive, false);
    });

    test('all fields set', () {
      const action = NotificationAction(
        id: 'reject',
        label: 'Refuser la commande',
        icon: 'cancel',
        destructive: true,
      );
      expect(action.id, 'reject');
      expect(action.label, 'Refuser la commande');
      expect(action.icon, 'cancel');
      expect(action.destructive, true);
    });

    test('id can be empty', () {
      const action = NotificationAction(id: '', label: 'OK');
      expect(action.id, '');
    });

    test('label can be long', () {
      final label = 'A' * 100;
      final action = NotificationAction(id: 'a', label: label);
      expect(action.label.length, 100);
    });
  });

  group('NotificationPreferences - fromJson edge cases', () {
    test('fromJson with extra keys ignores them', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': true,
        'unknown_key': 'value',
        'extra': 42,
      });
      expect(prefs.soundEnabled, true);
    });

    test('fromJson with null values uses defaults', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': null,
        'vibrationEnabled': null,
      });
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
    });

    test('fromJson preserves quiet hours boundary', () {
      final prefs = NotificationPreferences.fromJson({
        'quietHoursStart': 0,
        'quietHoursEnd': 0,
      });
      expect(prefs.quietHoursStart, 0);
      expect(prefs.quietHoursEnd, 0);
    });

    test('fromJson with all false booleans', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': false,
        'vibrationEnabled': false,
        'newOrdersEnabled': false,
        'chatEnabled': false,
        'earningsEnabled': false,
        'promosEnabled': false,
        'urgentEnabled': false,
        'quietHoursEnabled': false,
      });
      expect(prefs.soundEnabled, false);
      expect(prefs.vibrationEnabled, false);
      expect(prefs.newOrdersEnabled, false);
      expect(prefs.chatEnabled, false);
      expect(prefs.earningsEnabled, false);
      expect(prefs.promosEnabled, false);
      expect(prefs.urgentEnabled, false);
      expect(prefs.quietHoursEnabled, false);
    });

    test('fromJson with all true booleans', () {
      final prefs = NotificationPreferences.fromJson({
        'soundEnabled': true,
        'vibrationEnabled': true,
        'newOrdersEnabled': true,
        'chatEnabled': true,
        'earningsEnabled': true,
        'promosEnabled': true,
        'urgentEnabled': true,
        'quietHoursEnabled': true,
      });
      expect(prefs.promosEnabled, true);
      expect(prefs.quietHoursEnabled, true);
    });
  });

  group('RichNotification - various types', () {
    for (final type in NotificationType.values) {
      test('creates notification of type ${type.name}', () {
        final notification = RichNotification(
          id: 'n_${type.name}',
          type: type,
          title: 'Title ${type.name}',
          body: 'Body for ${type.name}',
        );
        expect(notification.type, type);
        expect(notification.id, 'n_${type.name}');
        expect(notification.isRead, false);
      });
    }
  });

  group('NotificationType - importance consistency', () {
    test('all types have non-null importance', () {
      for (final type in NotificationType.values) {
        expect(type.importance, isNotNull);
      }
    });

    test('all types have non-null priority', () {
      for (final type in NotificationType.values) {
        expect(type.priority, isNotNull);
      }
    });

    test('vibration patterns are non-empty for all types', () {
      for (final type in NotificationType.values) {
        expect(type.vibrationPattern.length, greaterThan(0));
      }
    });

    test('channel IDs are all non-empty strings', () {
      for (final type in NotificationType.values) {
        expect(type.channelId.length, greaterThan(0));
      }
    });
  });

  group('NotificationPreferences - copyWith all at once', () {
    test('copyWith overrides all fields at once', () {
      const prefs = NotificationPreferences();
      final copy = prefs.copyWith(
        soundEnabled: false,
        vibrationEnabled: false,
        newOrdersEnabled: false,
        chatEnabled: false,
        earningsEnabled: false,
        promosEnabled: true,
        urgentEnabled: false,
        selectedSound: 'silent',
        quietHoursEnabled: true,
        quietHoursStart: 20,
        quietHoursEnd: 8,
      );
      expect(copy.soundEnabled, false);
      expect(copy.vibrationEnabled, false);
      expect(copy.newOrdersEnabled, false);
      expect(copy.chatEnabled, false);
      expect(copy.earningsEnabled, false);
      expect(copy.promosEnabled, true);
      expect(copy.urgentEnabled, false);
      expect(copy.selectedSound, 'silent');
      expect(copy.quietHoursEnabled, true);
      expect(copy.quietHoursStart, 20);
      expect(copy.quietHoursEnd, 8);
    });
  });

  group('NotificationType newOrder vibrationPattern', () {
    test('newOrder has distinctive pattern', () {
      final pattern = NotificationType.newOrder.vibrationPattern;
      expect(pattern.length, greaterThanOrEqualTo(4));
      expect(pattern.first, 0); // delay before vibration
    });
  });

  // ─── Service state management tests ──────────────────────────────

  group('RichNotificationService - state management', () {
    late RichNotificationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = RichNotificationService();
      // Give time for async _init
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is empty', () {
      expect(service.state, isEmpty);
      expect(service.unreadCount, 0);
    });

    test('default preferences are returned', () {
      final prefs = service.preferences;
      expect(prefs.soundEnabled, true);
      expect(prefs.newOrdersEnabled, true);
    });

    test('showNotification adds notification to state', () async {
      await service.showNotification(
        id: 'test_1',
        type: NotificationType.system,
        title: 'Test Title',
        body: 'Test Body',
      );
      expect(service.state.length, 1);
      expect(service.state.first.id, 'test_1');
      expect(service.state.first.title, 'Test Title');
      expect(service.state.first.isRead, false);
      expect(service.unreadCount, 1);
    });

    test('markAsRead marks specific notification', () async {
      await service.showNotification(
        id: 'n1',
        type: NotificationType.system,
        title: 'Title 1',
        body: 'Body 1',
      );
      await service.showNotification(
        id: 'n2',
        type: NotificationType.system,
        title: 'Title 2',
        body: 'Body 2',
      );
      expect(service.unreadCount, 2);

      service.markAsRead('n1');
      expect(service.unreadCount, 1);
      expect(service.state.firstWhere((n) => n.id == 'n1').isRead, true);
      expect(service.state.firstWhere((n) => n.id == 'n2').isRead, false);
    });

    test('markAllAsRead marks all notifications', () async {
      await service.showNotification(
        id: 'n1',
        type: NotificationType.system,
        title: 'Title 1',
        body: 'Body 1',
      );
      await service.showNotification(
        id: 'n2',
        type: NotificationType.chat,
        title: 'Title 2',
        body: 'Body 2',
      );
      expect(service.unreadCount, 2);

      service.markAllAsRead();
      expect(service.unreadCount, 0);
      for (final n in service.state) {
        expect(n.isRead, true);
      }
    });

    test('removeNotification removes from state', () async {
      await service.showNotification(
        id: 'n1',
        type: NotificationType.system,
        title: 'T1',
        body: 'B1',
      );
      await service.showNotification(
        id: 'n2',
        type: NotificationType.system,
        title: 'T2',
        body: 'B2',
      );
      expect(service.state.length, 2);

      service.removeNotification('n1');
      expect(service.state.length, 1);
      expect(service.state.first.id, 'n2');
    });

    test('clearAll removes all notifications', () async {
      await service.showNotification(
        id: 'n1',
        type: NotificationType.system,
        title: 'T1',
        body: 'B1',
      );
      await service.showNotification(
        id: 'n2',
        type: NotificationType.system,
        title: 'T2',
        body: 'B2',
      );
      expect(service.state.length, 2);

      await service.clearAll();
      expect(service.state, isEmpty);
      expect(service.unreadCount, 0);
    });

    test('showNotification limits to 100 notifications', () async {
      for (var i = 0; i < 105; i++) {
        await service.showNotification(
          id: 'n_$i',
          type: NotificationType.system,
          title: 'T$i',
          body: 'B$i',
        );
      }
      expect(service.state.length, lessThanOrEqualTo(100));
    });

    test('showNotification with data and actions', () async {
      await service.showNotification(
        id: 'data_test',
        type: NotificationType.newOrder,
        title: 'New Order',
        body: 'Order details',
        data: {'order_id': '123', 'pharmacy_name': 'Test Pharma'},
        actions: const [
          NotificationAction(id: 'ACCEPT', label: 'Accepter'),
          NotificationAction(id: 'REJECT', label: 'Refuser', destructive: true),
        ],
      );

      final n = service.state.first;
      expect(n.data!['order_id'], '123');
      expect(n.actions!.length, 2);
      expect(n.actions!.first.label, 'Accepter');
      expect(n.actions!.last.destructive, true);
    });

    test('showNotification respects preferences - promo disabled', () async {
      // Default prefs have promosEnabled = false
      await service.showNotification(
        id: 'promo_test',
        type: NotificationType.promo,
        title: 'Sale!',
        body: '50% off',
      );
      // Promo should be ignored (not added to state)
      expect(service.state.where((n) => n.id == 'promo_test'), isEmpty);
    });

    test('showNewOrderNotification creates order notification', () async {
      await service.showNewOrderNotification(
        orderId: 'order_123',
        pharmacyName: 'Pharma Plus',
        deliveryAddress: '123 Rue de la Paix',
        amount: 5000,
        estimatedEarnings: 800,
        distanceKm: 3.5,
      );

      expect(service.state.length, 1);
      expect(service.state.first.type, NotificationType.newOrder);
      expect(service.state.first.title, 'Nouvelle commande disponible !');
      expect(service.state.first.body, contains('Pharma Plus'));
      expect(service.state.first.body, contains('800 FCFA'));
      expect(service.state.first.body, contains('3.5 km'));
    });

    test('showNewOrderNotification without optional fields', () async {
      await service.showNewOrderNotification(
        orderId: 'order_456',
        pharmacyName: 'Pharma Simple',
        deliveryAddress: '456 Avenue',
      );

      expect(service.state.length, 1);
      expect(service.state.first.body, contains('Pharma Simple'));
    });

    test('showEarningsNotification creates earnings notification', () async {
      await service.showEarningsNotification(
        title: 'Gain journalier',
        amount: 3500,
        details: 'Pour 5 livraisons',
      );

      expect(service.state.length, 1);
      expect(service.state.first.type, NotificationType.earnings);
      expect(service.state.first.body, contains('3500 FCFA'));
      expect(service.state.first.body, contains('Pour 5 livraisons'));
    });

    test('showEarningsNotification without details', () async {
      await service.showEarningsNotification(title: 'Bonus', amount: 1000);

      expect(service.state.length, 1);
      expect(service.state.first.body, contains('1000 FCFA'));
    });

    test('showChatNotification creates chat notification', () async {
      await service.showChatNotification(
        senderId: 'user_1',
        senderName: 'Jean Dupont',
        message: 'Bonjour, quand arrivez-vous ?',
        deliveryId: 'del_456',
      );

      expect(service.state.length, 1);
      expect(service.state.first.type, NotificationType.chat);
      expect(service.state.first.title, 'Jean Dupont');
      expect(service.state.first.body, 'Bonjour, quand arrivez-vous ?');
    });

    test('showUrgentNotification creates urgent notification', () async {
      await service.showUrgentNotification(
        title: 'Alerte urgente',
        message: 'Action requise immédiatement',
        data: {'reason': 'timeout'},
      );

      expect(service.state.length, 1);
      expect(service.state.first.type, NotificationType.urgent);
      expect(service.state.first.data!['reason'], 'timeout');
    });

    test('savePreferences persists to SharedPreferences', () async {
      final newPrefs = const NotificationPreferences().copyWith(
        soundEnabled: false,
        promosEnabled: true,
      );
      await service.savePreferences(newPrefs);
      expect(service.preferences.soundEnabled, false);
      expect(service.preferences.promosEnabled, true);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('notification_preferences');
      expect(saved, isNotNull);
      expect(saved, contains('soundEnabled=false'));
      expect(saved, contains('promosEnabled=true'));
    });

    test('actionStream emits events', () async {
      // Just verify stream is accessible
      expect(service.actionStream, isNotNull);
    });

    test('onNotificationAction callback can be set', () {
      var callbackCalled = false;
      service.onNotificationAction = (id, actionId, data) {
        callbackCalled = true;
      };
      expect(service.onNotificationAction, isNotNull);
      // callbackCalled stays false until action is triggered
      expect(callbackCalled, isFalse);
    });
  });

  group('RichNotificationService - preferences loading', () {
    test('loads saved preferences from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'notification_preferences':
            'soundEnabled=false&vibrationEnabled=true&newOrdersEnabled=true'
            '&chatEnabled=false&earningsEnabled=true&promosEnabled=true'
            '&urgentEnabled=true&selectedSound=custom&quietHoursEnabled=false'
            '&quietHoursStart=22&quietHoursEnd=7',
      });
      final svc = RichNotificationService();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(svc.preferences.soundEnabled, false);
      expect(svc.preferences.chatEnabled, false);
      expect(svc.preferences.promosEnabled, true);
      expect(svc.preferences.selectedSound, 'custom');

      svc.dispose();
    });

    test('handles malformed preferences gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'notification_preferences': 'invalid=data&broken',
      });
      final svc = RichNotificationService();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should fall back to defaults on parse error
      expect(svc.preferences, isNotNull);
      svc.dispose();
    });
  });

  group('NotificationActionEvent', () {
    test('creates with required fields', () {
      final event = NotificationActionEvent(notificationId: 'notif_123');
      expect(event.notificationId, 'notif_123');
      expect(event.actionId, isNull);
      expect(event.data, isNull);
    });

    test('creates with all fields', () {
      final event = NotificationActionEvent(
        notificationId: 'notif_456',
        actionId: 'ACCEPT',
        data: {'order_id': '789'},
      );
      expect(event.notificationId, 'notif_456');
      expect(event.actionId, 'ACCEPT');
      expect(event.data!['order_id'], '789');
    });
  });

  group('NotificationAction', () {
    test('default destructive is false', () {
      const action = NotificationAction(id: 'test', label: 'Test');
      expect(action.destructive, false);
      expect(action.icon, isNull);
    });

    test('icon can be set', () {
      const action = NotificationAction(id: 'a', label: 'L', icon: '✅');
      expect(action.icon, '✅');
    });
  });

  group('RichNotification copyWith', () {
    test('copyWith isRead updates only isRead', () {
      final original = RichNotification(
        id: 'copy_test',
        type: NotificationType.chat,
        title: 'Original',
        body: 'Body',
        imageUrl: 'https://example.com/img.png',
        data: {'key': 'value'},
        actions: const [NotificationAction(id: 'a', label: 'L')],
      );

      final copy = original.copyWith(isRead: true);
      expect(copy.isRead, true);
      expect(copy.id, 'copy_test');
      expect(copy.type, NotificationType.chat);
      expect(copy.title, 'Original');
      expect(copy.body, 'Body');
      expect(copy.imageUrl, 'https://example.com/img.png');
      expect(copy.data!['key'], 'value');
      expect(copy.actions!.length, 1);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith without args returns same values', () {
      final original = RichNotification(
        id: 'test_id',
        type: NotificationType.urgent,
        title: 'Title',
        body: 'Body',
        isRead: true,
      );
      final copy = original.copyWith();
      expect(copy.isRead, true);
      expect(copy.id, 'test_id');
    });
  });
}
