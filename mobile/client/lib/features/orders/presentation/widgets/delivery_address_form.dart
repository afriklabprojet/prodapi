import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Labels d'adresse valides (doivent correspondre au backend)
const List<String> _validAddressLabels = ['Maison', 'Bureau', 'Famille', 'Autre'];

/// Formulaire d'adresse de livraison manuelle
class DeliveryAddressForm extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final TextEditingController labelController;
  final bool saveAddress;
  final ValueChanged<bool> onSaveAddressChanged;
  final bool isDark;

  const DeliveryAddressForm({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.phoneController,
    required this.labelController,
    required this.saveAddress,
    required this.onSaveAddressChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAddressField(),
        const SizedBox(height: 12),
        _buildCityField(),
        const SizedBox(height: 12),
        _buildPhoneField(),
        const SizedBox(height: 16),
        _buildSaveAddressOption(),
      ],
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: addressController,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: const InputDecoration(
        labelText: 'Adresse complète *',
        hintText: 'Ex: 123 Rue des Jardins, Cocody',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer votre adresse';
        }
        if (value.trim().length < 10) {
          return 'Adresse trop courte';
        }
        return null;
      },
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      controller: cityController,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: const InputDecoration(
        labelText: 'Ville *',
        hintText: 'Ex: Abidjan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer la ville';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: const InputDecoration(
        labelText: 'Téléphone *',
        hintText: '+225 07 00 00 00 00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer votre numéro';
        }
        if (value.trim().length < 8) {
          return 'Numéro invalide';
        }
        return null;
      },
    );
  }

  Widget _buildSaveAddressOption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: saveAddress
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: saveAddress
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onSaveAddressChanged(!saveAddress),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: saveAddress,
                    onChanged: (value) => onSaveAddressChanged(value ?? false),
                    activeColor: AppColors.primary,
                    side: BorderSide(
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enregistrer cette adresse',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Pour vos prochaines commandes',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  saveAddress ? Icons.bookmark : Icons.bookmark_border,
                  color: saveAddress
                      ? AppColors.primary
                      : (isDark ? Colors.white60 : AppColors.textHint),
                ),
              ],
            ),
          ),
          if (saveAddress) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: labelController.text.isEmpty ? null : 
                (_validAddressLabels.contains(labelController.text) ? labelController.text : null),
              decoration: InputDecoration(
                labelText: 'Nom de l\'adresse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label_outline),
                isDense: true,
              ),
              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              items: _validAddressLabels.map((label) {
                return DropdownMenuItem<String>(
                  value: label,
                  child: Row(
                    children: [
                      Icon(
                        _getLabelIcon(label),
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  labelController.text = value;
                }
              },
              validator: (value) {
                if (saveAddress && (value == null || value.isEmpty)) {
                  return 'Choisissez un type d\'adresse';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Obtenir l'icône correspondant au label
  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'maison':
        return Icons.home;
      case 'bureau':
        return Icons.business;
      case 'famille':
        return Icons.family_restroom;
      case 'autre':
        return Icons.place;
      default:
        return Icons.location_on;
    }
  }
}
