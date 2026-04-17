import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase {
  final OrdersRepository repository;
  GetOrdersUseCase(this.repository);

  Future<Either<Failure, List<OrderEntity>>> call({String? status, int page = 1}) {
    return repository.getOrders(status: status, page: page);
  }
}
