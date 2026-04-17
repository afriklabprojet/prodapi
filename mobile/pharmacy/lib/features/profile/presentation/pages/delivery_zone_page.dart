import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Écran de définition de la zone de livraison de la pharmacie
///
/// Permet au pharmacien de tracer un polygone sur Google Maps
/// pour définir le périmètre de livraison de sa pharmacie.
class DeliveryZonePage extends ConsumerStatefulWidget {
  const DeliveryZonePage({super.key});

  @override
  ConsumerState<DeliveryZonePage> createState() => _DeliveryZonePageState();
}

class _DeliveryZonePageState extends ConsumerState<DeliveryZonePage> {
  GoogleMapController? _mapController;
  final List<LatLng> _polygonPoints = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  bool _isDrawing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingZone = false;
  LatLng _initialCenter = _abidjanFallback;

  // Fallback: Abidjan center (used only if geolocation unavailable)
  static const LatLng _abidjanFallback = LatLng(5.3600, -4.0083);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initialCenter = await _getPharmacyCenter();
      if (mounted) setState(() {});
      _loadExistingZone();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Charger la zone existante depuis l'API
  Future<void> _loadExistingZone() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/pharmacy/delivery-zone');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final polygon = data['polygon'] as List;
        
        if (polygon.isNotEmpty) {
          setState(() {
            _polygonPoints.clear();
            for (final point in polygon) {
              _polygonPoints.add(LatLng(
                (point['lat'] as num).toDouble(),
                (point['lng'] as num).toDouble(),
              ));
            }
            _hasExistingZone = true;
            _updatePolygonDisplay();
          });

          // Centrer la carte sur la zone
          if (_polygonPoints.isNotEmpty && _mapController != null) {
            _fitBounds();
          }
        }
      }
    } catch (e) {
      // Pas de zone existante, c'est normal
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sauvegarder la zone sur l'API
  Future<void> _saveZone() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez tracer au moins 3 points pour définir une zone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = ref.read(apiClientProvider);
      await client.post('/pharmacy/delivery-zone', data: {
        'polygon': _polygonPoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'is_active': true,
      });

      if (mounted) {
        setState(() => _hasExistingZone = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Zone de livraison enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Supprimer la zone
  Future<void> _deleteZone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la zone ?'),
        content: const Text(
          'Votre pharmacie sera accessible pour les livraisons partout.\nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(ctx).delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/pharmacy/delivery-zone');

      if (mounted) {
        setState(() {
          _polygonPoints.clear();
          _polygons = {};
          _markers = {};
          _hasExistingZone = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zone de livraison supprimée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Ajouter un point au polygone
  void _onMapTap(LatLng position) {
    if (!_isDrawing) return;

    setState(() {
      _polygonPoints.add(position);
      _updatePolygonDisplay();
    });
  }

  /// Supprimer le dernier point
  void _undoLastPoint() {
    if (_polygonPoints.isEmpty) return;
    setState(() {
      _polygonPoints.removeLast();
      _updatePolygonDisplay();
    });
  }

  /// Effacer tous les points
  void _clearAllPoints() {
    setState(() {
      _polygonPoints.clear();
      _polygons = {};
      _markers = {};
    });
  }

  /// Mettre à jour l'affichage du polygone et des marqueurs
  void _updatePolygonDisplay() {
    // Marqueurs pour chaque point
    _markers = {};
    for (int i = 0; i < _polygonPoints.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId('point_$i'),
        position: _polygonPoints[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        draggable: true,
        onDragEnd: (newPos) {
          setState(() {
            _polygonPoints[i] = newPos;
            _updatePolygonDisplay();
          });
        },
      ));
    }

    // Polygone si au moins 3 points
    if (_polygonPoints.length >= 3) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('delivery_zone'),
          points: _polygonPoints,
          fillColor: AppColors.primary.withValues(alpha: 0.2),
          strokeColor: AppColors.primary,
          strokeWidth: 3,
        ),
      };
    } else {
      _polygons = {};
    }
  }

  void _fitBounds() {
    if (_polygonPoints.isEmpty || _mapController == null) return;

    double minLat = _polygonPoints.first.latitude;
    double maxLat = _polygonPoints.first.latitude;
    double minLng = _polygonPoints.first.longitude;
    double maxLng = _polygonPoints.first.longitude;

    for (final p in _polygonPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      ),
      50,
    ));
  }

  /// Obtenir la position initiale depuis le profil pharma, puis géolocalisation, puis fallback
  Future<LatLng> _getPharmacyCenter() async {
    final authState = ref.read(authProvider);
    final pharmacy = authState.user?.pharmacy;
    if (pharmacy != null && pharmacy.latitude != null && pharmacy.longitude != null) {
      return LatLng(pharmacy.latitude!, pharmacy.longitude!);
    }
    // Fallback: position GPS du device
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Géolocalisation indisponible: $e');
    }
    return _abidjanFallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone de livraison'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          if (_hasExistingZone)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteZone,
              tooltip: 'Supprimer la zone',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_polygonPoints.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), _fitBounds);
              }
            },
            onTap: _onMapTap,
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Instructions banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey.shade800 : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isDrawing ? Icons.touch_app : Icons.map,
                        color: _isDrawing ? Colors.green : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isDrawing
                              ? 'Touchez la carte pour ajouter des points'
                              : _polygonPoints.isEmpty
                                  ? 'Définissez votre zone de livraison'
                                  : '${_polygonPoints.length} points — zone définie',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isDrawing && _polygonPoints.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Appuyez sur "Tracer" pour dessiner le périmètre de vos livraisons',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drawing controls
                  Row(
                    children: [
                      // Toggle drawing mode
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isDrawing = !_isDrawing);
                          },
                          icon: Icon(_isDrawing ? Icons.stop : Icons.edit),
                          label: Text(_isDrawing ? 'Arrêter' : 'Tracer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isDrawing ? Colors.orange : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Undo
                      IconButton(
                        onPressed:
                            _polygonPoints.isNotEmpty ? _undoLastPoint : null,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Annuler le dernier point',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Clear
                      IconButton(
                        onPressed:
                            _polygonPoints.isNotEmpty ? _clearAllPoints : null,
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Tout effacer',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving || _polygonPoints.length < 3
                          ? null
                          : _saveZone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor:
                            Colors.green.withValues(alpha: 0.3),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              _polygonPoints.length < 3
                                  ? 'Min. 3 points requis'
                                  : 'Enregistrer la zone',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
