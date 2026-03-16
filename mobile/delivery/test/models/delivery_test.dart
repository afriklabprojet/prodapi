import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery.dart';

void main() {
  group('Delivery Model Tests', () {
    test('should create Delivery from JSON', () {
      final json = {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharmacie Centrale',
        'pharmacy_address': '123 Pharmacy Street',
        'pharmacy_phone': '+225 0101010101',
        'customer_name': 'John Doe',
        'customer_phone': '+225 0707070707',
        'delivery_address': '456 Customer Avenue',
        'pharmacy_latitude': 5.3484,
        'pharmacy_longitude': -3.9485,
        'delivery_latitude': 5.3600,
        'delivery_longitude': -3.9700,
        'total_amount': 15000.0,
        'delivery_fee': 1500.0,
        'commission': 300.0,
        'estimated_earnings': 1200.0,
        'distance_km': 2.5,
        'status': 'pending',
        'created_at': '2024-01-15T09:00:00.000Z',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.id, 1);
      expect(delivery.reference, 'DEL-001');
      expect(delivery.pharmacyName, 'Pharmacie Centrale');
      expect(delivery.customerName, 'John Doe');
      expect(delivery.status, 'pending');
      expect(delivery.deliveryAddress, '456 Customer Avenue');
      expect(delivery.totalAmount, 15000.0);
      expect(delivery.deliveryFee, 1500.0);
      expect(delivery.estimatedEarnings, 1200.0);
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 1,
        'reference': 'DEL-002',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Test Address',
        'customer_name': 'Jane Doe',
        'delivery_address': 'Test Delivery',
        'total_amount': 5000.0,
        'status': 'pending',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.id, 1);
      expect(delivery.pharmacyPhone, isNull);
      expect(delivery.customerPhone, isNull);
      expect(delivery.deliveryFee, isNull);
      expect(delivery.commission, isNull);
      expect(delivery.distanceKm, isNull);
    });

    test('should convert Delivery to JSON', () {
      final delivery = Delivery(
        id: 1,
        reference: 'DEL-003',
        pharmacyName: 'Pharmacie ABC',
        pharmacyAddress: 'Pickup Address',
        customerName: 'Customer X',
        deliveryAddress: 'Delivery Address',
        totalAmount: 20000.0,
        status: 'delivered',
        deliveryFee: 2000.0,
        estimatedEarnings: 1600.0,
        pharmacyLat: 5.35,
        pharmacyLng: -3.95,
        deliveryLat: 5.36,
        deliveryLng: -3.96,
      );

      final json = delivery.toJson();

      expect(json['id'], 1);
      expect(json['reference'], 'DEL-003');
      expect(json['status'], 'delivered');
      expect(json['delivery_fee'], 2000.0);
      expect(json['total_amount'], 20000.0);
    });
  });

  group('Delivery Status Tests', () {
    test('should identify all valid statuses', () {
      final statuses = ['pending', 'accepted', 'picked_up', 'in_transit', 'delivered', 'cancelled'];
      
      for (final status in statuses) {
        final delivery = Delivery(
          id: 1,
          reference: 'DEL-STATUS-$status',
          pharmacyName: 'Pharmacy',
          pharmacyAddress: 'Address A',
          customerName: 'Customer',
          deliveryAddress: 'Address B',
          totalAmount: 1000.0,
          status: status,
        );
        expect(delivery.status, status);
      }
    });
  });
}
