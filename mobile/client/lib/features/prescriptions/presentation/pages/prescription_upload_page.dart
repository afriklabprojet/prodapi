import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../providers/prescriptions_provider.dart';

// Provider ID for this page
const _uploadLoadingId = 'prescription_upload_loading';

class PrescriptionUploadPage extends ConsumerStatefulWidget {
  const PrescriptionUploadPage({super.key});

  @override
  ConsumerState<PrescriptionUploadPage> createState() =>
      _PrescriptionUploadPageState();
}

class _PrescriptionUploadPageState
    extends ConsumerState<PrescriptionUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final TextEditingController _notesController = TextEditingController();
  bool _allowPop = false;
  // _isUploading migrated to loadingProvider(_uploadLoadingId)

  bool get _hasUnsavedChanges =>
      _selectedImages.isNotEmpty || _notesController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter cette page ?'),
            content: const Text(
              'Vos photos et notes non envoyées seront perdues si vous quittez maintenant.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuer l\'édition'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Quitter'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleBackNavigation() async {
    if (ref.read(loadingProvider(_uploadLoadingId)).isLoading) return;

    final shouldLeave = await _confirmDiscardChanges();
    if (!shouldLeave || !mounted) return;

    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de sélectionner l\'image. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette photo sera retirée de votre envoi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showReconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session expirée'),
        content: const Text(
          'Votre session a expiré. Veuillez vous reconnecter pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page and clear the stack
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPrescription() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une photo d\'ordonnance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(loadingProvider(_uploadLoadingId).notifier).startLoading();
    HapticFeedback.mediumImpact();

    try {
      // Upload prescription with API call
      await ref
          .read(prescriptionsProvider.notifier)
          .uploadPrescription(
            images: _selectedImages,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        final prescState = ref.read(prescriptionsProvider);

        if (prescState.lastUploadIsDuplicate) {
          // Show duplicate warning dialog before navigating back
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 48,
              ),
              title: const Text('Doublon détecté'),
              content: Text(
                'Cette ordonnance semble avoir déjà été soumise'
                '${prescState.lastUploadExistingId != null ? ' (Ordonnance #${prescState.lastUploadExistingId})' : ''}.\n\n'
                'Votre soumission a été enregistrée, mais veuillez vérifier vos ordonnances existantes pour éviter les doublons.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ordonnance envoyée avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'envoi';

        // Check for authentication/authorization errors
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          // Optionally redirect to login
          _showReconnectDialog();
          return;
        } else if (e.toString().contains('403') ||
            e.toString().contains('PHONE_NOT_VERIFIED')) {
          errorMessage =
              'Veuillez vérifier votre numéro de téléphone pour envoyer une ordonnance';
        } else if (e.toString().contains('422') ||
            e.toString().contains('Validation')) {
          errorMessage =
              'Format d\'image non supporté. Utilisez JPG, PNG ou GIF.';
        } else if (e.toString().contains('413') ||
            e.toString().contains('too large')) {
          errorMessage = 'Image trop volumineuse. Taille max: 10 Mo.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection')) {
          errorMessage = 'Erreur de connexion. Vérifiez votre internet.';
        } else {
          errorMessage = 'Erreur lors de l\'envoi. Veuillez réessayer.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(loadingProvider(_uploadLoadingId).notifier).stopLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(loadingProvider(_uploadLoadingId)).isLoading;

    return PopScope(
      canPop: (_allowPop || !_hasUnsavedChanges) && !isUploading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !mounted) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: _handleBackNavigation,
          ),
          title: const Text('Upload d\'ordonnance'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: isUploading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Envoi en cours...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Comment ça marche ?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Prenez une photo claire de votre ordonnance\n'
                              '2. Ajoutez des notes si nécessaire\n'
                              '3. Envoyez pour validation\n'
                              '4. Recevez une notification de confirmation',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Images Section
                    const Text(
                      'Photos de l\'ordonnance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedImages.isEmpty)
                      _buildEmptyImagesState()
                    else
                      _buildImagesGrid(),

                    const SizedBox(height: 16),

                    // Add Image Button
                    OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Ajouter une photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notes Section
                    const Text(
                      'Notes complémentaires (optionnel)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Ajoutez des informations complémentaires pour la pharmacie...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade100,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _selectedImages.isEmpty
                          ? null
                          : _submitPrescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3C3C3C)
                            : Colors.grey.shade300,
                      ),
                      child: const Text(
                        'Envoyer pour validation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Warning Text
                    Text(
                      '⚠️ Assurez-vous que toutes les informations de l\'ordonnance '
                      'sont clairement visibles sur la photo.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyImagesState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return Container(
      height: isCompact ? 170 : 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: isCompact ? 52 : 64,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune photo ajoutée',
            style: TextStyle(
              fontSize: isCompact ? 15 : 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez sur "Ajouter une photo" ci-dessous',
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 700 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImages[index].path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                    semanticLabel: 'Supprimer l\'image',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
