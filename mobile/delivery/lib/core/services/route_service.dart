import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_info.dart';

class RouteService {
  final String apiKey;
  final Dio _dio = Dio();

  RouteService(this.apiKey);

  Future<RouteInfo?> getRouteInfo(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final response = await _dio.get(url, queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': apiKey,
        'language': 'fr', // French instructions
      });

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final data = response.data;
        final route = data['routes'][0];
        final leg = route['legs'][0];
        
        // Decode points
        final points = PolylinePoints().decodePolyline(route['overview_polyline']['points']);
        final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        // Steps
        final steps = (leg['steps'] as List)
            .map((s) => RouteStep.fromJson(s))
            .toList();

        return RouteInfo(
          points: latLngs,
          totalDistance: leg['distance']['text'],
          totalDuration: leg['duration']['text'],
          steps: steps,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get optimized multi-waypoint route using Directions API
  /// Returns polyline points + optimized waypoint order
  Future<MultiRouteResult?> getOptimizedMultiRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
    bool optimize = true,
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final params = <String, dynamic>{
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': apiKey,
        'language': 'fr',
        'departure_time': 'now',
      };

      if (waypoints.isNotEmpty) {
        final prefix = optimize ? 'optimize:true|' : '';
        final waypointStr = prefix +
            waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
        params['waypoints'] = waypointStr;
      }

      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final legs = route['legs'] as List;

        // Decode full polyline
        final points = PolylinePoints()
            .decodePolyline(route['overview_polyline']['points']);
        final latLngs =
            points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        // Calculate totals from legs
        int totalDistanceM = 0;
        int totalDurationS = 0;
        final legInfos = <LegInfo>[];

        for (final leg in legs) {
          totalDistanceM += (leg['distance']['value'] as int);
          // Use duration_in_traffic if available
          final duration = leg['duration_in_traffic'] ?? leg['duration'];
          totalDurationS += (duration['value'] as int);
          legInfos.add(LegInfo(
            startAddress: leg['start_address'] ?? '',
            endAddress: leg['end_address'] ?? '',
            distanceText: leg['distance']['text'],
            durationText: duration['text'],
            distanceMeters: leg['distance']['value'],
            durationSeconds: duration['value'],
          ));
        }

        final waypointOrder =
            (route['waypoint_order'] as List?)?.cast<int>() ?? [];

        return MultiRouteResult(
          points: latLngs,
          totalDistanceKm: totalDistanceM / 1000.0,
          totalDurationMinutes: totalDurationS / 60.0,
          totalDistanceText:
              '${(totalDistanceM / 1000.0).toStringAsFixed(1)} km',
          totalDurationText: _formatDuration(totalDurationS),
          waypointOrder: waypointOrder,
          legs: legInfos,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '$minutes min';
  }

  // Legacy support
  Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    final info = await getRouteInfo(origin, destination);
    return info?.points ?? [];
  }
}

/// Result of a multi-waypoint optimized route
class MultiRouteResult {
  final List<LatLng> points;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final String totalDistanceText;
  final String totalDurationText;
  final List<int> waypointOrder;
  final List<LegInfo> legs;

  MultiRouteResult({
    required this.points,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.totalDistanceText,
    required this.totalDurationText,
    required this.waypointOrder,
    required this.legs,
  });
}

/// Info about one leg of the route
class LegInfo {
  final String startAddress;
  final String endAddress;
  final String distanceText;
  final String durationText;
  final int distanceMeters;
  final int durationSeconds;

  LegInfo({
    required this.startAddress,
    required this.endAddress,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
