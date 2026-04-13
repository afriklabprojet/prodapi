import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../../addresses/domain/entities/address_entity.dart';

/// État surge pricing
class SurgeInfo {
  final bool active;
  final double multiplier;
  final String level;
  final double amount;

  const SurgeInfo({
    this.active = false,
    this.multiplier = 1.0,
    this.level = 'none',
    this.amount = 0,
  });

  factory SurgeInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SurgeInfo();
    return SurgeInfo(
      active: json['active'] as bool? ?? false,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      level: json['level'] as String? ?? 'none',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeliveryFeeState {
  final double? fee;
  final double? baseFee;
  final SurgeInfo surge;
  final bool isLoading;
  final String? error;

  const DeliveryFeeState({
    this.fee,
    this.baseFee,
    this.surge = const SurgeInfo(),
    this.isLoading = false,
    this.error,
  });

  DeliveryFeeState copyWith({
    double? fee,
    double? baseFee,
    SurgeInfo? surge,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearFee = false,
  }) {
    return DeliveryFeeState(
      fee: clearFee ? null : (fee ?? this.fee),
      baseFee: clearFee ? null : (baseFee ?? this.baseFee),
      surge: surge ?? this.surge,
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
      // L'API renvoie { delivery_fee: X, distance_km: Y, surge: {...}, ... } sans wrapper 'data'
      final raw = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final fee =
          (raw['delivery_fee'] as num?)?.toDouble() ??
          (raw['data']?['delivery_fee'] as num?)?.toDouble() ??
          0.0;
      final baseFee = (raw['base_delivery_fee'] as num?)?.toDouble() ?? fee;
      final surge = SurgeInfo.fromJson(raw['surge'] as Map<String, dynamic>?);
      final distanceKm = (raw['distance_km'] as num?)?.toDouble();
      AppLogger.debug(
        '[DeliveryFee] Estimated: $fee FCFA (base: $baseFee), distance: $distanceKm km, surge: ${surge.active ? surge.level : "none"}',
      );
      state = state.copyWith(
        fee: fee,
        baseFee: baseFee,
        surge: surge,
        isLoading: false,
      );
      _lastDistanceKm = distanceKm;
    } catch (e) {
      AppLogger.error('Failed to estimate delivery fee', error: e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const DeliveryFeeState();
  }
}
