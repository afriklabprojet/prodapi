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

    test('creates with empty steps', () {
      final route = RouteInfo(
        points: const [LatLng(5.0, -4.0)],
        totalDistance: '0 km',
        totalDuration: '0 min',
        steps: [],
      );
      expect(route.steps, isEmpty);
      expect(route.points.length, 1);
    });

    test('creates with many points', () {
      final route = RouteInfo(
        points: List.generate(10, (i) => LatLng(5.0 + i * 0.01, -4.0)),
        totalDistance: '15 km',
        totalDuration: '30 min',
        steps: [
          RouteStep(instruction: 'Go', distance: '15 km', duration: '30 min'),
        ],
      );
      expect(route.points.length, 10);
    });

    test('instructions getter returns steps', () {
      final steps = [
        RouteStep(instruction: 'Go north', distance: '1 km', duration: '3 min'),
        RouteStep(
          instruction: 'Turn left',
          distance: '500 m',
          duration: '2 min',
        ),
      ];
      final route = RouteInfo(
        points: const [LatLng(14.0, -17.0)],
        totalDistance: '1.5 km',
        totalDuration: '5 min',
        steps: steps,
      );
      expect(route.instructions, equals(steps));
      expect(route.instructions.length, 2);
    });
  });

  group('RouteStep - additional', () {
    test('fromJson parses maneuver field', () {
      final json = {
        'html_instructions': 'Turn right',
        'distance': {'text': '200 m'},
        'duration': {'text': '1 min'},
        'maneuver': 'turn-right',
      };
      final step = RouteStep.fromJson(json);
      expect(step.maneuver, 'turn-right');
    });

    test('fromJson defaults maneuver to empty string', () {
      final json = {
        'html_instructions': 'Continue',
        'distance': {'text': '1 km'},
        'duration': {'text': '3 min'},
      };
      final step = RouteStep.fromJson(json);
      expect(step.maneuver, '');
    });

    test('text getter returns instruction', () {
      final step = RouteStep(
        instruction: 'Go straight',
        distance: '500 m',
        duration: '2 min',
      );
      expect(step.text, 'Go straight');
      expect(step.text, step.instruction);
    });

    test('fromJson handles null distance map', () {
      final json = {
        'html_instructions': 'Arrive',
        'duration': {'text': '0 min'},
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, 'Arrive');
      expect(step.distance, '');
    });

    test('fromJson handles null duration map', () {
      final json = {
        'html_instructions': 'Walk',
        'distance': {'text': '100 m'},
      };
      final step = RouteStep.fromJson(json);
      expect(step.duration, '');
    });

    test('RouteInstruction is same type as RouteStep', () {
      final step = RouteStep(
        instruction: 'Test',
        distance: '1 km',
        duration: '1 min',
      );
      // RouteInstruction is a typedef for RouteStep
      final RouteInstruction ri = step;
      expect(ri.instruction, 'Test');
    });

    test('fromJson handles empty strings', () {
      final json = {
        'html_instructions': '',
        'distance': {'text': ''},
        'duration': {'text': ''},
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, '');
      expect(step.distance, '');
      expect(step.duration, '');
    });

    test('fromJson handles long instructions with HTML', () {
      final json = {
        'html_instructions': '<b>Tourner</b> à <i>gauche</i> sur Rue 10',
        'distance': {'text': '2.5 km'},
        'duration': {'text': '15 min'},
        'maneuver': 'turn-left',
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, contains('Tourner'));
      expect(step.maneuver, 'turn-left');
    });
  });
}
