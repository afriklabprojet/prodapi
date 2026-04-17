import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Service d'ETA en temps réel via Google Directions API
/// Calcule le temps estimé entre le coursier et la destination
class EtaService {
  final Dio _dio = Dio();
  final String _apiKey;

  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  EtaService({String? apiKey})
      : _apiKey = apiKey ?? EnvConfig.googleMapsApiKey;

  /// Calculer l'ETA entre la position courante et la destination
  /// Retourne {duration_text, duration_seconds, distance_text, distance_meters, polyline}
  Future<EtaResult?> calculateEta({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await _dio.get(_directionsUrl, queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': 'driving',
        'departure_time': 'now', // Données trafic en temps réel
        'key': _apiKey,
        'language': 'fr',
      });

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final leg = response.data['routes'][0]['legs'][0];
        final polyline =
            response.data['routes'][0]['overview_polyline']['points'] ?? '';

        // Utiliser duration_in_traffic si disponible (plus précis)
        final duration = leg['duration_in_traffic'] ?? leg['duration'];

        return EtaResult(
          durationText: duration['text'] ?? '',
          durationSeconds: duration['value'] ?? 0,
          distanceText: leg['distance']['text'] ?? '',
          distanceMeters: leg['distance']['value'] ?? 0,
          polyline: polyline,
          startAddress: leg['start_address'] ?? '',
          endAddress: leg['end_address'] ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint('[EtaService] Error: $e');
      return null;
    }
  }
}

/// Résultat d'un calcul d'ETA
class EtaResult {
  final String durationText;
  final int durationSeconds;
  final String distanceText;
  final int distanceMeters;
  final String polyline;
  final String startAddress;
  final String endAddress;

  const EtaResult({
    required this.durationText,
    required this.durationSeconds,
    required this.distanceText,
    required this.distanceMeters,
    required this.polyline,
    required this.startAddress,
    required this.endAddress,
  });

  /// Distance en km
  double get distanceKm => distanceMeters / 1000;

  /// Durée en minutes 
  double get durationMinutes => durationSeconds / 60;

  /// Heure d'arrivée estimée
  DateTime get estimatedArrival =>
      DateTime.now().add(Duration(seconds: durationSeconds));
}
