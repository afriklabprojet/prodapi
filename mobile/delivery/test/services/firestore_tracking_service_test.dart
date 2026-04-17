import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:courier/core/services/firestore_tracking_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreTrackingService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreTrackingService(firestore: fakeFirestore);
  });

  tearDown(() {
    service.dispose();
  });

  group('FirestoreTrackingService', () {
    test('initialize sets courier ID', () {
      service.initialize(42);
      // Should not throw
    });

    test('goOnline updates Firestore document', () async {
      service.initialize(1);
      await service.goOnline();

      final doc = await fakeFirestore.collection('couriers').doc('1').get();
      expect(doc.exists, true);
      expect(doc.data()?['isOnline'], true);
    });

    test('goOffline updates Firestore document', () async {
      service.initialize(1);
      await service.goOnline();
      await service.goOffline();

      final doc = await fakeFirestore.collection('couriers').doc('1').get();
      expect(doc.data()?['isOnline'], false);
    });

    test('setDestination stores destination', () {
      service.initialize(1);
      service.setDestination(lat: 5.359952, lng: -4.008256);
      // Should not throw
    });

    test('clearDestination removes destination', () {
      service.initialize(1);
      service.setDestination(lat: 5.359952, lng: -4.008256);
      service.clearDestination();
      // Should not throw
    });

    test('updateDeliveryStatus updates delivery doc', () async {
      service.initialize(1);
      await service.updateDeliveryStatus(deliveryId: 10, status: 'picked_up');

      final doc = await fakeFirestore.collection('deliveries').doc('10').get();
      expect(doc.exists, true);
      expect(doc.data()?['status'], 'picked_up');
    });

    test('updateDeliveryStatus with estimated arrival', () async {
      service.initialize(1);
      final eta = DateTime(2024, 6, 15, 14, 30);
      await service.updateDeliveryStatus(
        deliveryId: 11,
        status: 'in_progress',
        estimatedArrival: eta,
      );

      final doc = await fakeFirestore.collection('deliveries').doc('11').get();
      expect(doc.exists, true);
      expect(doc.data()?['status'], 'in_progress');
    });

    test('dispose does not throw', () {
      service.initialize(1);
      service.dispose();
      // Should not throw
    });
  });
}
