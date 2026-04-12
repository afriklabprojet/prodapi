import '../errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../../features/products/domain/entities/product_entity.dart';
import '../../features/orders/domain/entities/cart_item_entity.dart';

/// ─────────────────────────────────────────────────────────
/// CartContract — Interface pour le service de panier
/// ─────────────────────────────────────────────────────────
///
/// Définit le contrat que tout service de panier doit implémenter.
/// Permet la substitution facile pour les tests ou différentes
/// implémentations (local, remote, hybrid).
abstract class CartContract {
  // ─────────────────────────────────────────────────────────
  // State & Streams
  // ─────────────────────────────────────────────────────────

  /// État actuel du panier
  CartData get currentCart;

  /// Stream des changements du panier (pour UI réactive)
  Stream<CartData> get cartStream;

  /// Statut de synchronisation
  Stream<CartSyncStatus> get syncStatusStream;

  // ─────────────────────────────────────────────────────────
  // Initialization & Lifecycle
  // ─────────────────────────────────────────────────────────

  /// Initialiser le service et restaurer le panier local
  Future<Either<Failure, CartData>> init();

  /// Libérer les ressources
  void dispose();

  // ─────────────────────────────────────────────────────────
  // Cart Operations
  // ─────────────────────────────────────────────────────────

  /// Ajouter un produit au panier
  Future<Either<Failure, CartData>> addItem(
    ProductEntity product, {
    int quantity = 1,
  });

  /// Supprimer un produit du panier
  Future<Either<Failure, CartData>> removeItem(int productId);

  /// Mettre à jour la quantité d'un produit
  Future<Either<Failure, CartData>> updateQuantity(
    int productId,
    int quantity,
  );

  /// Vider le panier
  Future<Either<Failure, CartData>> clearCart();

  // ─────────────────────────────────────────────────────────
  // Sync Operations (Backend)
  // ─────────────────────────────────────────────────────────

  /// Synchroniser le panier avec le serveur
  Future<Either<Failure, CartData>> syncWithServer();

  /// Fusionner le panier local avec le panier serveur
  /// Appelé après login quand l'utilisateur avait un panier local
  Future<Either<Failure, CartData>> mergeWithServerCart({
    required ConflictResolutionStrategy strategy,
  });

  /// Forcer le panier serveur (écrase le local)
  Future<Either<Failure, CartData>> forceServerCart();

  /// Forcer le panier local vers le serveur
  Future<Either<Failure, CartData>> pushLocalToServer();
}

/// ─────────────────────────────────────────────────────────
/// CartData — Données du panier
/// ─────────────────────────────────────────────────────────
class CartData {
  final List<CartItemEntity> items;
  final int? pharmacyId;
  final String? pharmacyName;
  final DateTime lastModified;
  final CartSource source;
  final int schemaVersion;

  const CartData({
    required this.items,
    this.pharmacyId,
    this.pharmacyName,
    required this.lastModified,
    required this.source,
    this.schemaVersion = 1,
  });

  /// Factory pour un panier vide
  factory CartData.empty() => CartData(
        items: const [],
        pharmacyId: null,
        pharmacyName: null,
        lastModified: DateTime.now(),
        source: CartSource.local,
        schemaVersion: 1,
      );

  // Computed properties
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => items.length;
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool get hasPrescriptionRequired =>
      items.any((item) => item.product.requiresPrescription);

  List<CartItemEntity> get prescriptionItems =>
      items.where((item) => item.product.requiresPrescription).toList();

  CartItemEntity? getItem(int productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  bool containsProduct(int productId) =>
      items.any((item) => item.product.id == productId);

  CartData copyWith({
    List<CartItemEntity>? items,
    int? pharmacyId,
    String? pharmacyName,
    DateTime? lastModified,
    CartSource? source,
    int? schemaVersion,
    bool clearPharmacy = false,
  }) {
    return CartData(
      items: items ?? this.items,
      pharmacyId: clearPharmacy ? null : (pharmacyId ?? this.pharmacyId),
      pharmacyName: clearPharmacy ? null : (pharmacyName ?? this.pharmacyName),
      lastModified: lastModified ?? this.lastModified,
      source: source ?? this.source,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
        'pharmacy_id': pharmacyId,
        'pharmacy_name': pharmacyName,
        'last_modified': lastModified.toIso8601String(),
        'source': source.name,
        'schema_version': schemaVersion,
      };

  @override
  String toString() =>
      'CartData(items: ${items.length}, pharmacy: $pharmacyId, source: $source)';
}

/// Source du panier
enum CartSource {
  /// Panier stocké localement
  local,

  /// Panier récupéré du serveur
  server,

  /// Panier fusionné (local + serveur)
  merged,
}

/// Stratégie de résolution des conflits
enum ConflictResolutionStrategy {
  /// Prendre les quantités les plus élevées
  takeHigherQuantity,

  /// Prendre les quantités du serveur
  preferServer,

  /// Prendre les quantités locales
  preferLocal,

  /// Additionner les quantités
  sumQuantities,

  /// Prendre le plus récent (par timestamp)
  takeNewest,
}

/// Statut de synchronisation
enum CartSyncStatus {
  /// En attente de synchronisation
  idle,

  /// Synchronisation en cours
  syncing,

  /// Synchronisé avec le serveur
  synced,

  /// Erreur de synchronisation
  error,

  /// Mode hors ligne (modifications en attente)
  offline,
}

/// Opération en attente de sync
class PendingCartOperation {
  final CartOperationType type;
  final int? productId;
  final int? quantity;
  final DateTime createdAt;
  final int retryCount;

  const PendingCartOperation({
    required this.type,
    this.productId,
    this.quantity,
    required this.createdAt,
    this.retryCount = 0,
  });

  PendingCartOperation incrementRetry() => PendingCartOperation(
        type: type,
        productId: productId,
        quantity: quantity,
        createdAt: createdAt,
        retryCount: retryCount + 1,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'product_id': productId,
        'quantity': quantity,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory PendingCartOperation.fromJson(Map<String, dynamic> json) {
    return PendingCartOperation(
      type: CartOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CartOperationType.add,
      ),
      productId: json['product_id'] as int?,
      quantity: json['quantity'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }
}

/// Types d'opérations sur le panier
enum CartOperationType {
  add,
  remove,
  updateQuantity,
  clear,
}
