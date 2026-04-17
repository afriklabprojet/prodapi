import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Résultat d'autocomplétion Places
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured['main_text'] ?? json['description'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
    );
  }
}

/// Détail d'un lieu (avec coordonnées GPS)
class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final String name;
  final double latitude;
  final double longitude;
  final String? city;
  final String? district;
  final String? country;

  const PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.city,
    this.district,
    this.country,
  });
}

/// Service d'autocomplétion d'adresses via Google Places API
class PlacesAutocompleteService {
  final Dio _dio = Dio();
  final String _apiKey;

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  // Centré sur Abidjan, Côte d'Ivoire
  static const _defaultLocation = '5.3600,-4.0083';
  static const _defaultRadius = 50000; // 50km autour d'Abidjan
  static const _country = 'ci'; // Côte d'Ivoire

  PlacesAutocompleteService({String? apiKey})
      : _apiKey = apiKey ?? EnvConfig.googleMapsApiKey;

  /// Rechercher des adresses (autocomplétion)
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'language': 'fr',
          'components': 'country:$_country',
          'location': _defaultLocation,
          'radius': _defaultRadius,
          'types': 'geocode|establishment',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions
            .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesAutocomplete] Error: $e');
      return [];
    }
  }

  /// Obtenir les détails d'un lieu (coordonnées GPS)
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': 'fr',
          'fields': 'geometry,formatted_address,name,address_components',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['result'];
        final location = result['geometry']['location'];
        final components = result['address_components'] as List? ?? [];

        String? city;
        String? district;
        String? country;

        for (final component in components) {
          final types = (component['types'] as List).cast<String>();
          if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('sublocality') ||
              types.contains('sublocality_level_1')) {
            district = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          }
        }

        return PlaceDetails(
          placeId: placeId,
          formattedAddress: result['formatted_address'] ?? '',
          name: result['name'] ?? '',
          latitude: (location['lat'] as num).toDouble(),
          longitude: (location['lng'] as num).toDouble(),
          city: city,
          district: district,
          country: country,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[PlacesAutocomplete] Details error: $e');
      return null;
    }
  }

  /// Recherche de pharmacies proches
  Future<List<Map<String, dynamic>>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radius,
          'type': 'pharmacy',
          'key': _apiKey,
          'language': 'fr',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((r) {
          final loc = r['geometry']['location'];
          return {
            'name': r['name'] ?? '',
            'address': r['vicinity'] ?? '',
            'latitude': (loc['lat'] as num).toDouble(),
            'longitude': (loc['lng'] as num).toDouble(),
            'rating': r['rating']?.toDouble(),
            'isOpen': r['opening_hours']?['open_now'],
            'placeId': r['place_id'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PlacesAutocomplete] Nearby error: $e');
      return [];
    }
  }
}
