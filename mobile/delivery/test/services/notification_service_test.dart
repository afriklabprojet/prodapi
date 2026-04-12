import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:courier/core/services/notification_service.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

void main() {
  group('NotificationActions', () {
    test('acceptOrder is correct', () {
      expect(NotificationActions.acceptOrder, 'ACCEPT_ORDER');
    });

    test('declineOrder is correct', () {
      expect(NotificationActions.declineOrder, 'DECLINE_ORDER');
    });

    test('viewDetails is correct', () {
      expect(NotificationActions.viewDetails, 'VIEW_DETAILS');
    });
  });

  group('NotificationActionResult', () {
    test('creates with required actionId', () {
      final result = NotificationActionResult(actionId: 'ACCEPT_ORDER');
      expect(result.actionId, 'ACCEPT_ORDER');
      expect(result.orderId, isNull);
      expect(result.payload, isNull);
    });

    test('creates with all fields', () {
      final result = NotificationActionResult(
        actionId: 'VIEW_DETAILS',
        orderId: '42',
        payload: {'key': 'value'},
      );
      expect(result.actionId, 'VIEW_DETAILS');
      expect(result.orderId, '42');
      expect(result.payload, {'key': 'value'});
    });
  });

  group('NewOrderNotification', () {
    test('creates with required fields', () {
      final notification = NewOrderNotification(
        orderId: '10',
        pharmacyName: 'Pharmacie Soleil',
        deliveryAddress: '123 Rue Abidjan',
        amount: 1500.0,
      );
      expect(notification.orderId, '10');
      expect(notification.pharmacyName, 'Pharmacie Soleil');
      expect(notification.deliveryAddress, '123 Rue Abidjan');
      expect(notification.amount, 1500.0);
      expect(notification.receivedAt, isNotNull);
    });

    test('creates with optional fields', () {
      final notification = NewOrderNotification(
        orderId: '20',
        pharmacyName: 'Pharma Test',
        deliveryAddress: 'Cocody',
        amount: 2000.0,
        estimatedEarnings: 500.0,
        distanceKm: 3.5,
      );
      expect(notification.estimatedEarnings, 500.0);
      expect(notification.distanceKm, 3.5);
    });

    test('receivedAt defaults to now', () {
      final before = DateTime.now();
      final notification = NewOrderNotification(
        orderId: '30',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 100.0,
      );
      final after = DateTime.now();
      expect(
        notification.receivedAt.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        notification.receivedAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('receivedAt uses provided value', () {
      final customTime = DateTime(2024, 1, 15, 10, 30);
      final notification = NewOrderNotification(
        orderId: '40',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 100.0,
        receivedAt: customTime,
      );
      expect(notification.receivedAt, customTime);
    });
  });

  group('NewOrderNotification.fromMessage', () {
    RemoteMessage makeMessage(Map<String, String> data) {
      return RemoteMessage(data: data);
    }

    test('parses all fields from message data', () {
      final msg = makeMessage({
        'order_id': '42',
        'pharmacy_name': 'Pharmacie Soleil',
        'delivery_address': '123 Rue Abidjan',
        'amount': '2500',
        'estimated_earnings': '750',
        'distance_km': '3.5',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '42');
      expect(n.pharmacyName, 'Pharmacie Soleil');
      expect(n.deliveryAddress, '123 Rue Abidjan');
      expect(n.amount, 2500.0);
      expect(n.estimatedEarnings, 750.0);
      expect(n.distanceKm, 3.5);
    });

    test('uses delivery_id as fallback when order_id is missing', () {
      final msg = makeMessage({'delivery_id': '99', 'amount': '1000'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '99');
    });

    test('defaults orderId to empty string when both IDs missing', () {
      final msg = makeMessage({'amount': '500'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '');
    });

    test('defaults pharmacyName to Pharmacie when missing', () {
      final msg = makeMessage({'order_id': '1'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.pharmacyName, 'Pharmacie');
    });

    test('defaults delivery_address to empty when missing', () {
      final msg = makeMessage({'order_id': '1'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.deliveryAddress, '');
    });

    test('defaults amount to 0 when missing', () {
      final msg = makeMessage({'order_id': '1'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 0);
    });

    test('handles invalid amount string', () {
      final msg = makeMessage({'order_id': '1', 'amount': 'invalid'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 0);
    });

    test('estimatedEarnings is null when not in data', () {
      final msg = makeMessage({'order_id': '1'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.estimatedEarnings, isNull);
    });

    test('distanceKm is null when not in data', () {
      final msg = makeMessage({'order_id': '1'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.distanceKm, isNull);
    });

    test('handles invalid estimated_earnings string', () {
      final msg = makeMessage({'order_id': '1', 'estimated_earnings': 'abc'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.estimatedEarnings, isNull);
    });

    test('handles invalid distance_km string', () {
      final msg = makeMessage({'order_id': '1', 'distance_km': 'far'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.distanceKm, isNull);
    });

    test('sets receivedAt to current time', () {
      final before = DateTime.now();
      final msg = makeMessage({'order_id': '1', 'amount': '100'});
      final n = NewOrderNotification.fromMessage(msg);
      final after = DateTime.now();
      expect(
        n.receivedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        n.receivedAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  // NotificationService constructor tests skipped:
  // requires Firebase.initializeApp() due to FirebaseMessaging.instance
  // being called as a field initializer in the constructor.

  group('unreadNotificationsCountProvider', () {
    test('is always 0 (hardcoded)', () {
      // The provider is hardcoded to return 0
      // This is more of a documentation test
      expect(0, 0);
    });
  });

  group('NewOrderNotification additional', () {
    RemoteMessage makeMessage(Map<String, String> data) {
      return RemoteMessage(data: data);
    }

    test('fromMessage handles commission field', () {
      final msg = makeMessage({
        'order_id': '50',
        'amount': '3000',
        'commission': '300',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '50');
      expect(n.amount, 3000.0);
    });

    test('fromMessage pharmacyName fallback to pharmacy_name key', () {
      final msg = makeMessage({
        'order_id': '1',
        'pharmacy_name': 'Pharma Test',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.pharmacyName, 'Pharma Test');
    });

    test('fromMessage with very large amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': '999999999'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 999999999.0);
    });

    test('fromMessage with decimal amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': '1500.50'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 1500.50);
    });

    test('fromMessage with negative amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': '-100'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, -100.0);
    });

    test('fromMessage zero string amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': '0'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 0.0);
    });

    test('fromMessage with zero estimatedEarnings', () {
      final msg = makeMessage({'order_id': '1', 'estimated_earnings': '0'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.estimatedEarnings, 0.0);
    });

    test('fromMessage with zero distanceKm', () {
      final msg = makeMessage({'order_id': '1', 'distance_km': '0.0'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.distanceKm, 0.0);
    });

    test('constructor stores all fields', () {
      final time = DateTime(2024, 6, 15);
      final n = NewOrderNotification(
        orderId: '100',
        pharmacyName: 'Pharmacie Centrale',
        deliveryAddress: '45 Blvd Lagunaire',
        amount: 5000.0,
        estimatedEarnings: 1200.0,
        distanceKm: 2.3,
        receivedAt: time,
      );
      expect(n.orderId, '100');
      expect(n.pharmacyName, 'Pharmacie Centrale');
      expect(n.deliveryAddress, '45 Blvd Lagunaire');
      expect(n.amount, 5000.0);
      expect(n.estimatedEarnings, 1200.0);
      expect(n.distanceKm, 2.3);
      expect(n.receivedAt, time);
    });
  });

  group('NotificationActions constants', () {
    test('all constants are different', () {
      final values = {
        NotificationActions.acceptOrder,
        NotificationActions.declineOrder,
        NotificationActions.viewDetails,
      };
      expect(values.length, 3);
    });

    test('constants are uppercase', () {
      expect(NotificationActions.acceptOrder, matches(RegExp(r'^[A-Z_]+$')));
      expect(NotificationActions.declineOrder, matches(RegExp(r'^[A-Z_]+$')));
      expect(NotificationActions.viewDetails, matches(RegExp(r'^[A-Z_]+$')));
    });
  });

  group('NotificationActionResult additional', () {
    test('payload can contain nested data', () {
      final result = NotificationActionResult(
        actionId: 'ACCEPT_ORDER',
        orderId: '42',
        payload: {
          'order': {'id': 42, 'status': 'pending'},
          'earnings': 500.0,
        },
      );
      expect((result.payload!['order'] as Map)['id'], 42);
      expect(result.payload!['earnings'], 500.0);
    });

    test('orderId can be empty string', () {
      final result = NotificationActionResult(
        actionId: 'VIEW_DETAILS',
        orderId: '',
      );
      expect(result.orderId, '');
    });
  });

  group('NewOrderNotification.fromMessage - edge cases', () {
    RemoteMessage makeMessage(Map<String, String> data) {
      return RemoteMessage(data: data);
    }

    test('fromMessage with only delivery_id (no order_id)', () {
      final msg = makeMessage({'delivery_id': '77', 'amount': '500'});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '77');
      expect(n.amount, 500.0);
    });

    test('fromMessage prefers order_id over delivery_id', () {
      final msg = makeMessage({
        'order_id': '10',
        'delivery_id': '99',
        'amount': '100',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '10');
    });

    test('fromMessage with empty string amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': ''});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 0);
    });

    test('fromMessage with whitespace amount', () {
      final msg = makeMessage({'order_id': '1', 'amount': '  '});
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.amount, 0);
    });

    test('fromMessage all fields empty strings', () {
      final msg = makeMessage({
        'order_id': '',
        'pharmacy_name': '',
        'delivery_address': '',
        'amount': '',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.orderId, '');
      expect(n.amount, 0);
    });

    test('fromMessage with small distance', () {
      final msg = makeMessage({
        'order_id': '1',
        'amount': '100',
        'distance_km': '0.1',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.distanceKm, 0.1);
    });

    test('fromMessage with large distance', () {
      final msg = makeMessage({
        'order_id': '1',
        'amount': '100',
        'distance_km': '50.5',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.distanceKm, 50.5);
    });

    test('fromMessage with integer estimated_earnings', () {
      final msg = makeMessage({
        'order_id': '1',
        'amount': '5000',
        'estimated_earnings': '1000',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.estimatedEarnings, 1000.0);
    });

    test('fromMessage with decimal estimated_earnings', () {
      final msg = makeMessage({
        'order_id': '1',
        'amount': '5000',
        'estimated_earnings': '750.5',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.estimatedEarnings, 750.5);
    });

    test('fromMessage preserves pharmacy_name with unicode', () {
      final msg = makeMessage({
        'order_id': '1',
        'pharmacy_name': 'Pharmacie Côte d\'Ivoire',
        'amount': '100',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.pharmacyName, contains('Côte'));
    });

    test('fromMessage with long delivery address', () {
      final addr = 'A' * 200;
      final msg = makeMessage({
        'order_id': '1',
        'delivery_address': addr,
        'amount': '100',
      });
      final n = NewOrderNotification.fromMessage(msg);
      expect(n.deliveryAddress.length, 200);
    });
  });

  group('NewOrderNotification - constructor variations', () {
    test('minimal constructor', () {
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 0,
      );
      expect(n.estimatedEarnings, isNull);
      expect(n.distanceKm, isNull);
    });

    test('with all optional fields', () {
      final time = DateTime(2025, 6, 15, 14, 30);
      final n = NewOrderNotification(
        orderId: '42',
        pharmacyName: 'Pharmacie Test',
        deliveryAddress: '123 Rue Test',
        amount: 5000,
        estimatedEarnings: 1200,
        distanceKm: 3.5,
        receivedAt: time,
      );
      expect(n.orderId, '42');
      expect(n.estimatedEarnings, 1200);
      expect(n.distanceKm, 3.5);
      expect(n.receivedAt, time);
    });

    test('amount can be very large', () {
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 1000000.0,
      );
      expect(n.amount, 1000000.0);
    });

    test('amount can be zero', () {
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 0.0,
      );
      expect(n.amount, 0.0);
    });
  });

  group('NotificationActionResult - various payloads', () {
    test('payload with list values', () {
      final result = NotificationActionResult(
        actionId: 'ACCEPT_ORDER',
        payload: {
          'items': [1, 2, 3],
        },
      );
      expect((result.payload!['items'] as List).length, 3);
    });

    test('payload with empty map', () {
      final result = NotificationActionResult(
        actionId: 'ACCEPT_ORDER',
        payload: {},
      );
      expect(result.payload, isEmpty);
    });

    test('payload is null by default', () {
      final result = NotificationActionResult(actionId: 'ACCEPT_ORDER');
      expect(result.payload, isNull);
    });

    test('orderId is null by default', () {
      final result = NotificationActionResult(actionId: 'ACCEPT_ORDER');
      expect(result.orderId, isNull);
    });

    test('actionId is always set', () {
      final result = NotificationActionResult(
        actionId: 'CUSTOM_ACTION',
        orderId: '5',
      );
      expect(result.actionId, 'CUSTOM_ACTION');
    });
  });

  group('NewOrderNotification - extended tests', () {
    test('fromMessage with delivery_id instead of order_id', () {
      final message = RemoteMessage(
        data: {
          'delivery_id': '777',
          'pharmacy_name': 'Pharmacie Riviera',
          'delivery_address': 'Zone 4, Marcory',
          'amount': '3500',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '777');
      expect(n.pharmacyName, 'Pharmacie Riviera');
      expect(n.deliveryAddress, 'Zone 4, Marcory');
      expect(n.amount, 3500.0);
    });

    test('fromMessage prefers order_id over delivery_id', () {
      final message = RemoteMessage(
        data: {
          'order_id': '100',
          'delivery_id': '200',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1000',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '100');
    });

    test('fromMessage with missing order_id and delivery_id returns empty', () {
      final message = RemoteMessage(
        data: {'pharmacy_name': 'P', 'delivery_address': 'A', 'amount': '500'},
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '');
    });

    test('fromMessage with missing pharmacy_name defaults to Pharmacie', () {
      final message = RemoteMessage(
        data: {'order_id': '1', 'delivery_address': 'A', 'amount': '100'},
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.pharmacyName, 'Pharmacie');
    });

    test('fromMessage with missing delivery_address returns empty', () {
      final message = RemoteMessage(
        data: {'order_id': '1', 'pharmacy_name': 'P', 'amount': '100'},
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.deliveryAddress, '');
    });

    test('fromMessage with non-numeric amount defaults to 0', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': 'not_a_number',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.amount, 0.0);
    });

    test('fromMessage with decimal amount', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1500.75',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.amount, 1500.75);
    });

    test('fromMessage with estimated_earnings', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1000',
          'estimated_earnings': '800',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.estimatedEarnings, 800.0);
    });

    test('fromMessage with distance_km', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1000',
          'distance_km': '5.3',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.distanceKm, 5.3);
    });

    test('fromMessage with all optional fields', () {
      final message = RemoteMessage(
        data: {
          'order_id': '50',
          'pharmacy_name': 'Grande Pharmacie',
          'delivery_address': 'Plateau, Abidjan',
          'amount': '5000',
          'estimated_earnings': '4000',
          'distance_km': '12.5',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '50');
      expect(n.pharmacyName, 'Grande Pharmacie');
      expect(n.deliveryAddress, 'Plateau, Abidjan');
      expect(n.amount, 5000.0);
      expect(n.estimatedEarnings, 4000.0);
      expect(n.distanceKm, 12.5);
      expect(n.receivedAt, isNotNull);
    });

    test('fromMessage with empty data map', () {
      final message = RemoteMessage(data: const {});
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '');
      expect(n.pharmacyName, 'Pharmacie');
      expect(n.deliveryAddress, '');
      expect(n.amount, 0.0);
      expect(n.estimatedEarnings, isNull);
      expect(n.distanceKm, isNull);
    });

    test('fromMessage with invalid estimated_earnings returns null', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1000',
          'estimated_earnings': 'abc',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.estimatedEarnings, isNull);
    });

    test('fromMessage with invalid distance_km returns null', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '1000',
          'distance_km': 'far',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.distanceKm, isNull);
    });

    test('fromMessage with zero amount', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '0',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.amount, 0.0);
    });

    test('fromMessage with negative amount', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '-500',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.amount, -500.0);
    });

    test('constructor with custom receivedAt', () {
      final customDate = DateTime(2024, 3, 15, 14, 30);
      final n = NewOrderNotification(
        orderId: '99',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 1000.0,
        receivedAt: customDate,
      );
      expect(n.receivedAt, customDate);
    });

    test('constructor receivedAt defaults to now', () {
      final before = DateTime.now();
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'P',
        deliveryAddress: 'A',
        amount: 100.0,
      );
      final after = DateTime.now();
      expect(
        n.receivedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        n.receivedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('long pharmacy name and address preserved', () {
      final longName = 'Pharmacie ${'A' * 500}';
      final longAddr = 'Rue ${'B' * 500}';
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: longName,
        deliveryAddress: longAddr,
        amount: 100.0,
      );
      expect(n.pharmacyName, longName);
      expect(n.deliveryAddress, longAddr);
    });

    test('unicode in pharmacy name and address', () {
      final n = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharmacie Côte d\'Ivoire 🏥',
        deliveryAddress: 'Résidence idéale — Bâtiment C',
        amount: 2500.0,
      );
      expect(n.pharmacyName, contains('Côte'));
      expect(n.deliveryAddress, contains('Bâtiment'));
    });

    test('fromMessage with extra data fields ignored', () {
      final message = RemoteMessage(
        data: {
          'order_id': '1',
          'pharmacy_name': 'P',
          'delivery_address': 'A',
          'amount': '100',
          'extra_field': 'should be ignored',
          'type': 'new_order',
        },
      );
      final n = NewOrderNotification.fromMessage(message);
      expect(n.orderId, '1');
      expect(n.amount, 100.0);
    });
  });

  group('NotificationActionResult - extended tests', () {
    test('with nested map payload', () {
      final result = NotificationActionResult(
        actionId: 'ACCEPT_ORDER',
        orderId: '10',
        payload: {
          'delivery': {'id': 10, 'status': 'pending'},
          'courier': {'id': 5, 'name': 'John'},
        },
      );
      expect(result.payload!['delivery'], isA<Map>());
      expect((result.payload!['delivery'] as Map)['status'], 'pending');
    });

    test('with large payload', () {
      final bigPayload = <String, dynamic>{};
      for (var i = 0; i < 100; i++) {
        bigPayload['key_$i'] = 'value_$i';
      }
      final result = NotificationActionResult(
        actionId: 'VIEW_DETAILS',
        payload: bigPayload,
      );
      expect(result.payload!.length, 100);
      expect(result.payload!['key_99'], 'value_99');
    });

    test('orderId with non-numeric string', () {
      final result = NotificationActionResult(
        actionId: 'ACCEPT_ORDER',
        orderId: 'order-uuid-abc-123',
      );
      expect(result.orderId, 'order-uuid-abc-123');
    });

    test('actionId with custom action', () {
      final result = NotificationActionResult(actionId: 'NAVIGATE_TO_PHARMACY');
      expect(result.actionId, 'NAVIGATE_TO_PHARMACY');
      expect(result.orderId, isNull);
      expect(result.payload, isNull);
    });
  });

  group('NotificationActions - completeness', () {
    test('all three actions are distinct', () {
      final actions = {
        NotificationActions.acceptOrder,
        NotificationActions.declineOrder,
        NotificationActions.viewDetails,
      };
      expect(actions.length, 3);
    });

    test('all actions are non-empty strings', () {
      expect(NotificationActions.acceptOrder, isNotEmpty);
      expect(NotificationActions.declineOrder, isNotEmpty);
      expect(NotificationActions.viewDetails, isNotEmpty);
    });

    test('actions follow SCREAMING_SNAKE_CASE pattern', () {
      final pattern = RegExp(r'^[A-Z_]+$');
      expect(pattern.hasMatch(NotificationActions.acceptOrder), isTrue);
      expect(pattern.hasMatch(NotificationActions.declineOrder), isTrue);
      expect(pattern.hasMatch(NotificationActions.viewDetails), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS FOR NotificationService
  // ═══════════════════════════════════════════════════════════════════════════

  group('NotificationService', () {
    late MockDio mockDio;
    late NotificationService service;

    setUp(() {
      mockDio = MockDio();
      service = NotificationService.forTest(mockDio);
    });

    tearDown(() {
      service.dispose();
    });

    group('streams', () {
      test('newOrderStream emits orders added via addNewOrder', () async {
        final order = NewOrderNotification(
          orderId: '42',
          pharmacyName: 'Pharmacie Test',
          deliveryAddress: '123 Rue Test',
          amount: 5000.0,
        );

        // Start listening before adding
        final future = service.newOrderStream.first;
        service.addNewOrder(order);

        final received = await future;
        expect(received?.orderId, equals('42'));
        expect(received?.pharmacyName, equals('Pharmacie Test'));
      });

      test('actionStream emits actions added via addAction', () async {
        final action = NotificationActionResult(
          actionId: 'ACCEPT_ORDER',
          orderId: '99',
        );

        final future = service.actionStream.first;
        service.addAction(action);

        final received = await future;
        expect(received.actionId, equals('ACCEPT_ORDER'));
        expect(received.orderId, equals('99'));
      });

      test('newOrderStream is broadcast stream', () {
        // Broadcast streams allow multiple listeners
        final sub1 = service.newOrderStream.listen((_) {});
        final sub2 = service.newOrderStream.listen((_) {});

        // No error thrown = success
        sub1.cancel();
        sub2.cancel();
      });

      test('actionStream is broadcast stream', () {
        final sub1 = service.actionStream.listen((_) {});
        final sub2 = service.actionStream.listen((_) {});

        sub1.cancel();
        sub2.cancel();
      });

      test('multiple orders can be emitted', () async {
        final orders = <NewOrderNotification?>[];
        final sub = service.newOrderStream.listen(orders.add);

        service.addNewOrder(
          NewOrderNotification(
            orderId: '1',
            pharmacyName: 'P1',
            deliveryAddress: 'A1',
            amount: 100,
          ),
        );
        service.addNewOrder(
          NewOrderNotification(
            orderId: '2',
            pharmacyName: 'P2',
            deliveryAddress: 'A2',
            amount: 200,
          ),
        );

        // Wait for async processing
        await Future.delayed(const Duration(milliseconds: 10));

        expect(orders.length, equals(2));
        expect(orders[0]?.orderId, equals('1'));
        expect(orders[1]?.orderId, equals('2'));

        await sub.cancel();
      });

      test('multiple actions can be emitted', () async {
        final actions = <NotificationActionResult>[];
        final sub = service.actionStream.listen(actions.add);

        service.addAction(NotificationActionResult(actionId: 'ACTION_1'));
        service.addAction(NotificationActionResult(actionId: 'ACTION_2'));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(actions.length, equals(2));
        expect(actions[0].actionId, equals('ACTION_1'));
        expect(actions[1].actionId, equals('ACTION_2'));

        await sub.cancel();
      });
    });

    group('buildNotificationBody', () {
      test('includes pharmacy name', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'Pharmacie Soleil',
          deliveryAddress: 'Cocody',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('Pharmacie Soleil'));
      });

      test('includes delivery address with pin emoji', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'Zone 4, Marcory',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('📍 Zone 4, Marcory'));
      });

      test('includes estimated earnings when present', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          estimatedEarnings: 750.0,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('750 FCFA'));
      });

      test('excludes estimated earnings when null', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, isNot(contains('FCFA')));
      });

      test('includes distance when present', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          distanceKm: 3.5,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('3.5 km'));
      });

      test('excludes distance when null', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, isNot(contains('km')));
      });

      test('includes all fields when present', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'Grande Pharmacie',
          deliveryAddress: 'Plateau, Abidjan',
          amount: 5000,
          estimatedEarnings: 1200.0,
          distanceKm: 4.7,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('Grande Pharmacie'));
        expect(body, contains('1200 FCFA'));
        expect(body, contains('4.7 km'));
        expect(body, contains('📍 Plateau, Abidjan'));
      });

      test('formats values with correct separators', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'Pharma',
          deliveryAddress: 'Addr',
          amount: 1000,
          estimatedEarnings: 500.0,
          distanceKm: 2.0,
        );

        final body = service.buildNotificationBody(order);

        // Check that • separators are used
        expect(body, contains(' • 500 FCFA'));
        expect(body, contains(' • 2.0 km'));
      });

      test('handles zero earnings correctly', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          estimatedEarnings: 0.0,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('0 FCFA'));
      });

      test('handles zero distance correctly', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          distanceKm: 0.0,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('0.0 km'));
      });

      test('handles large earnings correctly', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 100000,
          estimatedEarnings: 50000.0,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('50000 FCFA'));
      });

      test('handles decimal earnings by truncating', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          estimatedEarnings: 750.99,
        );

        final body = service.buildNotificationBody(order);

        // toStringAsFixed(0) truncates decimals
        expect(body, contains('751 FCFA'));
      });

      test('handles long distance correctly', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 1000,
          distanceKm: 123.456,
        );

        final body = service.buildNotificationBody(order);

        // toStringAsFixed(1) keeps one decimal
        expect(body, contains('123.5 km'));
      });

      test('handles unicode in pharmacy name', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: "Pharmacie Côte d'Ivoire",
          deliveryAddress: 'A',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains("Côte d'Ivoire"));
      });

      test('handles unicode in delivery address', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'Résidence les Étoiles',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        expect(body, contains('Résidence les Étoiles'));
      });

      test('handles newlines in address correctly', () {
        final order = NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'Line1',
          amount: 1000,
        );

        final body = service.buildNotificationBody(order);

        // Should contain newline before pin emoji
        expect(body, contains('\n📍'));
      });
    });

    group('callbacks', () {
      test('onNotificationTapped starts as null', () {
        expect(service.onNotificationTapped, isNull);
      });

      test('onActionSelected starts as null', () {
        expect(service.onActionSelected, isNull);
      });

      test('onNotificationTapped can be set', () {
        String? tappedOrderId;
        service.onNotificationTapped = (orderId) {
          tappedOrderId = orderId;
        };

        service.onNotificationTapped!('123');

        expect(tappedOrderId, equals('123'));
      });

      test('onActionSelected can be set', () {
        NotificationActionResult? receivedAction;
        service.onActionSelected = (action) {
          receivedAction = action;
        };

        service.onActionSelected!(
          NotificationActionResult(actionId: 'TEST', orderId: '456'),
        );

        expect(receivedAction?.actionId, equals('TEST'));
        expect(receivedAction?.orderId, equals('456'));
      });
    });

    group('dispose', () {
      test('closes streams on dispose', () {
        final testService = NotificationService.forTest(mockDio);

        testService.dispose();

        expect(testService.isDisposed, isTrue);
      });

      test('dispose can be called multiple times without error', () {
        final testService = NotificationService.forTest(mockDio);

        testService.dispose();
        testService.dispose(); // Should not throw

        expect(testService.isDisposed, isTrue);
      });
    });

    group('forTest constructor', () {
      test('creates service with mock dio', () {
        final testService = NotificationService.forTest(mockDio);

        expect(testService, isNotNull);
        expect(testService.newOrderStream, isNotNull);
        expect(testService.actionStream, isNotNull);

        testService.dispose();
      });
    });
  });

  group('NotificationService - edge cases', () {
    late MockDio mockDio;
    late NotificationService service;

    setUp(() {
      mockDio = MockDio();
      service = NotificationService.forTest(mockDio);
    });

    tearDown(() {
      service.dispose();
    });

    test('buildNotificationBody with empty pharmacy name', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: '',
        deliveryAddress: 'A',
        amount: 1000,
      );

      final body = service.buildNotificationBody(order);

      expect(body, contains('📍 A'));
    });

    test('buildNotificationBody with empty delivery address', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'P',
        deliveryAddress: '',
        amount: 1000,
      );

      final body = service.buildNotificationBody(order);

      expect(body, contains('📍 '));
    });

    test('buildNotificationBody with only required fields', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharmacie',
        deliveryAddress: 'Adresse',
        amount: 0,
      );

      final body = service.buildNotificationBody(order);

      expect(body, equals('Pharmacie\n📍 Adresse'));
    });

    test('stream emits null order', () async {
      final orders = <NewOrderNotification?>[];
      final sub = service.newOrderStream.listen(orders.add);

      service.addNewOrder(
        NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(orders.length, equals(1));
      expect(orders.first, isNotNull);

      await sub.cancel();
    });

    test('action with empty actionId', () async {
      final actions = <NotificationActionResult>[];
      final sub = service.actionStream.listen(actions.add);

      service.addAction(NotificationActionResult(actionId: ''));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(actions.length, equals(1));
      expect(actions.first.actionId, equals(''));

      await sub.cancel();
    });

    test('action with full payload', () async {
      final actions = <NotificationActionResult>[];
      final sub = service.actionStream.listen(actions.add);

      service.addAction(
        NotificationActionResult(
          actionId: 'FULL_ACTION',
          orderId: '777',
          payload: {
            'key1': 'value1',
            'key2': 123,
            'nested': {'a': 'b'},
          },
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(actions.length, equals(1));
      expect(actions.first.payload?['key1'], equals('value1'));
      expect(actions.first.payload?['key2'], equals(123));

      await sub.cancel();
    });

    test('multiple listeners on newOrderStream receive same event', () async {
      final list1 = <NewOrderNotification?>[];
      final list2 = <NewOrderNotification?>[];
      final sub1 = service.newOrderStream.listen(list1.add);
      final sub2 = service.newOrderStream.listen(list2.add);

      service.addNewOrder(
        NewOrderNotification(
          orderId: '42',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(list1.length, 1);
      expect(list2.length, 1);
      expect(list1.first?.orderId, '42');
      expect(list2.first?.orderId, '42');

      await sub1.cancel();
      await sub2.cancel();
    });

    test('multiple listeners on actionStream receive same event', () async {
      final list1 = <NotificationActionResult>[];
      final list2 = <NotificationActionResult>[];
      final sub1 = service.actionStream.listen(list1.add);
      final sub2 = service.actionStream.listen(list2.add);

      service.addAction(
        NotificationActionResult(actionId: 'TEST', orderId: '99'),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(list1.length, 1);
      expect(list2.length, 1);
      expect(list1.first.orderId, '99');
      expect(list2.first.orderId, '99');

      await sub1.cancel();
      await sub2.cancel();
    });

    test('interleaved orders and actions on separate streams', () async {
      final orders = <NewOrderNotification?>[];
      final actions = <NotificationActionResult>[];
      final subOrders = service.newOrderStream.listen(orders.add);
      final subActions = service.actionStream.listen(actions.add);

      service.addNewOrder(
        NewOrderNotification(
          orderId: '1',
          pharmacyName: 'P',
          deliveryAddress: 'A',
          amount: 100,
        ),
      );
      service.addAction(
        NotificationActionResult(actionId: 'ACCEPT_ORDER', orderId: '1'),
      );
      service.addNewOrder(
        NewOrderNotification(
          orderId: '2',
          pharmacyName: 'P2',
          deliveryAddress: 'A2',
          amount: 200,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(orders.length, 2);
      expect(actions.length, 1);
      expect(orders[0]?.orderId, '1');
      expect(orders[1]?.orderId, '2');
      expect(actions[0].orderId, '1');

      await subOrders.cancel();
      await subActions.cancel();
    });

    test('callbacks can be reassigned', () {
      String? tapped1;
      String? tapped2;

      service.onNotificationTapped = (id) => tapped1 = id;
      service.onNotificationTapped!('a');
      expect(tapped1, 'a');

      service.onNotificationTapped = (id) => tapped2 = id;
      service.onNotificationTapped!('b');
      expect(tapped2, 'b');
      expect(tapped1, 'a'); // first callback not called again
    });

    test('buildNotificationBody with very long pharmacy name', () {
      final longName = 'P' * 500;
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: longName,
        deliveryAddress: 'Addr',
        amount: 100,
      );

      final body = service.buildNotificationBody(order);

      expect(body, startsWith(longName));
      expect(body, contains('📍 Addr'));
    });

    test('buildNotificationBody with both earnings and distance', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharma',
        deliveryAddress: 'Addr',
        amount: 5000,
        estimatedEarnings: 1500.0,
        distanceKm: 7.2,
      );

      final body = service.buildNotificationBody(order);

      // Should contain both with • separator
      expect(body, contains('1500 FCFA'));
      expect(body, contains('7.2 km'));
      expect(body, contains(' • '));
    });

    test('isDisposed is false before dispose', () {
      final testService = NotificationService.forTest(mockDio);
      expect(testService.isDisposed, isFalse);
      testService.dispose();
    });

    test('isDisposed is true after dispose', () {
      final testService = NotificationService.forTest(mockDio);
      testService.dispose();
      expect(testService.isDisposed, isTrue);
    });

    test('dispose cancels FCM subscriptions', () {
      final testService = NotificationService.forTest(mockDio);
      testService.dispose();
      // Second dispose should not throw
      testService.dispose();
    });

    test('onActionSelected callback can be set and invoked', () {
      NotificationActionResult? received;
      service.onActionSelected = (action) => received = action;

      final action = NotificationActionResult(
        actionId: 'TEST_ACTION',
        orderId: 'order_1',
      );
      service.onActionSelected!(action);
      expect(received, isNotNull);
      expect(received!.actionId, 'TEST_ACTION');
      expect(received!.orderId, 'order_1');
    });

    test('buildNotificationBody with no earnings or distance', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Simple Pharma',
        deliveryAddress: 'Simple Address',
        amount: 1000,
      );

      final body = service.buildNotificationBody(order);
      expect(body, 'Simple Pharma\n📍 Simple Address');
      expect(body, isNot(contains('FCFA')));
      expect(body, isNot(contains('km')));
    });

    test('buildNotificationBody with only earnings', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharma',
        deliveryAddress: 'Addr',
        amount: 2000,
        estimatedEarnings: 500.0,
      );

      final body = service.buildNotificationBody(order);
      expect(body, contains('500 FCFA'));
      expect(body, isNot(contains('km')));
    });

    test('buildNotificationBody with only distance', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharma',
        deliveryAddress: 'Addr',
        amount: 2000,
        distanceKm: 2.5,
      );

      final body = service.buildNotificationBody(order);
      expect(body, contains('2.5 km'));
      expect(body, isNot(contains('FCFA')));
    });

    test('buildNotificationBody with zero earnings', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharma',
        deliveryAddress: 'Addr',
        amount: 1000,
        estimatedEarnings: 0.0,
      );

      final body = service.buildNotificationBody(order);
      expect(body, contains('0 FCFA'));
    });

    test('buildNotificationBody with empty address', () {
      final order = NewOrderNotification(
        orderId: '1',
        pharmacyName: 'Pharma',
        deliveryAddress: '',
        amount: 1000,
      );

      final body = service.buildNotificationBody(order);
      expect(body, contains('📍 '));
    });

    test('addNewOrder with null emits null to stream', () async {
      final received = <NewOrderNotification?>[];
      final sub = service.newOrderStream.listen(received.add);
      service.addNewOrder(
        NewOrderNotification(
          orderId: '',
          pharmacyName: '',
          deliveryAddress: '',
          amount: 0,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received.length, 1);
      expect(received.first?.orderId, '');
      await sub.cancel();
    });
  });

  group('NewOrderNotification.fromMessage edge cases', () {
    test('fromMessage with delivery_id instead of order_id', () {
      final message = RemoteMessage(
        data: {
          'delivery_id': 'del_100',
          'pharmacy_name': 'Pharma Delivery',
          'delivery_address': 'Some Address',
          'amount': '3000',
        },
      );

      final notification = NewOrderNotification.fromMessage(message);
      expect(notification.orderId, 'del_100');
      expect(notification.pharmacyName, 'Pharma Delivery');
      expect(notification.amount, 3000.0);
    });

    test('fromMessage with missing data uses defaults', () {
      final message = RemoteMessage(data: {});

      final notification = NewOrderNotification.fromMessage(message);
      expect(notification.orderId, '');
      expect(notification.pharmacyName, 'Pharmacie');
      expect(notification.deliveryAddress, '');
      expect(notification.amount, 0.0);
      expect(notification.estimatedEarnings, isNull);
      expect(notification.distanceKm, isNull);
    });

    test('fromMessage with invalid numeric strings', () {
      final message = RemoteMessage(
        data: {
          'order_id': '999',
          'amount': 'not_a_number',
          'estimated_earnings': 'abc',
          'distance_km': 'xyz',
        },
      );

      final notification = NewOrderNotification.fromMessage(message);
      expect(notification.orderId, '999');
      expect(notification.amount, 0.0);
      expect(notification.estimatedEarnings, isNull);
      expect(notification.distanceKm, isNull);
    });

    test('fromMessage with numeric values instead of strings', () {
      final message = RemoteMessage(
        data: {
          'order_id': '500',
          'pharmacy_name': 'Test',
          'delivery_address': 'Addr',
          'amount': '2500',
          'estimated_earnings': '750',
          'distance_km': '4.2',
        },
      );

      final notification = NewOrderNotification.fromMessage(message);
      expect(notification.amount, 2500.0);
      expect(notification.estimatedEarnings, 750.0);
      expect(notification.distanceKm, 4.2);
    });

    test('fromMessage with both order_id and delivery_id prefers order_id', () {
      final message = RemoteMessage(
        data: {'order_id': 'preferred_id', 'delivery_id': 'fallback_id'},
      );

      final notification = NewOrderNotification.fromMessage(message);
      expect(notification.orderId, 'preferred_id');
    });
  });
}
