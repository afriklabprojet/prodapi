import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/map_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/delivery.dart';
import '../../data/models/route_info.dart';
import '../providers/delivery_providers.dart';
import '../widgets/delivery/delivery_communication.dart';
import '../widgets/delivery/delivery_document_section.dart';
import '../widgets/delivery/delivery_info_section.dart';
import '../widgets/delivery/delivery_proof.dart';
import '../widgets/delivery/delivery_status_actions.dart';

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final Delivery delivery;

  const DeliveryDetailsScreen({super.key, required this.delivery});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen>
    with SingleTickerProviderStateMixin {
  final Set<Marker> _staticMarkers = {};
  bool _isLoading = false;

  // Google Maps Controller pour suivre le coursier
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isFollowingCourier = true;
  BitmapDescriptor? _courierIcon;
  Position? _lastPosition;

  // Route info pour ETA
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  // Pulse animation for CTA when near destination
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isNearDestination = false;

  // Mode condensé en mouvement (vitesse > 5 km/h)
  bool _isMoving = false;
  bool _forceExpanded = false;

  // Helpers
  late DeliveryCommunicationHelper _commHelper;
  late DeliveryProofHelper _proofHelper;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _fetchRouteInfo();
    _loadCourierIcon();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Charge l'icône personnalisée du coursier (moto)
  Future<void> _loadCourierIcon() async {
    try {
      _courierIcon = await _createCourierMarkerIcon();
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur chargement icône coursier: $e');
    }
  }

  /// Crée une icône de marqueur personnalisée pour le coursier
  Future<BitmapDescriptor> _createCourierMarkerIcon() async {
    const double size = 80;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Dessiner le cercle de fond avec effet de pulsation
    final Paint shadowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      shadowPaint,
    );

    // Cercle principal bleu
    final Paint circlePaint = Paint()
      ..color = const Color(0xFF1565C0)
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commHelper = DeliveryCommunicationHelper(
      context: context,
      delivery: widget.delivery,
    );
    _proofHelper = DeliveryProofHelper(
      context: context,
      ref: ref,
      delivery: widget.delivery,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _staticMarkers.clear();
    _routeInfo = null;
    // Libérer le controller Google Maps
    _mapController.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  /// Anime la caméra pour suivre le coursier
  Future<void> _animateCameraToCourier(Position position) async {
    if (!_isFollowingCourier || !mounted) return;

    try {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17.0,
            bearing: position.heading,
            tilt: 45.0,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur animation caméra: $e');
    }
  }

  /// Centre la caméra sur le coursier
  Future<void> _centerOnCourier() async {
    if (_lastPosition == null) return;
    setState(() => _isFollowingCourier = true);
    await _animateCameraToCourier(_lastPosition!);
  }

  Future<void> _fetchRouteInfo() async {
    LatLng? origin;
    LatLng? destination;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      origin = LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Position error, using pharmacy: $e');
      if (widget.delivery.pharmacyLat != null &&
          widget.delivery.pharmacyLng != null) {
        origin = LatLng(
          widget.delivery.pharmacyLat!,
          widget.delivery.pharmacyLng!,
        );
      }
    }

    final status = widget.delivery.status;
    if (status == 'assigned' || status == 'accepted') {
      if (widget.delivery.pharmacyLat != null &&
          widget.delivery.pharmacyLng != null) {
        destination = LatLng(
          widget.delivery.pharmacyLat!,
          widget.delivery.pharmacyLng!,
        );
      }
    } else {
      if (widget.delivery.deliveryLat != null &&
          widget.delivery.deliveryLng != null) {
        destination = LatLng(
          widget.delivery.deliveryLat!,
          widget.delivery.deliveryLng!,
        );
      }
    }

    if (origin == null || destination == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final routeService = ref.read(routeServiceProvider);
      final routeInfo = await routeService.getRouteInfo(origin, destination);

      if (mounted && routeInfo != null) {
        setState(() {
          _routeInfo = routeInfo;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Route loading error: $e');
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _setupMarkers() {
    if (widget.delivery.pharmacyLat != null &&
        widget.delivery.pharmacyLng != null) {
      _staticMarkers.add(
        Marker(
          markerId: const MarkerId('pharmacy'),
          position: LatLng(
            widget.delivery.pharmacyLat!,
            widget.delivery.pharmacyLng!,
          ),
          infoWindow: InfoWindow(
            title: widget.delivery.pharmacyName,
            snippet: 'Pharmacie (Récupération)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (widget.delivery.deliveryLat != null &&
        widget.delivery.deliveryLng != null) {
      _staticMarkers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: LatLng(
            widget.delivery.deliveryLat!,
            widget.delivery.deliveryLng!,
          ),
          infoWindow: InfoWindow(
            title: widget.delivery.customerName,
            snippet: 'Client (Livraison)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _checkProximity(Position position) {
    final wasMoving = _isMoving;
    final nowMoving = position.speed > 1.39;
    if (nowMoving != wasMoving) {
      setState(() {
        _isMoving = nowMoving;
        if (!nowMoving) _forceExpanded = false;
      });
    }

    double? destLat;
    double? destLng;

    final status = widget.delivery.status;
    if (status == 'pending' || status == 'assigned' || status == 'accepted') {
      destLat = widget.delivery.pharmacyLat;
      destLng = widget.delivery.pharmacyLng;
    } else if (status == 'picked_up') {
      destLat = widget.delivery.deliveryLat;
      destLng = widget.delivery.deliveryLng;
    }

    if (destLat == null || destLng == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destLat,
      destLng,
    );

    final wasNear = _isNearDestination;
    _isNearDestination = distance < 200;

    if (_isNearDestination && !wasNear) {
      _pulseController.repeat(reverse: true);
    } else if (!_isNearDestination && wasNear) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final initialPos =
        (widget.delivery.pharmacyLat != null &&
            widget.delivery.pharmacyLng != null)
        ? LatLng(widget.delivery.pharmacyLat!, widget.delivery.pharmacyLng!)
        : MapConstants.defaultLocation;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Full Screen Map avec suivi en temps réel
          Consumer(
            builder: (context, ref, _) {
              final locationAsync = ref.watch(locationStreamProvider);
              final Set<Marker> currentMarkers = Set.from(_staticMarkers);

              if (locationAsync.hasValue) {
                final position = locationAsync.value!;
                _lastPosition = position;
                _checkProximity(position);

                // Animer la caméra pour suivre le coursier
                if (_isFollowingCourier) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _animateCameraToCourier(position);
                  });
                }

                // Marqueur du coursier avec icône personnalisée et rotation
                currentMarkers.add(
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
                    flat: true, // Marqueur plat pour meilleure rotation
                    zIndexInt: 999, // Au-dessus des autres marqueurs
                    infoWindow: InfoWindow(
                      title: 'Ma position',
                      snippet: position.speed > 0.5
                          ? '${(position.speed * 3.6).toInt()} km/h'
                          : 'À l\'arrêt',
                    ),
                  ),
                );
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPos,
                  zoom: 16,
                  tilt: 45,
                ),
                markers: currentMarkers,
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                    // Centrer sur le coursier après création de la carte
                    if (_lastPosition != null) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _animateCameraToCourier(_lastPosition!);
                      });
                    }
                  }
                },
                onCameraMoveStarted: () {
                  // Détecter le mouvement manuel de la carte
                  if (_isFollowingCourier) {
                    setState(() => _isFollowingCourier = false);
                  }
                },
                myLocationEnabled: false, // On utilise notre propre marqueur
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                padding: const EdgeInsets.only(bottom: 250),
                compassEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
              );
            },
          ),

          // Bouton de recentrage (visible quand on ne suit pas le coursier)
          if (!_isFollowingCourier)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.55,
              child: FloatingActionButton.small(
                heroTag: 'recenter_delivery',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _centerOnCourier();
                },
                backgroundColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                elevation: 4,
                child: Icon(
                  Icons.my_location,
                  color: isDark ? Colors.white : const Color(0xFF1565C0),
                ),
              ),
            ),

          // 2. Sliding Detail Panel
          DraggableScrollableSheet(
            initialChildSize: 0.50,
            minChildSize: 0.25,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          DeliveryStepperBar(
                            delivery: widget.delivery,
                            routeInfo: _routeInfo,
                          ),
                          const SizedBox(height: 16),
                          DeliveryETASection(
                            delivery: widget.delivery,
                            routeInfo: _routeInfo,
                            isLoadingRoute: _isLoadingRoute,
                            onRefreshRoute: _fetchRouteInfo,
                          ),
                          const SizedBox(height: 20),
                          if (!_isMoving || _forceExpanded) ...[
                            DeliveryInfoHeader(delivery: widget.delivery),
                            const SizedBox(height: 20),
                            DeliveryTimeline(
                              delivery: widget.delivery,
                              commHelper: _commHelper,
                            ),
                            const SizedBox(height: 20),
                            DeliveryPaymentInfo(delivery: widget.delivery),
                            const SizedBox(height: 20),
                            DeliveryDocumentSection(delivery: widget.delivery),
                            const SizedBox(height: 24),
                          ],
                          if (_isMoving && !_forceExpanded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _forceExpanded = true),
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: const Text(
                                  'Voir les détails',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          DeliveryStatusActions(
                            delivery: widget.delivery,
                            isLoading: _isLoading,
                            isNearDestination: _isNearDestination,
                            pulseAnimation: _pulseAnimation,
                            commHelper: _commHelper,
                            proofHelper: _proofHelper,
                            onStatusChanged: () {
                              if (mounted) Navigator.pop(context);
                            },
                            onLoadingChanged: (loading) {
                              if (mounted) {
                                setState(() => _isLoading = loading);
                              }
                            },
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
