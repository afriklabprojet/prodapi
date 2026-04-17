import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/order_entity.dart';

/// Réponse paginée des commandes (cursor-based)
class PaginatedOrdersResult {
  final List<OrderEntity> orders;

  /// Curseur pour la page suivante (null = pas de page suivante)
  final String? nextCursor;

  final int perPage;
  final int total;

  PaginatedOrdersResult({
    required this.orders,
    this.nextCursor,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => nextCursor != null;
}

/// Interface abstraite du repository des commandes.
abstract class OrderRepository {
  /// Récupère la liste des commandes paginée, optionnellement filtrée par statut.
  /// [cursor] - curseur pour charger la page suivante (null pour la première page)
  Future<Either<Failure, PaginatedOrdersResult>> getOrders({
    String? status,
    String? cursor,
    int perPage = 20,
  });

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

  /// Note le coursier d'une commande.
  Future<Either<Failure, void>> rateCourier(
    int orderId, {
    required int rating,
    String? comment,
    List<String>? tags,
  });
}
