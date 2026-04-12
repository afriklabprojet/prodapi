import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/pharmacy_entity.dart';
import '../providers/pharmacies_state.dart';

/// Page dédiée aux pharmacies de garde avec vue carte directe
class OnDutyPharmaciesMapPage extends ConsumerStatefulWidget {
  const OnDutyPharmaciesMapPage({super.key});

  @override
  ConsumerState<OnDutyPharmaciesMapPage> createState() =>
      _OnDutyPharmaciesMapPageState();
}

class _OnDutyPharmaciesMapPageState
    extends ConsumerState<OnDutyPharmaciesMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  PharmacyEntity? _selectedPharmacy;
  bool _showList = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocationAndFetch();
  }

  Future<void> _initializeLocationAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sur le web, on saute la géolocalisation et on affiche directement la liste
      if (kIsWeb) {
        await _fetchOnDutyPharmacies(null, null);
        return;
      }

      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Les services de localisation sont désactivés. Activez-les pour voir les pharmacies de garde près de vous.';
          _isLoading = false;
        });
        // Fetch anyway without location
        await _fetchOnDutyPharmacies(null, null);
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'Permission de localisation refusée. Vous pouvez toujours voir les pharmacies de garde.';
          });
          await _fetchOnDutyPharmacies(null, null);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Permission de localisation refusée définitivement. Activez-la dans les paramètres.';
        });
        await _fetchOnDutyPharmacies(null, null);
        return;
      }

      // Obtenir la position actuelle - essayer plusieurs méthodes
      Position? position;
      try {
        // D'abord essayer avec haute précision
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Si ça échoue, essayer avec précision basse
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 15),
          );
        } catch (e2) {
          // Essayer de récupérer la dernière position connue
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
        });

        // Fetch pharmacies de garde avec la position
        await _fetchOnDutyPharmacies(position.latitude, position.longitude);

        // Centrer la carte sur la position de l'utilisateur
        if (_mapController.isCompleted) {
          final controller = await _mapController.future;
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              14,
            ),
          );
        }
      } else {
        // Aucune position disponible - continuer sans localisation
        await _fetchOnDutyPharmacies(null, null);
      }
    } catch (e) {
      // Fetch anyway without location - ne pas afficher d'erreur bloquante
      await _fetchOnDutyPharmacies(null, null);
    }
  }

  Future<void> _fetchOnDutyPharmacies(double? lat, double? lng) async {
    await ref
        .read(pharmaciesProvider.notifier)
        .fetchOnDutyPharmacies(latitude: lat, longitude: lng);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _createMarkers(List<PharmacyEntity> pharmacies) {
    final Set<Marker> markers = {};

    if (kDebugMode) {
      developer.log(
        '🏥 Creating on-duty markers for ${pharmacies.length} pharmacies',
        name: 'OnDutyPharmaciesMap',
      );
    }

    int validCount = 0;
    int invalidCount = 0;

    for (final pharmacy in pharmacies) {
      final hasValidCoords =
          pharmacy.latitude != null &&
          pharmacy.longitude != null &&
          pharmacy.latitude != 0.0 &&
          pharmacy.longitude != 0.0 &&
          _isValidLatitude(pharmacy.latitude!) &&
          _isValidLongitude(pharmacy.longitude!);

      if (kDebugMode) {
        developer.log(
          '  - ${pharmacy.name}: lat=${pharmacy.latitude}, lng=${pharmacy.longitude} => ${hasValidCoords ? "✅" : "❌"}',
          name: 'OnDutyPharmaciesMap',
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
              snippet: _getDutyLabel(pharmacy.dutyType),
              onTap: () => _onPharmacyTap(pharmacy),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () {
              setState(() {
                _selectedPharmacy = pharmacy;
              });
            },
          ),
        );
      } else {
        invalidCount++;
      }
    }

    if (kDebugMode) {
      developer.log(
        '📊 On-duty markers: $validCount valid, $invalidCount invalid',
        name: 'OnDutyPharmaciesMap',
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  bool _isValidLatitude(double lat) => lat >= -90.0 && lat <= 90.0;
  bool _isValidLongitude(double lng) => lng >= -180.0 && lng <= 180.0;

  void _onPharmacyTap(PharmacyEntity pharmacy) {
    context.goToPharmacyDetails(pharmacy.id);
  }

  String _getDutyLabel(String? type) {
    if (type == null) return 'Pharmacie de garde';
    switch (type.toLowerCase()) {
      case 'night':
        return 'Garde de Nuit';
      case 'weekend':
        return 'Garde de Weekend';
      case 'holiday':
        return 'Garde Férié';
      default:
        return 'Garde $type';
    }
  }

  Future<void> _goToPharmacy(PharmacyEntity pharmacy) async {
    if (pharmacy.latitude == null || pharmacy.longitude == null) return;

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pharmacy.latitude!, pharmacy.longitude!),
        16,
      ),
    );
    if (!mounted) return;
    setState(() {
      _selectedPharmacy = pharmacy;
      _showList = false;
    });
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position non disponible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesState = ref.watch(pharmaciesProvider);
    final onDutyPharmacies = pharmaciesState.onDutyPharmacies;

    // Update markers when pharmacies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onDutyPharmacies.isNotEmpty) {
        _createMarkers(onDutyPharmacies);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies de Garde'),
        backgroundColor: AppColors.onDuty,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showList ? Icons.map : Icons.list),
            tooltip: _showList ? 'Voir la carte' : 'Voir la liste',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showList = !_showList;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _initializeLocationAndFetch,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _showList
          ? _buildListView(onDutyPharmacies)
          : _buildMapView(pharmaciesState, onDutyPharmacies),
      floatingActionButton: !_showList && !kIsWeb
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentPosition != null)
                  FloatingActionButton.small(
                    heroTag: 'center_user',
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : Colors.white,
                    onPressed: _centerOnUser,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'toggle_list',
                  backgroundColor: AppColors.onDuty,
                  icon: const Icon(Icons.list, color: Colors.white),
                  label: Text(
                    '${onDutyPharmacies.length} pharmacie${onDutyPharmacies.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _showList = true;
                    });
                  },
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.onDuty),
          const SizedBox(height: 16),
          Text(
            'Recherche des pharmacies de garde...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Localisation en cours...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(
    PharmaciesState pharmaciesState,
    List<PharmacyEntity> onDutyPharmacies,
  ) {
    if (kIsWeb) {
      return _buildWebFallback(onDutyPharmacies);
    }

    CameraPosition initialPosition = _defaultPosition;

    if (_currentPosition != null) {
      initialPosition = CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      );
    } else if (onDutyPharmacies.isNotEmpty) {
      final firstPharm = onDutyPharmacies.firstWhere(
        (p) => p.latitude != null && p.longitude != null,
        orElse: () => onDutyPharmacies.first,
      );
      if (firstPharm.latitude != null) {
        initialPosition = CameraPosition(
          target: LatLng(firstPharm.latitude!, firstPharm.longitude!),
          zoom: 14,
        );
      }
    }

    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: initialPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
          },
        ),
        // Error banner if any
        if (_errorMessage != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        // Selected pharmacy card
        if (_selectedPharmacy != null)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildSelectedPharmacyCard(_selectedPharmacy!),
          ),
        // Empty state
        if (onDutyPharmacies.isEmpty &&
            pharmaciesState.status != PharmaciesStatus.loading)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_pharmacy_outlined,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[500]
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune pharmacie de garde',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune pharmacie de garde n\'est disponible actuellement dans votre zone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedPharmacyCard(PharmacyEntity pharmacy) {
    return GestureDetector(
      onTap: () => _onPharmacyTap(pharmacy),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_pharmacy,
                color: Color(0xFFFF5722),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pharmacy.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getDutyLabel(pharmacy.dutyType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (pharmacy.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pharmacy.address,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<PharmacyEntity> pharmacies) {
    if (pharmacies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune pharmacie de garde',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune pharmacie de garde disponible actuellement.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = pharmacies[index];
        return _buildPharmacyListItem(pharmacy);
      },
    );
  }

  Widget _buildPharmacyListItem(PharmacyEntity pharmacy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onPharmacyTap(pharmacy),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  color: Color(0xFFFF5722),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getDutyLabel(pharmacy.dutyType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (pharmacy.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pharmacy.address,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  if (pharmacy.latitude != null && pharmacy.longitude != null)
                    IconButton(
                      icon: const Icon(
                        Icons.directions,
                        color: Color(0xFFFF5722),
                      ),
                      tooltip: 'Voir sur la carte',
                      onPressed: () => _goToPharmacy(pharmacy),
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFallback(List<PharmacyEntity> onDutyPharmacies) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade100,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La carte n\'est pas disponible sur la version web.',
                  style: TextStyle(color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildListView(onDutyPharmacies)),
      ],
    );
  }
}
