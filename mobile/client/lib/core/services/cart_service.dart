import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../contracts/cart_contract.dart';
import '../errors/failures.dart';
import '../errors/cart_failures.dart';
import '../constants/storage_keys.dart';
import '../services/app_logger.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/products/data/models/pharmacy_model.dart';
import '../../features/products/data/models/category_model.dart';
import '../../features/orders/domain/entities/cart_item_entity.dart';

/// ─────────────────────────────────────────────────────────
/// CartService — Production-Ready Shopping Cart
/// ─────────────────────────────────────────────────────────
///
/// Features:
/// - Add / remove / update products with validation
/// - Local persistence with SharedPreferences
/// - Auto-restore on app launch
/// - Ready for backend sync (conflict resolution)
/// - Operation queue for offline support
/// - Debouncing for performance
/// - Comprehensive error handling
///
/// Architecture:
/// ```
/// ┌─────────────────────────────────────────────────────┐
/// │                    CartService                       │
/// ├─────────────────────────────────────────────────────┤
/// │  ┌─────────────┐  ┌──────────────┐  ┌───────────┐  │
/// │  │  Local      │  │  Operation   │  │  Sync     │  │
/// │  │  Storage    │◄─┤  Queue       │◄─┤  Manager  │  │
/// │  └─────────────┘  └──────────────┘  └───────────┘  │
/// │         │                │                 │        │
/// │         ▼                ▼                 ▼        │
/// │  ┌─────────────────────────────────────────────┐   │
/// │  │              Cart State Stream               │   │
/// │  └─────────────────────────────────────────────┘   │
/// └─────────────────────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// final cartService = ref.watch(cartServiceProvider);
///
/// // Listen to cart changes
/// cartService.cartStream.listen((cartData) {
///   updateUI(cartData);
/// });
///
/// // Add item
/// final result = await cartService.addItem(product, quantity: 2);
/// result.fold(
///   (failure) => showError(failure.message),
///   (cart) => showSuccess('Ajouté au panier'),
/// );
/// ```
class CartService implements CartContract {
  final SharedPreferences _prefs;
  
  /// Remote data source for backend sync (optional)
  /// Inject when online sync is enabled
  final Future<Either<Failure, CartData>> Function()? _fetchServerCart;
  final Future<Either<Failure, void>> Function(CartData cart)? _pushToServer;

  /// Configuration
  final int maxCartItems;
  final Duration cartExpirationDuration;
  final Duration debounceDuration;
  final int maxRetries;

  // ─────────────────────────────────────────────────────────
  // Internal State
  // ─────────────────────────────────────────────────────────

  /// Current cart state
  late CartData _currentCart;

  /// Stream controllers
  final _cartController = StreamController<CartData>.broadcast();
  final _syncStatusController = StreamController<CartSyncStatus>.broadcast();

  /// Pending operations queue (for offline support)
  final List<PendingCartOperation> _pendingOperations = [];

  /// Sync status
  CartSyncStatus _syncStatus = CartSyncStatus.idle;

  /// Debounce timer for save operations
  Timer? _saveDebounceTimer;

  /// Lock to prevent concurrent operations
  bool _operationInProgress = false;
  
  /// Completer for waiting on current operation
  Completer<void>? _operationCompleter;

  /// Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Schema version for migration
  static const int _schemaVersion = 3;

  // ─────────────────────────────────────────────────────────
  // Storage Keys
  // ─────────────────────────────────────────────────────────

  static const String _cartKey = StorageKeys.cart;
  static const String _pendingOpsKey = 'cart_pending_operations';
  static const String _lastSyncKey = 'cart_last_sync';

  CartService({
    required SharedPreferences prefs,
    Future<Either<Failure, CartData>> Function()? fetchServerCart,
    Future<Either<Failure, void>> Function(CartData cart)? pushToServer,
    this.maxCartItems = 50,
    this.cartExpirationDuration = const Duration(days: 7),
    this.debounceDuration = const Duration(milliseconds: 500),
    this.maxRetries = 3,
  })  : _prefs = prefs,
        _fetchServerCart = fetchServerCart,
        _pushToServer = pushToServer {
    _currentCart = CartData.empty();
  }

  // ─────────────────────────────────────────────────────────
  // Getters (CartContract)
  // ─────────────────────────────────────────────────────────

  @override
  CartData get currentCart => _currentCart;

  @override
  Stream<CartData> get cartStream => _cartController.stream;

  @override
  Stream<CartSyncStatus> get syncStatusStream => _syncStatusController.stream;

  // ─────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CartData>> init() async {
    try {
      AppLogger.info('🛒 CartService initializing...');

      // 1. Restore local cart
      final restoreResult = await _restoreLocalCart();
      if (restoreResult.isLeft()) {
        // Start fresh if restore fails
        _currentCart = CartData(
          items: [],
          lastModified: DateTime.now(),
          source: CartSource.local,
          schemaVersion: _schemaVersion,
        );
      }

      // 2. Restore pending operations
      await _restorePendingOperations();

      // 3. Check cart expiration
      if (_isCartExpired()) {
        AppLogger.warning('🛒 Cart expired, clearing...');
        await _clearLocalCart();
      }

      // 4. Setup connectivity listener for auto-sync
      _setupConnectivityListener();

      // 5. Emit initial state
      _emitCartState();

      AppLogger.info(
          '🛒 CartService initialized with ${_currentCart.items.length} items');

      return Right(_currentCart);
    } catch (e, stack) {
      AppLogger.error('🛒 CartService init failed', error: e, stackTrace: stack);
      return const Left(CartRestoreFailure());
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _cartController.close();
    _syncStatusController.close();
    AppLogger.info('🛒 CartService disposed');
  }

  // ─────────────────────────────────────────────────────────
  // Operation Lock Helpers
  // ─────────────────────────────────────────────────────────

  /// Acquire lock for cart operation (prevents race conditions)
  Future<bool> _acquireLock() async {
    // Wait for any pending operation to complete
    if (_operationInProgress && _operationCompleter != null) {
      try {
        await _operationCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            AppLogger.warning('🛒 Operation lock timeout, forcing release');
            _releaseLock();
          },
        );
      } catch (_) {
        // Continue anyway after timeout
      }
    }

    if (_operationInProgress) {
      return false; // Still locked after wait
    }

    _operationInProgress = true;
    _operationCompleter = Completer<void>();
    return true;
  }

  /// Release lock after cart operation
  void _releaseLock() {
    _operationInProgress = false;
    if (_operationCompleter != null && !_operationCompleter!.isCompleted) {
      _operationCompleter!.complete();
    }
    _operationCompleter = null;
  }

  /// Save immediately without debounce (for critical operations)
  Future<void> _saveImmediate() async {
    _saveDebounceTimer?.cancel();
    await _saveLocalCart();
  }

  // ─────────────────────────────────────────────────────────
  // Cart Operations
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CartData>> addItem(
    ProductEntity product, {
    int quantity = 1,
  }) async {
    // Acquire lock to prevent race conditions
    if (!await _acquireLock()) {
      return const Left(OperationInProgressFailure());
    }

    try {
      // Validation
      if (quantity <= 0) {
        return Left(InvalidQuantityFailure(quantity: quantity));
      }

      // Check product availability
    if (!product.isAvailable) {
      return Left(ProductUnavailableFailure(
        productId: product.id,
        productName: product.name,
      ));
    }

    // Check stock
    final existingItem = _currentCart.getItem(product.id);
    final totalQuantity = (existingItem?.quantity ?? 0) + quantity;

    if (totalQuantity > product.stockQuantity) {
      return Left(InsufficientStockFailure(
        productId: product.id,
        requestedQuantity: totalQuantity,
        availableStock: product.stockQuantity,
      ));
    }

    // Check pharmacy constraint (single pharmacy per cart)
    if (_currentCart.isNotEmpty &&
        _currentCart.pharmacyId != null &&
        _currentCart.pharmacyId != product.pharmacy.id) {
      return Left(DifferentPharmacyFailure(
        currentPharmacyId: _currentCart.pharmacyId!,
        currentPharmacyName: _currentCart.pharmacyName ?? 'Pharmacie actuelle',
        newPharmacyId: product.pharmacy.id,
        newPharmacyName: product.pharmacy.name,
      ));
    }

    // Check cart limit
    if (_currentCart.uniqueItemCount >= maxCartItems &&
        existingItem == null) {
      return Left(CartLimitReachedFailure(
        maxItems: maxCartItems,
        currentItems: _currentCart.uniqueItemCount,
      ));
    }

    // Perform operation
    List<CartItemEntity> updatedItems;

    if (existingItem != null) {
      // Update existing item
      updatedItems = _currentCart.items.map((item) {
        if (item.product.id == product.id) {
          return item.copyWith(quantity: totalQuantity);
        }
        return item;
      }).toList();

      AppLogger.info(
          '🛒 Updated ${product.name} quantity to $totalQuantity');
    } else {
      // Add new item
      final newItem = CartItemEntity(product: product, quantity: quantity);
      updatedItems = [..._currentCart.items, newItem];

      AppLogger.info('🛒 Added ${product.name} x$quantity to cart');
    }

    // Update state
    _currentCart = _currentCart.copyWith(
      items: updatedItems,
      pharmacyId: product.pharmacy.id,
      pharmacyName: product.pharmacy.name,
      lastModified: DateTime.now(),
      source: CartSource.local,
    );

    // Queue operation for sync
    _queueOperation(PendingCartOperation(
      type: existingItem != null
          ? CartOperationType.updateQuantity
          : CartOperationType.add,
      productId: product.id,
      quantity: totalQuantity,
      createdAt: DateTime.now(),
    ));

    // Save and emit (immediate for add operations to prevent data loss)
    await _saveImmediate();
    _emitCartState();

    return Right(_currentCart);
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<Either<Failure, CartData>> removeItem(int productId) async {
    // Acquire lock to prevent race conditions
    if (!await _acquireLock()) {
      return const Left(OperationInProgressFailure());
    }

    try {
      final existingItem = _currentCart.getItem(productId);

      if (existingItem == null) {
        return Left(ItemNotFoundFailure(productId: productId));
      }

    // Perform operation
    final updatedItems = _currentCart.items
        .where((item) => item.product.id != productId)
        .toList();

    final shouldClearPharmacy = updatedItems.isEmpty;

    _currentCart = _currentCart.copyWith(
      items: updatedItems,
      lastModified: DateTime.now(),
      source: CartSource.local,
      clearPharmacy: shouldClearPharmacy,
    );

    AppLogger.info('🛒 Removed ${existingItem.product.name} from cart');

    // Queue operation for sync
    _queueOperation(PendingCartOperation(
      type: CartOperationType.remove,
      productId: productId,
      createdAt: DateTime.now(),
    ));

    // Save and emit (immediate for remove operations)
    await _saveImmediate();
    _emitCartState();

    return Right(_currentCart);
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<Either<Failure, CartData>> updateQuantity(
    int productId,
    int quantity,
  ) async {
    // Remove if quantity is 0 or less
    if (quantity <= 0) {
      return removeItem(productId);
    }

    // Acquire lock to prevent race conditions
    if (!await _acquireLock()) {
      return const Left(OperationInProgressFailure());
    }

    try {
      final existingItem = _currentCart.getItem(productId);

    if (existingItem == null) {
      return Left(ItemNotFoundFailure(productId: productId));
    }

    // Check stock
    if (quantity > existingItem.product.stockQuantity) {
      return Left(InsufficientStockFailure(
        productId: productId,
        requestedQuantity: quantity,
        availableStock: existingItem.product.stockQuantity,
      ));
    }

    // Perform operation
    final updatedItems = _currentCart.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    _currentCart = _currentCart.copyWith(
      items: updatedItems,
      lastModified: DateTime.now(),
      source: CartSource.local,
    );

    AppLogger.info(
        '🛒 Updated ${existingItem.product.name} quantity to $quantity');

    // Queue operation for sync
    _queueOperation(PendingCartOperation(
      type: CartOperationType.updateQuantity,
      productId: productId,
      quantity: quantity,
      createdAt: DateTime.now(),
    ));

    // Save with debounce (quantity updates are frequent, debounce is ok)
    _debouncedSave();
    _emitCartState();

    return Right(_currentCart);
    } finally {
      _releaseLock();
    }
  }

  @override
  Future<Either<Failure, CartData>> clearCart() async {
    _currentCart = CartData(
      items: [],
      lastModified: DateTime.now(),
      source: CartSource.local,
      schemaVersion: _schemaVersion,
    );

    AppLogger.info('🛒 Cart cleared');

    // Queue operation for sync
    _queueOperation(PendingCartOperation(
      type: CartOperationType.clear,
      createdAt: DateTime.now(),
    ));

    // Clear pending operations (no point syncing old ops after clear)
    _pendingOperations.clear();
    await _prefs.remove(_pendingOpsKey);

    // Save immediately (no debounce for clear)
    await _saveLocalCart();
    _emitCartState();

    return Right(_currentCart);
  }

  // ─────────────────────────────────────────────────────────
  // Sync Operations
  // ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CartData>> syncWithServer() async {
    if (_fetchServerCart == null || _pushToServer == null) {
      AppLogger.warning('🛒 Sync not configured, skipping');
      return Right(_currentCart);
    }

    if (_operationInProgress) {
      return const Left(OperationInProgressFailure());
    }

    _operationInProgress = true;
    _updateSyncStatus(CartSyncStatus.syncing);

    try {
      // 1. Push pending operations to server
      if (_pendingOperations.isNotEmpty) {
        final pushResult = await _pushToServer(_currentCart);
        if (pushResult.isLeft()) {
          _updateSyncStatus(CartSyncStatus.error);
          _operationInProgress = false;
          return Left(CartSyncFailure(reason: 'Échec de l\'envoi au serveur'));
        }

        // Clear pending operations on success
        _pendingOperations.clear();
        await _prefs.remove(_pendingOpsKey);
      }

      // 2. Fetch server cart (to detect conflicts)
      final serverResult = await _fetchServerCart();
      
      return serverResult.fold(
        (failure) {
          _updateSyncStatus(CartSyncStatus.error);
          _operationInProgress = false;
          return Left(failure);
        },
        (serverCart) async {
          // No conflicts, we're in sync
          await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
          _updateSyncStatus(CartSyncStatus.synced);
          _operationInProgress = false;
          return Right(_currentCart);
        },
      );
    } catch (e, stack) {
      AppLogger.error('🛒 Sync failed', error: e, stackTrace: stack);
      _updateSyncStatus(CartSyncStatus.error);
      _operationInProgress = false;
      return Left(CartSyncFailure(reason: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartData>> mergeWithServerCart({
    required ConflictResolutionStrategy strategy,
  }) async {
    if (_fetchServerCart == null) {
      return Right(_currentCart);
    }

    _updateSyncStatus(CartSyncStatus.syncing);

    try {
      final serverResult = await _fetchServerCart();

      return serverResult.fold(
        (failure) {
          _updateSyncStatus(CartSyncStatus.error);
          return Left(failure);
        },
        (serverCart) async {
          final mergedCart = _mergeCartData(
            local: _currentCart,
            server: serverCart,
            strategy: strategy,
          );

          _currentCart = mergedCart.copyWith(
            source: CartSource.merged,
            lastModified: DateTime.now(),
          );

          await _saveLocalCart();
          _emitCartState();
          _updateSyncStatus(CartSyncStatus.synced);

          // Push merged cart to server
          if (_pushToServer != null) {
            await _pushToServer(_currentCart);
          }

          AppLogger.info('🛒 Cart merged using strategy: ${strategy.name}');
          return Right(_currentCart);
        },
      );
    } catch (e, stack) {
      AppLogger.error('🛒 Merge failed', error: e, stackTrace: stack);
      _updateSyncStatus(CartSyncStatus.error);
      return Left(CartSyncFailure(reason: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartData>> forceServerCart() async {
    if (_fetchServerCart == null) {
      return Right(_currentCart);
    }

    _updateSyncStatus(CartSyncStatus.syncing);

    try {
      final serverResult = await _fetchServerCart();

      return serverResult.fold(
        (failure) {
          _updateSyncStatus(CartSyncStatus.error);
          return Left(failure);
        },
        (serverCart) async {
          _currentCart = serverCart.copyWith(
            source: CartSource.server,
            lastModified: DateTime.now(),
          );

          // Clear pending operations
          _pendingOperations.clear();
          await _prefs.remove(_pendingOpsKey);

          await _saveLocalCart();
          _emitCartState();
          _updateSyncStatus(CartSyncStatus.synced);

          AppLogger.info('🛒 Forced server cart');
          return Right(_currentCart);
        },
      );
    } catch (e, stack) {
      AppLogger.error('🛒 Force server cart failed', error: e, stackTrace: stack);
      _updateSyncStatus(CartSyncStatus.error);
      return Left(CartSyncFailure(reason: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartData>> pushLocalToServer() async {
    if (_pushToServer == null) {
      return Right(_currentCart);
    }

    _updateSyncStatus(CartSyncStatus.syncing);

    try {
      final result = await _pushToServer(_currentCart);

      return result.fold(
        (failure) {
          _updateSyncStatus(CartSyncStatus.error);
          return Left(failure);
        },
        (_) {
          // Clear pending operations
          _pendingOperations.clear();
          _prefs.remove(_pendingOpsKey);

          _updateSyncStatus(CartSyncStatus.synced);
          AppLogger.info('🛒 Pushed local cart to server');
          return Right(_currentCart);
        },
      );
    } catch (e, stack) {
      AppLogger.error('🛒 Push to server failed', error: e, stackTrace: stack);
      _updateSyncStatus(CartSyncStatus.error);
      return Left(CartSyncFailure(reason: e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods - Persistence
  // ─────────────────────────────────────────────────────────

  Future<Either<Failure, void>> _restoreLocalCart() async {
    try {
      final cartJson = _prefs.getString(_cartKey);
      if (cartJson == null) {
        _currentCart = CartData(
          items: [],
          lastModified: DateTime.now(),
          source: CartSource.local,
          schemaVersion: _schemaVersion,
        );
        return const Right(null);
      }

      final cartData = jsonDecode(cartJson) as Map<String, dynamic>;

      // Check schema version
      final version = cartData['version'] as int? ?? 1;
      if (version < _schemaVersion) {
        AppLogger.warning('🛒 Cart schema outdated, migrating...');
        await _migrateCartSchema(version, cartData);
      }

      // Deserialize items
      final itemsJson = cartData['items'] as List<dynamic>?;
      final items = <CartItemEntity>[];

      if (itemsJson != null) {
        for (final itemJson in itemsJson) {
          try {
            final productJson = itemJson['product'] as Map<String, dynamic>;
            final quantity = itemJson['quantity'] as int;

            final productModel = ProductModel.fromJson(productJson);
            final product = productModel.toEntity();

            items.add(CartItemEntity(product: product, quantity: quantity));
          } catch (e) {
            AppLogger.warning('🛒 Failed to deserialize cart item: $e');
            // Continue with other items
          }
        }
      }

      _currentCart = CartData(
        items: items,
        pharmacyId: cartData['pharmacy_id'] as int?,
        pharmacyName: cartData['pharmacy_name'] as String?,
        lastModified: cartData['last_modified'] != null
            ? DateTime.parse(cartData['last_modified'] as String)
            : DateTime.now(),
        source: CartSource.local,
        schemaVersion: _schemaVersion,
      );

      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('🛒 Failed to restore cart', error: e, stackTrace: stack);
      return const Left(CartRestoreFailure());
    }
  }

  Future<void> _saveLocalCart() async {
    try {
      final itemsJson = _currentCart.items.map((item) {
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
        'version': _schemaVersion,
        'items': itemsJson,
        'pharmacy_id': _currentCart.pharmacyId,
        'pharmacy_name': _currentCart.pharmacyName,
        'last_modified': _currentCart.lastModified.toIso8601String(),
      };

      await _prefs.setString(_cartKey, jsonEncode(cartData));
      AppLogger.debug('🛒 Cart saved locally');
    } catch (e, stack) {
      AppLogger.error('🛒 Failed to save cart', error: e, stackTrace: stack);
    }
  }

  Future<void> _clearLocalCart() async {
    await _prefs.remove(_cartKey);
    _currentCart = CartData(
      items: [],
      lastModified: DateTime.now(),
      source: CartSource.local,
      schemaVersion: _schemaVersion,
    );
    _emitCartState();
  }

  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(debounceDuration, () {
      _saveLocalCart();
    });
  }

  bool _isCartExpired() {
    if (_currentCart.isEmpty) return false;

    // Use a valid DateTime for comparison when lastModified is null
    final lastModified = _currentCart.lastModified;
    final age = DateTime.now().difference(lastModified);
    return age > cartExpirationDuration;
  }

  Future<void> _migrateCartSchema(
      int oldVersion, Map<String, dynamic> oldData) async {
    // Implement migration logic for different schema versions
    // For now, just clear the cart
    AppLogger.warning(
        '🛒 Migrating from schema v$oldVersion to v$_schemaVersion');
    await _prefs.remove(_cartKey);
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods - Operations Queue
  // ─────────────────────────────────────────────────────────

  void _queueOperation(PendingCartOperation operation) {
    // Optimize queue by removing redundant operations
    _pendingOperations.removeWhere((op) {
      // Remove previous ops for same product
      if (op.productId == operation.productId) {
        return true;
      }
      // Remove all ops if this is a clear
      if (operation.type == CartOperationType.clear) {
        return true;
      }
      return false;
    });

    _pendingOperations.add(operation);
    _savePendingOperations();
    _updateSyncStatus(CartSyncStatus.offline);
  }

  Future<void> _savePendingOperations() async {
    try {
      final opsJson = _pendingOperations.map((op) => op.toJson()).toList();
      await _prefs.setString(_pendingOpsKey, jsonEncode(opsJson));
    } catch (e) {
      AppLogger.warning('🛒 Failed to save pending operations: $e');
    }
  }

  Future<void> _restorePendingOperations() async {
    try {
      final opsJson = _prefs.getString(_pendingOpsKey);
      if (opsJson == null) return;

      final opsList = jsonDecode(opsJson) as List<dynamic>;
      _pendingOperations.clear();
      _pendingOperations.addAll(
        opsList.map((json) =>
            PendingCartOperation.fromJson(json as Map<String, dynamic>)),
      );

      if (_pendingOperations.isNotEmpty) {
        _updateSyncStatus(CartSyncStatus.offline);
      }
    } catch (e) {
      AppLogger.warning('🛒 Failed to restore pending operations: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods - Merge
  // ─────────────────────────────────────────────────────────

  CartData _mergeCartData({
    required CartData local,
    required CartData server,
    required ConflictResolutionStrategy strategy,
  }) {
    if (local.isEmpty) return server;
    if (server.isEmpty) return local;

    // Collect all unique product IDs
    final allProductIds = <int>{
      ...local.items.map((i) => i.product.id),
      ...server.items.map((i) => i.product.id),
    };

    final mergedItems = <CartItemEntity>[];

    for (final productId in allProductIds) {
      final localItem = local.getItem(productId);
      final serverItem = server.getItem(productId);

      CartItemEntity? resolvedItem;

      switch (strategy) {
        case ConflictResolutionStrategy.takeHigherQuantity:
          if (localItem != null && serverItem != null) {
            resolvedItem = localItem.quantity >= serverItem.quantity
                ? localItem
                : serverItem;
          } else {
            resolvedItem = localItem ?? serverItem;
          }
          break;

        case ConflictResolutionStrategy.preferServer:
          resolvedItem = serverItem ?? localItem;
          break;

        case ConflictResolutionStrategy.preferLocal:
          resolvedItem = localItem ?? serverItem;
          break;

        case ConflictResolutionStrategy.sumQuantities:
          if (localItem != null && serverItem != null) {
            final sumQty = localItem.quantity + serverItem.quantity;
            final maxStock = localItem.product.stockQuantity;
            resolvedItem = localItem.copyWith(
              quantity: sumQty > maxStock ? maxStock : sumQty,
            );
          } else {
            resolvedItem = localItem ?? serverItem;
          }
          break;

        case ConflictResolutionStrategy.takeNewest:
          resolvedItem = local.lastModified.isAfter(server.lastModified)
              ? localItem ?? serverItem
              : serverItem ?? localItem;
          break;
      }

      if (resolvedItem != null) {
        mergedItems.add(resolvedItem);
      }
    }

    return CartData(
      items: mergedItems,
      pharmacyId: local.pharmacyId ?? server.pharmacyId,
      pharmacyName: local.pharmacyName ?? server.pharmacyName,
      lastModified: DateTime.now(),
      source: CartSource.merged,
      schemaVersion: _schemaVersion,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods - Connectivity
  // ─────────────────────────────────────────────────────────

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection && _pendingOperations.isNotEmpty) {
        AppLogger.info('🛒 Connection restored, syncing...');
        syncWithServer();
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods - State
  // ─────────────────────────────────────────────────────────

  void _emitCartState() {
    if (!_cartController.isClosed) {
      _cartController.add(_currentCart);
    }
  }

  void _updateSyncStatus(CartSyncStatus status) {
    _syncStatus = status;
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Convenience Methods
  // ─────────────────────────────────────────────────────────

  /// Increment quantity by 1
  Future<Either<Failure, CartData>> incrementQuantity(int productId) async {
    final item = _currentCart.getItem(productId);
    if (item == null) {
      return Left(ItemNotFoundFailure(productId: productId));
    }
    return updateQuantity(productId, item.quantity + 1);
  }

  /// Decrement quantity by 1 (removes if quantity becomes 0)
  Future<Either<Failure, CartData>> decrementQuantity(int productId) async {
    final item = _currentCart.getItem(productId);
    if (item == null) {
      return Left(ItemNotFoundFailure(productId: productId));
    }
    return updateQuantity(productId, item.quantity - 1);
  }

  /// Check if product is in cart
  bool containsProduct(int productId) =>
      _currentCart.containsProduct(productId);

  /// Get quantity for a product (0 if not in cart)
  int getQuantity(int productId) =>
      _currentCart.getItem(productId)?.quantity ?? 0;

  /// Check if cart has pending changes to sync
  bool get hasPendingChanges => _pendingOperations.isNotEmpty;

  /// Get current sync status
  CartSyncStatus get syncStatus => _syncStatus;

  /// Validate all items in cart (check stock, availability)
  Future<List<CartValidationIssue>> validateCart() async {
    final issues = <CartValidationIssue>[];

    for (final item in _currentCart.items) {
      if (!item.product.isAvailable) {
        issues.add(CartValidationIssue(
          productId: item.product.id,
          productName: item.product.name,
          type: CartValidationIssueType.unavailable,
          message: '${item.product.name} n\'est plus disponible',
        ));
      } else if (item.quantity > item.product.stockQuantity) {
        issues.add(CartValidationIssue(
          productId: item.product.id,
          productName: item.product.name,
          type: CartValidationIssueType.insufficientStock,
          message:
              'Stock insuffisant pour ${item.product.name} (max: ${item.product.stockQuantity})',
          suggestedQuantity: item.product.stockQuantity,
        ));
      }
    }

    return issues;
  }

  /// Auto-fix cart issues (adjust quantities, remove unavailable)
  Future<Either<Failure, CartData>> autoFixCart() async {
    final issues = await validateCart();
    if (issues.isEmpty) return Right(_currentCart);

    for (final issue in issues) {
      switch (issue.type) {
        case CartValidationIssueType.unavailable:
          await removeItem(issue.productId);
          break;
        case CartValidationIssueType.insufficientStock:
          if (issue.suggestedQuantity != null && issue.suggestedQuantity! > 0) {
            await updateQuantity(issue.productId, issue.suggestedQuantity!);
          } else {
            await removeItem(issue.productId);
          }
          break;
        case CartValidationIssueType.priceChanged:
          // Price changes don't require auto-fix
          break;
      }
    }

    AppLogger.info('🛒 Auto-fixed ${issues.length} cart issues');
    return Right(_currentCart);
  }
}

/// Issue found during cart validation
class CartValidationIssue {
  final int productId;
  final String productName;
  final CartValidationIssueType type;
  final String message;
  final int? suggestedQuantity;

  const CartValidationIssue({
    required this.productId,
    required this.productName,
    required this.type,
    required this.message,
    this.suggestedQuantity,
  });
}

/// Types of cart validation issues
enum CartValidationIssueType {
  unavailable,
  insufficientStock,
  priceChanged,
}
