import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/update_profile_entity.dart';
import '../providers/profile_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

// Provider IDs pour cette page
const _obscureCurrentPwdId = 'edit_profile_obscure_current';
const _obscureNewPwdId = 'edit_profile_obscure_new';
const _obscureConfirmPwdId = 'edit_profile_obscure_confirm';
const _changingPasswordId = 'edit_profile_changing_password';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Helper method for theme-aware input decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade50,
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize fields with current profile data
    Future.microtask(() {
      final profile = ref.read(profileProvider).profile;
      if (profile != null) {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone ?? '';
      }
      // Initialiser les toggles de mot de passe à true (obscurcir par défaut)
      ref.read(toggleProvider(_obscureCurrentPwdId).notifier).set(true);
      ref.read(toggleProvider(_obscureNewPwdId).notifier).set(true);
      ref.read(toggleProvider(_obscureConfirmPwdId).notifier).set(true);
      // isChangingPassword reste à false par défaut
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Show bottom sheet to pick image from gallery or camera
  Future<void> _pickAndUploadAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A3E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choisir une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Galerie'),
                subtitle: const Text('Choisir depuis vos photos'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Caméra'),
                subtitle: const Text('Prendre une nouvelle photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (source == null || !mounted) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile == null || !mounted) return;
      
      // Read image bytes
      final bytes = await File(pickedFile.path).readAsBytes();
      
      // Upload avatar
      final success = await ref.read(profileProvider.notifier).uploadAvatar(bytes);
      
      if (!mounted) return;
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Photo de profil mise à jour'
                : 'Erreur lors de la mise à jour',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isChangingPassword = ref.read(toggleProvider(_changingPasswordId));
    final updateProfile = UpdateProfileEntity(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      currentPassword:
          isChangingPassword && _currentPasswordController.text.isNotEmpty
          ? _currentPasswordController.text
          : null,
      newPassword: isChangingPassword && _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null,
      newPasswordConfirmation:
          isChangingPassword && _confirmPasswordController.text.isNotEmpty
          ? _confirmPasswordController.text
          : null,
    );

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(updateProfile);

    if (mounted) {
      if (success) {
        AppSnackbar.success(context, 'Profil mis à jour avec succès');
        Navigator.of(context).pop();
      } else {
        final errorMessage = ref.read(profileProvider).errorMessage;
        AppSnackbar.error(context, errorMessage ?? 'Erreur lors de la mise à jour');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isUpdating = profileState.isUpdating;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Providers pour les toggles de visibilité mot de passe
    final obscureCurrentPwd = ref.watch(toggleProvider(_obscureCurrentPwdId));
    final obscureNewPwd = ref.watch(toggleProvider(_obscureNewPwdId));
    final obscureConfirmPwd = ref.watch(toggleProvider(_obscureConfirmPwdId));
    final isChangingPassword = ref.watch(toggleProvider(_changingPasswordId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CachedAvatar(
                          imageUrl: profileState.profile?.avatar,
                          radius: 60,
                          fallbackText: profileState.profile?.initials ?? '?',
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: profileState.isUploadingAvatar
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              onPressed: profileState.isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: profileState.profile?.hasAvatar == true
                          ? () async {
                              if (!mounted) return;

                              // Capture BuildContext and ScaffoldMessenger before any async operation
                              final dialogContext = context;
                              final messenger = ScaffoldMessenger.of(context);

                              final confirmed = await showDialog<bool>(
                                context: dialogContext,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer l\'avatar'),
                                  content: const Text(
                                    'Voulez-vous vraiment supprimer votre photo de profil ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                      ),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && mounted) {
                                final success = await ref
                                    .read(profileProvider.notifier)
                                    .deleteAvatar();

                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Avatar supprimé'
                                            : 'Erreur lors de la suppression',
                                      ),
                                      backgroundColor: success
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer l\'avatar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Personal Information Section
              Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icons.person,
                  isDark: isDark,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icons.email,
                  isDark: isDark,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est requis';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  prefixIcon: Icons.phone,
                  isDark: isDark,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 8) {
                      return 'Le numéro doit contenir au moins 8 caractères';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Password Change Section
              Row(
                children: [
                  Text(
                    'Changer le mot de passe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isChangingPassword,
                    onChanged: (value) {
                      ref.read(toggleProvider(_changingPasswordId).notifier).set(value);
                      if (!value) {
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      }
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),

              if (isChangingPassword) ...[
                const SizedBox(height: 16),

                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !obscureCurrentPwd,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: Icons.lock_outline,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        !obscureCurrentPwd
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        ref.read(toggleProvider(_obscureCurrentPwdId).notifier).toggle();
                      },
                    ),
                  ),
                  validator: (value) {
                    if (isChangingPassword) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe actuel est requis';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !obscureNewPwd,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: Icons.lock,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        !obscureNewPwd
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        ref.read(toggleProvider(_obscureNewPwdId).notifier).toggle();
                      },
                    ),
                  ),
                  validator: (value) {
                    if (isChangingPassword) {
                      if (value == null || value.isEmpty) {
                        return 'Le nouveau mot de passe est requis';
                      }
                      if (value.length < 8) {
                        return 'Le mot de passe doit contenir au moins 8 caractères';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !obscureConfirmPwd,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: Icons.lock,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        !obscureConfirmPwd
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        ref.read(toggleProvider(_obscureConfirmPwdId).notifier).toggle();
                      },
                    ),
                  ),
                  validator: (value) {
                    if (isChangingPassword) {
                      if (value == null || value.isEmpty) {
                        return 'La confirmation est requise';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
