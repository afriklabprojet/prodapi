import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/providers/orders_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/products_repository_impl.dart';

/// État pour les produits fréquemment achetés
class FrequentProductsState {
  final List<FrequentProduct> products;
  final bool isLoading;
  final String? error;

  const FrequentProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  FrequentProductsState copyWith({
    List<FrequentProduct>? products,
    bool? isLoading,
    String? error,
  }) {
    return FrequentProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Un produit fréquemment acheté avec son nombre d'achats
class FrequentProduct {
  final ProductEntity product;
  final int purchaseCount;
  final DateTime lastPurchasedAt;

  const FrequentProduct({
    required this.product,
    required this.purchaseCount,
    required this.lastPurchasedAt,
  });
}

/// Provider pour les produits fréquemment achetés (basé sur l'historique des commandes)
final frequentProductsProvider =
    StateNotifierProvider<FrequentProductsNotifier, FrequentProductsState>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final repository = ref.watch(productsRepositoryProvider);
  return FrequentProductsNotifier(ordersState, repository as ProductsRepositoryImpl);
});

/// Provider pour les top 6 produits habituels (pour la home page)
final topFrequentProductsProvider = Provider<List<FrequentProduct>>((ref) {
  final state = ref.watch(frequentProductsProvider);
  return state.products.take(6).toList();
});

/// Provider pour vérifier si l'utilisateur a des produits habituels
final hasFrequentProductsProvider = Provider<bool>((ref) {
  final state = ref.watch(frequentProductsProvider);
  return state.products.isNotEmpty;
});

class FrequentProductsNotifier extends StateNotifier<FrequentProductsState> {
  final OrdersState _ordersState;
  final ProductsRepositoryImpl _repository;

  FrequentProductsNotifier(this._ordersState, this._repository)
      : super(const FrequentProductsState()) {
    _analyzeOrderHistory();
  }

  /// Analyse l'historique des commandes pour extraire les produits fréquemment achetés
  Future<void> _analyzeOrderHistory() async {
    if (_ordersState.orders.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Comptabiliser les achats par produit
      final productPurchases = <int, _ProductPurchaseData>{};

      for (final order in _ordersState.orders) {
        // Ne considérer que les commandes livrées ou confirmées
        if (order.status != OrderStatus.delivered && order.status != OrderStatus.confirmed) {
          continue;
        }

        for (final item in order.items) {
          // Skip items without productId
          final pid = item.productId;
          if (pid == null) continue;
          
          final existing = productPurchases[pid];
          if (existing != null) {
            productPurchases[pid] = _ProductPurchaseData(
              productId: pid,
              name: item.name,
              count: existing.count + item.quantity,
              lastPurchased: order.createdAt.isAfter(existing.lastPurchased)
                  ? order.createdAt
                  : existing.lastPurchased,
            );
          } else {
            productPurchases[pid] = _ProductPurchaseData(
              productId: pid,
              name: item.name,
              count: item.quantity,
              lastPurchased: order.createdAt,
            );
          }
        }
      }

      // Trier par nombre d'achats (décroissant), puis par date (plus récent d'abord)
      final sortedPurchases = productPurchases.values.toList()
        ..sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) return countCompare;
          return b.lastPurchased.compareTo(a.lastPurchased);
        });

      // Charger les détails des produits les plus achetés (top 10)
      final frequentProducts = <FrequentProduct>[];
      for (final purchase in sortedPurchases.take(10)) {
        final result = await _repository.getProductDetails(purchase.productId);
        result.fold(
          (failure) {
            // Si le produit n'existe plus, on l'ignore
          },
          (product) {
            frequentProducts.add(FrequentProduct(
              product: product,
              purchaseCount: purchase.count,
              lastPurchasedAt: purchase.lastPurchased,
            ));
          },
        );
      }

      state = FrequentProductsState(
        products: frequentProducts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'analyse de l\'historique',
      );
    }
  }

  /// Force le rechargement des produits fréquents
  Future<void> refresh() async {
    await _analyzeOrderHistory();
  }
}

class _ProductPurchaseData {
  final int productId;
  final String name;
  final int count;
  final DateTime lastPurchased;

  _ProductPurchaseData({
    required this.productId,
    required this.name,
    required this.count,
    required this.lastPurchased,
  });
}
