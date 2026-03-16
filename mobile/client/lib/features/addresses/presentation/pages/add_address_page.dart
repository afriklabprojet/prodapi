import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../core/services/places_autocomplete_service.dart';
import '../providers/addresses_provider.dart';
import '../widgets/address_autocomplete_field.dart';

// Provider IDs pour cette page
const _isDefaultId = 'add_address_is_default';
const _selectedLabelId = 'add_address_selected_label';
const _isLoadingLocationId = 'add_address_loading_location';

/// Page d'ajout d'une nouvelle adresse
class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  double? _latitude;
  double? _longitude;
  bool _phonePreFilled = false;
  final PlacesAutocompleteService _placesService = PlacesAutocompleteService();

  @override
  void initState() {
    super.initState();
    // Pré-remplir le téléphone avec celui du profil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preFillPhone();
    });
  }

  Future<void> _preFillPhone() async {
    if (_phonePreFilled) return;
    
    final formDataAsync = ref.read(addressFormDataProvider);
    formDataAsync.whenData((formData) {
      if (formData.defaultPhone != null && 
          formData.defaultPhone!.isNotEmpty && 
          _phoneController.text.isEmpty) {
        setState(() {
          _phoneController.text = formData.defaultPhone!;
          _phonePreFilled = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressesProvider);
    final formDataAsync = ref.watch(addressFormDataProvider);
    
    // Providers pour l'état UI
    final isDefault = ref.watch(toggleProvider(_isDefaultId));
    final selectedLabel = ref.watch(formFieldsProvider(_selectedLabelId))['label'] ?? 'Maison';
    final isLoadingLocation = ref.watch(loadingProvider(_isLoadingLocationId)).isLoading;
    
    // Pré-remplir le téléphone si disponible
    formDataAsync.whenData((formData) {
      if (!_phonePreFilled && 
          formData.defaultPhone != null && 
          formData.defaultPhone!.isNotEmpty && 
          _phoneController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _phoneController.text = formData.defaultPhone!;
            _phonePreFilled = true;
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle adresse'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label selector
            _buildSectionTitle('Type d\'adresse'),
            const SizedBox(height: 8),
            formDataAsync.when(
              data: (formData) => _buildLabelSelector(formData.labels, selectedLabel),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildLabelSelector(
                ['Maison', 'Bureau', 'Famille', 'Autre'],
                selectedLabel,
              ),
            ),
            const SizedBox(height: 24),

            // Address fields
            _buildSectionTitle('Adresse'),
            const SizedBox(height: 8),
            AddressAutocompleteField(
              controller: _addressController,
              placesService: _placesService,
              label: 'Adresse complète *',
              hint: 'Rechercher une adresse...',
              validator: FormValidators.validateAddress,
              onPlaceSelected: (details) {
                setState(() {
                  _latitude = details.latitude;
                  _longitude = details.longitude;
                  if (details.district != null && _districtController.text.isEmpty) {
                    _districtController.text = details.district!;
                  }
                  if (details.city != null && _cityController.text.isEmpty) {
                    _cityController.text = details.city!;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      labelText: 'Quartier',
                      hintText: 'Ex: Cocody',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      hintText: 'Ex: Abidjan',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // GPS Location
            _buildSectionTitle('Position GPS (optionnel)'),
            const SizedBox(height: 8),
            _buildLocationSection(isLoadingLocation),
            const SizedBox(height: 24),

            // Contact
            _buildSectionTitle('Contact'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone de contact',
                hintText: 'Ex: +225 07 XX XX XX XX',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Instructions
            _buildSectionTitle('Instructions de livraison'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions pour le livreur',
                hintText: 'Ex: Portail bleu, 2ème étage, code: 1234',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Default address toggle
            SwitchListTile(
              title: const Text('Définir comme adresse par défaut'),
              subtitle: Text(
                'Cette adresse sera utilisée par défaut pour vos commandes',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              value: isDefault,
              onChanged: (value) => ref.read(toggleProvider(_isDefaultId).notifier).set(value),
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? AppColors.primary : null),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : () => _submitForm(selectedLabel, isDefault),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enregistrer l\'adresse',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLabelSelector(List<String> labels, String selectedLabel) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final isSelected = selectedLabel == label;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getLabelIcon(label),
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref.read(formFieldsProvider(_selectedLabelId).notifier).setField('label', label);
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        );
      }).toList(),
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

  Widget _buildLocationSection(bool isLoadingLocation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_latitude != null && _longitude != null) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Position GPS enregistrée',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _latitude = null;
                        _longitude = null;
                      });
                    },
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontFamily: 'monospace',
                ),
              ),
            ] else ...[
              Text(
                'Ajoutez votre position GPS pour aider le livreur à vous trouver plus facilement.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoadingLocation ? null : _getCurrentLocation,
                  icon: isLoadingLocation
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    isLoadingLocation
                        ? 'Localisation en cours...'
                        : 'Utiliser ma position actuelle',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    ref.read(loadingProvider(_isLoadingLocationId).notifier).startLoading();

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ErrorHandler.showWarningSnackBar(
              context, 
              'Permission de localisation refusée',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ErrorHandler.showWarningSnackBar(
            context,
            'La localisation est désactivée. Activez-la dans les paramètres.',
          );
        }
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocoding - convertir les coordonnées en adresse
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          
          // Construire l'adresse complète
          final streetParts = <String>[];
          if (place.street != null && place.street!.isNotEmpty) {
            streetParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            streetParts.add(place.subLocality!);
          }
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty && 
              place.thoroughfare != place.street) {
            streetParts.add(place.thoroughfare!);
          }
          
          setState(() {
            // Remplir le champ adresse
            if (streetParts.isNotEmpty) {
              _addressController.text = streetParts.join(', ');
            } else if (place.name != null && place.name!.isNotEmpty) {
              _addressController.text = place.name!;
            }
            
            // Remplir la ville
            if (place.locality != null && place.locality!.isNotEmpty) {
              _cityController.text = place.locality!;
            } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              _cityController.text = place.administrativeArea!;
            }
            
            // Remplir le quartier/district
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              _districtController.text = place.subLocality!;
            } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
              _districtController.text = place.subAdministrativeArea!;
            }
          });
        }
      } catch (geocodeError) {
        // Le reverse geocoding a échoué, mais on a quand même les coordonnées
        AppLogger.location('Reverse geocoding failed', error: geocodeError);
      }

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          _addressController.text.isNotEmpty 
              ? 'Position et adresse enregistrées' 
              : 'Position GPS enregistrée',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Erreur de localisation: $e');
      }
    } finally {
      if (mounted) {
        ref.read(loadingProvider(_isLoadingLocationId).notifier).stopLoading();
      }
    }
  }

  Future<void> _submitForm(String selectedLabel, bool isDefault) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(addressesProvider.notifier).createAddress(
      label: selectedLabel,
      address: _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      isDefault: isDefault,
    );

    if (mounted) {
      if (success) {
        ErrorHandler.showSuccessSnackBar(context, 'Adresse ajoutée avec succès');
        Navigator.pop(context);
      } else {
        final error = ref.read(addressesProvider).error;
        ErrorHandler.showErrorSnackBar(
          context, 
          error ?? 'Erreur lors de l\'ajout de l\'adresse',
        );
      }
    }
  }
}
