import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/geofencing_service.dart';
import 'package:courier/core/services/location_service.dart';
import 'package:courier/core/services/firestore_tracking_service.dart';

class MockLocationService extends Mock implements LocationService {}

class MockFirestoreTrackingService extends Mock
    implements FirestoreTrackingService {}

void main() {
  group('GeofenceThresholds', () {
    test('approaching distance is 300m', () {
      expect(GeofenceThresholds.approaching, 300.0);
    });

    test('arrived distance is 50m', () {
      expect(GeofenceThresholds.arrived, 50.0);
    });

    test('departed distance is 500m', () {
      expect(GeofenceThresholds.departed, 500.0);
    });

    test('maxAccuracy is 100m', () {
      expect(GeofenceThresholds.maxAccuracy, 100.0);
    });

    test('requiredConsecutiveSamples is 3', () {
      expect(GeofenceThresholds.requiredConsecutiveSamples, 3);
    });

    test('approaching > arrived', () {
      expect(
        GeofenceThresholds.approaching,
        greaterThan(GeofenceThresholds.arrived),
      );
    });

    test('departed > approaching', () {
      expect(
        GeofenceThresholds.departed,
        greaterThan(GeofenceThresholds.approaching),
      );
    });
  });

  group('GeofenceState', () {
    test('has all expected values', () {
      expect(GeofenceState.values.length, 3);
      expect(GeofenceState.values, contains(GeofenceState.outside));
      expect(GeofenceState.values, contains(GeofenceState.approaching));
      expect(GeofenceState.values, contains(GeofenceState.arrived));
    });

    test('outside has index 0', () {
      expect(GeofenceState.outside.index, 0);
    });

    test('approaching has index 1', () {
      expect(GeofenceState.approaching.index, 1);
    });

    test('arrived has index 2', () {
      expect(GeofenceState.arrived.index, 2);
    });
  });

  group('GeofenceZone', () {
    test('creates with required fields', () {
      final zone = GeofenceZone(
        deliveryId: 1,
        type: 'pickup',
        latitude: 5.36,
        longitude: -4.008,
      );
      expect(zone.deliveryId, 1);
      expect(zone.type, 'pickup');
      expect(zone.latitude, 5.36);
      expect(zone.longitude, -4.008);
      expect(zone.name, isNull);
      expect(zone.state, GeofenceState.outside);
    });

    test('creates with optional name', () {
      final zone = GeofenceZone(
        deliveryId: 2,
        type: 'dropoff',
        latitude: 5.37,
        longitude: -4.01,
        name: 'Pharmacie du Plateau',
      );
      expect(zone.name, 'Pharmacie du Plateau');
    });

    test('state can be changed', () {
      final zone = GeofenceZone(
        deliveryId: 1,
        type: 'pickup',
        latitude: 5.36,
        longitude: -4.008,
      );
      zone.state = GeofenceState.approaching;
      expect(zone.state, GeofenceState.approaching);

      zone.state = GeofenceState.arrived;
      expect(zone.state, GeofenceState.arrived);
    });

    test('creates with initial state approaching', () {
      final zone = GeofenceZone(
        deliveryId: 3,
        type: 'pickup',
        latitude: 5.36,
        longitude: -4.008,
        state: GeofenceState.approaching,
      );
      expect(zone.state, GeofenceState.approaching);
    });

    test('dropoff type', () {
      final zone = GeofenceZone(
        deliveryId: 4,
        type: 'dropoff',
        latitude: 5.40,
        longitude: -3.99,
      );
      expect(zone.type, 'dropoff');
    });

    test('negative coordinates', () {
      final zone = GeofenceZone(
        deliveryId: 5,
        type: 'pickup',
        latitude: -33.86,
        longitude: 151.21,
      );
      expect(zone.latitude, -33.86);
      expect(zone.longitude, 151.21);
    });
  });

  group('GeofenceEvent', () {
    GeofenceZone makeZone({int id = 1, String type = 'pickup'}) {
      return GeofenceZone(
        deliveryId: id,
        type: type,
        latitude: 5.36,
        longitude: -4.008,
      );
    }

    test('creates with correct properties', () {
      final zone = makeZone();
      final event = GeofenceEvent(
        zone: zone,
        previousState: GeofenceState.outside,
        newState: GeofenceState.approaching,
        distance: 250.0,
      );
      expect(event.zone, zone);
      expect(event.previousState, GeofenceState.outside);
      expect(event.newState, GeofenceState.approaching);
      expect(event.distance, 250.0);
      expect(event.timestamp, isA<DateTime>());
    });

    test('timestamp is approximately now', () {
      final before = DateTime.now();
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.approaching,
        distance: 250.0,
      );
      final after = DateTime.now();
      expect(
        event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        event.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('isArriving is true from outside to approaching', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.approaching,
        distance: 280.0,
      );
      expect(event.isArriving, true);
      expect(event.isArrived, false);
      expect(event.isDeparted, false);
    });

    test('isArriving is false from approaching to arrived', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.approaching,
        newState: GeofenceState.arrived,
        distance: 30.0,
      );
      expect(event.isArriving, false);
    });

    test('isArriving is false from outside to arrived', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.arrived,
        distance: 20.0,
      );
      expect(event.isArriving, false);
    });

    test('isArrived is true when new state is arrived', () {
      final event = GeofenceEvent(
        zone: makeZone(type: 'dropoff'),
        previousState: GeofenceState.approaching,
        newState: GeofenceState.arrived,
        distance: 30.0,
      );
      expect(event.isArriving, false);
      expect(event.isArrived, true);
      expect(event.isDeparted, false);
    });

    test('isArrived is true regardless of previous state', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.arrived,
        distance: 10.0,
      );
      expect(event.isArrived, true);
    });

    test('isDeparted is true from approaching to outside', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.approaching,
        newState: GeofenceState.outside,
        distance: 600.0,
      );
      expect(event.isDeparted, true);
    });

    test('isDeparted is true from arrived to outside', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.arrived,
        newState: GeofenceState.outside,
        distance: 600.0,
      );
      expect(event.isArriving, false);
      expect(event.isArrived, false);
      expect(event.isDeparted, true);
    });

    test('isDeparted is false from outside to outside', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.outside,
        distance: 800.0,
      );
      expect(event.isDeparted, false);
    });

    test('all booleans false for approaching to approaching', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.approaching,
        newState: GeofenceState.approaching,
        distance: 200.0,
      );
      expect(event.isArriving, false);
      expect(event.isArrived, false);
      expect(event.isDeparted, false);
    });

    test('arrived to approaching: not arriving, not arrived, not departed', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.arrived,
        newState: GeofenceState.approaching,
        distance: 200.0,
      );
      expect(event.isArriving, false);
      expect(event.isArrived, false);
      expect(event.isDeparted, false);
    });

    test('distance is stored correctly', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.outside,
        newState: GeofenceState.approaching,
        distance: 299.99,
      );
      expect(event.distance, 299.99);
    });

    test('zero distance', () {
      final event = GeofenceEvent(
        zone: makeZone(),
        previousState: GeofenceState.approaching,
        newState: GeofenceState.arrived,
        distance: 0.0,
      );
      expect(event.distance, 0.0);
      expect(event.isArrived, true);
    });
  });

  // ── GeofencingService instance tests ──
  group('GeofencingService', () {
    late MockLocationService mockLocation;
    late MockFirestoreTrackingService mockTracking;
    late GeofencingService service;
    late StreamController<Position> positionController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockLocation = MockLocationService();
      mockTracking = MockFirestoreTrackingService();
      positionController = StreamController<Position>.broadcast();
      when(
        () => mockLocation.locationStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: any(named: 'deliveryId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});
      service = GeofencingService(mockLocation, mockTracking);
    });

    tearDown(() async {
      await positionController.close();
    });

    GeofenceZone makeZone({
      int deliveryId = 1,
      String type = 'pickup',
      double lat = 5.3364,
      double lng = -4.0267,
    }) {
      return GeofenceZone(
        deliveryId: deliveryId,
        type: type,
        latitude: lat,
        longitude: lng,
      );
    }

    Position makePosition({
      required double lat,
      required double lng,
      double accuracy = 10,
    }) {
      return Position(
        longitude: lng,
        latitude: lat,
        timestamp: DateTime.now(),
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    test('zoneCount starts at 0', () {
      expect(service.zoneCount, 0);
    });

    test('addZone increases zoneCount', () {
      service.addZone(makeZone());
      expect(service.zoneCount, 1);
    });

    test('addZone replaces duplicate (same deliveryId + type)', () {
      service.addZone(makeZone(deliveryId: 1, type: 'pickup'));
      service.addZone(makeZone(deliveryId: 1, type: 'pickup', lat: 6.0));
      expect(service.zoneCount, 1);
    });

    test('addZone allows different types for same delivery', () {
      service.addZone(makeZone(deliveryId: 1, type: 'pickup'));
      service.addZone(makeZone(deliveryId: 1, type: 'dropoff'));
      expect(service.zoneCount, 2);
    });

    test('addZone allows different deliveries', () {
      service.addZone(makeZone(deliveryId: 1));
      service.addZone(makeZone(deliveryId: 2));
      expect(service.zoneCount, 2);
    });

    test('removeZonesForDelivery removes matching zones', () {
      service.addZone(makeZone(deliveryId: 1, type: 'pickup'));
      service.addZone(makeZone(deliveryId: 1, type: 'dropoff'));
      service.addZone(makeZone(deliveryId: 2, type: 'pickup'));
      service.removeZonesForDelivery(1);
      expect(service.zoneCount, 1);
    });

    test('removeZonesForDelivery with non-existing id does nothing', () {
      service.addZone(makeZone(deliveryId: 1));
      service.removeZonesForDelivery(999);
      expect(service.zoneCount, 1);
    });

    test('clearAllZones empties everything', () {
      service.addZone(makeZone(deliveryId: 1));
      service.addZone(makeZone(deliveryId: 2));
      service.addZone(makeZone(deliveryId: 3));
      service.clearAllZones();
      expect(service.zoneCount, 0);
    });

    test('isEnabled defaults to true', () {
      expect(service.isEnabled, true);
    });

    test('events stream is broadcast', () {
      // Should be able to listen multiple times without error
      service.events.listen((_) {});
      service.events.listen((_) {});
    });

    test('startMonitoring does nothing when disabled', () {
      service.isEnabled = false;
      service.startMonitoring();
      // Should not throw or subscribe to location
    });

    test('stopMonitoring does not throw when not monitoring', () {
      service.stopMonitoring();
      // Should not throw
    });

    test('loadPreference reads persisted disabled value', () async {
      SharedPreferences.setMockInitialValues({'geofencing_enabled': false});
      await service.loadPreference();
      expect(service.isEnabled, false);
    });

    test('setting isEnabled persists the preference', () async {
      service.isEnabled = false;
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('geofencing_enabled'), false);
    });

    test('three approaching positions emit arriving event', () async {
      service.addZone(makeZone());
      final events = <GeofenceEvent>[];
      final sub = service.events.listen(events.add);

      service.startMonitoring();
      for (var i = 0; i < 3; i++) {
        positionController.add(makePosition(lat: 5.3382, lng: -4.0267));
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(1));
      expect(events.first.isArriving, true);
      verify(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: 1,
          status: 'arriving',
        ),
      ).called(1);
      await sub.cancel();
    });

    test('three arrived positions emit arrived status only once', () async {
      service.addZone(makeZone());
      final events = <GeofenceEvent>[];
      final sub = service.events.listen(events.add);

      service.startMonitoring();
      for (var i = 0; i < 3; i++) {
        positionController.add(makePosition(lat: 5.3382, lng: -4.0267));
        await Future<void>.delayed(Duration.zero);
      }
      for (var i = 0; i < 6; i++) {
        positionController.add(makePosition(lat: 5.33645, lng: -4.0267));
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events.where((e) => e.isArrived).length, 1);
      verify(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: 1,
          status: 'arrived_pharmacy',
        ),
      ).called(1);
      await sub.cancel();
    });

    test('inaccurate positions are ignored', () async {
      service.addZone(makeZone());
      final events = <GeofenceEvent>[];
      final sub = service.events.listen(events.add);

      service.startMonitoring();
      for (var i = 0; i < 4; i++) {
        positionController.add(
          makePosition(lat: 5.3382, lng: -4.0267, accuracy: 250),
        );
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events, isEmpty);
      verifyNever(
        () => mockTracking.updateDeliveryStatus(
          deliveryId: any(named: 'deliveryId'),
          status: any(named: 'status'),
        ),
      );
      await sub.cancel();
    });

    test('moving away emits departed event after approaching', () async {
      service.addZone(makeZone());
      final events = <GeofenceEvent>[];
      final sub = service.events.listen(events.add);

      service.startMonitoring();
      for (var i = 0; i < 3; i++) {
        positionController.add(makePosition(lat: 5.3382, lng: -4.0267));
        await Future<void>.delayed(Duration.zero);
      }
      for (var i = 0; i < 3; i++) {
        positionController.add(makePosition(lat: 5.3464, lng: -4.0267));
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events.any((event) => event.isDeparted), true);
      await sub.cancel();
    });
  });
}
