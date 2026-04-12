import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/pricing_model.dart';
import '../../domain/entities/pricing_entity.dart';

class PricingRepositoryImpl {
  final ApiClient apiClient;

  PricingRepositoryImpl({required this.apiClient});

  Future<Either<Failure, PricingConfigEntity>> getPricing() async {
    try {
      final response = await apiClient.get('/pricing');
      final data = response.data['data'] as Map<String, dynamic>;
      final model = PricingConfigModel.fromJson(data);
      return Right(model.toEntity());
    } catch (_) {
      return Right(PricingConfigModel.defaults().toEntity());
    }
  }

  Future<Either<Failure, PricingCalculationEntity>> calculateFees({
    required int subtotal,
    required int deliveryFee,
    required String paymentMode,
    int? serviceFeeAmount,
  }) async {
    try {
      final response = await apiClient.post(
        '/pricing/calculate',
        data: {
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'payment_mode': paymentMode,
          if (serviceFeeAmount != null) 'service_fee': serviceFeeAmount,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(
        PricingCalculationEntity(
          subtotal: (data['subtotal'] as num).toInt(),
          deliveryFee: (data['delivery_fee'] as num).toInt(),
          serviceFee: (data['service_fee'] as num).toInt(),
          paymentFee: (data['payment_fee'] as num).toInt(),
          totalAmount: (data['total_amount'] as num).toInt(),
          pharmacyAmount: (data['pharmacy_amount'] as num).toInt(),
        ),
      );
    } on DioException {
      return const Left(
        ServerFailure(message: 'Erreur lors du calcul des frais'),
      );
    } catch (_) {
      return const Left(
        ServerFailure(message: 'Erreur lors du calcul des frais'),
      );
    }
  }

  Future<Either<Failure, int>> estimateDeliveryFee({
    required double distanceKm,
    String? pharmacyId,
  }) async {
    try {
      final response = await apiClient.post(
        '/pricing/delivery',
        data: {
          'distance_km': distanceKm,
          if (pharmacyId != null) 'pharmacy_id': pharmacyId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final fee = (data['delivery_fee'] as num?)?.toInt() ?? 300;
      return Right(fee);
    } catch (_) {
      return const Right(300);
    }
  }
}
