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
      final statuses = [
        'pending',
        'accepted',
        'picked_up',
        'in_transit',
        'delivered',
        'cancelled',
      ];

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

  group('Delivery New Fields Tests', () {
    test('should parse estimatedDuration from JSON', () {
      final json = {
        'id': 1,
        'reference': 'DEL-ETA-001',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client Test',
        'delivery_address': 'Addr B',
        'total_amount': 5000.0,
        'status': 'accepted',
        'estimated_duration': 15,
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.estimatedDuration, 15);
    });

    test('should parse estimatedDuration as string from JSON', () {
      final json = {
        'id': 2,
        'reference': 'DEL-ETA-002',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client Test',
        'delivery_address': 'Addr B',
        'total_amount': 5000.0,
        'status': 'accepted',
        'estimated_duration': '25',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.estimatedDuration, 25);
    });

    test('should handle null estimatedDuration', () {
      final json = {
        'id': 3,
        'reference': 'DEL-ETA-003',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client Test',
        'delivery_address': 'Addr B',
        'total_amount': 5000.0,
        'status': 'pending',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.estimatedDuration, isNull);
    });

    test('should parse updatedAt from JSON', () {
      final json = {
        'id': 4,
        'reference': 'DEL-UPD-001',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client Test',
        'delivery_address': 'Addr B',
        'total_amount': 5000.0,
        'status': 'delivered',
        'updated_at': '2025-06-15T14:30:00.000Z',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.updatedAt, '2025-06-15T14:30:00.000Z');
    });

    test('should parse notes from JSON', () {
      final json = {
        'id': 5,
        'reference': 'DEL-NOTE-001',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client Test',
        'delivery_address': 'Addr B',
        'total_amount': 5000.0,
        'status': 'in_transit',
        'notes': 'Fragile, attention à la livraison',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.notes, 'Fragile, attention à la livraison');
    });

    test('should include new fields in toJson', () {
      final delivery = Delivery(
        id: 6,
        reference: 'DEL-ALL-001',
        pharmacyName: 'Pharmacie Complète',
        pharmacyAddress: 'Addr A',
        customerName: 'Client Complet',
        deliveryAddress: 'Addr B',
        totalAmount: 12000.0,
        status: 'accepted',
        estimatedDuration: 20,
        updatedAt: '2025-06-15T15:00:00.000Z',
        notes: 'Livraison urgente',
      );

      final json = delivery.toJson();

      expect(json['estimated_duration'], 20);
      expect(json['updated_at'], '2025-06-15T15:00:00.000Z');
      expect(json['notes'], 'Livraison urgente');
    });

    test('should handle all new fields as null', () {
      final delivery = Delivery(
        id: 7,
        reference: 'DEL-NULL-001',
        pharmacyName: 'Pharmacie Test',
        pharmacyAddress: 'Addr A',
        customerName: 'Client Test',
        deliveryAddress: 'Addr B',
        totalAmount: 3000.0,
        status: 'pending',
      );

      expect(delivery.estimatedDuration, isNull);
      expect(delivery.updatedAt, isNull);
      expect(delivery.notes, isNull);
    });

    test('should create delivery with all fields via constructor', () {
      final delivery = Delivery(
        id: 8,
        reference: 'DEL-FULL-001',
        pharmacyName: 'Pharmacie Complète',
        pharmacyAddress: 'Addr A',
        pharmacyPhone: '+225 0101010101',
        customerName: 'Client Complet',
        customerPhone: '+225 0707070707',
        deliveryAddress: 'Addr B',
        pharmacyLat: 5.35,
        pharmacyLng: -3.95,
        deliveryLat: 5.36,
        deliveryLng: -3.96,
        totalAmount: 15000.0,
        deliveryFee: 1500.0,
        commission: 300.0,
        estimatedEarnings: 1200.0,
        distanceKm: 2.5,
        estimatedDuration: 30,
        status: 'delivered',
        createdAt: '2025-06-15T10:00:00.000Z',
        updatedAt: '2025-06-15T11:00:00.000Z',
        notes: 'Livraison effectuée sans problème',
      );

      expect(delivery.id, 8);
      expect(delivery.estimatedDuration, 30);
      expect(delivery.updatedAt, '2025-06-15T11:00:00.000Z');
      expect(delivery.notes, 'Livraison effectuée sans problème');
      expect(delivery.distanceKm, 2.5);
      expect(delivery.commission, 300.0);
    });
  });
}
