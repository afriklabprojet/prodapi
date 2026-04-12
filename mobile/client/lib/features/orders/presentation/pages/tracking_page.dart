import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../domain/entities/delivery_address_entity.dart';
import '../../../../config/providers.dart'; // Pour ordersRepositoryProvider
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/messaging/messaging.dart';
import '../../../../core/services/firestore_tracking_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/eta_service.dart';
import 'courier_chat_page.dart';

/// Provider pour le service Firestore de tracking côté client
final firestoreTrackingServiceProvider = Provider<FirestoreTrackingService>((
  ref,
) {
  return FirestoreTrackingService();
});

/// Provider pour le stream de tracking d'une livraison en temps réel
final deliveryTrackingStreamProvider =
    StreamProvider.family<DeliveryTrackingData?, int>((ref, orderId) {
      final service = ref.watch(firestoreTrackingServiceProvider);
      return service.watchDeliveryTracking(orderId);
    });

/// Provider pour le stream de position d'un livreur en temps réel
final courierLocationStreamProvider =
    StreamProvider.family<CourierLocationData?, int>((ref, courierId) {
      final service = ref.watch(firestoreTrackingServiceProvider);
      return service.watchCourierLocation(courierId);
    });

class TrackingPage extends ConsumerStatefulWidget {
  final int orderId;
  final DeliveryAddressEntity deliveryAddress;
  final String?
  pharmacyAddress; // Assuming we can get coordinates via geocoding or passed
  // Ideally, we need LatLng for pharmacy and delivery. Does OrderEntity have them?
  // OrderEntity has DeliveryAddressEntity which might have lat/lng?

  const TrackingPage({
    super.key,
    required this.orderId,
    required this.deliveryAddress,
    this.pharmacyAddress,
  });

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _courierPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  // ETA temps réel
  final EtaService _etaService = EtaService();
  String? _etaText;
  String? _distanceText;
  Timer? _etaTimer;

  // Timeout/stale tracking - détecte quand le livreur ne répond plus
  DateTime? _lastPositionUpdate;
  Timer? _staleCheckTimer;
  bool _isPositionStale = false;
  static const Duration _staleThreshold = Duration(minutes: 2);

  // Courier info (chargé une fois depuis l'API, puis mis à jour via Firestore)
  int? _deliveryId;
  int? _courierId;
  String? _courierName;
  String? _courierPhone;
  String? _deliveryStatus;
  DateTime? _estimatedArrival;
  bool _isCourierCardExpanded = true;

  // Default coordinates (Abidjan)
  static const LatLng _center = LatLng(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );

  @override
  void dispose() {
    _etaTimer?.cancel();
    _staleCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialTrackingInfo();
    _startEtaTimer();
    _startStaleCheckTimer();
    // Listen to tracking stream changes outside of build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(deliveryTrackingStreamProvider(widget.orderId), (
        previous,
        next,
      ) {
        next.whenData((tracking) {
          if (tracking != null && mounted) {
            _updateMarkersFromFirestore(tracking);
            // Marquer la position comme fraîche
            _lastPositionUpdate = DateTime.now();
            if (_isPositionStale) {
              setState(() => _isPositionStale = false);
            }
            setState(() {
              _courierPosition = LatLng(tracking.latitude, tracking.longitude);
              _deliveryStatus = tracking.status;
              _estimatedArrival = tracking.estimatedArrival;
            });
          }
        });
      });
    });
  }

  /// Vérifie périodiquement si la position du livreur est périmée (pas de mise à jour récente)
  void _startStaleCheckTimer() {
    _staleCheckTimer?.cancel();
    _staleCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;

      if (_lastPositionUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastPositionUpdate!);
        final shouldBeStale = timeSinceUpdate > _staleThreshold;

        if (shouldBeStale != _isPositionStale) {
          setState(() => _isPositionStale = shouldBeStale);
        }
      }
    });
  }

  /// Démarre un timer pour rafraîchir l'ETA périodiquement (toutes les 30 secondes)
  void _startEtaTimer() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(AppConstants.etaRefreshInterval, (timer) {
      if (_courierPosition != null && mounted) {
        _refreshEta();
      }
    });
  }

  /// Recalcule l'ETA via Directions API avec données trafic
  Future<void> _refreshEta() async {
    if (_courierPosition == null || widget.deliveryAddress.latitude == null) {
      return;
    }

    final eta = await _etaService.calculateEta(
      originLat: _courierPosition!.latitude,
      originLng: _courierPosition!.longitude,
      destLat: widget.deliveryAddress.latitude!,
      destLng: widget.deliveryAddress.longitude!,
    );

    if (eta != null && mounted) {
      final points = PolylinePoints().decodePolyline(eta.polyline);
      final polylineCoords = points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _etaText = eta.durationText;
        _distanceText = eta.distanceText;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoords,
            color: AppColors.primary,
            width: 4,
          ),
        };
      });
    }
  }

  /// Récupérer les infos du livreur depuis l'API
  /// Ensuite Firestore prend le relais pour le tracking live
  Future<void> _fetchInitialTrackingInfo() async {
    try {
      final trackingData = await ref
          .read(ordersRepositoryProvider)
          .getTrackingInfo(widget.orderId);

      if (trackingData != null && mounted) {
        final delivery = trackingData['delivery'];
        if (delivery != null) {
          _deliveryId = delivery['id'] as int?;
        }

        final courier = trackingData['courier'];
        if (courier != null) {
          setState(() {
            _courierId = courier['id'] as int?;
            _courierName = courier['name'] as String?;
            _courierPhone = courier['phone'] as String?;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      AppLogger.warning('Error fetching initial tracking info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Met à jour les marqueurs sur la carte avec la position Firestore
  void _updateMarkersFromFirestore(DeliveryTrackingData tracking) {
    _markers = {};

    // Marqueur destination
    if (widget.deliveryAddress.latitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            widget.deliveryAddress.latitude!,
            widget.deliveryAddress.longitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Marqueur livreur (position live Firestore)
    final courierPos = LatLng(tracking.latitude, tracking.longitude);
    _markers.add(
      Marker(
        markerId: const MarkerId('courier'),
        position: courierPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: _courierName ?? 'Livreur'),
      ),
    );

    // Recalculer l'ETA si position a changé significativement
    if (_courierPosition == null ||
        (_courierPosition!.latitude - courierPos.latitude).abs() > 0.001 ||
        (_courierPosition!.longitude - courierPos.longitude).abs() > 0.001) {
      _courierPosition = courierPos;
      _refreshEta();
    }

    // Animer la caméra vers la position du livreur
    _animateCameraTo(courierPos);
  }

  /// Anime la caméra de la carte vers une position
  Future<void> _animateCameraTo(LatLng position) async {
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _makePhoneCall() async {
    if (_courierPhone == null) return;
    final uri = Uri.parse('tel:$_courierPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    if (_courierPhone == null) return;
    final messaging = ref.read(messagingServiceProvider);
    await MessagingUiHelper.sendWithFeedback(
      context: context,
      action: () => messaging.contactCourier(courierPhone: _courierPhone!),
    );
  }

  void _openChat() {
    if (_deliveryId == null || _courierId == null || _courierName == null) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourierChatPage(
          orderId: widget.orderId,
          deliveryId: _deliveryId!,
          courierId: _courierId!,
          courierName: _courierName!,
          courierPhone: _courierPhone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the stream for rebuild — state updates handled by ref.listenManual in initState
    final trackingAsync = ref.watch(
      deliveryTrackingStreamProvider(widget.orderId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          // Map avec données temps réel Firestore
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : trackingAsync.when(
                  data: (tracking) {
                    // State updates are handled by the listener in initState
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _courierPosition ??
                            (widget.deliveryAddress.latitude != null
                                ? LatLng(
                                    widget.deliveryAddress.latitude!,
                                    widget.deliveryAddress.longitude!,
                                  )
                                : _center),
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (GoogleMapController controller) {
                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                        }
                      },
                    );
                  },
                  loading: () => GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target:
                          _courierPosition ??
                          (widget.deliveryAddress.latitude != null
                              ? LatLng(
                                  widget.deliveryAddress.latitude!,
                                  widget.deliveryAddress.longitude!,
                                )
                              : _center),
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Impossible de charger le suivi en temps réel',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(
                            deliveryTrackingStreamProvider(widget.orderId),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),

          // Bandeau statut en temps réel
          if (_deliveryStatus != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                color: _getStatusColor(_deliveryStatus!),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(_deliveryStatus!),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusLabel(_deliveryStatus!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Avertissement position périmée - quand le livreur ne répond plus
          if (_isPositionStale && _courierPosition != null)
            Positioned(
              top: _deliveryStatus != null ? 44 : 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                color: Colors.orange.shade700,
                child: Row(
                  children: [
                    const Icon(
                      Icons.signal_wifi_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position non actualisée',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _getStaleMessage(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_courierPhone != null)
                      GestureDetector(
                        onTap: _openWhatsApp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.message,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Contacter',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Courier Info Card (bottom) — collapsible
          if (_courierName != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle + courier header (always visible, tap to toggle)
                    GestureDetector(
                      onTap: () => setState(
                        () => _isCourierCardExpanded = !_isCourierCardExpanded,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          children: [
                            // Drag indicator
                            Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Courier Info Row
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  radius: 24,
                                  child: Icon(
                                    Icons.delivery_dining,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _courierName!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'Votre livreur',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _isCourierCardExpanded ? 0.0 : 0.5,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expandable content
                    AnimatedCrossFade(
                      firstChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ETA display (Directions API ou Firestore)
                            if (_etaText != null ||
                                _estimatedArrival != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _etaText != null
                                                ? 'Arrivée dans $_etaText'
                                                : 'Arrivée estimée : ${_formatEta(_estimatedArrival!)}',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (_distanceText != null)
                                            Text(
                                              'Distance restante : $_distanceText',
                                              style: TextStyle(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Action Buttons
                            Row(
                              children: [
                                // Call Button
                                if (_courierPhone != null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _makePhoneCall,
                                      icon: const Icon(Icons.phone, size: 18),
                                      label: const Text('Appeler'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_courierPhone != null)
                                  const SizedBox(width: 8),

                                // WhatsApp Button
                                if (_courierPhone != null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openWhatsApp,
                                      icon: const Icon(Icons.message, size: 18),
                                      label: const Text('WhatsApp'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF25D366,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_courierPhone != null)
                                  const SizedBox(width: 8),

                                // Chat Button
                                if (_deliveryId != null && _courierId != null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openChat,
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                      crossFadeState: _isCourierCardExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Helpers pour le bandeau de statut en temps réel ---

  Color _getStatusColor(String status) {
    switch (status) {
      case 'picked_up':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      case 'arriving':
        return Colors.green;
      case 'delivered':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'picked_up':
        return Icons.inventory_2;
      case 'in_transit':
        return Icons.delivery_dining;
      case 'arriving':
        return Icons.pin_drop;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'picked_up':
        return 'Commande récupérée';
      case 'in_transit':
        return 'En route vers vous';
      case 'arriving':
        return 'Arrivée imminente !';
      case 'delivered':
        return 'Livré ✓';
      default:
        return 'En préparation...';
    }
  }

  /// Message explicatif quand la position du livreur n'est plus mise à jour
  String _getStaleMessage() {
    if (_lastPositionUpdate == null) {
      return 'Le livreur ne partage plus sa position';
    }

    final minutes = DateTime.now().difference(_lastPositionUpdate!).inMinutes;
    if (minutes < 3) {
      return 'Dernière mise à jour il y a ~2 min';
    } else if (minutes < 10) {
      return 'Dernière mise à jour il y a $minutes min';
    } else {
      return 'Le livreur est peut-être dans une zone sans réseau';
    }
  }

  /// Formate l'ETA en texte lisible
  String _formatEta(DateTime eta) {
    final now = DateTime.now();
    final diff = eta.difference(now);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Dans un instant';
    } else if (diff.inMinutes < 60) {
      return '~${diff.inMinutes} min';
    } else {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '~${h}h${m > 0 ? m.toString().padLeft(2, '0') : ''}';
    }
  }
}
