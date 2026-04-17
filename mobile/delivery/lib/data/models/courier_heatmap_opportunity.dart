import '../../core/utils/safe_json.dart';

class CourierHeatmapOpportunity {
  final double lat;
  final double lng;
  final double distanceKm;
  final int pendingOrders;
  final String heatLevel;
  final int potentialEarnings;

  const CourierHeatmapOpportunity({
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.pendingOrders,
    required this.heatLevel,
    required this.potentialEarnings,
  });

  factory CourierHeatmapOpportunity.fromJson(Map<String, dynamic> json) {
    final center = (json['center'] as Map<String, dynamic>?) ?? const {};

    return CourierHeatmapOpportunity(
      lat: safeDouble(center['lat']),
      lng: safeDouble(center['lng']),
      distanceKm: safeDouble(json['distance_km']),
      pendingOrders: safeInt(json['pending_orders']),
      heatLevel: (json['heat_level'] as String?) ?? 'cold',
      potentialEarnings: safeInt(json['potential_earnings']),
    );
  }
}

class CourierHeatmapPayload {
  final int courierId;
  final List<CourierHeatmapOpportunity> opportunities;
  final String bestAction;
  final String? generatedAt;

  const CourierHeatmapPayload({
    required this.courierId,
    required this.opportunities,
    required this.bestAction,
    this.generatedAt,
  });

  factory CourierHeatmapPayload.empty() {
    return const CourierHeatmapPayload(
      courierId: 0,
      opportunities: [],
      bestAction: 'Aucune opportunite detectee',
      generatedAt: null,
    );
  }

  factory CourierHeatmapPayload.fromJson(Map<String, dynamic> json) {
    final opportunitiesData = json['opportunities'];
    final opportunities = opportunitiesData is List
        ? opportunitiesData
              .whereType<Map<String, dynamic>>()
              .map(CourierHeatmapOpportunity.fromJson)
              .toList()
        : <CourierHeatmapOpportunity>[];

    return CourierHeatmapPayload(
      courierId: safeInt(json['courier_id']),
      opportunities: opportunities,
      bestAction:
          (json['best_action'] as String?) ??
          'Aucune recommandation disponible',
      generatedAt: json['generated_at'] as String?,
    );
  }
}
