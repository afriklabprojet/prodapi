import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../../../core/errors/failures.dart';

/// Représente une alternative de prix d'un produit dans une autre pharmacie
class PriceAlternative {
  final int id;
  final String name;
  final double price;
  final double? originalPrice;
  final bool hasPromo;
  final int stock;
  final int pharmacyId;
  final String pharmacyName;
  final String? pharmacyAddress;

  const PriceAlternative({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.hasPromo,
    required this.stock,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyAddress,
  });

  // Méthode sécurisée pour parser les doubles
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Méthode sécurisée pour parser les entiers
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory PriceAlternative.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacy'] as Map<String, dynamic>? ?? {};
    return PriceAlternative(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      originalPrice: json['original_price'] != null 
          ? _parseDouble(json['original_price'])
          : null,
      hasPromo: json['has_promo'] == true || json['has_promo'] == 'true',
      stock: _parseInt(json['stock']),
      pharmacyId: _parseInt(pharmacy['id']),
      pharmacyName: pharmacy['name']?.toString() ?? 'Pharmacie',
      pharmacyAddress: pharmacy['address']?.toString(),
    );
  }
}

/// État de la comparaison de prix
class PriceComparisonState {
  final bool isLoading;
  final List<PriceAlternative> alternatives;
  final String? error;
  final double? currentPrice;

  const PriceComparisonState({
    this.isLoading = false,
    this.alternatives = const [],
    this.error,
    this.currentPrice,
  });

  bool get hasAlternatives => alternatives.isNotEmpty;
  
  /// Trouve le meilleur prix parmi les alternatives
  PriceAlternative? get bestPrice {
    if (alternatives.isEmpty) return null;
    return alternatives.reduce((a, b) => a.price < b.price ? a : b);
  }
  
  /// Économie potentielle par rapport au prix actuel
  double? get potentialSavings {
    if (currentPrice == null || bestPrice == null) return null;
    final savings = currentPrice! - bestPrice!.price;
    return savings > 0 ? savings : null;
  }

  PriceComparisonState copyWith({
    bool? isLoading,
    List<PriceAlternative>? alternatives,
    String? error,
    double? currentPrice,
  }) {
    return PriceComparisonState(
      isLoading: isLoading ?? this.isLoading,
      alternatives: alternatives ?? this.alternatives,
      error: error,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}

class PriceComparisonNotifier extends StateNotifier<PriceComparisonState> {
  final Ref _ref;

  PriceComparisonNotifier(this._ref) : super(const PriceComparisonState());

  Future<void> comparePrices(int productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/products/$productId/compare-prices');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        final alternativesJson = data['alternatives'] as List<dynamic>? ?? [];

        final alternatives = alternativesJson
            .map((json) => PriceAlternative.fromJson(json as Map<String, dynamic>))
            .toList();

        state = PriceComparisonState(
          isLoading: false,
          alternatives: alternatives,
          currentPrice: current != null 
              ? PriceAlternative._parseDouble(current['price']) 
              : null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de comparer les prix',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e.message : 'Erreur de connexion',
      );
    }
  }

  void reset() {
    state = const PriceComparisonState();
  }
}

/// Provider familial pour comparer les prix par produit
final priceComparisonProvider = StateNotifierProvider.family<
    PriceComparisonNotifier, PriceComparisonState, int>((ref, productId) {
  final notifier = PriceComparisonNotifier(ref);
  // Auto-fetch on creation
  notifier.comparePrices(productId);
  return notifier;
});
