import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:courier/core/services/route_service.dart';

void main() {
  group('MultiRouteResult', () {
    test('constructor and properties', () {
      final result = MultiRouteResult(
        points: [const LatLng(5.0, -4.0), const LatLng(5.1, -4.1)],
        totalDistanceKm: 12.5,
        totalDurationMinutes: 25.0,
        totalDistanceText: '12.5 km',
        totalDurationText: '25 min',
        waypointOrder: [1, 0, 2],
        legs: [
          LegInfo(
            startAddress: 'Pharmacie A',
            endAddress: 'Client B',
            distanceText: '5 km',
            durationText: '10 min',
            distanceMeters: 5000,
            durationSeconds: 600,
          ),
        ],
      );
      expect(result.points.length, 2);
      expect(result.totalDistanceKm, 12.5);
      expect(result.totalDurationMinutes, 25.0);
      expect(result.totalDistanceText, '12.5 km');
      expect(result.totalDurationText, '25 min');
      expect(result.waypointOrder, [1, 0, 2]);
      expect(result.legs.length, 1);
    });
  });

  group('LegInfo', () {
    test('constructor and properties', () {
      final leg = LegInfo(
        startAddress: 'Point A',
        endAddress: 'Point B',
        distanceText: '3.2 km',
        durationText: '8 min',
        distanceMeters: 3200,
        durationSeconds: 480,
      );
      expect(leg.startAddress, 'Point A');
      expect(leg.endAddress, 'Point B');
      expect(leg.distanceText, '3.2 km');
      expect(leg.durationText, '8 min');
      expect(leg.distanceMeters, 3200);
      expect(leg.durationSeconds, 480);
    });

    test('multiple legs in a route', () {
      final legs = [
        LegInfo(
          startAddress: 'Départ',
          endAddress: 'Waypoint 1',
          distanceText: '2 km',
          durationText: '5 min',
          distanceMeters: 2000,
          durationSeconds: 300,
        ),
        LegInfo(
          startAddress: 'Waypoint 1',
          endAddress: 'Waypoint 2',
          distanceText: '3 km',
          durationText: '7 min',
          distanceMeters: 3000,
          durationSeconds: 420,
        ),
        LegInfo(
          startAddress: 'Waypoint 2',
          endAddress: 'Destination',
          distanceText: '1.5 km',
          durationText: '4 min',
          distanceMeters: 1500,
          durationSeconds: 240,
        ),
      ];
      expect(legs.length, 3);
      final totalDistance = legs.fold(0, (sum, l) => sum + l.distanceMeters);
      expect(totalDistance, 6500);
      final totalDuration = legs.fold(0, (sum, l) => sum + l.durationSeconds);
      expect(totalDuration, 960);
    });
  });
}
