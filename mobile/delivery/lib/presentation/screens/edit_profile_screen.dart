import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../providers/profile_provider.dart';
import '../../core/utils/snackbar_extension.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/profile/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _plateCtrl;
  late String _selectedVehicle;
  bool _saving = false;

  static const _vehicleOptions = [
    ('motorcycle', 'Moto', Icons.two_wheeler_rounded),
    ('car', 'Voiture', Icons.directions_car_rounded),
    ('scooter', 'Scooter', Icons.electric_scooter_rounded),
    ('bicycle', 'Vélo', Icons.pedal_bike_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _plateCtrl = TextEditingController(
      text: widget.user.courier?.vehicleNumber ?? '',
    );
    _selectedVehicle = widget.user.courier?.vehicleType ?? 'motorcycle';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final u = widget.user;
    return _nameCtrl.text.trim() != u.name ||
        _phoneCtrl.text.trim() != (u.phone ?? '') ||
        _plateCtrl.text.trim() != (u.courier?.vehicleNumber ?? '') ||
        _selectedVehicle != (u.courier?.vehicleType ?? 'motorcycle');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    _buildAvatarSection(),
                    const SizedBox(height: 32),

                    // Personal info
                    _sectionLabel('Informations personnelles'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Nom complet',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: '+225 07 XX XX XX XX',
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final clean = v.replaceAll(RegExp(r'[\s\-\.]'), '');
                          if (clean.length < 8) return 'Numéro trop court';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: widget.user.email,
                      icon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 32),

                    // Vehicle info
                    _sectionLabel('Véhicule'),
                    const SizedBox(height: 12),
                    _buildVehicleSelector(),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _plateCtrl,
                      label: 'Numéro de plaque',
                      icon: Icons.badge_outlined,
                      hint: 'AB 1234 CI',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\s\-]'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: const Color(
                            0xFF059669,
                          ).withValues(alpha: 0.5),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPad + 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF374151),
            ),
            const Expanded(
              child: Text(
                'Modifier le profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D26),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ProfileAvatar(
            name: widget.user.name,
            imageUrl: widget.user.avatar,
            size: 100,
            onTap: _showPhotoOptions,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showPhotoOptions,
            child: const Text(
              'Changer la photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1D26),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _vehicleOptions.map((opt) {
          final (key, label, icon) = opt;
          final selected = _selectedVehicle == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedVehicle = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF059669).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF059669)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF059669)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF059669)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === Save ===

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      context.pop();
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(deliveryRepositoryProvider)
          .updateCourierProfile(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isNotEmpty
                ? _phoneCtrl.text.trim()
                : null,
            vehicleType: _selectedVehicle,
            vehicleNumber: _plateCtrl.text.trim(),
          );

      ref.invalidate(profileProvider);

      if (mounted) {
        context.showSuccess('Profil mis à jour');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        context.showErrorMessage(msg);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // === Photo ===

  void _showPhotoOptions() {
    final hasAvatar =
        widget.user.avatar != null && widget.user.avatar!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Photo de profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D26),
                ),
              ),
              const SizedBox(height: 16),
              _photoOption(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              _photoOption(
                icon: Icons.camera_alt_rounded,
                label: 'Caméra',
                color: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              if (hasAvatar)
                _photoOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Supprimer la photo',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color == const Color(0xFFEF4444)
              ? color
              : const Color(0xFF374151),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      if (!mounted) return;
      LoadingDialog.show(context, message: 'Envoi de la photo...');

      final bytes = await picked.readAsBytes();
      await ref.read(authRepositoryProvider).uploadAvatar(bytes);
      ref.invalidate(profileProvider);

      if (mounted) {
        LoadingDialog.hide(context);
        context.showSuccess('Photo de profil mise à jour');
      }
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        context.showErrorMessage(msg);
      }
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      LoadingDialog.show(context, message: 'Suppression...');
      await ref.read(authRepositoryProvider).deleteAvatar();
      ref.invalidate(profileProvider);
      if (mounted) {
        LoadingDialog.hide(context);
        context.showSuccess('Photo supprimée');
      }
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        context.showErrorMessage(msg);
      }
    }
  }
}
