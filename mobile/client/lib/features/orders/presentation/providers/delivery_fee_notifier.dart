import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../../addresses/domain/entities/address_entity.dart';

class DeliveryFeeState {
  final double? fee;
  final bool isLoading;
  final String? error;

  const DeliveryFeeState({this.fee, this.isLoading = false, this.error});

  DeliveryFeeState copyWith({
    double? fee,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearFee = false,
  }) {
    return DeliveryFeeState(
      fee: clearFee ? null : (fee ?? this.fee),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DeliveryFeeNotifier extends StateNotifier<DeliveryFeeState> {
  final ApiClient apiClient;

  double? _lastDistanceKm;
  double? get lastDistanceKm => _lastDistanceKm;

  DeliveryFeeNotifier({required this.apiClient})
      : super(const DeliveryFeeState());

  Future<void> estimateDeliveryFee({required AddressEntity address}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await apiClient.post(
        ApiConstants.deliveryEstimate,
        data: {
          'latitude': address.latitude,
          'longitude': address.longitude,
          'address': address.address,
          if (address.city != null) 'city': address.city,
        },
      );
      // L'API renvoie { delivery_fee: X, distance_km: Y, ... } sans wrapper 'data'
      final raw = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
      final fee = (raw['delivery_fee'] as num?)?.toDouble()
          ?? (raw['data']?['delivery_fee'] as num?)?.toDouble()
          ?? 0.0;
      final distanceKm = (raw['distance_km'] as num?)?.toDouble();
      AppLogger.debug('[DeliveryFee] Estimated: $fee FCFA, distance: $distanceKm km');
      state = state.copyWith(fee: fee, isLoading: false);
      _lastDistanceKm = distanceKm;
    } catch (e) {
      AppLogger.error('Failed to estimate delivery fee', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const DeliveryFeeState();
  }
}
