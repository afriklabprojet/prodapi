import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/pharmacy_entity.dart';

class PharmaciesMapPage extends StatefulWidget {
  final List<PharmacyEntity> pharmacies;
  final double? userLatitude;
  final double? userLongitude;

  const PharmaciesMapPage({
    super.key,
    required this.pharmacies,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<PharmaciesMapPage> createState() => _PharmaciesMapPageState();
}

class _PharmaciesMapPageState extends State<PharmaciesMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    final Set<Marker> markers = {};

    if (kDebugMode) {
      developer.log(
        '📍 Creating markers for ${widget.pharmacies.length} pharmacies',
        name: 'PharmaciesMap',
      );
    }

    int validCount = 0;
    int invalidCount = 0;

    for (final pharmacy in widget.pharmacies) {
      // Vérifier que les coordonnées sont valides
      final hasValidCoords =
          pharmacy.latitude != null &&
          pharmacy.longitude != null &&
          pharmacy.latitude != 0.0 &&
          pharmacy.longitude != 0.0 &&
          _isValidLatitude(pharmacy.latitude!) &&
          _isValidLongitude(pharmacy.longitude!);

      if (kDebugMode) {
        developer.log(
          '  - ${pharmacy.name}: lat=${pharmacy.latitude}, lng=${pharmacy.longitude} => ${hasValidCoords ? "✅ VALID" : "❌ INVALID"}',
          name: 'PharmaciesMap',
        );
      }

      if (hasValidCoords) {
        validCount++;
        markers.add(
          Marker(
            markerId: MarkerId(pharmacy.id.toString()),
            position: LatLng(pharmacy.latitude!, pharmacy.longitude!),
            infoWindow: InfoWindow(
              title: pharmacy.name,
              snippet: pharmacy.isOnDuty == true
                  ? 'Garde ${pharmacy.dutyType != null ? "- ${pharmacy.dutyType}" : ""}'
                  : (pharmacy.isOpen ? 'Ouverte' : 'Fermée'),
              onTap: () {
                context.goToPharmacyDetails(pharmacy.id);
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              pharmacy.isOnDuty == true
                  ? BitmapDescriptor.hueOrange
                  : (pharmacy.isOpen
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueRed),
            ),
          ),
        );
      } else {
        invalidCount++;
      }
    }

    if (kDebugMode) {
      developer.log(
        '📊 Markers summary: $validCount valid, $invalidCount invalid',
        name: 'PharmaciesMap',
      );
    }

    // Mettre à jour les markers avec setState pour rafraîchir l'affichage
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  /// Vérifie si la latitude est dans les limites valides (-90 à 90)
  bool _isValidLatitude(double lat) {
    return lat >= -90.0 && lat <= 90.0;
  }

  /// Vérifie si la longitude est dans les limites valides (-180 à 180)
  bool _isValidLongitude(double lng) {
    return lng >= -180.0 && lng <= 180.0;
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialPosition = _defaultPosition;

    if (widget.userLatitude != null && widget.userLongitude != null) {
      initialPosition = CameraPosition(
        target: LatLng(widget.userLatitude!, widget.userLongitude!),
        zoom: 14,
      );
    } else if (widget.pharmacies.isNotEmpty) {
      final firstPharm = widget.pharmacies.firstWhere(
        (p) => p.latitude != null && p.longitude != null,
        orElse: () => widget.pharmacies.first,
      );
      if (firstPharm.latitude != null) {
        initialPosition = CameraPosition(
          target: LatLng(firstPharm.latitude!, firstPharm.longitude!),
          zoom: 14,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Pharmacies'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Badge affichant le nombre de marqueurs
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _markers.isEmpty
                    ? Colors.orange
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_markers.length} / ${widget.pharmacies.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: kIsWeb
          ? _buildWebFallback()
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
                // Alerte si aucun marqueur n'est affiché
                if (_markers.isEmpty && widget.pharmacies.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aucune pharmacie avec coordonnées GPS valides.\n${widget.pharmacies.length} pharmacie(s) sans localisation.',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
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

  Widget _buildWebFallback() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.info.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'La carte n\'est pas disponible sur la version web. Utilisez la liste ci-dessous.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = widget.pharmacies[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pharmacy.isOnDuty == true
                        ? AppColors.onDuty
                        : (pharmacy.isOpen
                              ? AppColors.pharmacyOpen
                              : AppColors.pharmacyClosed),
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    pharmacy.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    pharmacy.address.isNotEmpty
                        ? pharmacy.address
                        : 'Adresse non disponible',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pharmacy.isOnDuty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Garde',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      else
                        Text(
                          pharmacy.isOpen ? 'Ouverte' : 'Fermée',
                          style: TextStyle(
                            color: pharmacy.isOpen
                                ? AppColors.pharmacyOpen
                                : AppColors.pharmacyClosed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    context.goToPharmacyDetails(pharmacy.id);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
