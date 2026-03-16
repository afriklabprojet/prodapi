// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/services/app_logger.dart';
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
import 'payment_webview_page.dart';
import '../providers/orders_state.dart';
import '../providers/orders_provider.dart';
import '../widgets/widgets.dart';
import '../widgets/prescription_requirement_section.dart';
import '../../../../core/router/app_router.dart';

// Provider IDs pour cette page
const _useManualAddressId = 'checkout_use_manual_address';
const _saveNewAddressId = 'checkout_save_new_address';
const _isSubmittingId = 'checkout_is_submitting';
const _paymentModeId = 'checkout_payment_mode';

// Provider spécifique pour l'adresse sélectionnée (objet nullable)
// autoDispose pour éviter les fuites mémoire quand l'utilisateur quitte la page
final selectedAddressProvider = StateProvider.autoDispose<AddressEntity?>((ref) => null);

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressLabelController = TextEditingController();
  
  // Flag to prevent pop when navigating to confirmation
  bool _isNavigatingToConfirmation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndSelectDefaultAddress();
      _prefillUserPhone();
      _loadPricingConfig();
    });
  }

  /// Charger la configuration de tarification (frais de service et paiement)
  Future<void> _loadPricingConfig() async {
    await ref.read(pricingProvider.notifier).loadPricing();
    final pricingState = ref.read(pricingProvider);
    if (pricingState.config != null) {
      ref.read(cartProvider.notifier).updatePricingConfig(pricingState.config!);
    }
  }

  Future<void> _loadAndSelectDefaultAddress() async {
    await ref.read(addressesProvider.notifier).loadAddresses();
    final state = ref.read(addressesProvider);
    if (state.defaultAddress != null) {
      ref.read(selectedAddressProvider.notifier).state = state.defaultAddress;
      ref.read(toggleProvider(_useManualAddressId).notifier).set(false);
      // Calculer les frais de livraison pour l'adresse par défaut
      _calculateDeliveryFee(state.defaultAddress!);
    } else if (state.addresses.isEmpty) {
      ref.read(toggleProvider(_useManualAddressId).notifier).set(true);
    }
  }

  /// Calculer les frais de livraison pour une adresse
  void _calculateDeliveryFee(AddressEntity address) {
    ref.read(deliveryFeeProvider.notifier).estimateDeliveryFee(address: address);
  }

  void _prefillUserPhone() {
    final authState = ref.read(authProvider);
    if (authState.user != null && _phoneController.text.isEmpty) {
      _phoneController.text = authState.user!.phone;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _addressLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final ordersState = ref.watch(ordersProvider);
    final addressesState = ref.watch(addressesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Providers pour l'état UI
    final useManualAddress = ref.watch(toggleProvider(_useManualAddressId));
    final saveNewAddress = ref.watch(toggleProvider(_saveNewAddressId));
    final isSubmitting = ref.watch(loadingProvider(_isSubmittingId)).isLoading;
    final paymentMode = ref.watch(formFieldsProvider(_paymentModeId))['mode'] ?? AppConstants.paymentModePlatform;
    final selectedSavedAddress = ref.watch(selectedAddressProvider);

    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );

    if (cartState.isEmpty && !_isNavigatingToConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigatingToConfirmation) {
          Navigator.of(context).pop();
        }
      });
    }

    // État des frais de livraison
    final deliveryFeeState = ref.watch(deliveryFeeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation de la commande'),
        backgroundColor: AppColors.primary,
      ),
      body: ordersState.status == OrdersStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary avec frais de livraison, service et paiement
                    OrderSummaryCard(
                      items: cartState.items,
                      subtotal: cartState.subtotal,
                      deliveryFee: cartState.deliveryFee,
                      serviceFee: cartState.serviceFee,
                      paymentFee: cartState.paymentFee,
                      total: cartState.total,
                      distanceKm: cartState.deliveryDistanceKm,
                      isLoadingDeliveryFee: deliveryFeeState.isLoading,
                      currencyFormat: currencyFormat,
                      paymentMode: paymentMode,
                    ),
                    const SizedBox(height: 24),

                    // Prescription Requirement Section (si nécessaire)
                    if (cartState.hasPrescriptionRequiredItems) ...[
                      _buildSectionTitle('Ordonnance médicale'),
                      const SizedBox(height: 12),
                      PrescriptionRequirementSection(
                        requiredProductNames: cartState.prescriptionRequiredProductNames,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Delivery Address Section
                    DeliveryAddressSection(
                      useManualAddress: useManualAddress,
                      hasAddresses: addressesState.addresses.isNotEmpty,
                      selectedAddress: selectedSavedAddress,
                      onToggleManualAddress: (manual) {
                        ref.read(toggleProvider(_useManualAddressId).notifier).set(manual);
                        if (manual) {
                          // Réinitialiser les frais si adresse manuelle
                          ref.read(deliveryFeeProvider.notifier).reset();
                        }
                      },
                      onAddressSelected: (address) {
                        ref.read(selectedAddressProvider.notifier).state = address;
                        // Calculer les frais pour la nouvelle adresse
                        if (address != null) {
                          _calculateDeliveryFee(address);
                        } else {
                          ref.read(deliveryFeeProvider.notifier).reset();
                        }
                      },
                      addressController: _addressController,
                      cityController: _cityController,
                      phoneController: _phoneController,
                      labelController: _addressLabelController,
                      saveAddress: saveNewAddress,
                      onSaveAddressChanged: (save) {
                        ref.read(toggleProvider(_saveNewAddressId).notifier).set(save);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Payment Mode
                    _buildSectionTitle('Mode de paiement'),
                    const SizedBox(height: 12),
                    PaymentModeSelector(
                      selectedMode: paymentMode,
                      onModeChanged: (mode) {
                        ref.read(formFieldsProvider(_paymentModeId).notifier).setField('mode', mode);
                        // Mettre à jour le mode de paiement dans le cart pour recalculer les frais
                        ref.read(cartProvider.notifier).updatePaymentMode(mode);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    _buildSectionTitle('Notes (optionnel)'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Instructions spéciales pour la livraison...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CheckoutSubmitButton(
                      isSubmitting: isSubmitting,
                      totalFormatted: currencyFormat.format(cartState.total),
                      onPressed: () => _submitOrder(
                        useManualAddress: useManualAddress,
                        saveNewAddress: saveNewAddress,
                        paymentMode: paymentMode,
                        selectedSavedAddress: selectedSavedAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _submitOrder({
    required bool useManualAddress,
    required bool saveNewAddress,
    required String paymentMode,
    required AddressEntity? selectedSavedAddress,
  }) async {
    final isSubmitting = ref.read(loadingProvider(_isSubmittingId)).isLoading;
    if (isSubmitting) {
      _showSnackBar('Commande en cours de traitement...', Colors.orange);
      return;
    }

    final cartState = ref.read(cartProvider);

    // Vérifier si une ordonnance est requise et si elle a été fournie
    if (cartState.hasPrescriptionRequiredItems) {
      final prescriptionState = ref.read(checkoutPrescriptionProvider);
      if (!prescriptionState.hasValidPrescription) {
        _showSnackBar(
          'Veuillez ajouter une ordonnance pour les produits qui le nécessitent',
          Colors.orange,
        );
        return;
      }
    }

    if (!useManualAddress && selectedSavedAddress == null) {
      _showSnackBar('Veuillez sélectionner une adresse de livraison', Colors.orange);
      return;
    }

    if (useManualAddress && !_formKey.currentState!.validate()) {
      return;
    }

    // Validate phone number is present
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      _showSnackBar('Veuillez entrer un numéro de téléphone valide', Colors.orange);
      return;
    }

    ref.read(loadingProvider(_isSubmittingId).notifier).startLoading();

    final orderItems = _buildOrderItems(cartState);
    final deliveryAddress = _buildDeliveryAddress(useManualAddress, selectedSavedAddress);

    if (useManualAddress && saveNewAddress) {
      await _saveAddressToProfile();
    }

    // Upload prescription images if required
    String? prescriptionImage;
    int? prescriptionId;
    if (cartState.hasPrescriptionRequiredItems) {
      final prescriptionState = ref.read(checkoutPrescriptionProvider);
      if (prescriptionState.images.isNotEmpty) {
        try {
          AppLogger.debug('[Checkout] Uploading prescription images...');
          await ref.read(prescriptionsProvider.notifier).uploadPrescription(
            images: prescriptionState.images,
            notes: prescriptionState.notes,
          );
          
          // Get the uploaded prescription to extract image URL and ID
          final uploadedPrescription = ref.read(prescriptionsProvider).uploadedPrescription;
          if (uploadedPrescription != null) {
            prescriptionId = uploadedPrescription.id;
            if (uploadedPrescription.imageUrls.isNotEmpty) {
              prescriptionImage = uploadedPrescription.imageUrls.first;
            }
            AppLogger.debug('[Checkout] Prescription uploaded: id=$prescriptionId, image=$prescriptionImage');
          }
        } catch (e) {
          AppLogger.error('[Checkout] Failed to upload prescription', error: e);
          ref.read(loadingProvider(_isSubmittingId).notifier).stopLoading();
          _showSnackBar(
            'Erreur lors de l\'envoi de l\'ordonnance. Veuillez réessayer.',
            AppColors.error,
          );
          return;
        }
      }
    }

    AppLogger.debug('[Checkout] Creating order with pharmacyId: ${cartState.selectedPharmacyId}');
    AppLogger.debug('[Checkout] Payment mode: $paymentMode');
    AppLogger.debug('[Checkout] Delivery address: ${deliveryAddress.address}');
    AppLogger.debug('[Checkout] Prescription image: $prescriptionImage');
    AppLogger.debug('[Checkout] Prescription ID: $prescriptionId');

    await ref.read(ordersProvider.notifier).createOrder(
      pharmacyId: cartState.selectedPharmacyId!,
      items: orderItems,
      deliveryAddress: deliveryAddress,
      paymentMode: paymentMode,
      prescriptionImage: prescriptionImage,
      prescriptionId: prescriptionId,
      customerNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final ordersState = ref.read(ordersProvider);
    AppLogger.debug('[Checkout] Order state after create: ${ordersState.status}');
    AppLogger.debug('[Checkout] Created order: ${ordersState.createdOrder?.id}');
    AppLogger.debug('[Checkout] Error message: ${ordersState.errorMessage}');
    AppLogger.debug('[Checkout] Payment mode selected: $paymentMode');

    if (ordersState.status == OrdersStatus.loaded &&
        ordersState.createdOrder != null) {
      AppLogger.debug('[Checkout] SUCCESS - Order created with id: ${ordersState.createdOrder!.id}');
      
      final orderId = ordersState.createdOrder!.id;

      if (mounted) {
        AppLogger.debug('[Checkout] Widget still mounted, processing payment mode: $paymentMode');
        if (paymentMode == 'platform') {
          // Stop loading before payment process
          ref.read(loadingProvider(_isSubmittingId).notifier).stopLoading();
          AppLogger.debug('[Checkout] Calling _processPayment for order $orderId');
          await _processPayment(orderId);
          // Note: clearCart is called in _navigateToConfirmation to avoid premature rebuild
        } else {
          // For cash payment, navigate directly (clearCart will be called in _navigateToConfirmation)
          AppLogger.debug('[Checkout] Cash payment - navigating to confirmation');
          _showSnackBar('Commande créée avec succès!', AppColors.success);
          _navigateToConfirmation(orderId, isPaid: false);
        }
      } else {
        AppLogger.debug('[Checkout] Widget NOT mounted after order creation!');
      }
    } else if (ordersState.status == OrdersStatus.error) {
      AppLogger.debug('[Checkout] ERROR - ${ordersState.errorMessage}');
      if (mounted) {
        ref.read(loadingProvider(_isSubmittingId).notifier).stopLoading();
        _showSnackBar(
          _getReadableOrderError(ordersState.errorMessage),
          AppColors.error,
          duration: const Duration(seconds: 4),
        );
      }
    } else {
      AppLogger.debug('[Checkout] UNEXPECTED STATE - status: ${ordersState.status}');
      // In case of unexpected state, stop loading
      ref.read(loadingProvider(_isSubmittingId).notifier).stopLoading();
    }
  }

  List<OrderItemEntity> _buildOrderItems(dynamic cartState) {
    return cartState.items.map<OrderItemEntity>((item) {
      return OrderItemEntity(
        productId: item.product.id,
        name: item.product.name,
        quantity: item.quantity,
        unitPrice: item.product.price,
        totalPrice: item.totalPrice,
      );
    }).toList();
  }

  DeliveryAddressEntity _buildDeliveryAddress(bool useManualAddress, AddressEntity? selectedSavedAddress) {
    // Always use phone from controller (prefilled with user's phone or manual input)
    final phone = _phoneController.text.trim();
    
    if (useManualAddress) {
      return DeliveryAddressEntity(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: phone,
      );
    }
    return DeliveryAddressEntity(
      address: selectedSavedAddress!.fullAddress,
      city: selectedSavedAddress.city,
      // Use saved address phone if available, otherwise use the phone from controller
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
    
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('stock') || errorLower.contains('disponible')) {
      return 'Certains produits ne sont plus disponibles. Veuillez vérifier votre panier.';
    }
    if (errorLower.contains('pharmacy') || errorLower.contains('pharmacie')) {
      return 'La pharmacie n\'est pas disponible actuellement. Veuillez en choisir une autre.';
    }
    if (errorLower.contains('network') || errorLower.contains('connexion') || errorLower.contains('internet') || errorLower.contains('serveur')) {
      return 'Problème de connexion. Vérifiez votre internet et réessayez.';
    }
    if (errorLower.contains('address') || errorLower.contains('adresse')) {
      return 'L\'adresse de livraison est invalide. Veuillez la vérifier.';
    }
    if (errorLower.contains('téléphone') || errorLower.contains('phone')) {
      return 'Le numéro de téléphone est invalide. Veuillez le vérifier.';
    }
    if (errorLower.contains('validation') || errorLower.contains('requis') || errorLower.contains('required')) {
      return 'Certaines informations sont manquantes. Veuillez vérifier le formulaire.';
    }
    if (errorLower.contains('session') || errorLower.contains('reconnecter') || errorLower.contains('401')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    
    // Show actual error for better debugging (truncated)
    if (error.length > 100) {
      return 'Erreur: ${error.substring(0, 100)}...';
    }
    return 'Erreur: $error';
  }

  Future<void> _processPayment(int orderId) async {
    AppLogger.debug('[Payment] Starting _processPayment for order $orderId');
    if (!mounted) {
      AppLogger.debug('[Payment] Widget not mounted, returning');
      return;
    }

    AppLogger.debug('[Payment] Showing PaymentProviderDialog');
    final selection = await PaymentProviderDialog.show(context);
    AppLogger.debug('[Payment] Selection: $selection');

    if (selection == null) {
      AppLogger.debug('[Payment] Selection is null, navigating to confirmation without payment');
      if (mounted) _navigateToConfirmation(orderId, isPaid: false);
      return;
    }

    final provider = selection['provider'] ?? 'jeko';
    final paymentMethod = selection['payment_method'] ?? 'orange';

    if (!mounted) return;

    AppLogger.debug('[Payment] Showing loading dialog');
    PaymentLoadingDialog.show(context);

    AppLogger.debug('[Payment] Initiating payment with provider: $provider, method: $paymentMethod');
    final result = await ref
        .read(ordersProvider.notifier)
        .initiatePayment(orderId: orderId, provider: provider, paymentMethod: paymentMethod);

    AppLogger.debug('[Payment] Payment initiation result: $result');

    if (!mounted) return;
    PaymentLoadingDialog.hide(context);

    if (result != null && result.containsKey('payment_url')) {
      final paymentUrl = result['payment_url'] as String;
      AppLogger.debug('[Payment] Payment URL received: $paymentUrl');
      
      // Check if it's a sandbox URL (local development)
      if (paymentUrl.contains('sandbox/confirm') || paymentUrl.contains('localhost')) {
        AppLogger.debug('[Payment] Sandbox mode detected, showing sandbox dialog');
        // For sandbox mode, open in a dialog or directly confirm
        final confirmed = await _showSandboxPaymentDialog(paymentUrl);
        AppLogger.debug('[Payment] Sandbox dialog result: $confirmed');
        if (mounted) {
          _navigateToConfirmation(orderId, isPaid: confirmed);
        }
      } else {
        // Production: Open WebView for better mobile experience
        AppLogger.debug('[Payment] Production mode, opening WebView');
        final paymentResult = await PaymentWebViewPage.show(
          context,
          paymentUrl: paymentUrl,
          orderId: orderId.toString(),
        );
        
        // paymentResult: true = success, false = error, null = user closed
        AppLogger.debug('[Payment] WebView result: $paymentResult');
        if (mounted) {
          // Navigate to confirmation - actual status will be fetched from API
          _navigateToConfirmation(orderId, isPaid: paymentResult == true);
        }
      }
    } else {
      AppLogger.debug('[Payment] No payment_url in result, showing error');
      if (mounted) {
        _showSnackBar(
          'Erreur lors de l\'initialisation du paiement',
          AppColors.error,
        );
        _navigateToConfirmation(orderId, isPaid: false);
      }
    }
  }

  /// Show sandbox payment confirmation dialog for local development
  Future<bool> _showSandboxPaymentDialog(String sandboxUrl) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.developer_mode, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mode Sandbox'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous êtes en mode développement.\n\n'
              'Dans la version production, vous seriez redirigé vers la page de paiement Jèko.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le paiement sera automatiquement confirmé',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Call sandbox URL to confirm payment
              try {
                final uri = Uri.parse(sandboxUrl);
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                // Wait a bit for the payment to be confirmed
                await Future.delayed(const Duration(milliseconds: 500));
              } catch (e) {
                // Ignore errors, sandbox might auto-confirm
              }
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Simuler le paiement'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveAddressToProfile() async {
    try {
      final label = _addressLabelController.text.trim().isNotEmpty
          ? _addressLabelController.text.trim()
          : 'Adresse ${DateTime.now().day}/${DateTime.now().month}';
      
      await ref.read(addressesProvider.notifier).createAddress(
        label: label,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        isDefault: ref.read(addressesProvider).addresses.isEmpty,
      );
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Adresse "$label" enregistrée');
      }
    } catch (e) {
      AppLogger.error('Erreur lors de l\'enregistrement de l\'adresse', error: e);
    }
  }

  void _showSnackBar(
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

  void _navigateToConfirmation(int orderId, {required bool isPaid}) {
    // Set flag to prevent empty cart pop during navigation
    _isNavigatingToConfirmation = true;
    
    // Stop loading before navigation
    ref.read(loadingProvider(_isSubmittingId).notifier).stopLoading();
    
    // Clear cart - the flag prevents the empty cart check from triggering a pop
    ref.read(cartProvider.notifier).clearCart();
    
    // Use GoRouter to navigate — replaces the current stack cleanly
    context.goToOrderConfirmation(orderId: orderId, isPaid: isPaid);
  }
}
