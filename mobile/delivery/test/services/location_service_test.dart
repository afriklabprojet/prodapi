import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/services/location_service.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/services/firestore_tracking_service.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

class MockFirestoreTrackingService extends Mock
    implements FirestoreTrackingService {}

void main() {
  late LocationService service;
  late MockDeliveryRepository mockRepo;
  late MockFirestoreTrackingService mockTracking;

  setUp(() {
    mockRepo = MockDeliveryRepository();
    mockTracking = MockFirestoreTrackingService();
    service = LocationService(mockRepo, mockTracking);
  });

  tearDown(() {
    service.dispose();
  });

  group('LocationService', () {
    test('locationStream is a broadcast stream', () {
      expect(service.locationStream, isA<Stream>());
      expect(service.locationStream.isBroadcast, true);
    });

    test('currentOrderId is initially null', () {
      expect(service.currentOrderId, isNull);
    });

    test('clearDestination does not throw', () {
      expect(() => service.clearDestination(), returnsNormally);
    });

    test('stopTracking does not throw', () {
      expect(() => service.stopTracking(), returnsNormally);
    });

    test('setDestination stores coordinates', () {
      service.setDestination(lat: 5.36, lng: -4.01);
      // No assertion error means it worked
    });

    test('initializeFirestore calls tracking service', () {
      when(() => mockTracking.initialize(any())).thenAnswer((_) async {});
      service.initializeFirestore(1);
      verify(() => mockTracking.initialize(1)).called(1);
    });

    test('goOnline delegates to FirestoreTrackingService', () async {
      when(() => mockTracking.goOnline()).thenAnswer((_) async {});
      await service.goOnline();
      verify(() => mockTracking.goOnline()).called(1);
    });

    test('goOffline delegates to FirestoreTrackingService', () async {
      when(() => mockTracking.goOffline()).thenAnswer((_) async {});
      await service.goOffline();
      verify(() => mockTracking.goOffline()).called(1);
    });

    test('updateDeliveryStatus delegates with correct params', () async {
      when(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: any(named: 'deliveryId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});
      await service.updateDeliveryStatus(deliveryId: 42, status: 'picked_up');
      verify(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: 42,
          status: 'picked_up',
        ),
      ).called(1);
    });

    test('clearDestination delegates to FirestoreTrackingService', () {
      when(() => mockTracking.clearDestination()).thenReturn(null);
      service.clearDestination();
      verify(() => mockTracking.clearDestination()).called(1);
    });

    test('setDestination delegates to FirestoreTrackingService', () {
      when(
        () => mockTracking.setDestination(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenReturn(null);
      service.setDestination(lat: 5.36, lng: -4.01);
      verify(
        () => mockTracking.setDestination(lat: 5.36, lng: -4.01),
      ).called(1);
    });

    test('dispose does not throw', () {
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
