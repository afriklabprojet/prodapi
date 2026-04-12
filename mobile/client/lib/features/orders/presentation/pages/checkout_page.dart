import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_prescription_provider.dart';
import '../mixins/checkout_logic_mixin.dart';
import '../widgets/checkout/checkout_items_section.dart';
import '../widgets/checkout/checkout_prescription_section.dart';
import '../widgets/checkout/checkout_address_section.dart';
import '../widgets/checkout/checkout_payment_section.dart';
import '../widgets/checkout/checkout_promo_section.dart';
import '../../../addresses/domain/entities/address_entity.dart';

// ─── Re-export providers & IDs so downstream code keeps working ───────────────
// ignore: unused_import
export '../mixins/checkout_logic_mixin.dart' show selectedAddressProvider;

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage>
    with CheckoutLogicMixin<CheckoutPage> {
  int _currentStep = 0;

  static final _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDefaultAddress();
      prefillPhone();
      initPricingConfig();
    });
  }

  // dispose() is handled by CheckoutLogicMixin (controllers + super.dispose())

  @override
  Widget build(BuildContext context) {
    final ordersStatus = ref.watch(ordersProvider.select((s) => s.status));
    final isEmpty = ref.watch(cartProvider.select((s) => s.isEmpty));
    final isSubmitting = ref.watch(
      loadingProvider(checkoutIsSubmittingId).select((s) => s.isLoading),
    );
    // Surveiller l'adresse sélectionnée ici (widget racine du checkout) pour
    // que le provider autoDispose reste en vie pendant toute la durée du
    // parcours de commande, quelle que soit l'étape affichée.
    final selectedAddress = ref.watch(selectedAddressProvider);

    if (isEmpty && !isNavigatingToConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !isNavigatingToConfirmation) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        backgroundColor: AppColors.primary,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: ordersStatus == OrdersStatus.loading || isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Step indicator
                _buildStepIndicator(),

                // Step content
                Expanded(
                  child: Form(
                    key: formKey,
                    child: _buildCurrentStep(selectedAddress),
                  ),
                ),

                // Bottom action button
                _buildBottomButton(),
              ],
            ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Adresse de livraison';
      case 1:
        return 'Mode de paiement';
      case 2:
        return 'Confirmation';
      default:
        return 'Commande';
    }
  }

  Widget _buildStepIndicator() {
    return Semantics(
      label:
          'Étape ${_currentStep + 1} sur 3: ${['Adresse', 'Paiement', 'Confirmer'][_currentStep]}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStepDot(0, 'Adresse'),
            _buildStepLine(0),
            _buildStepDot(1, 'Paiement'),
            _buildStepLine(1),
            _buildStepDot(2, 'Confirmer'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    final statusText = isCurrent
        ? 'en cours'
        : (isActive ? 'terminé' : 'à venir');

    return Expanded(
      child: Semantics(
        label: 'Étape ${step + 1}: $label, $statusText',
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 36 : 28,
              height: isCurrent ? 36 : 28,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isActive && !isCurrent
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                        semanticLabel: 'Terminé',
                      )
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: isCurrent ? 16 : 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AddressEntity? selectedAddress) {
    switch (_currentStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildConfirmationStep(selectedAddress);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Utilisez la géolocalisation pour une livraison plus rapide',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Address section
          CheckoutAddressSection(
            addressController: addressController,
            cityController: cityController,
            phoneController: phoneController,
            labelController: addressLabelController,
            onLocationDetected: (lat, lng) {
              manualLatitude = lat;
              manualLongitude = lng;
            },
            onCalculateDeliveryFee: updateDeliveryFeeForAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final cartState = ref.watch(cartProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary mini card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartState.itemCount} article${cartState.itemCount > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _currency.format(cartState.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('Voir détails'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prescription if needed
          const CheckoutPrescriptionSection(),

          // Payment section
          const CheckoutPaymentSection(),
          const SizedBox(height: 24),

          // Promo code
          const CheckoutPromoSection(),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(AddressEntity? selectedAddress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items summary
          const CheckoutItemsSection(),
          const SizedBox(height: 20),

          // Delivery address summary
          _buildAddressSummary(selectedAddress),
          const SizedBox(height: 20),

          // Payment method summary
          _buildPaymentSummary(),
          const SizedBox(height: 20),

          // Notes
          const Text(
            'Notes (optionnel)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Instructions spéciales...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSummary(AddressEntity? selectedAddress) {
    final useManual = ref.watch(toggleProvider(checkoutUseManualAddressId));

    final address = useManual
        ? addressController.text
        : selectedAddress?.fullAddress ?? selectedAddress?.address ?? '';
    final phone = phoneController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Adresse de livraison',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: const Text('Modifier'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address.isNotEmpty ? address : 'Non définie'),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tél: $phone', style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final paymentMode =
        ref.watch(
          formFieldsProvider(checkoutPaymentModeId).select((s) => s['mode']),
        ) ??
        AppConstants.paymentModePlatform;

    final paymentLabel = paymentMode == AppConstants.paymentModeOnDelivery
        ? 'Paiement à la livraison'
        : 'Paiement en ligne (Wallet/Mobile Money)';
    final paymentIcon = paymentMode == AppConstants.paymentModeOnDelivery
        ? Icons.payments_outlined
        : Icons.account_balance_wallet_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(paymentIcon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              paymentLabel,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final total = ref.watch(cartProvider.select((s) => s.total));
    final isSubmitting = ref.watch(
      loadingProvider(checkoutIsSubmittingId).select((s) => s.isLoading),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _onNextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getButtonLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_currentStep == 2) ...[
                        const SizedBox(width: 8),
                        Text(
                          _currency.format(total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Continuer vers le paiement';
      case 1:
        return 'Vérifier la commande';
      case 2:
        return 'Confirmer et payer';
      default:
        return 'Continuer';
    }
  }

  void _onNextOrSubmit() {
    HapticFeedback.lightImpact();

    switch (_currentStep) {
      case 0:
        if (_validateAddressStep()) {
          setState(() => _currentStep = 1);
        }
        break;
      case 1:
        if (_validatePaymentStep()) {
          setState(() => _currentStep = 2);
        }
        break;
      case 2:
        submitOrder();
        break;
    }
  }

  bool _validateAddressStep() {
    final useManual = ref.read(toggleProvider(checkoutUseManualAddressId));
    final selectedAddress = ref.read(selectedAddressProvider);

    if (!useManual && selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (useManual) {
      if (addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer une adresse de livraison'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    if (phoneController.text.trim().isEmpty ||
        phoneController.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un numéro de téléphone valide'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  bool _validatePaymentStep() {
    final cartState = ref.read(cartProvider);

    // Check prescription if required
    if (cartState.hasPrescriptionRequiredItems) {
      final prescriptionState = ref.read(checkoutPrescriptionProvider);
      if (!prescriptionState.hasValidPrescription) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez ajouter une ordonnance pour les produits qui le nécessitent',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }
}
