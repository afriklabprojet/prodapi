import 'failures.dart';

/// ─────────────────────────────────────────────────────────
/// Cart Failures — Erreurs spécifiques au panier
/// ─────────────────────────────────────────────────────────
///
/// Hiérarchie d'erreurs permettant une gestion fine
/// des différents cas d'échec du panier.

/// Produit non disponible (stock épuisé)
class ProductUnavailableFailure extends Failure {
  final int productId;
  final String productName;

  const ProductUnavailableFailure({
    required this.productId,
    required this.productName,
  }) : super(message: '$productName n\'est plus disponible');

  @override
  List<Object?> get props => [message, productId, productName];
}

/// Stock insuffisant pour la quantité demandée
class InsufficientStockFailure extends Failure {
  final int productId;
  final int requestedQuantity;
  final int availableStock;

  const InsufficientStockFailure({
    required this.productId,
    required this.requestedQuantity,
    required this.availableStock,
  }) : super(
            message:
                'Stock insuffisant. Demandé: $requestedQuantity, Disponible: $availableStock');

  @override
  List<Object?> get props =>
      [message, productId, requestedQuantity, availableStock];
}

/// Tentative d'ajouter un produit d'une autre pharmacie
class DifferentPharmacyFailure extends Failure {
  final int currentPharmacyId;
  final String currentPharmacyName;
  final int newPharmacyId;
  final String newPharmacyName;

  const DifferentPharmacyFailure({
    required this.currentPharmacyId,
    required this.currentPharmacyName,
    required this.newPharmacyId,
    required this.newPharmacyName,
  }) : super(
            message:
                'Vous ne pouvez commander que dans une seule pharmacie à la fois. '
                'Panier actuel: $currentPharmacyName. Videz le panier pour changer.');

  @override
  List<Object?> get props => [
        message,
        currentPharmacyId,
        currentPharmacyName,
        newPharmacyId,
        newPharmacyName
      ];
}

/// Produit non trouvé dans le panier
class ItemNotFoundFailure extends Failure {
  final int productId;

  const ItemNotFoundFailure({required this.productId})
      : super(message: 'Produit non trouvé dans le panier');

  @override
  List<Object?> get props => [message, productId];
}

/// Quantité invalide (négative ou zéro)
class InvalidQuantityFailure extends Failure {
  final int quantity;

  const InvalidQuantityFailure({required this.quantity})
      : super(message: 'Quantité invalide: $quantity');

  @override
  List<Object?> get props => [message, quantity];
}

/// Échec de persistance locale
class CartPersistenceFailure extends Failure {
  final String operation;

  const CartPersistenceFailure({required this.operation})
      : super(message: 'Erreur de sauvegarde du panier: $operation');

  @override
  List<Object?> get props => [message, operation];
}

/// Échec de restauration du panier
class CartRestoreFailure extends Failure {
  const CartRestoreFailure()
      : super(message: 'Impossible de restaurer le panier');
}

/// Échec de synchronisation avec le serveur
class CartSyncFailure extends Failure {
  final String? reason;

  const CartSyncFailure({this.reason})
      : super(message: reason ?? 'Erreur de synchronisation du panier');

  @override
  List<Object?> get props => [message, reason];
}

/// Conflit entre panier local et serveur
class CartConflictFailure extends Failure {
  final int localItemCount;
  final int serverItemCount;

  const CartConflictFailure({
    required this.localItemCount,
    required this.serverItemCount,
  }) : super(
            message:
                'Conflit de panier détecté. Local: $localItemCount items, Serveur: $serverItemCount items');

  @override
  List<Object?> get props => [message, localItemCount, serverItemCount];
}

/// Limite du panier atteinte
class CartLimitReachedFailure extends Failure {
  final int maxItems;
  final int currentItems;

  const CartLimitReachedFailure({
    required this.maxItems,
    required this.currentItems,
  }) : super(message: 'Limite du panier atteinte ($maxItems articles maximum)');

  @override
  List<Object?> get props => [message, maxItems, currentItems];
}

/// Panier expiré (trop ancien)
class CartExpiredFailure extends Failure {
  final Duration age;

  const CartExpiredFailure({required this.age})
      : super(
            message:
                'Votre panier a expiré. Les prix peuvent avoir changé.');

  @override
  List<Object?> get props => [message, age];
}

/// Produit retiré du catalogue
class ProductDiscontinuedFailure extends Failure {
  final int productId;
  final String productName;

  const ProductDiscontinuedFailure({
    required this.productId,
    required this.productName,
  }) : super(message: '$productName a été retiré du catalogue');

  @override
  List<Object?> get props => [message, productId, productName];
}

/// Prix du produit a changé
class PriceChangedFailure extends Failure {
  final int productId;
  final double oldPrice;
  final double newPrice;

  PriceChangedFailure({
    required this.productId,
    required this.oldPrice,
    required this.newPrice,
  }) : super(
            message:
                'Le prix a changé de ${oldPrice.toStringAsFixed(0)} FCFA à ${newPrice.toStringAsFixed(0)} FCFA');

  @override
  List<Object?> get props => [message, productId, oldPrice, newPrice];
}

/// Pharmacie fermée
class PharmacyClosedFailure extends Failure {
  final int pharmacyId;
  final String pharmacyName;

  const PharmacyClosedFailure({
    required this.pharmacyId,
    required this.pharmacyName,
  }) : super(message: '$pharmacyName est actuellement fermée');

  @override
  List<Object?> get props => [message, pharmacyId, pharmacyName];
}

/// Opération en cours (debounce)
class OperationInProgressFailure extends Failure {
  const OperationInProgressFailure()
      : super(message: 'Une opération est déjà en cours');
}
