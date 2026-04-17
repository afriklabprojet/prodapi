import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/config/app_config.dart';
import '../../data/models/courier_profile.dart';
import '../../data/models/route_info.dart';
import '../providers/delivery_providers.dart';
import '../providers/courier_heatmap_provider.dart';
import '../providers/profile_provider.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/geofencing_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/kyc_guard_service.dart';
import '../../core/utils/app_exceptions.dart';
import '../../core/constants/map_constants.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/home/home_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polylines = {};
  int? _lastDeliveryId;
  String? _lastStatus;
  bool _isFollowingUser = true;
  BitmapDescriptor? _courierIcon;
  RouteInfo? _currentRouteInfo;

  // Position initiale - sera mise à jour avec la position GPS réelle
  CameraPosition _initialCameraPosition = CameraPosition(
    target: MapConstants.defaultLocation,
    zoom: 14.4746,
  );
  bool _hasInitialPosition = false;

  bool _isTogglingStatus =
      false; // Indicateur de chargement pour le changement de statut
  DateTime? _lastToggleTime; // Debounce pour éviter le spam du toggle

  StreamSubscription<GeofenceEvent>? _geofenceSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCourierIcon();
    // Obtenir la position GPS réelle dès le démarrage
    _initializeRealPosition();
    // Écouter les événements de geofencing pour afficher les notifications d'arrivée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_geofenceSubscription != null) return;
      _geofenceSubscription = ref
          .read(geofencingServiceProvider)
          .events
          .listen(_onGeofenceEvent);
      _checkForUpdate();
      // Synchroniser le statut en ligne au démarrage
      _syncOnlineStatus();
    });
  }

  /// Initialise la position réelle de l'utilisateur dès le démarrage
  Future<void> _initializeRealPosition() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('📍 Permissions de localisation refusées');
        return;
      }

      // Obtenir la position actuelle avec haute précision
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15.0,
        );
        _hasInitialPosition = true;
      });

      debugPrint(
        '📍 Position initiale obtenue: ${position.latitude}, ${position.longitude}',
      );

      // Si la carte est déjà créée, centrer immédiatement
      if (_controller.isCompleted) {
        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      }
    } catch (e) {
      debugPrint('📍 Erreur obtention position initiale: $e');
      // Fallback: utiliser la dernière position connue
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted) {
          setState(() {
            _initialCameraPosition = CameraPosition(
              target: LatLng(lastPosition.latitude, lastPosition.longitude),
              zoom: 15.0,
            );
            _hasInitialPosition = true;
          });
          debugPrint(
            '📍 Dernière position connue utilisée: ${lastPosition.latitude}, ${lastPosition.longitude}',
          );
        }
      } catch (_) {
        // Ignorer - garder la position par défaut
      }
    }
  }

  /// Charge l'icône personnalisée du coursier
  Future<void> _loadCourierIcon() async {
    try {
      _courierIcon = await _createCourierMarkerIcon();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ Erreur chargement icône coursier: $e');
    }
  }

  /// Crée une icône de marqueur personnalisée pour le coursier (cercle bleu avec flèche)
  Future<BitmapDescriptor> _createCourierMarkerIcon() async {
    const double size = 80;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Cercle d'ombre pour effet de profondeur
    final Paint shadowPaint = Paint()
      ..color = DesignTokens.primary.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      shadowPaint,
    );

    // Cercle principal
    final Paint circlePaint = Paint()
      ..color = DesignTokens.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3, circlePaint);

    // Bordure blanche
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3, borderPaint);

    // Flèche de direction (triangle vers le haut)
    final Paint arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Path arrowPath = Path();
    arrowPath.moveTo(size / 2, size / 2 - 12); // Pointe
    arrowPath.lineTo(size / 2 - 8, size / 2 + 6); // Gauche
    arrowPath.lineTo(size / 2 + 8, size / 2 + 6); // Droite
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Appelé quand l'app revient en premier plan ou passe en arrière-plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app revient en premier plan : resynchroniser le statut
      _syncOnlineStatus();
    }
  }

  /// Synchronise le statut "en ligne" depuis le serveur et redémarre le tracking si nécessaire.
  Future<void> _syncOnlineStatus() async {
    try {
      // Rafraîchir le profil depuis le serveur
      ref.invalidate(courierProfileProvider);
      final profile = await ref.read(courierProfileProvider.future);

      if (!mounted) return;

      final isOnline = profile.status == 'available';
      ref.read(isOnlineProvider.notifier).set(isOnline);

      // Redémarrer le tracking si en ligne
      final locationService = ref.read(locationServiceProvider);
      if (isOnline) {
        locationService.initializeFirestore(profile.id);
        locationService.startTracking();
        locationService.goOnline();
        // Centrer la carte sur la position actuelle après un court délai
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _centerOnMyLocation();
        });
      }
    } catch (_) {
      // Ignorer les erreurs de synchronisation silencieuses
    }
  }

  /// Vérifie si une mise à jour forcée est nécessaire au démarrage.
  void _checkForUpdate() {
    ref.read(appUpdateProvider.future).then((result) {
      if (result != null && result.forceUpdate && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ForceUpdateDialog(result: result),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _geofenceSubscription?.cancel();
    _geofenceSubscription = null;
    // Libérer le controller natif Google Maps pour éviter les fuites mémoire
    _controller.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  /// Notification quand le livreur arrive à proximité d'un point
  void _onGeofenceEvent(GeofenceEvent event) {
    if (!mounted) return;

    final loc = AppLocalizations.of(context);

    if (event.isArriving) {
      final zoneName = event.zone.name ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.zone.type == 'pickup'
                ? '📦 ${loc?.approachingPharmacy(zoneName) ?? "Vous approchez de la pharmacie $zoneName"}'
                : '📍 ${loc?.approachingClient(zoneName) ?? "Vous approchez du client $zoneName"}',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: AppConfig.snackbarDurationSec),
        ),
      );
    } else if (event.isArrived) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.zone.type == 'pickup'
                ? '✅ ${loc?.arrivedAtPharmacy ?? "Vous êtes arrivé à la pharmacie !"}'
                : '✅ ${loc?.arrivedAtClient ?? "Vous êtes arrivé chez le client !"}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: loc?.ok ?? 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Centre la carte sur la position actuelle avec haute précision GPS
  Future<void> _centerOnMyLocation({bool animate = true}) async {
    try {
      // Obtenir la position actuelle avec la meilleure précision
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // Précision maximale
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final latLng = LatLng(position.latitude, position.longitude);
      final controller = await _controller.future;

      if (animate) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17.0,
              bearing: position.heading,
              tilt: 45.0,
            ),
          ),
        );
      } else {
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17.0,
              bearing: position.heading,
              tilt: 45.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('📍 Erreur centrage position: $e');
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Si on veut passer en ligne, vérifier le KYC après refresh des profils
    if (value) {
      if (!await KycGuard.ensureVerified(context, ref)) return;
    }

    // Empêcher les clics multiples pendant le chargement
    if (_isTogglingStatus) return;
    // Debounce: ignorer si le dernier toggle date de moins de 3 secondes
    final now = DateTime.now();
    if (_lastToggleTime != null &&
        now.difference(_lastToggleTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastToggleTime = now;

    setState(() => _isTogglingStatus = true);

    try {
      // Optimistic update
      ref.read(isOnlineProvider.notifier).set(value);

      // Envoie le statut souhaité explicitement pour éviter les désynchronisations
      final desiredStatus = value ? 'available' : 'offline';
      final actualStatus = await ref
          .read(deliveryRepositoryProvider)
          .toggleAvailability(desiredStatus: desiredStatus);

      // Synchroniser avec le statut réel retourné par le serveur
      ref.read(isOnlineProvider.notifier).set(actualStatus);
      ref.invalidate(courierProfileProvider);
      ref.invalidate(profileProvider);

      final locationService = ref.read(locationServiceProvider);
      if (actualStatus) {
        locationService.startTracking();
        // Signaler en ligne dans Firestore
        locationService.goOnline();
        // Centrer la carte sur la position actuelle avec haute précision
        _centerOnMyLocation();
      } else {
        locationService.stopTracking();
        // Signaler hors ligne dans Firestore
        locationService.goOffline();
      }
    } catch (e) {
      // Revert on error
      ref.read(isOnlineProvider.notifier).set(!value);
      if (mounted) {
        // KYC incomplet → rediriger vers l'écran de soumission des documents
        if (e is IncompleteKycException) {
          context.push(
            AppRoutes.kycResubmission,
            extra: {'rejectionReason': e.rejectionReason},
          );
        } else {
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
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final profileAsync = ref.watch(courierProfileProvider);
    final activeDeliveriesAsync = ref.watch(deliveriesProvider('active'));
    final heatmapState = ref.watch(courierHeatmapProvider);

    // Update shared state when provider data changes (but not during toggle)
    ref.listen<AsyncValue<CourierProfile>>(courierProfileProvider, (
      prev,
      next,
    ) {
      if (next.hasValue && next.value != null) {
        final profile = next.value!;
        // Ne pas écraser le statut si un toggle est en cours
        if (!_isTogglingStatus) {
          ref
              .read(isOnlineProvider.notifier)
              .set(profile.status == 'available');
        }
        // Initialiser le tracking Firestore avec l'ID du livreur
        ref.read(locationServiceProvider).initializeFirestore(profile.id);
      }
    });

    // Listen to active deliveries to update route + geofencing
    ref.listen<AsyncValue<List<dynamic>>>(deliveriesProvider('active'), (
      prev,
      next,
    ) {
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

    // Effect: Update camera when location changes (sans ref.watch pour éviter les rebuilds)
    ref.listen<AsyncValue<Position>>(locationStreamProvider, (prev, next) {
      if (next.hasValue && next.value != null && isOnline && _isFollowingUser) {
        final pos = next.value!;
        final latLng = LatLng(pos.latitude, pos.longitude);

        _controller.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latLng,
                zoom: 17.0, // Zoom closer for navigation feeling
                bearing: pos.heading, // Rotate map with movement
                tilt: 45.0, // 3D effect
              ),
            ),
          );
        });
      }
    });

    // Connectivity state for no-network banner
    final isDisconnected = ref.watch(isDisconnectedProvider);

    return Scaffold(
      body: AsyncValueWidget<List<dynamic>>(
        value: activeDeliveriesAsync,
        data: (activeDeliveries) {
          final hasActiveDelivery = activeDeliveries.isNotEmpty;
          final activeDelivery = hasActiveDelivery
              ? activeDeliveries.first
              : null;

          // Prepare Markers & Polylines
          Set<Marker> markers = {};
          // Use our calculated polylines (Directions API) instead of manual straight line
          Set<Polyline> polylines = _polylines;
          Set<Circle> heatCircles = {};

          if (activeDelivery != null) {
            LatLng? pharmacyLoc;
            LatLng? customerLoc;

            if (activeDelivery.pharmacyLat != null &&
                activeDelivery.pharmacyLng != null) {
              pharmacyLoc = LatLng(
                activeDelivery.pharmacyLat!,
                activeDelivery.pharmacyLng!,
              );
              markers.add(
                Marker(
                  markerId: const MarkerId('pharmacy'),
                  position: pharmacyLoc,
                  infoWindow: const InfoWindow(title: 'Pharmacie'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                ),
              );
            }

            if (activeDelivery.deliveryLat != null &&
                activeDelivery.deliveryLng != null) {
              customerLoc = LatLng(
                activeDelivery.deliveryLat!,
                activeDelivery.deliveryLng!,
              );
              markers.add(
                Marker(
                  markerId: const MarkerId('customer'),
                  position: customerLoc,
                  infoWindow: const InfoWindow(title: 'Client'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              );
            }
          }

          // Ajouter le marqueur du coursier depuis la position en temps réel
          final locationAsync = ref.watch(locationStreamProvider);
          if (locationAsync.hasValue &&
              locationAsync.value != null &&
              isOnline) {
            final position = locationAsync.value!;
            markers.add(
              Marker(
                markerId: const MarkerId('courier'),
                position: LatLng(position.latitude, position.longitude),
                icon:
                    _courierIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                anchor: const Offset(0.5, 0.5),
                rotation: position.heading,
                flat: true,
                zIndexInt: 999,
                infoWindow: InfoWindow(
                  title: 'Ma position',
                  snippet: position.speed > 0.5
                      ? '${(position.speed * 3.6).toInt()} km/h'
                      : 'En attente',
                ),
              ),
            );
          }

          // Overlay de zones chaudes (sans livraison active)
          if (isOnline &&
              !hasActiveDelivery &&
              heatmapState.opportunities.isNotEmpty) {
            for (final zone in heatmapState.opportunities.take(5)) {
              final heatColor = _heatLevelColor(zone.heatLevel);
              final radiusMeters = 350 + (zone.pendingOrders * 120);

              heatCircles.add(
                Circle(
                  circleId: CircleId('heat_${zone.lat}_${zone.lng}'),
                  center: LatLng(zone.lat, zone.lng),
                  radius: radiusMeters.toDouble(),
                  fillColor: heatColor.withValues(alpha: 0.18),
                  strokeColor: heatColor.withValues(alpha: 0.65),
                  strokeWidth: 2,
                ),
              );
            }
          }

          return Stack(
            children: [
              // 1. MAP BACKGROUND - Lazy load: pas de carte si offline sans livraison
              // Économise ~50-80 MB de RAM et évite le téléchargement de tiles
              if (isOnline || hasActiveDelivery)
                _buildMap(
                  markers: markers,
                  polylines: polylines,
                  circles: heatCircles,
                )
              else
                _buildOfflineMapPlaceholder(),

              // 0. NO-NETWORK BANNER
              if (isDisconnected)
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.red.shade700,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pas de connexion — positions non envoyées',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref
                                .read(connectivityProvider.notifier)
                                .checkConnectivity(),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Refresh deliveries button
              if (isOnline && !hasActiveDelivery)
                Positioned(
                  left: 16,
                  bottom: hasActiveDelivery ? 200 : 120,
                  child: FloatingActionButton.small(
                    heroTag: 'refresh_btn',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.invalidate(deliveriesProvider('active'));
                      ref.invalidate(deliveriesProvider('pending'));
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: DesignTokens.primary,
                    ),
                  ),
                ),

              // Re-Center Button (Floating)
              if (isOnline && !_isFollowingUser)
                Positioned(
                  right: 16,
                  bottom: hasActiveDelivery ? 200 : 120,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_btn',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isFollowingUser = true);
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: Icon(
                      Icons.gps_fixed_rounded,
                      color: DesignTokens.primary,
                    ),
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
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.multiRoute);
                    },
                    backgroundColor: DesignTokens.primary,
                    elevation: 4,
                    icon: const Icon(Icons.route_rounded, color: Colors.white),
                    label: Text(
                      '${activeDeliveries.length} livraisons',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // 2. OVERLAY FOR OFFLINE STATE
              if (!isOnline && !hasActiveDelivery) const OfflineOverlay(),

              // 3. TOP STATUS BAR (Earnings & Status)
              HomeStatusBar(profileAsync: profileAsync),

              // 4. BOTTOM ACTION BUTTON (GO ONLINE)
              if (!hasActiveDelivery)
                GoOnlineButton(
                  isOnline: isOnline,
                  isToggling: _isTogglingStatus,
                  onToggle: () => _toggleAvailability(!isOnline),
                ),

              // 5. FINDING ORDERS + NEW ORDER ALERT (BROADCAST SYSTEM)
              if (isOnline && !hasActiveDelivery) ...[
                _buildSearchingIndicator(),
                const BroadcastOffersOverlay(),
                HeatmapOpportunitiesOverlay(onNavigateToZone: _focusOnHeatZone),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252540) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DesignTokens.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recherche de commandes...',
                style: TextStyle(
                  color: isDark
                      ? DesignTokens.textMutedDarkMode
                      : DesignTokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _focusOnHeatZone(double lat, double lng) async {
    final controller = await _controller.future;
    setState(() => _isFollowingUser = false);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 13.8),
      ),
    );
  }

  Color _heatLevelColor(String level) {
    switch (level) {
      case 'extreme':
        return const Color(0xFF7C3AED);
      case 'hot':
        return const Color(0xFFEF4444);
      case 'warm':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  // Style de carte propre pour app de livraison
  static const String _mapStyle = '''[
    {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#c8e6c9"}]},
    {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#ffd54f"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#ffb300"}]},
    {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#d6d6d6"}]},
    {"featureType":"road.local","elementType":"geometry.fill","stylers":[{"color":"#f5f5f5"}]},
    {"featureType":"road.local","elementType":"geometry.stroke","stylers":[{"color":"#e0e0e0"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#b3e5fc"}]},
    {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#f0f0f0"}]},
    {"featureType":"landscape.natural","elementType":"geometry.fill","stylers":[{"color":"#e8f5e9"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]}
  ]''';

  /// Placeholder statique quand l'utilisateur est offline sans livraison
  /// Économise ~50-80 MB de RAM et évite les appels API Google Maps
  Widget _buildOfflineMapPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
              : [const Color(0xFFe8f5e9), const Color(0xFFc8e6c9)],
        ),
      ),
      child: Stack(
        children: [
          // Grille simulant une carte
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(isDark: isDark),
          ),
          // Icône centrale
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carte inactive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passez en ligne pour activer',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap({
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Circle>? circles,
  }) {
    return GoogleMap(
      mapType: MapType.normal,
      style: _mapStyle,
      initialCameraPosition: _initialCameraPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: markers ?? {},
      polylines: polylines ?? {},
      circles: circles ?? {},
      onCameraMoveStarted: () {
        _isFollowingUser = false; // L'utilisateur déplace la carte manuellement
      },
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
          // Si on n'a pas encore la position réelle, centrer dès qu'elle est disponible
          if (!_hasInitialPosition) {
            _centerOnMyLocation(animate: false);
          }
        }
      },
    );
  }

  /// Obtenir la position actuelle ou la dernière connue
  Future<LatLng?> _getCurrentOrLastPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return LatLng(lastPosition.latitude, lastPosition.longitude);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _updateRoute(dynamic delivery, LatLng? myLocation) async {
    if (delivery == null) {
      if (_polylines.isNotEmpty) setState(() => _polylines = {});
      return;
    }

    LatLng? origin;
    LatLng? destination;

    if (delivery.status == 'assigned' || delivery.status == 'accepted') {
      // Utiliser la position passée, ou obtenir la position réelle
      origin = myLocation ?? await _getCurrentOrLastPosition();
      if (origin == null) {
        debugPrint('⚠️ Impossible d\'obtenir la position pour la route');
        return;
      }
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
              color: DesignTokens.primary,
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
          delivery.pharmacyLat != null &&
          delivery.pharmacyLng != null) {
        geofencing.addZone(
          GeofenceZone(
            deliveryId: delivery.id as int,
            type: 'pickup',
            latitude: delivery.pharmacyLat!,
            longitude: delivery.pharmacyLng!,
            name: delivery.pharmacyName,
          ),
        );
      }

      // Zone client (dropoff) — pour statuts picked_up/in_transit
      if ((delivery.status == 'picked_up' || delivery.status == 'in_transit') &&
          delivery.deliveryLat != null &&
          delivery.deliveryLng != null) {
        geofencing.addZone(
          GeofenceZone(
            deliveryId: delivery.id as int,
            type: 'dropoff',
            latitude: delivery.deliveryLat!,
            longitude: delivery.deliveryLng!,
            name: delivery.customerName,
          ),
        );
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
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }
}

/// Painter pour dessiner une grille simulant une carte
/// Utilisé quand l'utilisateur est offline pour économiser la batterie/RAM
class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Lignes verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Lignes horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
