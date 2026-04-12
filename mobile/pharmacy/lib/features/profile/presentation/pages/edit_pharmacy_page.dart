import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/presentation/mixins/form_guard_mixin.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/pharmacy_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/duty_zones_provider.dart';
import '../providers/profile_provider.dart';


class EditPharmacyPage extends ConsumerStatefulWidget {
  final PharmacyEntity pharmacy;

  const EditPharmacyPage({super.key, required this.pharmacy});

  @override
  ConsumerState<EditPharmacyPage> createState() => _EditPharmacyPageState();
}

class _EditPharmacyPageState extends ConsumerState<EditPharmacyPage> with FormGuardMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _emailController;
  late TextEditingController _licenseNumberController;
  int? _selectedDutyZoneId;

  final ImagePicker _picker = ImagePicker();
  XFile? _licenseFile;
  XFile? _idCardFile;

  // GPS coordinates
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  GoogleMapController? _mapController;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pharmacy.name);
    _phoneController = TextEditingController(text: widget.pharmacy.phone);
    _addressController = TextEditingController(text: widget.pharmacy.address);
    _cityController = TextEditingController(text: widget.pharmacy.city);
    _emailController = TextEditingController(text: widget.pharmacy.email);
    _licenseNumberController = TextEditingController(text: widget.pharmacy.licenseNumber);
    _selectedDutyZoneId = widget.pharmacy.dutyZoneId;
    _latitude = widget.pharmacy.latitude;
    _longitude = widget.pharmacy.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isLicense) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isLicense) {
          _licenseFile = image;
        } else {
          _idCardFile = image;
        }
      });
    }
  }

  /// Détecter automatiquement les coordonnées GPS
  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Activez les services de localisation sur votre téléphone';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permission refusée définitivement. Activez-la dans les paramètres.';
          _isLocating = false;
        });
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocating = false;
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(_latitude!, _longitude!)),
        );
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Impossible de détecter votre position. Réessayez.';
        _isLocating = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      dynamic data;
      
      // Check if we need FormData (if files are present)
      if (_licenseFile != null || _idCardFile != null) {
        final formData = FormData.fromMap({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'license_number': _licenseNumberController.text,
          if (_selectedDutyZoneId != null) 'duty_zone_id': _selectedDutyZoneId,
          if (_emailController.text.isNotEmpty) 'email': _emailController.text,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
        });

        if (_licenseFile != null) {
          final bytes = await _licenseFile!.readAsBytes();
          formData.files.add(MapEntry(
            'license_document',
            MultipartFile.fromBytes(bytes, filename: _licenseFile!.name),
          ));
        }

        if (_idCardFile != null) {
          final bytes = await _idCardFile!.readAsBytes();
          formData.files.add(MapEntry(
            'id_card_document',
            MultipartFile.fromBytes(bytes, filename: _idCardFile!.name),
          ));
        }
        
        data = formData;
      } else {
        // Simple JSON update
        data = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'license_number': _licenseNumberController.text,
          'duty_zone_id': _selectedDutyZoneId,
          'email': _emailController.text.isNotEmpty ? _emailController.text : null,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
        };
      }

      await ref.read(profileProvider.notifier).updatePharmacy(widget.pharmacy.id, data);
      
      final state = ref.read(profileProvider);
      if (state.hasError) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.error}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pharmacie mise à jour avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          markClean();
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final isLoading = state.isLoading;
    final dutyZonesValue = ref.watch(dutyZonesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get the latest pharmacy data from auth provider
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final PharmacyEntity currentPharmacy = user?.pharmacies.firstWhere(
      (p) => p.id == widget.pharmacy.id,
      orElse: () => widget.pharmacy,
    ) ?? widget.pharmacy;

    return buildGuardedScaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: Text('Gérer ma Pharmacie', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () => markDirty(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Informations Générales'),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _nameController,
                        label: 'Nom de la Pharmacie',
                        icon: Icons.store_mall_directory_outlined,
                        validator: (v) => v!.isEmpty ? 'Le nom est requis' : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Localisation'),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _cityController,
                        label: 'Ville / Quartier',
                        icon: Icons.location_city_outlined,
                        validator: (v) => v!.isEmpty ? 'La ville est requise' : null,
                      ),
                      const SizedBox(height: 16),
                      // Zone de Garde Dropdown
                      dutyZonesValue.when(
                        data: (zones) => DropdownButtonFormField<int>(
                          initialValue: _selectedDutyZoneId,
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Zone de Garde',
                            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                            prefixIcon: Icon(Icons.share_location_outlined, color: isDark ? Colors.grey[400] : Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                          ),
                          items: zones.map((zone) => DropdownMenuItem(
                            value: zone.id,
                            child: Text(zone.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          )).toList(),
                          onChanged: (val) {
                             setState(() => _selectedDutyZoneId = val);
                          },
                          validator: (val) => val == null ? 'Veuillez sélectionner une zone' : null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, stack) => Text('Erreur chargement zones: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller: _addressController,
                        label: 'Adresse exacte (ex: En face de la mairie)',
                        icon: Icons.map_outlined,
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'L\'adresse est requise' : null,
                      ),
                      const SizedBox(height: 16),
                      // GPS Coordinates
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[850] : Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gps_fixed, color: isDark ? Colors.grey[400] : Colors.grey[500], size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Coordonnées GPS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_latitude != null && _longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: Text(
                                  'Aucune position enregistrée',
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                                ),
                              ),
                            if (_locationError != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 34, top: 4),
                                child: Text(
                                  _locationError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            if (_latitude != null && _longitude != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 180,
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(_latitude!, _longitude!),
                                      zoom: 16,
                                    ),
                                    onMapCreated: (controller) => _mapController = controller,
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('pharmacy'),
                                        position: LatLng(_latitude!, _longitude!),
                                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                      ),
                                    },
                                    zoomControlsEnabled: false,
                                    myLocationButtonEnabled: false,
                                    mapToolbarEnabled: false,
                                    scrollGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLocating ? null : _detectLocation,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        _latitude != null ? Icons.refresh : Icons.my_location,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isLocating
                                      ? 'Détection en cours...'
                                      : (_latitude != null ? 'Actualiser la position' : 'Détecter ma position'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionTitle(context, 'Documents & Vérification'),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _licenseNumberController,
                        label: 'Numéro de Licence',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildFilePicker(
                        context: context,
                        title: 'Document de Licence',
                        file: _licenseFile,
                        onTap: () => _pickFile(true),
                        isUploaded: currentPharmacy.licenseDocument != null && currentPharmacy.licenseDocument!.isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      _buildFilePicker(
                        context: context,
                        title: 'CNI / Pièce d\'Identité',
                        file: _idCardFile,
                        onTap: () => _pickFile(false),
                        isUploaded: currentPharmacy.idCardDocument != null && currentPharmacy.idCardDocument!.isNotEmpty,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Contact'),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        controller: _phoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Le téléphone est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller: _emailController,
                        label: 'Email professionnel (Optionnel)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[500], size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
      ),
    );
  }

  Widget _buildFilePicker({
    required BuildContext context,
    required String title,
    required XFile? file,
    required VoidCallback onTap,
    bool isUploaded = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey[850] : Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : (isUploaded ? Icons.verified : Icons.upload_file),
              color: file != null ? Colors.green : (isUploaded ? Colors.blue : (isDark ? Colors.grey[400] : Colors.grey)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                  Text(
                    file != null ? file.name : (isUploaded ? "Document reçu (Cliquez pour modifier)" : "Aucun fichier sélectionné"),
                    style: TextStyle(
                      color: file != null ? Colors.green : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey),
          ],
        ),
      ),
    );
  }
}
