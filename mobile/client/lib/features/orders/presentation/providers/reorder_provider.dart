import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../domain/entities/order_entity.dart';
import 'cart_provider.dart';

/// État du processus de reorder
enum ReorderStatus { idle, loading, success, partialSuccess, error }

class ReorderState {
  final ReorderStatus status;
  final String? message;
  final int addedCount;
  final int totalCount;
  final List<String> failedProducts;

  const ReorderState({
    this.status = ReorderStatus.idle,
    this.message,
    this.addedCount = 0,
    this.totalCount = 0,
    this.failedProducts = const [],
  });

  ReorderState copyWith({
    ReorderStatus? status,
    String? message,
    int? addedCount,
    int? totalCount,
    List<String>? failedProducts,
  }) {
    return ReorderState(
      status: status ?? this.status,
      message: message ?? this.message,
      addedCount: addedCount ?? this.addedCount,
      totalCount: totalCount ?? this.totalCount,
      failedProducts: failedProducts ?? this.failedProducts,
    );
  }
}

class ReorderNotifier extends StateNotifier<ReorderState> {
  final Ref _ref;

  ReorderNotifier(this._ref) : super(const ReorderState());

  /// Recommande une commande précédente en ajoutant tous ses articles au panier
  Future<bool> reorder(OrderEntity order) async {
    if (order.items.isEmpty) {
      state = const ReorderState(
        status: ReorderStatus.error,
        message: 'Aucun article dans cette commande',
      );
      return false;
    }

    state = ReorderState(
      status: ReorderStatus.loading,
      totalCount: order.items.length,
    );

    final productsNotifier = _ref.read(productsProvider.notifier);
    final cartNotifier = _ref.read(cartProvider.notifier);
    
    int addedCount = 0;
    List<String> failedProducts = [];

    for (final item in order.items) {
      if (item.productId == null) {
        failedProducts.add(item.name);
        continue;
      }

      try {
        // Charger les détails du produit
        await productsNotifier.loadProductDetails(item.productId!);
        final product = _ref.read(productsProvider).selectedProduct;

        if (product == null) {
          failedProducts.add(item.name);
          continue;
        }

        // Vérifier la disponibilité
        if (!product.isAvailable) {
          failedProducts.add('${item.name} (indisponible)');
          continue;
        }

        // Ajouter au panier
        await cartNotifier.addItem(product, quantity: item.quantity);
        addedCount++;
      } catch (_) {
        failedProducts.add(item.name);
      }
    }

    if (addedCount == 0) {
      state = ReorderState(
        status: ReorderStatus.error,
        message: 'Impossible d\'ajouter les articles au panier',
        addedCount: 0,
        totalCount: order.items.length,
        failedProducts: failedProducts,
      );
      return false;
    }

    if (failedProducts.isNotEmpty) {
      state = ReorderState(
        status: ReorderStatus.partialSuccess,
        message: '$addedCount article${addedCount > 1 ? 's' : ''} ajouté${addedCount > 1 ? 's' : ''} au panier',
        addedCount: addedCount,
        totalCount: order.items.length,
        failedProducts: failedProducts,
      );
      return true;
    }

    state = ReorderState(
      status: ReorderStatus.success,
      message: '$addedCount article${addedCount > 1 ? 's' : ''} ajouté${addedCount > 1 ? 's' : ''} au panier',
      addedCount: addedCount,
      totalCount: order.items.length,
    );
    return true;
  }

  void reset() {
    state = const ReorderState();
  }
}

final reorderProvider = StateNotifierProvider<ReorderNotifier, ReorderState>((ref) {
  return ReorderNotifier(ref);
});
