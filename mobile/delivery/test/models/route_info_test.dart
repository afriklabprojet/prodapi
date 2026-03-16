import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/route_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('RouteStep', () {
    test('fromJson parses correctly', () {
      final json = {
        'html_instructions': 'Tourner à droite sur Rue 10',
        'distance': {'text': '500 m'},
        'duration': {'text': '2 min'},
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, 'Tourner à droite sur Rue 10');
      expect(step.distance, '500 m');
      expect(step.duration, '2 min');
    });

    test('fromJson handles missing instructions', () {
      final json = {
        'distance': {'text': '1 km'},
        'duration': {'text': '5 min'},
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, '');
    });
  });

  group('RouteInfo', () {
    test('creates correctly', () {
      final route = RouteInfo(
        points: const [LatLng(14.6928, -17.4467), LatLng(14.7000, -17.4500)],
        totalDistance: '2.5 km',
        totalDuration: '10 min',
        steps: [
          RouteStep(instruction: 'Go', distance: '1 km', duration: '5 min'),
          RouteStep(instruction: 'Turn', distance: '1.5 km', duration: '5 min'),
        ],
      );
      expect(route.points.length, 2);
      expect(route.totalDistance, '2.5 km');
      expect(route.totalDuration, '10 min');
      expect(route.steps.length, 2);
    });
  });
}
