import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/inventory/domain/entities/product_entity.dart';
import '../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../features/orders/domain/entities/order_entity.dart';
import '../../../features/orders/presentation/providers/order_list_provider.dart';
import '../../../features/prescriptions/data/models/prescription_model.dart';
import '../../../features/prescriptions/presentation/providers/prescription_provider.dart'
    show prescriptionListProvider;

/// Type de résultat de recherche globale
enum GlobalSearchResultType { product, order, prescription }

/// Un résultat de recherche globale avec type et données
class GlobalSearchResult {
  final GlobalSearchResultType type;
  final dynamic data;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int id;

  const GlobalSearchResult({
    required this.type,
    required this.data,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.id,
  });

  /// Crée un résultat à partir d'un produit
  factory GlobalSearchResult.fromProduct(ProductEntity product) {
    return GlobalSearchResult(
      type: GlobalSearchResultType.product,
      data: product,
      title: product.name,
      subtitle:
          '${product.stockQuantity} en stock • ${product.price.toStringAsFixed(0)} FCFA',
      imageUrl: product.imageUrl,
      id: product.id,
    );
  }

  /// Crée un résultat à partir d'une commande
  factory GlobalSearchResult.fromOrder(OrderEntity order) {
    return GlobalSearchResult(
      type: GlobalSearchResultType.order,
      data: order,
      title: 'Commande ${order.reference}',
      subtitle: '${order.customerName} • ${order.status.displayLabel}',
      id: order.id,
    );
  }

  /// Crée un résultat à partir d'une ordonnance
  factory GlobalSearchResult.fromPrescription(PrescriptionModel prescription) {
    final customerName =
        prescription.customer?['name'] as String? ??
        'Client #${prescription.customerId}';
    return GlobalSearchResult(
      type: GlobalSearchResultType.prescription,
      data: prescription,
      title: 'Ordonnance #${prescription.id}',
      subtitle: '$customerName • ${prescription.status}',
      imageUrl: prescription.images?.isNotEmpty == true
          ? prescription.images!.first
          : null,
      id: prescription.id,
    );
  }
}

/// État de la recherche globale
class GlobalSearchState {
  final String query;
  final bool isSearching;
  final List<GlobalSearchResult> results;
  final String? error;

  const GlobalSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.error,
  });

  GlobalSearchState copyWith({
    String? query,
    bool? isSearching,
    List<GlobalSearchResult>? results,
    String? error,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      error: error,
    );
  }

  /// Résultats filtrés par type
  List<GlobalSearchResult> get products =>
      results.where((r) => r.type == GlobalSearchResultType.product).toList();

  List<GlobalSearchResult> get orders =>
      results.where((r) => r.type == GlobalSearchResultType.order).toList();

  List<GlobalSearchResult> get prescriptions => results
      .where((r) => r.type == GlobalSearchResultType.prescription)
      .toList();
}

/// Provider de recherche globale
class GlobalSearchNotifier extends AutoDisposeNotifier<GlobalSearchState> {
  @override
  GlobalSearchState build() {
    return const GlobalSearchState();
  }

  /// Lance une recherche globale
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const GlobalSearchState();
      return;
    }

    state = state.copyWith(query: query, isSearching: true, error: null);

    try {
      final results = <GlobalSearchResult>[];
      final queryLower = query.toLowerCase();

      // Recherche dans l'inventaire
      final inventoryState = ref.read(inventoryProvider);
      for (final product in inventoryState.products) {
        if (_matchesProduct(product, queryLower)) {
          results.add(GlobalSearchResult.fromProduct(product));
        }
      }

      // Recherche dans les commandes
      final orderState = ref.read(orderListProvider);
      for (final order in orderState.orders) {
        if (_matchesOrder(order, queryLower)) {
          results.add(GlobalSearchResult.fromOrder(order));
        }
      }

      // Recherche dans les ordonnances
      final prescriptionState = ref.read(prescriptionListProvider);
      for (final prescription in prescriptionState.prescriptions) {
        if (_matchesPrescription(prescription, queryLower)) {
          results.add(GlobalSearchResult.fromPrescription(prescription));
        }
      }

      // Trier par pertinence (titre commence par query en premier)
      results.sort((a, b) {
        final aStartsWith = a.title.toLowerCase().startsWith(queryLower);
        final bStartsWith = b.title.toLowerCase().startsWith(queryLower);
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        return a.title.compareTo(b.title);
      });

      state = state.copyWith(isSearching: false, results: results);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: 'Erreur de recherche: $e',
      );
    }
  }

  bool _matchesProduct(ProductEntity product, String query) {
    return product.name.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query) ||
        (product.barcode?.toLowerCase().contains(query) ?? false) ||
        (product.activeIngredient?.toLowerCase().contains(query) ?? false) ||
        (product.brand?.toLowerCase().contains(query) ?? false) ||
        product.category.toLowerCase().contains(query);
  }

  bool _matchesOrder(OrderEntity order, String query) {
    return order.reference.toLowerCase().contains(query) ||
        order.customerName.toLowerCase().contains(query) ||
        order.customerPhone.contains(query);
  }

  bool _matchesPrescription(PrescriptionModel prescription, String query) {
    final customerName = prescription.customer?['name'] as String? ?? '';
    final customerPhone = prescription.customer?['phone'] as String? ?? '';
    return prescription.id.toString().contains(query) ||
        customerName.toLowerCase().contains(query) ||
        customerPhone.contains(query) ||
        (prescription.ocrRawText?.toLowerCase().contains(query) ?? false);
  }

  /// Efface la recherche
  void clear() {
    state = const GlobalSearchState();
  }
}

final globalSearchProvider =
    AutoDisposeNotifierProvider<GlobalSearchNotifier, GlobalSearchState>(
      GlobalSearchNotifier.new,
    );
