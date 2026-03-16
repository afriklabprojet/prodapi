import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen_redesign.dart';
import 'pending_approval_screen.dart';

class KycResubmissionScreen extends ConsumerStatefulWidget {
  final String? rejectionReason;
  
  const KycResubmissionScreen({
    super.key,
    this.rejectionReason,
  });

  @override
  ConsumerState<KycResubmissionScreen> createState() => _KycResubmissionScreenState();
}

class _KycResubmissionScreenState extends ConsumerState<KycResubmissionScreen> {
  final ImagePicker _picker = ImagePicker();
  
  // Documents
  File? _idCardFrontImage;
  File? _idCardBackImage;
  File? _selfieImage;
  File? _drivingLicenseFrontImage;
  File? _drivingLicenseBackImage;
  
  bool _isLoading = false;
  String? _error;
  
  // Documents existants (récupérés de l'API)
  Map<String, bool> _existingDocs = {};

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    try {
      final status = await ref.read(authRepositoryProvider).getKycStatus();
      if (!mounted) return;
      setState(() {
        _existingDocs = Map<String, bool>.from(status['documents'] ?? {});
      });
    } catch (e) {
      // Ignorer l'erreur, on utilise les valeurs par défaut
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'id_card_front':
              _idCardFrontImage = File(image.path);
              break;
            case 'id_card_back':
              _idCardBackImage = File(image.path);
              break;
            case 'selfie':
              _selfieImage = File(image.path);
              break;
            case 'driving_license_front':
              _drivingLicenseFrontImage = File(image.path);
              break;
            case 'driving_license_back':
              _drivingLicenseBackImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image');
    }
  }

  void _showImagePickerDialog(String type, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImagePickerOption(
                    icon: Icons.camera_alt,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera, type);
                    },
                  ),
                  _ImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, type);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDocuments() async {
    // Vérifier qu'au moins un document est sélectionné
    if (_idCardFrontImage == null && 
        _idCardBackImage == null && 
        _selfieImage == null &&
        _drivingLicenseFrontImage == null &&
        _drivingLicenseBackImage == null) {
      _showError('Veuillez sélectionner au moins un document à soumettre');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authRepositoryProvider).resubmitKycDocuments(
        idCardFrontImage: _idCardFrontImage,
        idCardBackImage: _idCardBackImage,
        selfieImage: _selfieImage,
        drivingLicenseFrontImage: _drivingLicenseFrontImage,
        drivingLicenseBackImage: _drivingLicenseBackImage,
      );
      
      if (mounted) {
        final kycStatus = result['kyc_status'] as String?;
        
        if (kycStatus == 'pending_review') {
          // Documents soumis, rediriger vers l'écran d'attente
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen(
                status: 'pending_approval',
                message: 'Vos documents ont été soumis avec succès. Votre dossier est maintenant en cours de vérification par notre équipe.',
              ),
            ),
            (route) => false,
          );
        } else {
          // Documents pas encore complets
          _showSuccess('Documents téléchargés. Veuillez soumettre tous les documents obligatoires.');
          _loadKycStatus(); // Recharger le statut
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Documents KYC'),
        backgroundColor: context.cardBackground,
        foregroundColor: context.primaryText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreenRedesign()),
                  (route) => false,
                );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message d'erreur ou raison de rejet
            if (widget.rejectionReason != null && widget.rejectionReason!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Documents à corriger',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.rejectionReason!,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              'Veuillez soumettre les documents demandés pour compléter votre vérification d\'identité.',
              style: TextStyle(
                color: context.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // CNI Recto
            _DocumentUploadCard(
              title: 'Carte d\'identité (Recto) *',
              subtitle: 'Face avant de votre CNI',
              icon: Icons.badge,
              image: _idCardFrontImage,
              hasExisting: _existingDocs['id_card_front'] ?? false,
              onTap: () => _showImagePickerDialog('id_card_front', 'CNI (Recto)'),
            ),
            const SizedBox(height: 16),

            // CNI Verso
            _DocumentUploadCard(
              title: 'Carte d\'identité (Verso) *',
              subtitle: 'Face arrière de votre CNI',
              icon: Icons.badge_outlined,
              image: _idCardBackImage,
              hasExisting: _existingDocs['id_card_back'] ?? false,
              onTap: () => _showImagePickerDialog('id_card_back', 'CNI (Verso)'),
            ),
            const SizedBox(height: 16),

            // Selfie
            _DocumentUploadCard(
              title: 'Selfie de vérification *',
              subtitle: 'Photo de vous tenant votre CNI',
              icon: Icons.camera_front,
              image: _selfieImage,
              hasExisting: _existingDocs['selfie'] ?? false,
              onTap: () => _showImagePickerDialog('selfie', 'Selfie'),
            ),
            const SizedBox(height: 16),

            // Permis Recto
            _DocumentUploadCard(
              title: 'Permis de conduire (Recto)',
              subtitle: 'Face avant de votre permis',
              icon: Icons.drive_eta,
              image: _drivingLicenseFrontImage,
              hasExisting: _existingDocs['driving_license_front'] ?? false,
              onTap: () => _showImagePickerDialog('driving_license_front', 'Permis (Recto)'),
            ),
            const SizedBox(height: 16),

            // Permis Verso
            _DocumentUploadCard(
              title: 'Permis de conduire (Verso)',
              subtitle: 'Face arrière de votre permis',
              icon: Icons.drive_eta_outlined,
              image: _drivingLicenseBackImage,
              hasExisting: _existingDocs['driving_license_back'] ?? false,
              onTap: () => _showImagePickerDialog('driving_license_back', 'Permis (Verso)'),
            ),
            
            const SizedBox(height: 24),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les champs marqués * sont obligatoires. Vos documents seront vérifiés sous 24-48h.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitDocuments,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Soumettre les documents'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour l'option de sélection d'image
class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.blue.shade600),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Widget pour le card d'upload de document
class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? image;
  final bool hasExisting;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.hasExisting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNewImage = image != null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasNewImage 
              ? Colors.green.shade50 
              : hasExisting 
                  ? Colors.blue.shade50 
                  : context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNewImage 
                ? Colors.green.shade300 
                : hasExisting 
                    ? Colors.blue.shade200 
                    : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (hasNewImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: hasExisting 
                      ? Colors.blue.shade100 
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasExisting ? Icons.check_circle : icon,
                  color: hasExisting 
                      ? Colors.blue.shade600 
                      : Colors.grey.shade600,
                  size: 28,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasNewImage 
                        ? 'Nouveau document sélectionné'
                        : hasExisting 
                            ? 'Document existant - Cliquez pour modifier'
                            : subtitle,
                    style: TextStyle(
                      color: hasNewImage 
                          ? Colors.green.shade700 
                          : hasExisting 
                              ? Colors.blue.shade700 
                              : context.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasNewImage 
                  ? Icons.check_circle 
                  : Icons.add_photo_alternate,
              color: hasNewImage 
                  ? Colors.green.shade600 
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
