// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/offline_queue_service.dart';
import '../../../../config/providers.dart';
import '../../../addresses/domain/entities/address_entity.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prescriptions/presentation/providers/prescriptions_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_prescription_provider.dart';
import '../providers/delivery_fee_provider.dart';
import '../providers/pricing_provider.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/delivery_address_entity.dart';
import '../pages/payment_webview_page.dart';
import '../providers/orders_state.dart';
import '../providers/orders_provider.dart';
import '../providers/promo_code_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/payment_state.dart';
import '../widgets/widgets.dart';
import '../../../../core/router/app_router.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// ─── Provider IDs ─────────────────────────────────────────────────────────────

// Public so section widgets can reference them without importing checkout_page.
const checkoutUseManualAddressId = 'checkout_use_manual_address';
const checkoutSaveNewAddressId = 'checkout_save_new_address';
const checkoutIsSubmittingId = 'checkout_is_submitting';
const checkoutPaymentModeId = 'checkout_payment_mode';

// ─── Selected-address provider ────────────────────────────────────────────────

/// autoDispose: cleared automatically when the user leaves CheckoutPage.
final selectedAddressProvider = StateProvider.autoDispose<AddressEntity?>(
  (ref) => null,
);

// ─── Mixin ────────────────────────────────────────────────────────────────────

/// Encapsulates all business logic for CheckoutPage so the widget itself stays
/// under 150 lines.
///
/// Usage:
///   class _CheckoutPageState extends `ConsumerState<CheckoutPage>`
///       with `CheckoutLogicMixin<CheckoutPage>` { … }
mixin CheckoutLogicMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // ── Form state (public: accessed from build() in checkout_page.dart) ────────

  final formKey = GlobalKey<FormState>();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final addressLabelController = TextEditingController();

  double? manualLatitude;
  double? manualLongitude;

  /// Prevents the empty-cart guard in build() from popping the page while
  /// navigating to the confirmation screen.
  bool isNavigatingToConfirmation = false;

  @override
  void dispose() {
    addressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    notesController.dispose();
    addressLabelController.dispose();
    super.dispose();
  }

  // ── Initialisation helpers (called from initState via postFrameCallback) ────

  Future<void> initPricingConfig() async {
    await ref.read(pricingProvider.notifier).loadPricing();
    final pricingState = ref.read(pricingProvider);
    if (pricingState.config != null) {
      ref.read(cartProvider.notifier).updatePricingConfig(pricingState.config!);
    }
  }

  Future<void> initDefaultAddress() async {
    await ref.read(addressesProvider.notifier).loadAddresses();
    final addrState = ref.read(addressesProvider);

    // Sélectionner automatiquement l'adresse par défaut ou la première adresse disponible
    final addressToSelect =
        addrState.defaultAddress ??
        (addrState.addresses.isNotEmpty ? addrState.addresses.first : null);

    if (addressToSelect != null) {
      ref.read(selectedAddressProvider.notifier).state = addressToSelect;
      ref.read(toggleProvider(checkoutUseManualAddressId).notifier).set(false);
      await updateDeliveryFeeForAddress(addressToSelect);
    } else {
      // Pas d'adresse enregistrée, activer le mode manuel
      ref.read(toggleProvider(checkoutUseManualAddressId).notifier).set(true);
    }
  }

  void prefillPhone() {
    final authState = ref.read(authProvider);
    if (authState.user != null && phoneController.text.isEmpty) {
      phoneController.text = authState.user!.phone;
    }
  }

  /// Triggers a delivery-fee estimate for [address]; called from
  /// CheckoutAddressSection via callback.
  /// Updates both DeliveryFeeState and CartState so the displayed total is accurate.
  Future<void> updateDeliveryFeeForAddress(AddressEntity address) async {
    final notifier = ref.read(deliveryFeeProvider.notifier);
    await notifier.estimateDeliveryFee(address: address);
    final feeState = ref.read(deliveryFeeProvider);
    if (feeState.fee != null && feeState.fee! > 0) {
      ref
          .read(cartProvider.notifier)
          .updateDeliveryFee(
            deliveryFee: feeState.fee!,
            distanceKm: notifier.lastDistanceKm,
          );
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  /// Validates the form, verifies stocks, optionally uploads prescription,
  /// creates the order and initiates payment.
  ///
  /// All Riverpod reads happen here at button-press time so build() no longer
  /// needs to watch these providers just to pass them as parameters.
  Future<void> submitOrder() async {
    final useManualAddress = ref.read(
      toggleProvider(checkoutUseManualAddressId),
    );
    final saveNewAddress = ref.read(toggleProvider(checkoutSaveNewAddressId));
    final paymentMode =
        ref.read(formFieldsProvider(checkoutPaymentModeId))['mode'] ??
        AppConstants.paymentModePlatform;
    final selectedSavedAddress = ref.read(selectedAddressProvider);

    if (ref.read(loadingProvider(checkoutIsSubmittingId)).isLoading) {
      _showCheckoutSnackBar(
        'Commande en cours de traitement...',
        Colors.orange,
      );
      return;
    }

    // === Offline check =======================================================
    final isConnected = ref.read(connectivityProvider);
    if (!isConnected) {
      // Queue order for later submission
      await _queueOrderForOffline(
        useManualAddress: useManualAddress,
        saveNewAddress: saveNewAddress,
        paymentMode: paymentMode,
        selectedSavedAddress: selectedSavedAddress,
      );
      return;
    }

    final cartState = ref.read(cartProvider);

    // === Pharmacy validation =================================================
    if (cartState.selectedPharmacyId == null) {
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
      _showCheckoutSnackBar(
        'Veuillez sélectionner une pharmacie',
        Colors.orange,
      );
      return;
    }

    // === Stock verification ===================================================
    ref.read(loadingProvider(checkoutIsSubmittingId).notifier).startLoading();

    final stockIssues = await _verifyStocksBeforeCheckout(cartState.items);
    if (stockIssues.isNotEmpty) {
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
      await _showStockIssuesDialog(stockIssues);
      return;
    }

    // === Prescription check ==================================================
    if (cartState.hasPrescriptionRequiredItems) {
      final prescriptionState = ref.read(checkoutPrescriptionProvider);
      if (!prescriptionState.hasValidPrescription) {
        ref
            .read(loadingProvider(checkoutIsSubmittingId).notifier)
            .stopLoading();
        _showCheckoutSnackBar(
          'Veuillez ajouter une ordonnance pour les produits qui le nécessitent',
          Colors.orange,
        );
        return;
      }
    }

    // === Address validation ==================================================
    if (!useManualAddress && selectedSavedAddress == null) {
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
      _showCheckoutSnackBar(
        'Veuillez sélectionner une adresse de livraison',
        Colors.orange,
      );
      return;
    }

    if (useManualAddress && !formKey.currentState!.validate()) {
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
      _showCheckoutSnackBar(
        'Veuillez entrer un numéro de téléphone valide',
        Colors.orange,
      );
      return;
    }

    // =========================================================================

    final orderItems = _buildOrderItems(cartState);
    final deliveryAddress = _buildDeliveryAddress(
      useManualAddress,
      selectedSavedAddress,
    );

    if (useManualAddress && saveNewAddress) {
      await _saveAddressToProfile();
    }

    // === Prescription upload =================================================
    String? prescriptionImage;
    int? prescriptionId;

    if (cartState.hasPrescriptionRequiredItems) {
      final prescriptionState = ref.read(checkoutPrescriptionProvider);
      if (prescriptionState.isAlreadyUploaded) {
        AppLogger.debug(
          '[Checkout] Prescription already uploaded, reusing: id=${prescriptionState.uploadedPrescriptionId}',
        );
        prescriptionId = prescriptionState.uploadedPrescriptionId;
        prescriptionImage = prescriptionState.uploadedPrescriptionImage;
      } else if (prescriptionState.images.isNotEmpty) {
        try {
          AppLogger.debug('[Checkout] Uploading prescription images...');
          await ref
              .read(prescriptionsProvider.notifier)
              .uploadPrescription(
                images: prescriptionState.images,
                notes: prescriptionState.notes,
              );

          final prescState = ref.read(prescriptionsProvider);
          final uploaded = prescState.uploadedPrescription;

          // Warn about duplicate prescription
          if (prescState.lastUploadIsDuplicate && mounted) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                title: const Text('Doublon détecté'),
                content: Text(
                  'Cette ordonnance semble avoir déjà été soumise'
                  '${prescState.lastUploadExistingId != null ? ' (Ordonnance #${prescState.lastUploadExistingId})' : ''}.\n\n'
                  'Voulez-vous continuer la commande ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Continuer'),
                  ),
                ],
              ),
            );
            if (shouldContinue != true) {
              ref
                  .read(loadingProvider(checkoutIsSubmittingId).notifier)
                  .stopLoading();
              return;
            }
          }

          if (uploaded != null) {
            prescriptionId = uploaded.id;
            if (uploaded.imageUrls.isNotEmpty) {
              prescriptionImage = uploaded.imageUrls.first;
            }
            AppLogger.debug(
              '[Checkout] Prescription uploaded: id=$prescriptionId, image=$prescriptionImage',
            );
            ref
                .read(checkoutPrescriptionProvider.notifier)
                .markAsUploaded(prescriptionId, prescriptionImage);
          }
        } catch (e) {
          AppLogger.error('[Checkout] Failed to upload prescription', error: e);
          ref
              .read(loadingProvider(checkoutIsSubmittingId).notifier)
              .stopLoading();
          _showCheckoutSnackBar(
            'Erreur lors de l\'envoi de l\'ordonnance. Veuillez réessayer.',
            AppColors.error,
          );
          return;
        }
      }
    }

    // === Order creation ======================================================
    AppLogger.debug(
      '[Checkout] Creating order with pharmacyId: ${cartState.selectedPharmacyId}',
    );
    AppLogger.debug('[Checkout] Payment mode: $paymentMode');
    AppLogger.debug('[Checkout] Delivery address: ${deliveryAddress.address}');
    AppLogger.debug('[Checkout] Prescription image: $prescriptionImage');
    AppLogger.debug('[Checkout] Prescription ID: $prescriptionId');

    // === Promo code =========================================================
    final promoState = ref.read(promoCodeProvider);
    final promoCode = promoState.code;

    await ref
        .read(ordersProvider.notifier)
        .createOrder(
          pharmacyId:
              cartState.selectedPharmacyId!, // guarded by null check above
          items: orderItems,
          deliveryAddress: deliveryAddress,
          paymentMode: paymentMode,
          prescriptionImage: prescriptionImage,
          prescriptionId: prescriptionId,
          customerNotes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          promoCode: promoCode,
        );

    final ordersState = ref.read(ordersProvider);
    AppLogger.debug(
      '[Checkout] Order state after create: ${ordersState.status}',
    );
    AppLogger.debug(
      '[Checkout] Created order: ${ordersState.createdOrder?.id}',
    );
    AppLogger.debug('[Checkout] Error message: ${ordersState.errorMessage}');
    AppLogger.debug('[Checkout] Payment mode selected: $paymentMode');

    if (ordersState.status == OrdersStatus.loaded &&
        ordersState.createdOrder != null) {
      HapticFeedback.heavyImpact();
      AppLogger.debug(
        '[Checkout] SUCCESS - Order created with id: ${ordersState.createdOrder!.id}',
      );
      final orderId = ordersState.createdOrder!.id;
      if (mounted) {
        AppLogger.debug(
          '[Checkout] Widget still mounted, processing payment mode: $paymentMode',
        );
        if (paymentMode == AppConstants.paymentModePlatform) {
          ref
              .read(loadingProvider(checkoutIsSubmittingId).notifier)
              .stopLoading();
          AppLogger.debug(
            '[Checkout] Calling _processPayment for order $orderId',
          );
          await _processPayment(orderId);
        } else {
          AppLogger.debug(
            '[Checkout] Cash payment - navigating to confirmation',
          );
          _showCheckoutSnackBar(
            'Commande créée avec succès!',
            AppColors.success,
          );
          _navigateToConfirmation(orderId, isPaid: false);
        }
      } else {
        AppLogger.debug('[Checkout] Widget NOT mounted after order creation!');
      }
    } else if (ordersState.status == OrdersStatus.error) {
      AppLogger.debug('[Checkout] ERROR - ${ordersState.errorMessage}');
      if (mounted) {
        ref
            .read(loadingProvider(checkoutIsSubmittingId).notifier)
            .stopLoading();
        _showCheckoutSnackBar(
          _getReadableOrderError(ordersState.errorMessage),
          AppColors.error,
          duration: const Duration(seconds: 4),
        );
      }
    } else {
      AppLogger.debug(
        '[Checkout] UNEXPECTED STATE - status: ${ordersState.status}',
      );
      ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
    }
  }

  // ── Private: order helpers ───────────────────────────────────────────────────

  List<OrderItemEntity> _buildOrderItems(dynamic cartState) {
    return cartState.items
        .map<OrderItemEntity>(
          (item) => OrderItemEntity(
            productId: item.product.id,
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
            totalPrice: item.totalPrice,
          ),
        )
        .toList();
  }

  DeliveryAddressEntity _buildDeliveryAddress(
    bool useManualAddress,
    AddressEntity? selectedSavedAddress,
  ) {
    final phone = phoneController.text.trim();
    if (useManualAddress) {
      return DeliveryAddressEntity(
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        phone: phone,
        latitude: manualLatitude,
        longitude: manualLongitude,
      );
    }
    return DeliveryAddressEntity(
      address: selectedSavedAddress!.fullAddress.isNotEmpty
          ? selectedSavedAddress.fullAddress
          : selectedSavedAddress.address,
      city: selectedSavedAddress.city,
      phone: selectedSavedAddress.phone?.isNotEmpty == true
          ? selectedSavedAddress.phone!
          : phone,
      latitude: selectedSavedAddress.latitude,
      longitude: selectedSavedAddress.longitude,
    );
  }

  String _getReadableOrderError(String? error) {
    if (error == null || error.isEmpty) {
      return 'Une erreur est survenue lors de la création de la commande.';
    }
    final e = error.toLowerCase();
    if (e.contains('stock') || e.contains('disponible')) {
      return 'Certains produits ne sont plus disponibles. Veuillez vérifier votre panier.';
    }
    if (e.contains('pharmacy') || e.contains('pharmacie')) {
      return 'La pharmacie n\'est pas disponible actuellement. Veuillez en choisir une autre.';
    }
    if (e.contains('network') ||
        e.contains('connexion') ||
        e.contains('internet') ||
        e.contains('serveur')) {
      return 'Problème de connexion. Vérifiez votre internet et réessayez.';
    }
    if (e.contains('address') || e.contains('adresse')) {
      return 'L\'adresse de livraison est invalide. Veuillez la vérifier.';
    }
    if (e.contains('téléphone') || e.contains('phone')) {
      return 'Le numéro de téléphone est invalide. Veuillez le vérifier.';
    }
    if (e.contains('validation') ||
        e.contains('requis') ||
        e.contains('required')) {
      return 'Certaines informations sont manquantes. Veuillez vérifier le formulaire.';
    }
    if (e.contains('session') ||
        e.contains('reconnecter') ||
        e.contains('401')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    if (error.length > 100) {
      return 'Erreur: ${error.substring(0, 100)}...';
    }
    return 'Erreur: $error';
  }

  // ── Private: payment flow ───────────────────────────────────────────────────

  Future<void> _processPayment(int orderId) async {
    AppLogger.debug('[Payment] Starting _processPayment for order $orderId');
    if (!mounted) {
      AppLogger.debug('[Payment] Widget not mounted, returning');
      return;
    }

    final walletState = ref.read(walletProvider);
    final createdOrder = ref.read(ordersProvider).createdOrder;
    final orderTotal = createdOrder?.totalAmount;
    final orderReference = createdOrder?.reference ?? orderId.toString();

    AppLogger.debug('[Payment] Showing PaymentProviderDialog');
    final selection = await PaymentProviderDialog.show(
      context,
      walletBalance: walletState.wallet?.balance,
      orderAmount: orderTotal,
    );
    AppLogger.debug('[Payment] Selection: $selection');

    if (selection == null) {
      AppLogger.debug(
        '[Payment] Selection is null — user dismissed dialog, cancelling order and restoring cart',
      );
      if (mounted) await _cancelAndRestoreCart(orderId);
      return;
    }

    final provider = selection['provider'] ?? 'jeko';
    final paymentMethod = selection['payment_method'] ?? 'orange';
    if (!mounted) return;

    // ── Wallet payment ────────────────────────────────────────────────────────
    if (provider == 'wallet') {
      AppLogger.debug(
        '[Payment] Wallet payment for order $orderReference, amount: $orderTotal',
      );
      PaymentLoadingDialog.show(context);
      final success = await ref
          .read(walletProvider.notifier)
          .payOrder(amount: orderTotal ?? 0, orderReference: orderReference);
      if (!mounted) return;
      PaymentLoadingDialog.hide(context);
      if (success) {
        _navigateToConfirmation(orderId, isPaid: true);
      } else {
        await _cancelAndRestoreCart(
          orderId,
          message: 'Paiement portefeuille échoué. Votre panier est conservé.',
        );
      }
      return;
    }
    // ─────────────────────────────────────────────────────────────────────────

    AppLogger.debug('[Payment] Showing loading dialog');
    PaymentLoadingDialog.show(context);

    AppLogger.debug(
      '[Payment] Initiating payment with provider: $provider, method: $paymentMethod',
    );
    await ref
        .read(paymentProvider.notifier)
        .initiatePayment(
          orderId: orderId,
          provider: provider,
          paymentMethod: paymentMethod,
        );
    AppLogger.debug('[Payment] Payment initiation complete');

    if (!mounted) return;
    PaymentLoadingDialog.hide(context);

    final paymentState = ref.read(paymentProvider);
    if (paymentState.status == PaymentStatus.success &&
        paymentState.result != null) {
      final paymentUrl = paymentState.result!.paymentUrl;
      AppLogger.debug('[Payment] Payment URL received: $paymentUrl');

      final paymentResult = await PaymentWebViewPage.show(
        context,
        paymentUrl: paymentUrl,
        orderId: orderId.toString(),
      );
      // paymentResult: true = success, false = error, null = user closed
      AppLogger.debug('[Payment] WebView result: $paymentResult');
      if (mounted) {
        if (paymentResult == true) {
          _navigateToConfirmation(orderId, isPaid: true);
        } else {
          await _cancelAndRestoreCart(
            orderId,
            message: paymentResult == false
                ? 'Paiement échoué. Votre panier est conservé.'
                : 'Paiement annulé. Votre panier est conservé.',
          );
        }
      }
    } else {
      final errorMessage =
          paymentState.errorMessage ??
          'Erreur lors de l\'initialisation du paiement';
      AppLogger.debug('[Payment] Payment failed. error=$errorMessage');
      if (mounted) {
        await _cancelAndRestoreCart(
          orderId,
          message: 'Paiement échoué. Votre panier est conservé.',
        );
      }
    }
  }

  // ── Private: stock verification ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _verifyStocksBeforeCheckout(
    List<dynamic> cartItems,
  ) async {
    final stockIssues = <Map<String, dynamic>>[];
    final repository = ref.read(productsRepositoryProvider);
    AppLogger.debug(
      '[Checkout] Verifying stock for ${cartItems.length} items...',
    );

    for (final item in cartItems) {
      try {
        final result = await repository.getProductDetails(item.product.id);
        result.fold(
          (failure) {
            AppLogger.warning(
              '[Checkout] Failed to verify stock for product ${item.product.id}: ${failure.message}',
            );
            // Network errors: let the server validate — continue without blocking
          },
          (product) {
            if (!product.isAvailable) {
              stockIssues.add({
                'productName': product.name,
                'issue': 'indisponible',
                'requested': item.quantity,
                'available': 0,
              });
            } else if (product.stockQuantity < item.quantity) {
              stockIssues.add({
                'productName': product.name,
                'issue': 'insuffisant',
                'requested': item.quantity,
                'available': product.stockQuantity,
              });
            }
          },
        );
      } catch (e) {
        AppLogger.error(
          '[Checkout] Error verifying stock for product ${item.product.id}',
          error: e,
        );
      }
    }

    AppLogger.debug(
      '[Checkout] Stock verification complete. Issues found: ${stockIssues.length}',
    );
    return stockIssues;
  }

  Future<void> _showStockIssuesDialog(List<Map<String, dynamic>> issues) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Stock insuffisant', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Certains produits ne sont plus disponibles en quantité suffisante:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...issues.map(
                (issue) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['productName'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue['issue'] == 'indisponible'
                            ? 'Produit indisponible'
                            : 'Stock: ${issue['available']} (demandé: ${issue['requested']})',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez modifier votre panier avant de continuer.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Modifier le panier'),
          ),
        ],
      ),
    );
  }

  // ── Private: offline queue handling ──────────────────────────────────────────

  /// Queue order for submission when back online
  Future<void> _queueOrderForOffline({
    required bool useManualAddress,
    required bool saveNewAddress,
    required String paymentMode,
    required AddressEntity? selectedSavedAddress,
  }) async {
    final cartState = ref.read(cartProvider);

    // Validate required fields before queuing
    if (cartState.selectedPharmacyId == null) {
      _showCheckoutSnackBar(
        'Veuillez sélectionner une pharmacie',
        Colors.orange,
      );
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      _showCheckoutSnackBar(
        'Veuillez entrer un numéro de téléphone valide',
        Colors.orange,
      );
      return;
    }

    if (!useManualAddress && selectedSavedAddress == null) {
      _showCheckoutSnackBar(
        'Veuillez sélectionner une adresse de livraison',
        Colors.orange,
      );
      return;
    }

    if (useManualAddress && !formKey.currentState!.validate()) {
      return;
    }

    // Build order payload
    final orderItems = _buildOrderItems(cartState);
    final deliveryAddress = _buildDeliveryAddress(
      useManualAddress,
      selectedSavedAddress,
    );
    final prescriptionState = ref.read(checkoutPrescriptionProvider);
    final promoState = ref.read(promoCodeProvider);

    final payload = {
      'pharmacyId': cartState.selectedPharmacyId,
      'items': orderItems
          .map(
            (item) => {
              'productId': item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
            },
          )
          .toList(),
      'deliveryAddress': {
        'address': deliveryAddress.address,
        'city': deliveryAddress.city,
        'phone': deliveryAddress.phone,
        'latitude': deliveryAddress.latitude,
        'longitude': deliveryAddress.longitude,
      },
      'paymentMode': paymentMode,
      'customerNotes': notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      'promoCode': promoState.code,
      'hasPrescription': cartState.hasPrescriptionRequiredItems,
      'prescriptionNotes': prescriptionState.notes,
    };

    // Queue the action
    await ref
        .read(offlineQueueProvider.notifier)
        .enqueue(QueuedActionType.createOrder, payload);

    // Show confirmation
    HapticFeedback.mediumImpact();
    _showOfflineQueuedDialog();
  }

  /// Show dialog confirming order was queued
  void _showOfflineQueuedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.wifi_off_rounded,
          color: Colors.orange.shade600,
          size: 48,
        ),
        title: const Text(
          'Commande en attente',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous êtes actuellement hors ligne.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre commande sera envoyée automatiquement dès que vous serez reconnecté.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre panier est conservé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop(); // Return to cart
              },
              child: const Text('Compris'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Private: navigation & UI helpers ────────────────────────────────────────

  /// Annule la commande et conserve le panier quand le paiement en ligne
  /// est abandonné ou a échoué. L'utilisateur est renvoyé au panier.
  Future<void> _cancelAndRestoreCart(
    int orderId, {
    String? message,
  }) async {
    if (!mounted) return;
    ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();

    // Annulation silencieuse côté serveur
    try {
      await ref
          .read(ordersProvider.notifier)
          .cancelOrder(orderId, 'Paiement non complété');
      AppLogger.debug('[Payment] Order $orderId cancelled after payment abort');
    } catch (e) {
      AppLogger.warning(
        '[Payment] Could not cancel order $orderId',
        error: e,
      );
    }

    if (!mounted) return;

    _showCheckoutSnackBar(
      message ?? 'Paiement annulé. Votre panier est conservé.',
      Colors.orange,
    );

    // Retour au panier sans vider son contenu
    context.go(AppRoutes.cart);
  }

  void _navigateToConfirmation(int orderId, {required bool isPaid}) {
    isNavigatingToConfirmation = true;
    ref.read(loadingProvider(checkoutIsSubmittingId).notifier).stopLoading();
    ref.read(cartProvider.notifier).clearCart();
    context.goToOrderConfirmation(orderId: orderId, isPaid: isPaid);
  }

  void _showCheckoutSnackBar(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (backgroundColor == AppColors.success) {
      ErrorHandler.showSuccessSnackBar(context, message);
    } else if (backgroundColor == AppColors.error) {
      ErrorHandler.showErrorSnackBar(context, message);
    } else {
      ErrorHandler.showWarningSnackBar(context, message);
    }
  }

  /// Delegates address persistence to [AddressesNotifier.saveFromCheckout].
  /// Shows a success snackbar on completion (UI concern stays in the mixin).
  Future<void> _saveAddressToProfile() async {
    try {
      await ref
          .read(addressesProvider.notifier)
          .saveFromCheckout(
            address: addressController.text.trim(),
            city: cityController.text.trim(),
            phone: phoneController.text.trim(),
            labelHint: addressLabelController.text.trim(),
            latitude: manualLatitude,
            longitude: manualLongitude,
          );
      if (mounted) {
        final label = addressLabelController.text.trim().isNotEmpty
            ? addressLabelController.text.trim()
            : 'Adresse ${DateTime.now().day}/${DateTime.now().month}';
        ErrorHandler.showSuccessSnackBar(
          context,
          'Adresse "$label" enregistrée',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'enregistrement de l\'adresse',
        error: e,
      );
    }
  }
}
