import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

/// Constantes de carte pour l'application coursier
/// Note: Les valeurs de base viennent de AppConfig
class MapConstants {
  MapConstants._();

  /// Coordonnées par défaut (depuis AppConfig)
  static double get defaultLatitude => AppConfig.defaultLatitude;
  static double get defaultLongitude => AppConfig.defaultLongitude;
  static LatLng get defaultLocation => LatLng(defaultLatitude, defaultLongitude);
  static double get defaultZoom => AppConfig.mapDefaultZoom;
}
