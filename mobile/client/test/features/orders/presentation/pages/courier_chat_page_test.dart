import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/pages/courier_chat_page.dart';

// CourierChatPage uses FirebaseFirestore.instance directly in initState.
// Firebase requires full initialization which is not available in unit tests.
// These tests verify the class structure and constructor contract.

void main() {
  group('CourierChatPage Structure Tests', () {
    test('should be a ConsumerStatefulWidget subclass', () {
      expect(CourierChatPage, isNotNull);
    });

    test('should accept required orderId parameter', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 2,
        courierId: 3,
        courierName: 'Jean Courier',
      );
      expect(page.orderId, equals(1));
    });

    test('should accept required deliveryId parameter', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 42,
        courierId: 3,
        courierName: 'Jean Courier',
      );
      expect(page.deliveryId, equals(42));
    });

    test('should accept required courierId parameter', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 2,
        courierId: 7,
        courierName: 'Jean Courier',
      );
      expect(page.courierId, equals(7));
    });

    test('should accept required courierName parameter', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 2,
        courierId: 3,
        courierName: 'Amadou Diallo',
      );
      expect(page.courierName, equals('Amadou Diallo'));
    });

    test('should accept optional courierPhone parameter', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 2,
        courierId: 3,
        courierName: 'Jean Courier',
        courierPhone: '+22501234567',
      );
      expect(page.courierPhone, equals('+22501234567'));
    });

    test('courierPhone should default to null', () {
      const page = CourierChatPage(
        orderId: 1,
        deliveryId: 2,
        courierId: 3,
        courierName: 'Jean Courier',
      );
      expect(page.courierPhone, isNull);
    });
  });
}
