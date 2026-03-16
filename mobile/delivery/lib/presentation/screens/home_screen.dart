import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/models/courier_profile.dart';
import '../../data/models/route_info.dart';
import '../providers/delivery_providers.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/geofencing_service.dart';
import '../../core/constants/map_constants.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/home/home_widgets.dart';
import 'multi_route_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polylines = {};
  int? _lastDeliveryId;
  String? _lastStatus;
  bool _isFollowingUser = true;
  RouteInfo? _currentRouteInfo;
  
  // Abidjan coordinates as default
  static const CameraPosition _kAbidjan = CameraPosition(
    target: MapConstants.defaultLocation,
    zoom: 14.4746,
  );

  bool _isOnline = false;
  bool _isTogglingStatus = false; // Indicateur de chargement pour le changement de statut

  StreamSubscription<GeofenceEvent>? _geofenceSubscription;

  @override
  void initState() {
    super.initState();
    // Écouter les événements de geofencing pour afficher les notifications d'arrivée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geofenceSubscription = ref.read(geofencingServiceProvider).events.listen(_onGeofenceEvent);
    });
  }

  @override
  void dispose() {
    _geofenceSubscription?.cancel();
    // Libérer le controller natif Google Maps pour éviter les fuites mémoire
    _controller.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  /// Notification quand le livreur arrive à proximité d'un point
  void _onGeofenceEvent(GeofenceEvent event) {
    if (!mounted) return;

    if (event.isArriving) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.zone.type == 'pickup'
                ? '📦 Vous approchez de la pharmacie ${event.zone.name ?? ""}'
                : '📍 Vous approchez du client ${event.zone.name ?? ""}',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (event.isArrived) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.zone.type == 'pickup'
                ? '✅ Vous êtes arrivé à la pharmacie !'
                : '✅ Vous êtes arrivé chez le client !',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Empêcher les clics multiples pendant le chargement
    if (_isTogglingStatus) return;
    
    setState(() => _isTogglingStatus = true);
    
    try {
      // Optimistic update
      setState(() => _isOnline = value);
      
      // Envoie le statut souhaité explicitement pour éviter les désynchronisations
      final desiredStatus = value ? 'available' : 'offline';
      final actualStatus = await ref.read(deliveryRepositoryProvider).toggleAvailability(desiredStatus: desiredStatus);
      
      // Synchroniser avec le statut réel retourné par le serveur
      setState(() => _isOnline = actualStatus);
      ref.invalidate(courierProfileProvider);

      final locationService = ref.read(locationServiceProvider);
      if (actualStatus) {
        locationService.startTracking();
        // Signaler en ligne dans Firestore
        locationService.goOnline();
      } else {
        locationService.stopTracking();
        // Signaler hors ligne dans Firestore
        locationService.goOffline();
      }
    } catch (e) {
      // Revert on error
      setState(() => _isOnline = !value);
      if (mounted) {
        // Extraire le message d'erreur propre
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(courierProfileProvider);
    final activeDeliveriesAsync = ref.watch(deliveriesProvider('active'));

    // Update local state when provider data changes
    ref.listen<AsyncValue<CourierProfile>>(courierProfileProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        final profile = next.value!;
        if (mounted) setState(() => _isOnline = profile.status == 'available');
        // Initialiser le tracking Firestore avec l'ID du livreur
        ref.read(locationServiceProvider).initializeFirestore(profile.id);
      }
    });

    // Listen to active deliveries to update route + geofencing
    ref.listen<AsyncValue<List<dynamic>>>(deliveriesProvider('active'), (prev, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
         final delivery = next.value!.first;
         if (delivery.id != _lastDeliveryId || delivery.status != _lastStatus) {
            _lastDeliveryId = delivery.id;
            _lastStatus = delivery.status;
            _updateRoute(delivery, null);
            // Setup geofencing zones for all active deliveries
            _setupGeofencing(next.value!);
         }
      } else if (next.hasValue && (next.value?.isEmpty ?? true)) {
         // Plus de livraison active - nettoyer l'état
         _lastDeliveryId = null;
         _lastStatus = null;
         _currentRouteInfo = null;
         if (_polylines.isNotEmpty && mounted) {
           setState(() => _polylines = {});
         }
         // Clear geofencing zones
         ref.read(geofencingServiceProvider).clearAllZones();
         ref.read(geofencingServiceProvider).stopMonitoring();
      }
    });

    // Listen to location updates for live tracking
    ref.watch(locationStreamProvider);
    
    // Effect: Update camera when location changes
    ref.listen<AsyncValue<Position>>(locationStreamProvider, (prev, next) {
      if (next.hasValue && next.value != null && _isOnline && _isFollowingUser) {
        final pos = next.value!;
        final latLng = LatLng(pos.latitude, pos.longitude);
        
        _controller.future.then((controller) {
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17.0, // Zoom closer for navigation feeling
              bearing: pos.heading, // Rotate map with movement
              tilt: 45.0, // 3D effect
            ),
          ));
        });
      }
    });

    return Scaffold(
      body: AsyncValueWidget<List<dynamic>>(
        value: activeDeliveriesAsync,
        data: (activeDeliveries) {
          final hasActiveDelivery = activeDeliveries.isNotEmpty;
          final activeDelivery = hasActiveDelivery ? activeDeliveries.first : null;

          // Prepare Markers & Polylines
          Set<Marker> markers = {};
          // Use our calculated polylines (Directions API) instead of manual straight line
          Set<Polyline> polylines = _polylines; 
          
          if (activeDelivery != null) {
              LatLng? pharmacyLoc;
              LatLng? customerLoc;

              if (activeDelivery.pharmacyLat != null && activeDelivery.pharmacyLng != null) {
                pharmacyLoc = LatLng(activeDelivery.pharmacyLat!, activeDelivery.pharmacyLng!);
                markers.add(Marker(
                  markerId: const MarkerId('pharmacy'),
                  position: pharmacyLoc,
                  infoWindow: const InfoWindow(title: 'Pharmacie'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ));
              }

              if (activeDelivery.deliveryLat != null && activeDelivery.deliveryLng != null) {
                customerLoc = LatLng(activeDelivery.deliveryLat!, activeDelivery.deliveryLng!);
                markers.add(Marker(
                  markerId: const MarkerId('customer'),
                  position: customerLoc,
                  infoWindow: const InfoWindow(title: 'Client'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ));
              }

              // Add Courier Marker (simulated vehicle if needed, or rely on Blue Dot)
              // But for "Seeing displacement", let's ensure the blue dot is visible.
              // IF we want a custom icon (Motorbike), we would add it here using _currentPosition.
              
              // We also want to re-calculate route from MY position to destination periodically
              // But for now, stationary route is safer to avoid flickering.
          }

          return Stack(
            children: [
              // 1. MAP BACKGROUND
              _buildMap(markers: markers, polylines: polylines),

              // Re-Center Button (Floating)
              if (_isOnline && !_isFollowingUser)
                Positioned(
                  right: 16,
                  bottom: hasActiveDelivery ? 200 : 120,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_btn',
                    onPressed: () => setState(() => _isFollowingUser = true),
                    backgroundColor: Theme.of(context).cardColor,
                    child: const Icon(Icons.gps_fixed, color: Colors.blue),
                  ),
                ),

              // Multi-Route Button (Quand plusieurs livraisons actives)
              if (activeDeliveries.length > 1)
                Positioned(
                  right: 16,
                  bottom: 260,
                  child: FloatingActionButton.extended(
                    heroTag: 'multi_route_btn',
                    onPressed: () {
                      context.pushSlide(const MultiRouteScreen());
                    },
                    backgroundColor: Colors.deepPurple,
                    icon: const Icon(Icons.route, color: Colors.white),
                    label: Text(
                      '${activeDeliveries.length} livraisons',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // 2. OVERLAY FOR OFFLINE STATE
              if (!_isOnline && !hasActiveDelivery)
                const OfflineOverlay(),

              // 3. TOP STATUS BAR (Earnings & Status)
              HomeStatusBar(profileAsync: profileAsync),

              // 4. BOTTOM ACTION BUTTON (GO ONLINE)
              if (!hasActiveDelivery)
                GoOnlineButton(
                  isOnline: _isOnline,
                  isToggling: _isTogglingStatus,
                  onToggle: () => _toggleAvailability(!_isOnline),
                ),
              
              // 5. FINDING ORDERS + NEW ORDER ALERT
              if (_isOnline && !hasActiveDelivery) ...[
                _buildSearchingIndicator(),
                const IncomingOrderCard(),
              ],

              // 6. ACTIVE DELIVERY PANEL
              if (hasActiveDelivery)
                ActiveDeliveryPanel(
                  delivery: activeDelivery!,
                  routeInfo: _currentRouteInfo,
                  onShowItinerary: () {
                    if (_currentRouteInfo != null) {
                      ItinerarySheet.show(context, _currentRouteInfo!);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchingIndicator() {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Recherche de commandes...',
                style: TextStyle(color: context.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap({Set<Marker>? markers, Set<Polyline>? polylines}) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kAbidjan,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We use custom logic
      zoomControlsEnabled: false,
      markers: markers ?? {},
      polylines: polylines ?? {},
      onCameraMoveStarted: () {
         // If user touches map, stop following automatically
         // We might need a better heuristic, but this is simple.
         // _isFollowingUser = false; 
         // Actually onCameraMoveStarted is triggered by animations too.
         // Use gesture recognizers if needed, but let's keep it simple: 
         // allow user to pan, but snap back on next location update IF _isFollowingUser is true.
         // If they want to stop, they should toggle a button. 
         // For now, let's assume "Navigation Mode" means Always Follow.
      },
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
      },
    );
  }

  Future<void> _updateRoute(dynamic delivery, LatLng? myLocation) async {
    if (delivery == null) {
      if (_polylines.isNotEmpty) setState(() => _polylines = {});
      return;
    }

    LatLng? origin;
    LatLng? destination;

    if (delivery.status == 'assigned' || delivery.status == 'accepted') {
       origin = myLocation ?? MapConstants.defaultLocation;
       if (delivery.pharmacyLat != null && delivery.pharmacyLng != null) {
         destination = LatLng(delivery.pharmacyLat!, delivery.pharmacyLng!);
       }
    } else if (delivery.status == 'picked_up') {
       if (delivery.pharmacyLat != null && delivery.pharmacyLng != null) {
          origin = LatLng(delivery.pharmacyLat!, delivery.pharmacyLng!);
       }
       if (delivery.deliveryLat != null && delivery.deliveryLng != null) {
          destination = LatLng(delivery.deliveryLat!, delivery.deliveryLng!);
       }
    }

    if (origin != null && destination != null) {
       final routeService = ref.read(routeServiceProvider);
       final routeInfo = await routeService.getRouteInfo(origin, destination);
       
       if (routeInfo != null && mounted) {
          setState(() {
            _currentRouteInfo = routeInfo;
            final points = routeInfo.points.cast<LatLng>();
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            };
            _fitBounds(points);
          });
       }
    }
  }

  /// Configure les zones de geofencing pour les livraisons actives
  void _setupGeofencing(List<dynamic> deliveries) {
    final geofencing = ref.read(geofencingServiceProvider);
    geofencing.clearAllZones();

    for (final delivery in deliveries) {
      // Zone pharmacie (pickup) — pour statuts assigned/accepted
      if ((delivery.status == 'assigned' || delivery.status == 'accepted') &&
          delivery.pharmacyLat != null && delivery.pharmacyLng != null) {
        geofencing.addZone(GeofenceZone(
          deliveryId: delivery.id as int,
          type: 'pickup',
          latitude: delivery.pharmacyLat!,
          longitude: delivery.pharmacyLng!,
          name: delivery.pharmacyName,
        ));
      }

      // Zone client (dropoff) — pour statuts picked_up/in_transit
      if ((delivery.status == 'picked_up' || delivery.status == 'in_transit') &&
          delivery.deliveryLat != null && delivery.deliveryLng != null) {
        geofencing.addZone(GeofenceZone(
          deliveryId: delivery.id as int,
          type: 'dropoff',
          latitude: delivery.deliveryLat!,
          longitude: delivery.deliveryLng!,
          name: delivery.customerName,
        ));
      }
    }

    if (geofencing.zoneCount > 0) {
      geofencing.startMonitoring();
    }
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50,
    ));
  }
}
