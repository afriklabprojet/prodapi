import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../models/courier_heatmap_opportunity.dart';

final courierHeatmapRepositoryProvider = Provider<CourierHeatmapRepository>((
  ref,
) {
  return CourierHeatmapRepository(ref.read(dioProvider));
});

class CourierHeatmapRepository {
  final Dio _dio;

  CourierHeatmapRepository(this._dio);

  Future<CourierHeatmapPayload> getOpportunities({
    double maxDistanceKm = 15,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.heatmapOpportunities,
        queryParameters: {'max_distance_km': maxDistanceKm},
      );

      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return CourierHeatmapPayload.empty();
      }

      return CourierHeatmapPayload.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [HeatmapRepo] getOpportunities: $e');
      throw Exception(ErrorHandler.getDeliveryErrorMessage(e));
    }
  }
}
