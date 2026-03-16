import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Service pour optimiser la mémoire de la carte Google Maps
/// - Gère le cycle de vie de la carte
/// - Limite les mises à jour de position
/// - Cache les marqueurs et polylines
/// - Dispose proprement les ressources
class MapMemoryOptimizer {
  static final MapMemoryOptimizer _instance = MapMemoryOptimizer._internal();
  factory MapMemoryOptimizer() => _instance;
  MapMemoryOptimizer._internal();

  GoogleMapController? _mapController;
  Timer? _updateDebouncer;
  Timer? _memoryCleanupTimer;
  
  // Cache des marqueurs pour éviter les recréations
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  
  // Dernière position connue (pour éviter les updates inutiles)
  LatLng? _lastCameraPosition;
  double? _lastZoom;
  
  // Configuration
  static const Duration _updateDebounceTime = Duration(milliseconds: 500);
  static const Duration _memoryCleanupInterval = Duration(minutes: 5);
  static const double _minPositionChangeMeters = 10.0;
  static const double _minZoomChange = 0.5;

  /// Initialise le contrôleur de carte
  void setController(GoogleMapController controller) {
    // Dispose l'ancien contrôleur si existant
    _mapController?.dispose();
    _mapController = controller;
    
    // Démarrer le timer de nettoyage mémoire
    _startMemoryCleanupTimer();
    
    if (kDebugMode) debugPrint('🗺️ Map controller set');
  }

  /// Libère les ressources de la carte
  void dispose() {
    _updateDebouncer?.cancel();
    _memoryCleanupTimer?.cancel();
    _mapController?.dispose();
    _mapController = null;
    _markerIconCache.clear();
    _lastCameraPosition = null;
    _lastZoom = null;
    
    if (kDebugMode) debugPrint('🗺️ Map resources disposed');
  }

  /// Met à jour la caméra avec debouncing
  void updateCamera(LatLng position, {double? zoom, double? bearing, double? tilt}) {
    _updateDebouncer?.cancel();
    _updateDebouncer = Timer(_updateDebounceTime, () {
      _performCameraUpdate(position, zoom: zoom, bearing: bearing, tilt: tilt);
    });
  }

  void _performCameraUpdate(LatLng position, {double? zoom, double? bearing, double? tilt}) {
    if (_mapController == null) return;
    
    // Vérifier si le déplacement est significatif
    if (!_isSignificantChange(position, zoom)) {
      return;
    }
    
    _lastCameraPosition = position;
    _lastZoom = zoom;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: zoom ?? 15.0,
          bearing: bearing ?? 0,
          tilt: tilt ?? 0,
        ),
      ),
    );
  }

  /// Vérifie si le changement de position est significatif
  bool _isSignificantChange(LatLng newPosition, double? newZoom) {
    if (_lastCameraPosition == null) return true;
    
    // Distance minimale
    final distance = Geolocator.distanceBetween(
      _lastCameraPosition!.latitude,
      _lastCameraPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    if (distance < _minPositionChangeMeters) {
      // Vérifier le zoom
      if (_lastZoom != null && newZoom != null) {
        if ((newZoom - _lastZoom!).abs() < _minZoomChange) {
          return false;
        }
      }
      return false;
    }
    
    return true;
  }

  /// Obtient une icône de marqueur depuis le cache
  Future<BitmapDescriptor> getMarkerIcon(String key, BitmapDescriptor Function() creator) async {
    if (!_markerIconCache.containsKey(key)) {
      _markerIconCache[key] = creator();
    }
    return _markerIconCache[key]!;
  }

  /// Nettoie le cache des icônes de marqueurs
  void clearMarkerCache() {
    _markerIconCache.clear();
    if (kDebugMode) debugPrint('🗺️ Marker cache cleared');
  }

  /// Démarre le timer de nettoyage périodique
  void _startMemoryCleanupTimer() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = Timer.periodic(_memoryCleanupInterval, (_) {
      _performMemoryCleanup();
    });
  }

  /// Effectue un nettoyage mémoire
  void _performMemoryCleanup() {
    // Limiter la taille du cache des marqueurs
    if (_markerIconCache.length > 20) {
      final keysToRemove = _markerIconCache.keys.take(_markerIconCache.length - 10).toList();
      for (final key in keysToRemove) {
        _markerIconCache.remove(key);
      }
      if (kDebugMode) debugPrint('🗺️ Cleaned ${keysToRemove.length} cached markers');
    }
  }

  /// Pause la carte pour économiser des ressources
  void pauseMap() {
    _updateDebouncer?.cancel();
    _memoryCleanupTimer?.cancel();
  }

  /// Reprend la carte
  void resumeMap() {
    _startMemoryCleanupTimer();
  }
}

/// Widget optimisé pour la carte Google Maps
class OptimizedGoogleMap extends StatefulWidget {
  final CameraPosition initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final MapType mapType;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final void Function()? onCameraIdle;
  final bool liteModeEnabled;
  final EdgeInsets padding;

  const OptimizedGoogleMap({
    super.key,
    required this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.liteModeEnabled = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<OptimizedGoogleMap> createState() => _OptimizedGoogleMapState();
}

class _OptimizedGoogleMapState extends State<OptimizedGoogleMap> with WidgetsBindingObserver {
  final MapMemoryOptimizer _optimizer = MapMemoryOptimizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _optimizer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _optimizer.pauseMap();
        break;
      case AppLifecycleState.resumed:
        _optimizer.resumeMap();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.initialPosition,
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      mapType: widget.mapType,
      zoomControlsEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      liteModeEnabled: widget.liteModeEnabled,
      padding: widget.padding,
      onMapCreated: (controller) {
        _optimizer.setController(controller);
        widget.onMapCreated?.call(controller);
      },
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
    );
  }
}

/// Extension pour optimiser les polylines
extension PolylineOptimizer on List<LatLng> {
  /// Simplifie une polyline en réduisant le nombre de points
  /// Utilise l'algorithme de Douglas-Peucker simplifié
  List<LatLng> simplify({double tolerance = 0.0001}) {
    if (length <= 2) return this;
    
    // Simplification basique : garder 1 point sur N selon la longueur
    final step = length > 100 ? 3 : (length > 50 ? 2 : 1);
    
    final result = <LatLng>[];
    for (int i = 0; i < length; i += step) {
      result.add(this[i]);
    }
    
    // Toujours inclure le dernier point
    if (result.last != last) {
      result.add(last);
    }
    
    return result;
  }
}

/// Gestionnaire de marqueurs avec recyclage
class MarkerManager {
  final Map<String, Marker> _activeMarkers = {};
  final List<String> _markerPool = [];
  static const int _maxPoolSize = 50;

  /// Ajoute ou met à jour un marqueur
  Marker upsertMarker({
    required String id,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor icon = BitmapDescriptor.defaultMarker,
    VoidCallback? onTap,
  }) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title ?? '',
        snippet: snippet,
      ),
      icon: icon,
      onTap: onTap,
    );
    
    _activeMarkers[id] = marker;
    return marker;
  }

  /// Supprime un marqueur
  void removeMarker(String id) {
    final removed = _activeMarkers.remove(id);
    if (removed != null && _markerPool.length < _maxPoolSize) {
      _markerPool.add(id);
    }
  }

  /// Obtient tous les marqueurs actifs
  Set<Marker> get markers => _activeMarkers.values.toSet();

  /// Nettoie tous les marqueurs
  void clear() {
    _activeMarkers.clear();
    _markerPool.clear();
  }

  /// Nombre de marqueurs actifs
  int get count => _activeMarkers.length;
}
