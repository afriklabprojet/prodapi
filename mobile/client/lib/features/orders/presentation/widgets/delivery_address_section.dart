import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../addresses/domain/entities/address_entity.dart';
import 'delivery_address_form.dart';

/// Section de sélection/saisie d'adresse de livraison dans le checkout
class DeliveryAddressSection extends StatelessWidget {
  final bool useManualAddress;
  final bool hasAddresses;
  final AddressEntity? selectedAddress;
  final ValueChanged<bool> onToggleManualAddress;
  final ValueChanged<AddressEntity?> onAddressSelected;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final TextEditingController labelController;
  final bool saveAddress;
  final ValueChanged<bool> onSaveAddressChanged;
  final bool isDark;

  /// Callback quand les coordonnées GPS sont détectées
  final void Function(double latitude, double longitude)? onLocationDetected;

  const DeliveryAddressSection({
    super.key,
    required this.useManualAddress,
    required this.hasAddresses,
    required this.selectedAddress,
    required this.onToggleManualAddress,
    required this.onAddressSelected,
    required this.addressController,
    required this.cityController,
    required this.phoneController,
    required this.labelController,
    required this.saveAddress,
    required this.onSaveAddressChanged,
    required this.isDark,
    this.onLocationDetected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse de livraison',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Toggle between saved addresses and manual entry
        if (hasAddresses) ...[
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  context,
                  label: 'Adresses enregistrées',
                  isSelected: !useManualAddress,
                  onTap: () => onToggleManualAddress(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  context,
                  label: 'Nouvelle adresse',
                  isSelected: useManualAddress,
                  onTap: () => onToggleManualAddress(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        if (useManualAddress || !hasAddresses)
          DeliveryAddressForm(
            addressController: addressController,
            cityController: cityController,
            phoneController: phoneController,
            labelController: labelController,
            saveAddress: saveAddress,
            onSaveAddressChanged: onSaveAddressChanged,
            isDark: isDark,
            onLocationDetected: onLocationDetected,
          )
        else if (selectedAddress != null)
          _buildSelectedAddressCard(context)
        else
          _buildNoAddressSelected(context),
      ],
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAddressCard(BuildContext context) {
    final address = selectedAddress!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on, color: AppColors.primary),
        title: Text(
          address.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(address.fullAddress),
        trailing: TextButton(
          onPressed: () => onAddressSelected(null),
          child: const Text('Changer'),
        ),
      ),
    );
  }

  Widget _buildNoAddressSelected(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => onAddressSelected(null),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.add_location_alt, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sélectionner une adresse de livraison',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
