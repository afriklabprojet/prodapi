import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/pharmacy_model.dart';
import '../../../products/data/models/category_model.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

// ─── Abstract contract ────────────────────────────────────────────────────────

abstract class CartLocalDataSource {
  /// Persist [items] (and the associated pharmacy id) to local storage.
  Future<void> saveCart(List<CartItemEntity> items, {int? pharmacyId});

  /// Restore cart items from local storage.
  /// Returns an empty list when nothing was previously saved.
  Future<({List<CartItemEntity> items, int? pharmacyId})> loadCart();

  /// Wipe the persisted cart.
  Future<void> clearCart();
}

// ─── Implementation ───────────────────────────────────────────────────────────

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences _prefs;

  static const String _cartKey = 'shopping_cart';

  /// Increment this when the persisted schema changes so stale caches are
  /// automatically discarded on first load.
  static const int _cartVersion = 2;

  CartLocalDataSourceImpl({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // ── Public API ──────────────────────────────────────────────────────────────

  @override
  Future<({List<CartItemEntity> items, int? pharmacyId})> loadCart() async {
    try {
      final raw = _prefs.getString(_cartKey);
      if (raw == null) return (items: <CartItemEntity>[], pharmacyId: null);

      final cartData = jsonDecode(raw) as Map<String, dynamic>;

      // Discard caches from older schema versions
      final version = cartData['version'] as int? ?? 1;
      if (version < _cartVersion) {
        await _prefs.remove(_cartKey);
        return (items: <CartItemEntity>[], pharmacyId: null);
      }

      final itemsJson = cartData['items'] as List<dynamic>?;
      if (itemsJson == null || itemsJson.isEmpty) {
        return (items: <CartItemEntity>[], pharmacyId: null);
      }

      final items = itemsJson
          .map((e) => _itemFromJson(e as Map<String, dynamic>))
          .toList();

      final pharmacyId = cartData['pharmacy_id'] as int?;
      return (items: items, pharmacyId: pharmacyId);
    } catch (_) {
      return (items: <CartItemEntity>[], pharmacyId: null);
    }
  }

  @override
  Future<void> saveCart(List<CartItemEntity> items, {int? pharmacyId}) async {
    try {
      final cartData = <String, dynamic>{
        'version': _cartVersion,
        'items': items.map(_itemToJson).toList(),
        'pharmacy_id': pharmacyId,
      };
      await _prefs.setString(_cartKey, jsonEncode(cartData));
    } catch (_) {
      // Persist failures are non-fatal — the in-memory state remains valid.
    }
  }

  @override
  Future<void> clearCart() => _prefs.remove(_cartKey);

  // ── Private helpers ─────────────────────────────────────────────────────────

  CartItemEntity _itemFromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>;
    final quantity = json['quantity'] as int;
    final product = ProductModel.fromJson(productJson).toEntity();
    return CartItemEntity(product: product, quantity: quantity);
  }

  Map<String, dynamic> _itemToJson(CartItemEntity item) {
    final product = item.product;
    return {
      'product': _productToJson(product),
      'quantity': item.quantity,
    };
  }

  Map<String, dynamic> _productToJson(ProductEntity product) {
    final pharmacy = product.pharmacy;
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

    final categoryModel = product.category != null
        ? CategoryModel(
            id: product.category!.id,
            name: product.category!.name,
            description: product.category!.description,
          )
        : null;

    final productModel = ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
      stockQuantity: product.stockQuantity,
      manufacturer: product.manufacturer,
      requiresPrescription: product.requiresPrescription,
      pharmacy: pharmacyModel,
      category: categoryModel,
      createdAt: product.createdAt.toIso8601String(),
      updatedAt: product.updatedAt.toIso8601String(),
    );

    return productModel.toJson();
  }
}
