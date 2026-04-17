import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/home_widget_service.dart';

void main() {
  group('HomeWidgetKeys', () {
    test('isOnline key is correct', () {
      expect(HomeWidgetKeys.isOnline, 'is_online');
    });

    test('hasActiveDelivery key is correct', () {
      expect(HomeWidgetKeys.hasActiveDelivery, 'has_active_delivery');
    });

    test('activeDeliveryId key is correct', () {
      expect(HomeWidgetKeys.activeDeliveryId, 'active_delivery_id');
    });

    test('pharmacyName key is correct', () {
      expect(HomeWidgetKeys.pharmacyName, 'pharmacy_name');
    });

    test('customerAddress key is correct', () {
      expect(HomeWidgetKeys.customerAddress, 'customer_address');
    });

    test('deliveryStatus key is correct', () {
      expect(HomeWidgetKeys.deliveryStatus, 'delivery_status');
    });

    test('estimatedTime key is correct', () {
      expect(HomeWidgetKeys.estimatedTime, 'estimated_time');
    });

    test('todayEarnings key is correct', () {
      expect(HomeWidgetKeys.todayEarnings, 'today_earnings');
    });

    test('todayDeliveries key is correct', () {
      expect(HomeWidgetKeys.todayDeliveries, 'today_deliveries');
    });

    test('lastUpdated key is correct', () {
      expect(HomeWidgetKeys.lastUpdated, 'last_updated');
    });
  });

  group('WidgetDeliveryStatus', () {
    test('has 5 values', () {
      expect(WidgetDeliveryStatus.values.length, 5);
    });

    test('contains all expected statuses', () {
      expect(WidgetDeliveryStatus.values, contains(WidgetDeliveryStatus.none));
      expect(
        WidgetDeliveryStatus.values,
        contains(WidgetDeliveryStatus.toPickup),
      );
      expect(
        WidgetDeliveryStatus.values,
        contains(WidgetDeliveryStatus.atPharmacy),
      );
      expect(
        WidgetDeliveryStatus.values,
        contains(WidgetDeliveryStatus.enRoute),
      );
      expect(
        WidgetDeliveryStatus.values,
        contains(WidgetDeliveryStatus.atCustomer),
      );
    });

    test('name values are correct', () {
      expect(WidgetDeliveryStatus.none.name, 'none');
      expect(WidgetDeliveryStatus.toPickup.name, 'toPickup');
      expect(WidgetDeliveryStatus.atPharmacy.name, 'atPharmacy');
      expect(WidgetDeliveryStatus.enRoute.name, 'enRoute');
      expect(WidgetDeliveryStatus.atCustomer.name, 'atCustomer');
    });
  });
}
