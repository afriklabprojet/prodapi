import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuver = '',
  });

  /// Alias for instruction - used by navigation_widgets
  String get text => instruction;

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['html_instructions'] ?? '',
      distance: (json['distance'] as Map<String, dynamic>?)?['text'] ?? '',
      duration: (json['duration'] as Map<String, dynamic>?)?['text'] ?? '',
      maneuver: json['maneuver'] ?? '',
    );
  }
}

/// Alias for RouteStep for compatibility with navigation_widgets
typedef RouteInstruction = RouteStep;

class RouteInfo {
  final List<LatLng> points;
  final String totalDistance;
  final String totalDuration;
  final List<RouteStep> steps;

  RouteInfo({
    required this.points,
    required this.totalDistance,
    required this.totalDuration,
    required this.steps,
  });

  /// Alias for steps - used by navigation_widgets
  List<RouteStep> get instructions => steps;
}
