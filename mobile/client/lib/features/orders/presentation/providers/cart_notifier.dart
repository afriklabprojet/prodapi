import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/pharmacy_model.dart';
import '../../../products/data/models/category_model.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/pricing_entity.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  final SharedPreferences sharedPreferences;
  static const String _cartKey = 'shopping_cart';
  static const int _cartVersion = 2; // Increment when cart schema changes

  CartNotifier(this.sharedPreferences) : super(const CartState.initial()) {
    _loadCart();
  }

  // Load cart from local storage
  Future<void> _loadCart() async {
    try {
      final cartString = sharedPreferences.getString(_cartKey);
      if (cartString != null) {
        final cartData = jsonDecode(cartString) as Map<String, dynamic>;

        // Check cart version — clear if outdated
        final version = cartData['version'] as int? ?? 1;
        if (version < _cartVersion) {
          await sharedPreferences.remove(_cartKey);
          state = const CartState.initial();
          return;
        }

        // Deserialize cart items
        final itemsJson = cartData['items'] as List<dynamic>?;
        if (itemsJson != null && itemsJson.isNotEmpty) {
          final items = itemsJson.map((itemJson) {
            final productJson = itemJson['product'] as Map<String, dynamic>;
            final quantity = itemJson['quantity'] as int;

            // Convert ProductModel to ProductEntity
            final productModel = ProductModel.fromJson(productJson);
            final product = productModel.toEntity();

            return CartItemEntity(product: product, quantity: quantity);
          }).toList();

          final pharmacyId = cartData['pharmacy_id'] as int?;

          state = CartState(
            status: CartStatus.loaded,
            items: items,
            selectedPharmacyId: pharmacyId,
          );
        } else {
          state = const CartState.initial();
        }
      }
    } catch (e) {
      // If deserialization fails, start with empty cart
      state = const CartState.initial();
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      // Serialize cart items
      final itemsJson = state.items.map((item) {
        // Convert ProductEntity to ProductModel for serialization
        final pharmacy = item.product.pharmacy;
        final pharmacyModel = PharmacyModel(
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          phone: pharmacy.phone,
          email: pharmacy.email,
          latitude: pharmacy.latitude,
          longitude: pharmacy.longitude,
          status: pharmacy.status,
          isOpen: pharmacy.isOpen,
        );

        final categoryModel = item.product.category != null
            ? CategoryModel(
                id: item.product.category!.id,
                name: item.product.category!.name,
                description: item.product.category!.description,
              )
            : null;

        final productModel = ProductModel(
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          imageUrl: item.product.imageUrl,
          stockQuantity: item.product.stockQuantity,
          manufacturer: item.product.manufacturer,
          requiresPrescription: item.product.requiresPrescription,
          pharmacy: pharmacyModel,
          category: categoryModel,
          createdAt: item.product.createdAt.toIso8601String(),
          updatedAt: item.product.updatedAt.toIso8601String(),
        );

        return {'product': productModel.toJson(), 'quantity': item.quantity};
      }).toList();

      final cartData = {
        'version': _cartVersion,
        'items': itemsJson,
        'pharmacy_id': state.selectedPharmacyId,
      };

      await sharedPreferences.setString(_cartKey, jsonEncode(cartData));
    } catch (e) {
      // Handle error silently
    }
  }

  // Add item to cart
  Future<void> addItem(ProductEntity product, {int quantity = 1}) async {
    if (quantity <= 0) return;

    // Check if product is available
    if (!product.isAvailable) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Ce produit n\'est plus disponible',
      );
      return;
    }

    // Check stock
    if (product.stockQuantity < quantity) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Stock insuffisant. Disponible: ${product.stockQuantity}',
      );
      return;
    }

    // Check if cart has items from different pharmacy
    if (state.isNotEmpty &&
        state.selectedPharmacyId != null &&
        state.selectedPharmacyId != product.pharmacy.id) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage:
            'Vous ne pouvez commander que dans une seule pharmacie à la fois. Videz le panier pour changer de pharmacie.',
      );
      return;
    }

    final existingItem = state.getItem(product.id);

    if (existingItem != null) {
      // Update quantity
      final newQuantity = existingItem.quantity + quantity;

      if (newQuantity > product.stockQuantity) {
        state = state.copyWith(
          status: CartStatus.error,
          errorMessage:
              'Stock insuffisant. Disponible: ${product.stockQuantity}',
        );
        return;
      }

      final updatedItems = state.items.map((item) {
        if (item.product.id == product.id) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();

      state = state.copyWith(
        status: CartStatus.loaded,
        items: updatedItems,
        errorMessage: null,
      );
    } else {
      // Add new item
      final newItem = CartItemEntity(product: product, quantity: quantity);
      final updatedItems = [...state.items, newItem];

      state = state.copyWith(
        status: CartStatus.loaded,
        items: updatedItems,
        selectedPharmacyId: product.pharmacy.id,
        errorMessage: null,
      );
    }

    await _saveCart();
  }

  // Remove item from cart
  Future<void> removeItem(int productId) async {
    final updatedItems = state.items
        .where((item) => item.product.id != productId)
        .toList();

    state = state.copyWith(
      status: CartStatus.loaded,
      items: updatedItems,
      clearPharmacyId: updatedItems.isEmpty,
      errorMessage: null,
    );

    await _saveCart();
  }

  // Update item quantity
  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    final item = state.getItem(productId);
    if (item == null) return;

    // Check stock
    if (quantity > item.product.stockQuantity) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage:
            'Stock insuffisant. Disponible: ${item.product.stockQuantity}',
      );
      return;
    }

    final updatedItems = state.items.map((cartItem) {
      if (cartItem.product.id == productId) {
        return cartItem.copyWith(quantity: quantity);
      }
      return cartItem;
    }).toList();

    state = state.copyWith(
      status: CartStatus.loaded,
      items: updatedItems,
      errorMessage: null,
    );

    await _saveCart();
  }

  // Clear cart
  Future<void> clearCart() async {
    state = const CartState.initial();
    await sharedPreferences.remove(_cartKey);
  }

  // Clear error
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        errorMessage: null,
        status: state.items.isEmpty ? CartStatus.initial : CartStatus.loaded,
      );
    }
  }

  /// Mettre à jour les frais de livraison calculés dynamiquement
  /// Appelé depuis le checkout quand l'adresse de livraison est sélectionnée
  void updateDeliveryFee({
    required double deliveryFee,
    double? distanceKm,
  }) {
    state = state.copyWith(
      calculatedDeliveryFee: deliveryFee,
      deliveryDistanceKm: distanceKm,
    );
  }

  /// Réinitialiser les frais de livraison (quand l'adresse change)
  void clearDeliveryFee() {
    state = state.copyWith(
      clearDeliveryFee: true,
    );
  }

  /// Mettre à jour la configuration de tarification
  /// Appelé au démarrage ou quand on ouvre le panier
  void updatePricingConfig(PricingConfigEntity config) {
    state = state.copyWith(pricingConfig: config);
  }

  /// Mettre à jour le mode de paiement sélectionné
  /// Affecte le calcul des frais de paiement
  void updatePaymentMode(String paymentMode) {
    state = state.copyWith(paymentMode: paymentMode);
  }
}
