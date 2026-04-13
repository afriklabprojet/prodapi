import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Suggestions rapides pour le label d'adresse
const List<String> _labelSuggestions = ['Maison', 'Bureau', 'Famille', 'Autre'];

/// Formulaire d'adresse de livraison manuelle
class DeliveryAddressForm extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final TextEditingController labelController;
  final bool saveAddress;
  final ValueChanged<bool> onSaveAddressChanged;
  final bool isDark;

  /// Callback quand les coordonnées GPS sont obtenues
  final void Function(double latitude, double longitude)? onLocationDetected;

  const DeliveryAddressForm({
    super.key,
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
  State<DeliveryAddressForm> createState() => _DeliveryAddressFormState();
}

class _DeliveryAddressFormState extends State<DeliveryAddressForm> {
  bool _isLoadingLocation = false;
  bool _hasLocation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLocationButton(),
        const SizedBox(height: 12),
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

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _hasLocation ? Icons.check_circle : Icons.my_location,
                color: _hasLocation ? AppColors.success : null,
              ),
        label: Text(
          _isLoadingLocation
              ? 'Localisation en cours...'
              : _hasLocation
              ? 'Position détectée ✓'
              : 'Utiliser ma position actuelle',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: _hasLocation ? AppColors.success : AppColors.primary,
          ),
          foregroundColor: _hasLocation ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppSnackbar.warning(context, 'Veuillez activer la localisation');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppSnackbar.warning(context, 'Permission de localisation refusée');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackbar.warning(
            context,
            'La localisation est désactivée. Activez-la dans les paramètres.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Notify parent of coordinates
      widget.onLocationDetected?.call(position.latitude, position.longitude);

      // Reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;

          final streetParts = <String>[];
          if (place.street != null && place.street!.isNotEmpty) {
            streetParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            streetParts.add(place.subLocality!);
          }
          if (place.thoroughfare != null &&
              place.thoroughfare!.isNotEmpty &&
              place.thoroughfare != place.street) {
            streetParts.add(place.thoroughfare!);
          }

          if (streetParts.isNotEmpty) {
            widget.addressController.text = streetParts.join(', ');
          } else if (place.name != null && place.name!.isNotEmpty) {
            widget.addressController.text = place.name!;
          }

          if (place.locality != null && place.locality!.isNotEmpty) {
            widget.cityController.text = place.locality!;
          } else if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            widget.cityController.text = place.administrativeArea!;
          }
        }
      } catch (_) {
        // Reverse geocoding failed but we still have coordinates
      }

      if (mounted) {
        setState(() => _hasLocation = true);
        AppSnackbar.success(
          context,
          widget.addressController.text.isNotEmpty
              ? 'Position et adresse détectées'
              : 'Position GPS détectée',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Erreur de localisation: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: widget.addressController,
      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
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
      controller: widget.cityController,
      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
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
      controller: widget.phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
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
        color: widget.saveAddress
            ? AppColors.primary.withValues(alpha: 0.1)
            : (widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.saveAddress
              ? AppColors.primary.withValues(alpha: 0.3)
              : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => widget.onSaveAddressChanged(!widget.saveAddress),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.saveAddress,
                    onChanged: (value) =>
                        widget.onSaveAddressChanged(value ?? false),
                    activeColor: AppColors.primary,
                    side: BorderSide(
                      color: widget.isDark ? Colors.white60 : Colors.grey,
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
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Pour vos prochaines commandes',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.white60
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  widget.saveAddress ? Icons.bookmark : Icons.bookmark_border,
                  color: widget.saveAddress
                      ? AppColors.primary
                      : (widget.isDark ? Colors.white60 : AppColors.textHint),
                ),
              ],
            ),
          ),
          if (widget.saveAddress) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.labelController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Nom de l\'adresse',
                hintText: 'Ex: Chez Maman, Mon appart...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label_outline),
                isDense: true,
              ),
              validator: (value) {
                if (widget.saveAddress &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Donnez un nom à cette adresse';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _labelSuggestions.map((suggestion) {
                final isSelected = widget.labelController.text == suggestion;
                return ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLabelIcon(suggestion),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(suggestion),
                    ],
                  ),
                  backgroundColor: isSelected ? AppColors.primary : null,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.labelController.text = suggestion;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtenir l'icône correspondant au label
  static IconData _getLabelIcon(String label) {
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
