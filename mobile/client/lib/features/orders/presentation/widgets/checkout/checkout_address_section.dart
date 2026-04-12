import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/ui_state_providers.dart';
import '../../../../addresses/domain/entities/address_entity.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../providers/delivery_fee_provider.dart';
import '../../mixins/checkout_logic_mixin.dart';
import '../delivery_address_section.dart';

/// Handles all Riverpod interactions for the delivery-address step so that
/// [CheckoutPage] only needs to pass form controllers and the GPS callback.
///
/// Internally handles:
/// - toggle manual / saved address
/// - propagate address selection to [selectedAddressProvider]
/// - trigger / reset delivery-fee estimation
class CheckoutAddressSection extends ConsumerWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final TextEditingController labelController;

  /// Called with new GPS coordinates when the user auto-detects their location.
  /// ⚠️ Must update the mixin's [manualLatitude] / [manualLongitude] fields.
  final void Function(double lat, double lng)? onLocationDetected;

  /// Called when a saved address is selected so the mixin can start the
  /// delivery-fee request.
  final void Function(AddressEntity address) onCalculateDeliveryFee;

  const CheckoutAddressSection({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.phoneController,
    required this.labelController,
    required this.onCalculateDeliveryFee,
    this.onLocationDetected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useManualAddress = ref.watch(toggleProvider(checkoutUseManualAddressId));
    final saveNewAddress   = ref.watch(toggleProvider(checkoutSaveNewAddressId));
    final hasAddresses     = ref.watch(
      addressesProvider.select((s) => s.addresses.isNotEmpty),
    );
    final selectedAddress  = ref.watch(selectedAddressProvider);
    final isDark           = Theme.of(context).brightness == Brightness.dark;

    return DeliveryAddressSection(
      useManualAddress: useManualAddress,
      hasAddresses:     hasAddresses,
      selectedAddress:  selectedAddress,
      onToggleManualAddress: (manual) {
        ref.read(toggleProvider(checkoutUseManualAddressId).notifier).set(manual);
        if (manual) ref.read(deliveryFeeProvider.notifier).reset();
      },
      onAddressSelected: (address) {
        ref.read(selectedAddressProvider.notifier).state = address;
        if (address != null) {
          onCalculateDeliveryFee(address);
        } else {
          ref.read(deliveryFeeProvider.notifier).reset();
        }
      },
      addressController:    addressController,
      cityController:       cityController,
      phoneController:      phoneController,
      labelController:      labelController,
      saveAddress:          saveNewAddress,
      onSaveAddressChanged: (save) =>
          ref.read(toggleProvider(checkoutSaveNewAddressId).notifier).set(save),
      isDark:               isDark,
      onLocationDetected:   onLocationDetected,
    );
  }
}
