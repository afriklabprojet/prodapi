import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/navigation_service.dart';
import '../../core/constants/map_constants.dart';
import '../../data/repositories/delivery_repository.dart';
import '../widgets/common/common_widgets.dart';

class MultiRouteScreen extends ConsumerStatefulWidget {
  const MultiRouteScreen({super.key});

  @override
  ConsumerState<MultiRouteScreen> createState() => _MultiRouteScreenState();
}

class _MultiRouteScreenState extends ConsumerState<MultiRouteScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _routeData;
  bool _isLoading = true;
  String? _error;
  Set<Polyline> _polylines = {};
  String? _totalDurationText;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final data = await repo.getOptimizedRoute();
      if (!mounted) return;

      // Decode polyline from API if available
      final polylineEncoded = data['polyline'] as String?;
      Set<Polyline> polylines = {};
      if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
        final points = PolylinePoints().decodePolyline(polylineEncoded);
        final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        if (latLngs.isNotEmpty) {
          polylines.add(Polyline(
            polylineId: const PolylineId('optimized_route'),
            points: latLngs,
            color: Colors.blue,
            width: 4,
            patterns: const [],
          ));
        }
      }

      // Total duration from API
      final durationMin = data['total_duration_minutes'] as num?;
      String? durationText;
      if (durationMin != null && durationMin > 0) {
        final hours = durationMin.toInt() ~/ 60;
        final mins = durationMin.toInt() % 60;
        durationText = hours > 0 ? '${hours}h ${mins}min' : '$mins min';
      }

      setState(() {
        _routeData = data;
        _polylines = polylines;
        _totalDurationText = durationText;
        _isLoading = false;
      });
      _fitBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _fitBounds() {
    if (_mapController == null || _routeData == null) return;

    final stops = _routeData!['stops'] as List? ?? [];
    if (stops.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final stop in stops) {
      final lat = (stop['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (stop['longitude'] as num?)?.toDouble() ?? 0;
      if (lat != 0 && lng != 0) {
        minLat = lat < minLat ? lat : minLat;
        maxLat = lat > maxLat ? lat : maxLat;
        minLng = lng < minLng ? lng : minLng;
        maxLng = lng > maxLng ? lng : maxLng;
      }
    }

    if (minLat != double.infinity) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - 0.01, minLng - 0.01),
            northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
          ),
          50,
        ),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_routeData == null) return markers;

    final stops = _routeData!['stops'] as List? ?? [];
    int pickupIndex = 1;
    int dropoffIndex = 1;

    for (final stop in stops) {
      final lat = (stop['latitude'] as num?)?.toDouble();
      final lng = (stop['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final isPickup = stop['type'] == 'pickup';
      final index = isPickup ? pickupIndex++ : dropoffIndex++;

      markers.add(
        Marker(
          markerId: MarkerId('${stop['type']}_${stop['delivery_id']}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isPickup ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '${isPickup ? "📦 Récup." : "📍 Livr."} $index: ${stop['name']}',
            snippet: stop['address'],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Itinéraire'),
        backgroundColor: context.cardBackground,
        foregroundColor: context.primaryText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoute,
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingWidget()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadRoute,
                )
              : _buildContent(currencyFormat),
    );
  }

  Widget _buildContent(NumberFormat currencyFormat) {
    final stops = _routeData?['stops'] as List? ?? [];
    final totalDistance = (_routeData?['total_distance_km'] ?? 0).toDouble();
    final totalEarnings = (_routeData?['total_estimated_earnings'] ?? 0).toDouble();
    final pickupCount = _routeData?['pickup_count'] ?? 0;
    final deliveryCount = _routeData?['delivery_count'] ?? 0;

    if (stops.isEmpty) {
      return const AppEmptyWidget(
        icon: Icons.route_outlined,
        message: 'Aucune course active',
        subtitle: 'Acceptez des courses pour voir votre itinéraire',
      );
    }

    return Stack(
      children: [
        // Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: MapConstants.defaultLocation,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _fitBounds();
          },
          markers: _buildMarkers(),
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Summary card at top
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBackground,
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      icon: Icons.store,
                      value: '$pickupCount',
                      label: 'Récup.',
                      color: Colors.blue,
                    ),
                    _SummaryItem(
                      icon: Icons.local_shipping,
                      value: '$deliveryCount',
                      label: 'Livr.',
                      color: Colors.red,
                    ),
                    _SummaryItem(
                      icon: Icons.straighten,
                      value: '${totalDistance.toStringAsFixed(1)} km',
                      label: 'Distance',
                      color: Colors.orange,
                    ),
                    _SummaryItem(
                      icon: Icons.monetization_on,
                      value: '${currencyFormat.format(totalEarnings)} F',
                      label: 'Gains',
                      color: Colors.green,
                    ),
                  ],
                ),
                if (_totalDurationText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Durée totale estimée : $_totalDurationText',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Stops list at bottom
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.15,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
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
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Étapes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${stops.length} arrêts',
                          style: TextStyle(
                            color: context.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stops.length,
                      itemBuilder: (context, index) {
                        final stop = stops[index];
                        return _StopCard(
                          stop: stop,
                          index: index + 1,
                          isLast: index == stops.length - 1,
                          currencyFormat: currencyFormat,
                          onNavigate: () => _navigateToStop(stop),
                          onCall: () => _callPhone(stop['phone']),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _navigateToStop(Map<String, dynamic> stop) async {
    final lat = (stop['latitude'] as num?)?.toDouble();
    final lng = (stop['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final navService = ref.read(navigationServiceProvider);
    final name = stop['name'] as String? ?? 'Destination';
    
    await navService.showAppSelector(
      context,
      destinationLat: lat,
      destinationLng: lng,
      destinationName: name,
    );
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.secondaryText),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final Map<String, dynamic> stop;
  final int index;
  final bool isLast;
  final NumberFormat currencyFormat;
  final VoidCallback onNavigate;
  final VoidCallback onCall;

  const _StopCard({
    required this.stop,
    required this.index,
    required this.isLast,
    required this.currencyFormat,
    required this.onNavigate,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = stop['type'] == 'pickup';
    final color = isPickup ? Colors.blue : Colors.red;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: context.dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPickup ? '📦 Récupération' : '📍 Livraison',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isPickup && stop['estimated_earnings'] != null)
                      Text(
                        '+${currencyFormat.format(stop['estimated_earnings'])} F',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stop['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  stop['address'] ?? '',
                  style: TextStyle(fontSize: 13, color: context.secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isPickup && stop['total_amount'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Montant: ${currencyFormat.format(stop['total_amount'])} FCFA',
                    style: TextStyle(fontSize: 12, color: context.secondaryText),
                  ),
                ],
                // Leg distance/duration from Directions API
                if (stop['leg_distance'] != null || stop['leg_duration'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (stop['leg_distance'] != null) ...[
                        Icon(Icons.straighten, size: 12, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          stop['leg_distance'],
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (stop['leg_duration'] != null) ...[
                        Icon(Icons.access_time, size: 12, color: Colors.purple),
                        const SizedBox(width: 2),
                        Text(
                          stop['leg_duration'],
                          style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.navigation,
                      label: 'Y aller',
                      color: Colors.blue,
                      onTap: onNavigate,
                    ),
                    const SizedBox(width: 8),
                    if (stop['phone'] != null)
                      _ActionButton(
                        icon: Icons.phone,
                        label: 'Appeler',
                        color: Colors.green,
                        onTap: onCall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
