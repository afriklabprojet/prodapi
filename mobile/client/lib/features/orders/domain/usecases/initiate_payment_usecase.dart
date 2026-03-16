import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class InitiatePaymentUseCase {
  final OrdersRepository repository;

  InitiatePaymentUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required int orderId,
    required String provider,
    String? paymentMethod,
  }) async {
    // Validation
    if (orderId <= 0) {
      return Left(
        ValidationFailure(
          message: 'Invalid order ID',
          errors: {
            'orderId': ['Invalid order ID'],
          },
        ),
      );
    }

    if (provider.trim().isEmpty) {
      return Left(
        ValidationFailure(
          message: 'Payment provider is required',
          errors: {
            'provider': ['Payment provider is required'],
          },
        ),
      );
    }

    // Supported providers: jeko only
    final supportedProviders = ['jeko'];
    if (!supportedProviders.contains(provider.toLowerCase())) {
      return Left(
        ValidationFailure(
          message:
              'Unsupported payment provider. Supported: ${supportedProviders.join(", ")}',
          errors: {
            'provider': ['Unsupported payment provider'],
          },
        ),
      );
    }

    return await repository.initiatePayment(
      orderId: orderId,
      provider: provider,
      paymentMethod: paymentMethod,
    );
  }
}
