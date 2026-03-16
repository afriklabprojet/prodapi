import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/advanced_notification_service.dart';

void main() {
  group('NotificationType', () {
    test('should have all expected values', () {
      expect(NotificationType.values.length, 6);
      expect(NotificationType.newDelivery.index, 0);
      expect(NotificationType.deliveryUpdate.index, 1);
      expect(NotificationType.earnings.index, 2);
      expect(NotificationType.promotion.index, 3);
      expect(NotificationType.system.index, 4);
      expect(NotificationType.urgent.index, 5);
    });
  });

  group('NotificationSound', () {
    test('should have static sounds defined', () {
      expect(NotificationSound.defaultSound.id, 'default');
      expect(NotificationSound.defaultSound.name, 'Par défaut');
      
      expect(NotificationSound.urgentSound.id, 'urgent');
      expect(NotificationSound.urgentSound.name, 'Urgent');
      
      expect(NotificationSound.deliverySound.id, 'delivery');
      expect(NotificationSound.deliverySound.name, 'Nouvelle livraison');
      
      expect(NotificationSound.earningsSound.id, 'earnings');
      expect(NotificationSound.earningsSound.name, 'Gains');
      
      expect(NotificationSound.silentSound.id, 'silent');
      expect(NotificationSound.silentSound.name, 'Silencieux');
    });

    test('all list should contain all sounds', () {
      final allSounds = NotificationSound.all;
      expect(allSounds.length, 5);
      expect(allSounds.map((s) => s.id), contains('default'));
      expect(allSounds.map((s) => s.id), contains('urgent'));
      expect(allSounds.map((s) => s.id), contains('delivery'));
      expect(allSounds.map((s) => s.id), contains('earnings'));
      expect(allSounds.map((s) => s.id), contains('silent'));
    });

    test('should create custom sound', () {
      const sound = NotificationSound(
        id: 'custom',
        name: 'Custom Sound',
        assetPath: 'sounds/custom.mp3',
        isCustom: true,
      );

      expect(sound.id, 'custom');
      expect(sound.isCustom, true);
    });
  });

  group('NotificationAction', () {
    test('should have predefined actions', () {
      expect(NotificationAction.accept.id, 'accept');
      expect(NotificationAction.accept.label, 'Accepter');
      
      expect(NotificationAction.decline.id, 'decline');
      expect(NotificationAction.decline.label, 'Refuser');
      expect(NotificationAction.decline.destructive, true);
      
      expect(NotificationAction.viewDetails.id, 'view_details');
      expect(NotificationAction.viewDetails.label, 'Voir détails');
      
      expect(NotificationAction.navigate.id, 'navigate');
      expect(NotificationAction.navigate.label, 'Naviguer');
      
      expect(NotificationAction.call.id, 'call');
      expect(NotificationAction.call.label, 'Appeler');
      expect(NotificationAction.call.requiresUnlock, true);
    });

    test('should create with custom properties', () {
      const action = NotificationAction(
        id: 'custom',
        label: 'Custom Action',
        icon: 'star',
        destructive: false,
        requiresUnlock: true,
      );

      expect(action.id, 'custom');
      expect(action.label, 'Custom Action');
      expect(action.icon, 'star');
      expect(action.destructive, false);
      expect(action.requiresUnlock, true);
    });
  });

  group('NotificationPayload', () {
    test('should create with required properties', () {
      final payload = NotificationPayload(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.newDelivery,
      );

      expect(payload.id, 1);
      expect(payload.title, 'Test Title');
      expect(payload.body, 'Test Body');
      expect(payload.type, NotificationType.newDelivery);
      expect(payload.data, isNull);
      expect(payload.actions, isEmpty);
      expect(payload.groupId, isNull);
      expect(payload.imageUrl, isNull);
      expect(payload.silent, false);
      expect(payload.createdAt, isNotNull);
    });

    test('should create with all properties', () {
      final now = DateTime.now();
      final payload = NotificationPayload(
        id: 2,
        title: 'Full Test',
        body: 'Full Body',
        type: NotificationType.earnings,
        data: {'amount': 5000},
        actions: [NotificationAction.viewDetails],
        createdAt: now,
        groupId: 'earnings_group',
        imageUrl: 'https://example.com/image.png',
        silent: true,
      );

      expect(payload.data!['amount'], 5000);
      expect(payload.actions.length, 1);
      expect(payload.createdAt, now);
      expect(payload.groupId, 'earnings_group');
      expect(payload.imageUrl, 'https://example.com/image.png');
      expect(payload.silent, true);
    });

    test('toJson should serialize correctly', () {
      final payload = NotificationPayload(
        id: 3,
        title: 'JSON Test',
        body: 'Body',
        type: NotificationType.system,
      );

      final json = payload.toJson();

      expect(json['id'], 3);
      expect(json['title'], 'JSON Test');
      expect(json['body'], 'Body');
      expect(json['type'], 'system');
      expect(json['createdAt'], isNotNull);
    });
  });

  group('NotificationPreferences', () {
    test('should create with default values', () {
      const prefs = NotificationPreferences();

      expect(prefs.enabled, true);
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.groupNotifications, true);
      expect(prefs.showPreview, true);
      expect(prefs.quietHoursEnabled, false);
      expect(prefs.quietHoursStart, 22);
      expect(prefs.quietHoursEnd, 7);
      expect(prefs.allowUrgentDuringQuiet, true);
    });

    test('typeEnabled should have all types enabled by default', () {
      const prefs = NotificationPreferences();

      expect(prefs.typeEnabled[NotificationType.newDelivery], true);
      expect(prefs.typeEnabled[NotificationType.deliveryUpdate], true);
      expect(prefs.typeEnabled[NotificationType.earnings], true);
      expect(prefs.typeEnabled[NotificationType.promotion], true);
      expect(prefs.typeEnabled[NotificationType.system], true);
      expect(prefs.typeEnabled[NotificationType.urgent], true);
    });

    test('typeSounds should have correct default sounds', () {
      const prefs = NotificationPreferences();

      expect(prefs.typeSounds[NotificationType.newDelivery]?.id, 'delivery');
      expect(prefs.typeSounds[NotificationType.earnings]?.id, 'earnings');
      expect(prefs.typeSounds[NotificationType.urgent]?.id, 'urgent');
    });
  });
}
