import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Constantes de carte pour l'application coursier
class MapConstants {
  MapConstants._();

  /// Coordonnées par défaut (Abidjan, Côte d'Ivoire)
  static const double defaultLatitude = 5.3600;
  static const double defaultLongitude = -4.0083;
  static const LatLng defaultLocation = LatLng(defaultLatitude, defaultLongitude);
  static const double defaultZoom = 14.0;
}
