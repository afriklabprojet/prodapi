import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../addresses/domain/entities/address_entity.dart';
import '../../../addresses/presentation/pages/addresses_list_page.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';

/// Widget pour sélectionner une adresse de livraison dans le checkout
class AddressSelector extends ConsumerStatefulWidget {
  final Function(AddressEntity?) onAddressSelected;
  final AddressEntity? initialAddress;
  
  const AddressSelector({
    super.key,
    required this.onAddressSelected,
    this.initialAddress,
  });

  @override
  ConsumerState<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends ConsumerState<AddressSelector> {
  @override
  void initState() {
    super.initState();
    // Charger les adresses si pas encore chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(addressesProvider);
      if (state.addresses.isEmpty && !state.isLoading) {
        ref.read(addressesProvider.notifier).loadAddresses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressesProvider);
    final selectedAddress = state.selectedAddress ?? widget.initialAddress;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Adresse de livraison',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.addresses.isNotEmpty)
                  TextButton(
                    onPressed: () => _selectAddress(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Changer'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (selectedAddress != null)
              _buildSelectedAddress(selectedAddress)
            else if (state.addresses.isEmpty)
              _buildNoAddresses()
            else
              _buildSelectPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAddress(AddressEntity address) {
    return InkWell(
      onTap: () => _selectAddress(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getLabelIcon(address.label),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Par défaut',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (address.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            address.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddresses() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_location_alt,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune adresse enregistrée',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoutez une adresse pour faciliter vos commandes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addNewAddress(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter une adresse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return InkWell(
      onTap: () => _selectAddress(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Veuillez sélectionner une adresse de livraison',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade700),
          ],
        ),
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'maison':
        return Icons.home;
      case 'bureau':
        return Icons.business;
      case 'famille':
        return Icons.family_restroom;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _selectAddress(BuildContext context) async {
    final selected = await Navigator.push<AddressEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesListPage(selectionMode: true),
      ),
    );

    if (selected != null) {
      widget.onAddressSelected(selected);
    }
  }

  Future<void> _addNewAddress() async {
    context.goToAddAddress();
    
    // Rafraîchir les adresses et sélectionner la nouvelle si c'est la première
    await ref.read(addressesProvider.notifier).loadAddresses();
    
    final state = ref.read(addressesProvider);
    if (state.addresses.length == 1) {
      widget.onAddressSelected(state.addresses.first);
    }
  }
}
