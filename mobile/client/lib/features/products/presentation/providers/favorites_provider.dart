import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pharmacy_entity.dart';
import '../../../../core/services/app_logger.dart';

/// Clé de stockage pour les favoris
const _favoritesKey = 'favorite_products';
const _favoriteDetailsKey = 'favorite_product_details';

/// État des favoris
class FavoritesState {
  final Set<int> favoriteIds;
  final List<ProductEntity> favoriteProducts;
  final bool isLoading;

  const FavoritesState({
    this.favoriteIds = const {},
    this.favoriteProducts = const [],
    this.isLoading = false,
  });

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  FavoritesState copyWith({
    Set<int>? favoriteIds,
    List<ProductEntity>? favoriteProducts,
    bool? isLoading,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier pour gérer les favoris
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger les IDs
      final idsJson = prefs.getString(_favoritesKey);
      Set<int> ids = {};
      if (idsJson != null) {
        final List<dynamic> idsList = jsonDecode(idsJson);
        ids = idsList.map((e) => e as int).toSet();
      }
      
      // Charger les détails des produits
      final detailsJson = prefs.getString(_favoriteDetailsKey);
      List<ProductEntity> products = [];
      if (detailsJson != null) {
        final List<dynamic> detailsList = jsonDecode(detailsJson);
        products = detailsList
            .map((e) => _productFromJson(e as Map<String, dynamic>))
            .whereType<ProductEntity>()
            .toList();
      }
      
      state = FavoritesState(
        favoriteIds: ids,
        favoriteProducts: products,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load favorites', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleFavorite(ProductEntity product) async {
    final newIds = Set<int>.from(state.favoriteIds);
    List<ProductEntity> newProducts = List.from(state.favoriteProducts);
    
    if (newIds.contains(product.id)) {
      // Retirer des favoris
      newIds.remove(product.id);
      newProducts.removeWhere((p) => p.id == product.id);
    } else {
      // Ajouter aux favoris
      newIds.add(product.id);
      newProducts.insert(0, product);
    }
    
    state = state.copyWith(
      favoriteIds: newIds,
      favoriteProducts: newProducts,
    );
    
    await _saveFavorites();
  }

  Future<void> addFavorite(ProductEntity product) async {
    if (state.favoriteIds.contains(product.id)) return;
    
    final newIds = Set<int>.from(state.favoriteIds)..add(product.id);
    final newProducts = [product, ...state.favoriteProducts];
    
    state = state.copyWith(
      favoriteIds: newIds,
      favoriteProducts: newProducts,
    );
    
    await _saveFavorites();
  }

  Future<void> removeFavorite(int productId) async {
    if (!state.favoriteIds.contains(productId)) return;
    
    final newIds = Set<int>.from(state.favoriteIds)..remove(productId);
    final newProducts = state.favoriteProducts.where((p) => p.id != productId).toList();
    
    state = state.copyWith(
      favoriteIds: newIds,
      favoriteProducts: newProducts,
    );
    
    await _saveFavorites();
  }

  /// Supprime tous les favoris
  Future<void> clearAll() async {
    state = state.copyWith(
      favoriteIds: <int>{},
      favoriteProducts: <ProductEntity>[],
    );
    await _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les IDs
      await prefs.setString(_favoritesKey, jsonEncode(state.favoriteIds.toList()));
      
      // Sauvegarder les détails (max 20 produits pour limiter la taille)
      final productsToSave = state.favoriteProducts.take(20).toList();
      final detailsJson = productsToSave.map((p) => _productToJson(p)).toList();
      await prefs.setString(_favoriteDetailsKey, jsonEncode(detailsJson));
    } catch (e) {
      AppLogger.error('Failed to save favorites', error: e);
    }
  }

  Map<String, dynamic> _productToJson(ProductEntity p) {
    return {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'price': p.price,
      'imageUrl': p.imageUrl,
      'stockQuantity': p.stockQuantity,
      'manufacturer': p.manufacturer,
      'requiresPrescription': p.requiresPrescription,
      'pharmacyId': p.pharmacy.id,
      'pharmacyName': p.pharmacy.name,
    };
  }

  ProductEntity? _productFromJson(Map<String, dynamic> json) {
    try {
      return ProductEntity(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        stockQuantity: json['stockQuantity'] as int? ?? 0,
        manufacturer: json['manufacturer'] as String?,
        requiresPrescription: json['requiresPrescription'] as bool? ?? false,
        pharmacy: _minimalPharmacy(json),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to parse favorite product', error: e);
      return null;
    }
  }

  PharmacyEntity _minimalPharmacy(Map<String, dynamic> json) {
    return PharmacyEntity(
      id: json['pharmacyId'] as int? ?? 0,
      name: json['pharmacyName'] as String? ?? 'Pharmacie',
      address: '',
      phone: '',
      status: 'open',
      isOpen: true,
    );
  }
}

/// Provider global pour les favoris
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(),
);

/// Provider pour vérifier si un produit est favori
final isFavoriteProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(favoritesProvider).isFavorite(productId);
});
