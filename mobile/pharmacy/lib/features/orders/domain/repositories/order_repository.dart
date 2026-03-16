import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order_entity.dart';

/// Interface abstraite du repository des commandes.
abstract class OrderRepository {
  /// Récupère la liste des commandes, optionnellement filtrée par statut.
  Future<Either<Failure, List<OrderEntity>>> getOrders({String? status});
  
  /// Récupère les détails d'une commande par son ID.
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId);
  
  /// Confirme une commande.
  Future<Either<Failure, void>> confirmOrder(int orderId);
  
  /// Marque une commande comme prête.
  Future<Either<Failure, void>> markOrderReady(int orderId);
  
  /// Marque une commande comme livrée.
  Future<Either<Failure, void>> markOrderDelivered(int orderId);
  
  /// Rejette une commande avec une raison optionnelle.
  Future<Either<Failure, void>> rejectOrder(int orderId, {String? reason});
  
  /// Ajoute des notes pharmacien à une commande.
  Future<Either<Failure, void>> addNotes(int orderId, String notes);
}
