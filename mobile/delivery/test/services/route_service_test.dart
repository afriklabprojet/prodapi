import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/route_service.dart';
import 'package:courier/data/models/route_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  late RouteService service;

  setUp(() {
    service = RouteService('test-api-key');
  });

  group('RouteService', () {
    test('constructor accepts API key', () {
      expect(service, isNotNull);
    });

    test('getRouteInfo returns null on invalid API key', () async {
      final result = await service.getRouteInfo(
        const LatLng(5.36, -4.01),
        const LatLng(5.37, -4.02),
      );
      // With invalid API key, should return null
      expect(result, isNull);
    });

    test('getRoute returns empty list on failure', () async {
      final result = await service.getRoute(
        const LatLng(5.36, -4.01),
        const LatLng(5.37, -4.02),
      );
      expect(result, isA<List<LatLng>>());
    });

    test('getOptimizedMultiRoute returns null on failure', () async {
      final result = await service.getOptimizedMultiRoute(
        origin: const LatLng(5.36, -4.01),
        destination: const LatLng(5.37, -4.02),
        waypoints: [const LatLng(5.365, -4.015)],
        optimize: true,
      );
      expect(result, isNull);
    });

    test('getOptimizedMultiRoute works without waypoints', () async {
      final result = await service.getOptimizedMultiRoute(
        origin: const LatLng(5.36, -4.01),
        destination: const LatLng(5.37, -4.02),
        waypoints: [],
      );
      expect(result, isNull); // Invalid API key
    });

    test('getOptimizedMultiRoute with optimize false', () async {
      final result = await service.getOptimizedMultiRoute(
        origin: const LatLng(5.36, -4.01),
        destination: const LatLng(5.37, -4.02),
        waypoints: [const LatLng(5.365, -4.015)],
        optimize: false,
      );
      expect(result, isNull);
    });
  });

  group('RouteInfo', () {
    test('constructor stores all fields correctly', () {
      final points = [const LatLng(5.36, -4.01), const LatLng(5.37, -4.02)];
      final steps = [
        RouteStep(
          instruction: 'Turn left',
          distance: '100 m',
          duration: '1 min',
        ),
      ];
      final info = RouteInfo(
        points: points,
        totalDistance: '5 km',
        totalDuration: '15 min',
        steps: steps,
      );
      expect(info.points.length, 2);
      expect(info.totalDistance, '5 km');
      expect(info.totalDuration, '15 min');
      expect(info.steps.length, 1);
    });

    test('instructions alias returns steps', () {
      final steps = [
        RouteStep(
          instruction: 'Go straight',
          distance: '200 m',
          duration: '2 min',
        ),
      ];
      final info = RouteInfo(
        points: [],
        totalDistance: '0 km',
        totalDuration: '0 min',
        steps: steps,
      );
      expect(info.instructions, same(info.steps));
    });

    test('empty route info', () {
      final info = RouteInfo(
        points: [],
        totalDistance: '',
        totalDuration: '',
        steps: [],
      );
      expect(info.points, isEmpty);
      expect(info.steps, isEmpty);
    });
  });

  group('RouteStep', () {
    test('constructor with all parameters', () {
      final step = RouteStep(
        instruction: 'Turn right onto Avenue',
        distance: '500 m',
        duration: '3 min',
        maneuver: 'turn-right',
      );
      expect(step.instruction, 'Turn right onto Avenue');
      expect(step.distance, '500 m');
      expect(step.duration, '3 min');
      expect(step.maneuver, 'turn-right');
    });

    test('constructor with default maneuver', () {
      final step = RouteStep(
        instruction: 'Continue',
        distance: '1 km',
        duration: '5 min',
      );
      expect(step.maneuver, '');
    });

    test('text alias returns instruction', () {
      final step = RouteStep(
        instruction: 'Head north',
        distance: '100 m',
        duration: '1 min',
      );
      expect(step.text, step.instruction);
    });

    test('fromJson with full data', () {
      final json = {
        'html_instructions': 'Take the <b>second exit</b>',
        'distance': {'text': '250 m', 'value': 250},
        'duration': {'text': '1 min', 'value': 60},
        'maneuver': 'roundabout-right',
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, 'Take the <b>second exit</b>');
      expect(step.distance, '250 m');
      expect(step.duration, '1 min');
      expect(step.maneuver, 'roundabout-right');
    });

    test('fromJson with missing fields uses defaults', () {
      final step = RouteStep.fromJson({});
      expect(step.instruction, '');
      expect(step.distance, '');
      expect(step.duration, '');
      expect(step.maneuver, '');
    });

    test('fromJson with null values', () {
      final json = {
        'html_instructions': null,
        'distance': null,
        'duration': null,
        'maneuver': null,
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, '');
      expect(step.distance, '');
      expect(step.duration, '');
      expect(step.maneuver, '');
    });

    test('fromJson with partial distance data', () {
      final json = {
        'html_instructions': 'Go',
        'distance': {'value': 100}, // missing 'text'
        'duration': {'value': 30},
      };
      final step = RouteStep.fromJson(json);
      expect(step.distance, '');
      expect(step.duration, '');
    });
  });

  group('MultiRouteResult', () {
    test('constructor works', () {
      final result = MultiRouteResult(
        points: const [LatLng(5.36, -4.01)],
        totalDistanceKm: 3.5,
        totalDurationMinutes: 12,
        totalDistanceText: '3.5 km',
        totalDurationText: '12 min',
        waypointOrder: const [0, 1],
        legs: const [],
      );
      expect(result.points.length, 1);
      expect(result.totalDistanceKm, 3.5);
      expect(result.totalDurationMinutes, 12);
    });
  });

  group('LegInfo', () {
    test('constructor works', () {
      final leg = LegInfo(
        startAddress: 'Rue A',
        endAddress: 'Rue B',
        distanceText: '2 km',
        durationText: '5 min',
        distanceMeters: 2000,
        durationSeconds: 300,
      );
      expect(leg.startAddress, 'Rue A');
      expect(leg.distanceMeters, 2000);
    });

    test('endAddress is stored correctly', () {
      final leg = LegInfo(
        startAddress: 'Pharmacie du Plateau',
        endAddress: 'Rue 10, Cocody',
        distanceText: '5.2 km',
        durationText: '15 min',
        distanceMeters: 5200,
        durationSeconds: 900,
      );
      expect(leg.endAddress, 'Rue 10, Cocody');
      expect(leg.durationText, '15 min');
      expect(leg.durationSeconds, 900);
    });

    test('distanceText and durationText formatting', () {
      final leg = LegInfo(
        startAddress: 'A',
        endAddress: 'B',
        distanceText: '500 m',
        durationText: '2 min',
        distanceMeters: 500,
        durationSeconds: 120,
      );
      expect(leg.distanceText, '500 m');
      expect(leg.durationText, '2 min');
    });
  });

  group('MultiRouteResult - additional', () {
    test('totalDistanceText and waypointOrder', () {
      final result = MultiRouteResult(
        points: const [LatLng(5.36, -4.01), LatLng(5.37, -4.02)],
        totalDistanceKm: 10.5,
        totalDurationMinutes: 25,
        totalDistanceText: '10.5 km',
        totalDurationText: '25 min',
        waypointOrder: const [2, 0, 1],
        legs: const [],
      );
      expect(result.totalDistanceText, '10.5 km');
      expect(result.totalDurationText, '25 min');
      expect(result.waypointOrder, [2, 0, 1]);
    });

    test('legs access', () {
      final legs = [
        LegInfo(
          startAddress: 'A',
          endAddress: 'B',
          distanceText: '2 km',
          durationText: '5 min',
          distanceMeters: 2000,
          durationSeconds: 300,
        ),
        LegInfo(
          startAddress: 'B',
          endAddress: 'C',
          distanceText: '3 km',
          durationText: '8 min',
          distanceMeters: 3000,
          durationSeconds: 480,
        ),
      ];
      final result = MultiRouteResult(
        points: const [LatLng(5.36, -4.01)],
        totalDistanceKm: 5,
        totalDurationMinutes: 13,
        totalDistanceText: '5 km',
        totalDurationText: '13 min',
        waypointOrder: const [0, 1],
        legs: legs,
      );
      expect(result.legs.length, 2);
      expect(result.legs[0].startAddress, 'A');
      expect(result.legs[1].endAddress, 'C');
    });

    test('empty waypoints and points', () {
      final result = MultiRouteResult(
        points: const [],
        totalDistanceKm: 0,
        totalDurationMinutes: 0,
        totalDistanceText: '0 km',
        totalDurationText: '0 min',
        waypointOrder: const [],
        legs: const [],
      );
      expect(result.points, isEmpty);
      expect(result.waypointOrder, isEmpty);
      expect(result.legs, isEmpty);
    });

    test('large route with many legs', () {
      final legs = List.generate(
        5,
        (i) => LegInfo(
          startAddress: 'Point $i',
          endAddress: 'Point ${i + 1}',
          distanceText: '${i + 1} km',
          durationText: '${(i + 1) * 3} min',
          distanceMeters: (i + 1) * 1000,
          durationSeconds: (i + 1) * 180,
        ),
      );
      final result = MultiRouteResult(
        points: List.generate(10, (i) => LatLng(5.36 + i * 0.01, -4.01)),
        totalDistanceKm: 15,
        totalDurationMinutes: 45,
        totalDistanceText: '15 km',
        totalDurationText: '45 min',
        waypointOrder: const [0, 1, 2, 3, 4],
        legs: legs,
      );
      expect(result.legs.length, 5);
      expect(result.points.length, 10);
    });
  });
}
