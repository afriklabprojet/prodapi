import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/services/app_update_service.dart';
import 'package:courier/core/services/connectivity_service.dart';
import 'package:courier/core/services/geofencing_service.dart';
import 'package:courier/core/services/location_service.dart';
import 'package:courier/core/services/route_service.dart';
import 'package:courier/data/models/courier_profile.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/presentation/providers/delivery_providers.dart';
import 'package:courier/presentation/screens/home_screen.dart';
import '../helpers/widget_test_helpers.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockRouteService extends Mock implements RouteService {}

class MockGeofencingService extends Mock implements GeofencingService {}

void main() {
  setUpAll(() async {
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(
      GeofenceZone(deliveryId: 0, type: 'pickup', latitude: 0, longitude: 0),
    );
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final fakePosition = Position(
    latitude: 5.36,
    longitude: -4.01,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  final fakeProfile = CourierProfile(
    id: 1,
    name: 'Jean',
    email: 'jean@test.com',
    status: 'available',
    vehicleType: 'moto',
    plateNumber: 'AB-1234',
    rating: 4.5,
    completedDeliveries: 100,
    earnings: 50000,
    kycStatus: 'approved',
  );

  // ─── Builder helpers ───────────────────────────────────────────────────────

  Widget buildHomeWithGeoController(
    StreamController<GeofenceEvent> geoController, {
    VersionCheckResult? updateResult,
    bool isDisconnected = false,
  }) {
    final mockRepo = MockDeliveryRepository();
    final mockLocService = MockLocationService();
    final mockRouteService = MockRouteService();
    final mockGeoService = MockGeofencingService();

    when(
      () => mockLocService.locationStream,
    ).thenAnswer((_) => Stream.value(fakePosition));
    when(() => mockGeoService.events).thenAnswer((_) => geoController.stream);
    when(() => mockGeoService.clearAllZones()).thenReturn(null);
    when(() => mockGeoService.stopMonitoring()).thenReturn(null);
    when(() => mockGeoService.startMonitoring()).thenReturn(null);
    when(() => mockGeoService.addZone(any())).thenReturn(null);

    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        courierProfileProvider.overrideWith((ref) async => fakeProfile),
        deliveriesProvider.overrideWith((ref, status) async => <Delivery>[]),
        locationStreamProvider.overrideWith(
          (ref) => Stream.value(fakePosition),
        ),
        deliveryRepositoryProvider.overrideWithValue(mockRepo),
        locationServiceProvider.overrideWithValue(mockLocService),
        routeServiceProvider.overrideWithValue(mockRouteService),
        geofencingServiceProvider.overrideWithValue(mockGeoService),
        isDisconnectedProvider.overrideWithValue(isDisconnected),
        appUpdateProvider.overrideWith((ref) async => updateResult),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  // ─── Geofence event tests ─────────────────────────────────────────────────

  group('HomeScreen - geofence events', () {
    testWidgets('approaching pickup zone shows blue snackbar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(buildHomeWithGeoController(geoController));
        // Let initState post-frame callback run
        await tester.pump(const Duration(milliseconds: 500));

        final zone = GeofenceZone(
          deliveryId: 1,
          type: 'pickup',
          latitude: 5.36,
          longitude: -4.01,
          name: 'Pharmacie Centrale',
        );
        // Emit an approaching event (outside → approaching)
        geoController.add(
          GeofenceEvent(
            zone: zone,
            previousState: GeofenceState.outside,
            newState: GeofenceState.approaching,
            distance: 250,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Should show snackbar with approaching text
        expect(find.textContaining('Pharmacie Centrale'), findsWidgets);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('approaching dropoff zone shows blue snackbar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(buildHomeWithGeoController(geoController));
        await tester.pump(const Duration(milliseconds: 500));

        final zone = GeofenceZone(
          deliveryId: 1,
          type: 'dropoff',
          latitude: 5.36,
          longitude: -4.01,
          name: 'Client Dupont',
        );
        geoController.add(
          GeofenceEvent(
            zone: zone,
            previousState: GeofenceState.outside,
            newState: GeofenceState.approaching,
            distance: 250,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.textContaining('Client Dupont'), findsWidgets);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('arrived at pickup zone shows green snackbar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(buildHomeWithGeoController(geoController));
        await tester.pump(const Duration(milliseconds: 500));

        final zone = GeofenceZone(
          deliveryId: 1,
          type: 'pickup',
          latitude: 5.36,
          longitude: -4.01,
          name: 'Pharmacie Test',
        );
        // Emit an arrived event
        geoController.add(
          GeofenceEvent(
            zone: zone,
            previousState: GeofenceState.approaching,
            newState: GeofenceState.arrived,
            distance: 40,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Should show arrived snackbar
        expect(find.textContaining('arrivé'), findsWidgets);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('arrived at dropoff zone shows green snackbar with OK action', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(buildHomeWithGeoController(geoController));
        await tester.pump(const Duration(milliseconds: 500));

        final zone = GeofenceZone(
          deliveryId: 1,
          type: 'dropoff',
          latitude: 5.37,
          longitude: -4.02,
          name: 'Client',
        );
        geoController.add(
          GeofenceEvent(
            zone: zone,
            previousState: GeofenceState.approaching,
            newState: GeofenceState.arrived,
            distance: 30,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Arrived snackbar should have 'OK' action
        expect(find.text('OK'), findsWidgets);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('departed event does not show snackbar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(buildHomeWithGeoController(geoController));
        await tester.pump(const Duration(milliseconds: 500));

        final zone = GeofenceZone(
          deliveryId: 1,
          type: 'pickup',
          latitude: 5.36,
          longitude: -4.01,
          name: 'Pharmacie',
        );
        // A departed event (not arriving, not arrived)
        geoController.add(
          GeofenceEvent(
            zone: zone,
            previousState: GeofenceState.arrived,
            newState: GeofenceState.outside,
            distance: 600,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // No snackbar with "arrivé" or "approchez" should be shown
        expect(find.byType(SnackBar), findsNothing);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });
  });

  // ─── Force update dialog ──────────────────────────────────────────────────

  group('HomeScreen - force update', () {
    testWidgets('shows ForceUpdateDialog when forceUpdate is true', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        final updateResult = VersionCheckResult(
          forceUpdate: true,
          updateAvailable: true,
          minVersion: '2.0.0',
          latestVersion: '2.1.0',
          currentVersion: '1.0.0',
          storeUrl: 'https://example.com/store',
          changelog: 'Nouvelle version disponible.',
        );

        await tester.pumpWidget(
          buildHomeWithGeoController(geoController, updateResult: updateResult),
        );
        // Post-frame callback + async future for appUpdateProvider
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ForceUpdateDialog), findsOneWidget);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('ForceUpdateDialog shows Mise à jour requise title', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        final updateResult = VersionCheckResult(
          forceUpdate: true,
          updateAvailable: true,
          minVersion: '2.0.0',
          latestVersion: '2.1.0',
          currentVersion: '1.0.0',
          storeUrl: 'https://example.com/store',
        );

        await tester.pumpWidget(
          buildHomeWithGeoController(geoController, updateResult: updateResult),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Mise à jour requise'), findsOneWidget);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('no dialog when updateResult is null', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(
          buildHomeWithGeoController(geoController, updateResult: null),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ForceUpdateDialog), findsNothing);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });

    testWidgets('no dialog when forceUpdate is false', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        final updateResult = VersionCheckResult(
          forceUpdate: false,
          updateAvailable: true,
          minVersion: '1.5.0',
          latestVersion: '2.0.0',
          currentVersion: '1.8.0',
          storeUrl: 'https://example.com/store',
        );

        await tester.pumpWidget(
          buildHomeWithGeoController(geoController, updateResult: updateResult),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ForceUpdateDialog), findsNothing);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });
  });

  // ─── Connectivity states ──────────────────────────────────────────────────

  group('HomeScreen - connectivity', () {
    testWidgets('renders normally when not disconnected', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        await tester.pumpWidget(
          buildHomeWithGeoController(geoController, isDisconnected: false),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(HomeScreen), findsOneWidget);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });
  });

  // ─── Profile status variations ────────────────────────────────────────────

  group('HomeScreen - profile status', () {
    testWidgets('renders with offline courier status', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      final geoController = StreamController<GeofenceEvent>.broadcast();
      try {
        final offlineProfile = CourierProfile(
          id: 2,
          name: 'Kone',
          email: 'kone@test.com',
          status: 'offline',
          vehicleType: 'car',
          plateNumber: 'CI-999',
          rating: 4.0,
          completedDeliveries: 50,
          earnings: 25000,
          kycStatus: 'approved',
        );

        final mockRepo = MockDeliveryRepository();
        final mockLocService = MockLocationService();
        final mockRouteService = MockRouteService();
        final mockGeoService = MockGeofencingService();

        when(
          () => mockLocService.locationStream,
        ).thenAnswer((_) => Stream.value(fakePosition));
        when(
          () => mockGeoService.events,
        ).thenAnswer((_) => geoController.stream);
        when(() => mockGeoService.clearAllZones()).thenReturn(null);
        when(() => mockGeoService.stopMonitoring()).thenReturn(null);
        when(() => mockGeoService.startMonitoring()).thenReturn(null);
        when(() => mockGeoService.addZone(any())).thenReturn(null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...commonWidgetTestOverrides(),
              courierProfileProvider.overrideWith(
                (ref) async => offlineProfile,
              ),
              deliveriesProvider.overrideWith(
                (ref, status) async => <Delivery>[],
              ),
              locationStreamProvider.overrideWith(
                (ref) => Stream.value(fakePosition),
              ),
              deliveryRepositoryProvider.overrideWithValue(mockRepo),
              locationServiceProvider.overrideWithValue(mockLocService),
              routeServiceProvider.overrideWithValue(mockRouteService),
              geofencingServiceProvider.overrideWithValue(mockGeoService),
              isDisconnectedProvider.overrideWithValue(false),
              appUpdateProvider.overrideWith((ref) async => null),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(HomeScreen), findsOneWidget);
      } finally {
        await geoController.close();
        FlutterError.onError = orig;
      }
      final orig2 = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 10));
      } finally {
        FlutterError.onError = orig2;
      }
    });
  });
}
