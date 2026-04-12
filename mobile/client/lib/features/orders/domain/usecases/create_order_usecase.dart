import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../entities/order_item_entity.dart';
import '../entities/delivery_address_entity.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  final OrdersRepository repository;
  CreateOrderUseCase(this.repository);

  Future<Either<Failure, OrderEntity>> call({
    required int pharmacyId,
    required List<OrderItemEntity> items,
    required DeliveryAddressEntity deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId,
    String? promoCode,
  }) {
    return repository.createOrder(
      pharmacyId: pharmacyId,
      items: items,
      deliveryAddress: deliveryAddress,
      paymentMode: paymentMode,
      prescriptionImage: prescriptionImage,
      customerNotes: customerNotes,
      prescriptionId: prescriptionId,
      promoCode: promoCode,
    );
  }
}
