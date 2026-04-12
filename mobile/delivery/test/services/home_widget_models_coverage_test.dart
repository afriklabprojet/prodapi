import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/delivery_proof_service.dart';
import 'package:courier/core/services/home_widget_service.dart';

void main() {
  // ════════════════════════════════════════════
  // DeliveryProof model
  // ════════════════════════════════════════════
  group('DeliveryProof', () {
    test('constructor with defaults', () {
      final proof = DeliveryProof();
      expect(proof.photo, null);
      expect(proof.signatureBytes, null);
      expect(proof.notes, null);
      expect(proof.timestamp, isA<DateTime>());
      expect(proof.latitude, null);
      expect(proof.longitude, null);
    });

    test('hasPhoto is false when no photo', () {
      final proof = DeliveryProof();
      expect(proof.hasPhoto, false);
    });

    test('hasSignature is false when no signature', () {
      final proof = DeliveryProof();
      expect(proof.hasSignature, false);
    });

    test('hasSignature is false when empty bytes', () {
      final proof = DeliveryProof(signatureBytes: Uint8List(0));
      expect(proof.hasSignature, false);
    });

    test('hasSignature is true when bytes present', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(proof.hasSignature, true);
    });

    test('isValid is false when no photo and no signature', () {
      final proof = DeliveryProof();
      expect(proof.isValid, false);
    });

    test('isValid is true when signature present', () {
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(proof.isValid, true);
    });

    test('constructor with all params', () {
      final now = DateTime(2024, 1, 15);
      final proof = DeliveryProof(
        signatureBytes: Uint8List.fromList([10, 20]),
        notes: 'Left at door',
        timestamp: now,
        latitude: 48.8566,
        longitude: 2.3522,
      );
      expect(proof.notes, 'Left at door');
      expect(proof.timestamp, now);
      expect(proof.latitude, 48.8566);
      expect(proof.longitude, 2.3522);
    });
  });

  // ════════════════════════════════════════════
  // HomeWidgetKeys constants
  // ════════════════════════════════════════════
  group('HomeWidgetKeys', () {
    test('isOnline', () => expect(HomeWidgetKeys.isOnline, 'is_online'));
    test(
      'hasActiveDelivery',
      () => expect(HomeWidgetKeys.hasActiveDelivery, 'has_active_delivery'),
    );
    test(
      'activeDeliveryId',
      () => expect(HomeWidgetKeys.activeDeliveryId, 'active_delivery_id'),
    );
    test(
      'pharmacyName',
      () => expect(HomeWidgetKeys.pharmacyName, 'pharmacy_name'),
    );
    test(
      'customerAddress',
      () => expect(HomeWidgetKeys.customerAddress, 'customer_address'),
    );
    test(
      'deliveryStatus',
      () => expect(HomeWidgetKeys.deliveryStatus, 'delivery_status'),
    );
    test(
      'estimatedTime',
      () => expect(HomeWidgetKeys.estimatedTime, 'estimated_time'),
    );
    test(
      'todayEarnings',
      () => expect(HomeWidgetKeys.todayEarnings, 'today_earnings'),
    );
    test(
      'todayDeliveries',
      () => expect(HomeWidgetKeys.todayDeliveries, 'today_deliveries'),
    );
    test(
      'lastUpdated',
      () => expect(HomeWidgetKeys.lastUpdated, 'last_updated'),
    );
  });

  // ════════════════════════════════════════════
  // WidgetDeliveryStatus enum
  // ════════════════════════════════════════════
  group('WidgetDeliveryStatus', () {
    test('has 5 values', () {
      expect(WidgetDeliveryStatus.values.length, 5);
    });

    test('none', () => expect(WidgetDeliveryStatus.none.index, 0));
    test('toPickup', () => expect(WidgetDeliveryStatus.toPickup.index, 1));
    test('atPharmacy', () => expect(WidgetDeliveryStatus.atPharmacy.index, 2));
    test('enRoute', () => expect(WidgetDeliveryStatus.enRoute.index, 3));
    test('atCustomer', () => expect(WidgetDeliveryStatus.atCustomer.index, 4));
  });
}
