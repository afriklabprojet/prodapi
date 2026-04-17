import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/pricing_entity.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  final CartLocalDataSource _cartLocalDataSource;

  CartNotifier(this._cartLocalDataSource) : super(const CartState.initial()) {
    _loadCart();
  }

  // Load cart from local storage
  Future<void> _loadCart() async {
    try {
      final (:items, :pharmacyId) = await _cartLocalDataSource.loadCart();
      if (items.isNotEmpty) {
        state = CartState(
          status: CartStatus.loaded,
          items: items,
          selectedPharmacyId: pharmacyId,
        );
      } else {
        state = const CartState.initial();
      }
    } catch (_) {
      state = const CartState.initial();
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    await _cartLocalDataSource.saveCart(
      state.items,
      pharmacyId: state.selectedPharmacyId,
    );
  }

  // Add item to cart
  Future<bool> addItem(ProductEntity product, {int quantity = 1}) async {
    if (quantity <= 0) return false;

    // Check if product is available
    if (!product.isAvailable) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Ce produit n\'est plus disponible',
      );
      return false;
    }

    // Check stock
    if (product.stockQuantity < quantity) {
      state = state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Stock insuffisant. Disponible: ${product.stockQuantity}',
      );
      return false;
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
      return false;
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
        return false;
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
    return true;
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
    await _cartLocalDataSource.clearCart();
  }

  // Clear error
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        clearError: true,
        status: state.items.isEmpty ? CartStatus.initial : CartStatus.loaded,
      );
    }
  }

  /// Mettre à jour les frais de livraison calculés dynamiquement
  /// Appelé depuis le checkout quand l'adresse de livraison est sélectionnée
  void updateDeliveryFee({required double deliveryFee, double? distanceKm}) {
    state = state.copyWith(
      calculatedDeliveryFee: deliveryFee,
      deliveryDistanceKm: distanceKm,
    );
  }

  /// Réinitialiser les frais de livraison (quand l'adresse change)
  void clearDeliveryFee() {
    state = state.copyWith(clearDeliveryFee: true);
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
