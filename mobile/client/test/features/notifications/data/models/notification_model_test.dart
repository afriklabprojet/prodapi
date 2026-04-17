import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/notifications/data/models/notification_model.dart';
import 'package:drpharma_client/features/notifications/domain/entities/notification_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _notifJson({
  String id = 'uuid-abc-123',
  String type = 'App\\Notifications\\OrderStatusUpdated',
  Map<String, dynamic>? data,
  String? readAt,
  String createdAt = '2024-06-01T10:00:00.000Z',
}) => <String, dynamic>{
  'id': id,
  'type': type,
  'data':
      data ??
      <String, dynamic>{
        'title': 'Commande mise à jour',
        'message': 'Votre commande est confirmée.',
      },
  'read_at': ?readAt,
  'created_at': createdAt,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // NotificationModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('NotificationModel', () {
    group('fromJson', () {
      test('parses all required fields', () {
        final model = NotificationModel.fromJson(_notifJson());

        expect(model.id, 'uuid-abc-123');
        expect(model.type, 'App\\Notifications\\OrderStatusUpdated');
        expect(model.data['title'], 'Commande mise à jour');
        expect(model.data['message'], 'Votre commande est confirmée.');
        expect(model.readAt, isNull);
        expect(model.createdAt, '2024-06-01T10:00:00.000Z');
      });

      test('parses readAt when present', () {
        final model = NotificationModel.fromJson(
          _notifJson(readAt: '2024-06-02T08:00:00.000Z'),
        );
        expect(model.readAt, '2024-06-02T08:00:00.000Z');
      });

      test('readAt is null when absent', () {
        final model = NotificationModel.fromJson(_notifJson());
        expect(model.readAt, isNull);
      });

      test('parses different notification types', () {
        final model = NotificationModel.fromJson(
          _notifJson(type: 'App\\Notifications\\NewMessage'),
        );
        expect(model.type, 'App\\Notifications\\NewMessage');
      });

      test('parses data map with extra keys', () {
        final model = NotificationModel.fromJson(
          _notifJson(
            data: <String, dynamic>{
              'title': 'Livraison',
              'message': 'En route',
              'order_id': 42,
              'status': 'delivered',
            },
          ),
        );
        expect(model.data['order_id'], 42);
        expect(model.data['status'], 'delivered');
      });
    });

    group('toJson', () {
      test('round-trip preserves required fields', () {
        final original = _notifJson(readAt: '2024-06-02T09:00:00.000Z');
        final model = NotificationModel.fromJson(original);
        final json = model.toJson();

        expect(json['id'], 'uuid-abc-123');
        expect(json['type'], 'App\\Notifications\\OrderStatusUpdated');
        expect(json['read_at'], '2024-06-02T09:00:00.000Z');
        expect(json['created_at'], '2024-06-01T10:00:00.000Z');
      });

      test('read_at is null in json when not set', () {
        final json = NotificationModel.fromJson(_notifJson()).toJson();
        expect(json['read_at'], isNull);
      });
    });

    // ────────────────────────────────────────────────────────────────────────────
    // toEntity()
    // ────────────────────────────────────────────────────────────────────────────
    group('toEntity', () {
      test('returns a NotificationEntity', () {
        final entity = NotificationModel.fromJson(_notifJson()).toEntity();
        expect(entity, isA<NotificationEntity>());
      });

      test('isRead is false when readAt is null', () {
        final entity = NotificationModel.fromJson(_notifJson()).toEntity();
        expect(entity.isRead, isFalse);
      });

      test('isRead is true when readAt is set', () {
        final entity = NotificationModel.fromJson(
          _notifJson(readAt: '2024-06-02T08:00:00.000Z'),
        ).toEntity();
        expect(entity.isRead, isTrue);
      });

      test('maps data[title] to entity.title', () {
        final entity = NotificationModel.fromJson(
          _notifJson(
            data: <String, dynamic>{
              'title': 'Ordonnance validée',
              'message': 'OK',
            },
          ),
        ).toEntity();
        expect(entity.title, 'Ordonnance validée');
      });

      test('maps data[message] to entity.body', () {
        final entity = NotificationModel.fromJson(
          _notifJson(
            data: <String, dynamic>{
              'title': 'X',
              'message': 'Corps du message',
            },
          ),
        ).toEntity();
        expect(entity.body, 'Corps du message');
      });

      test('entity.title falls back to Notification when missing', () {
        final entity = NotificationModel.fromJson(
          _notifJson(data: <String, dynamic>{'message': 'Msg sans titre'}),
        ).toEntity();
        expect(entity.title, 'Notification');
      });

      test('entity.body falls back to empty string when missing', () {
        final entity = NotificationModel.fromJson(
          _notifJson(data: <String, dynamic>{'title': 'Titre uniquement'}),
        ).toEntity();
        expect(entity.body, '');
      });

      test('parses valid createdAt date', () {
        final entity = NotificationModel.fromJson(_notifJson()).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-06-01T10:00:00.000Z'));
      });

      test('passes data map through to entity', () {
        final data = <String, dynamic>{
          'title': 'T',
          'message': 'M',
          'order_id': 99,
        };
        final entity = NotificationModel.fromJson(
          _notifJson(data: data),
        ).toEntity();
        expect(entity.data, isNotNull);
        expect(entity.data!['order_id'], 99);
      });

      test('entity id, type pass through', () {
        final entity = NotificationModel.fromJson(
          _notifJson(id: 'notif-999', type: 'App\\Notifications\\Promo'),
        ).toEntity();
        expect(entity.id, 'notif-999');
        expect(entity.type, 'App\\Notifications\\Promo');
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // NotificationEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('NotificationEntity', () {
    NotificationEntity make({bool isRead = false}) => NotificationEntity(
      id: 'e-1',
      type: 'orderUpdate',
      title: 'Mise à jour',
      body: 'Votre commande avance.',
      isRead: isRead,
      createdAt: DateTime(2024, 6, 1),
    );

    test('props contains id, type, title, isRead, createdAt', () {
      final entity = make();
      expect(
        entity.props,
        containsAll([
          entity.id,
          entity.type,
          entity.title,
          entity.isRead,
          entity.createdAt,
        ]),
      );
    });

    test('two identical entities are equal', () {
      expect(make(), equals(make()));
    });

    test('read vs unread are different', () {
      expect(make(isRead: false), isNot(equals(make(isRead: true))));
    });
  });
}
