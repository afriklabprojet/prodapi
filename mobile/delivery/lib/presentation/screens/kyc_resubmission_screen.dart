import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/router/route_names.dart';
import '../../data/repositories/auth_repository.dart';

class KycResubmissionScreen extends ConsumerStatefulWidget {
  final String? rejectionReason;

  const KycResubmissionScreen({super.key, this.rejectionReason});

  @override
  ConsumerState<KycResubmissionScreen> createState() =>
      _KycResubmissionScreenState();
}

class _KycResubmissionScreenState extends ConsumerState<KycResubmissionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // Documents
  File? _idCardFrontImage;
  File? _idCardBackImage;
  File? _selfieImage;
  File? _drivingLicenseFrontImage;
  File? _drivingLicenseBackImage;

  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _error;

  // Documents existants (récupérés de l'API)
  Map<String, bool> _existingDocs = {};
  bool _livenessVerified = false;

  // Animation controller pour le header
  late AnimationController _headerAnimController;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadKycStatus();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
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
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image == null) return;

      final file = File(image.path);

      // Validation qualité
      final qualityResult = await _validateImageQuality(file);
      if (!qualityResult.isValid && mounted) {
        _showImageQualityWarning(qualityResult, () async {
          // L'utilisateur veut quand même utiliser l'image
          final compressed = await _compressImage(file);
          _setDocumentImage(type, compressed);
        });
        return;
      }

      // Compression intelligente
      final compressed = await _compressImage(file);

      // Preview avant validation
      if (mounted) {
        _showDocumentPreview(compressed, type, _getDocTitle(type));
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image');
    }
  }

  /// Validation de la qualité de l'image
  Future<_ImageQualityResult> _validateImageQuality(File file) async {
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final warnings = <String>[];

    // Vérifier la taille minimale (50 KB)
    if (fileSize < 50 * 1024) {
      warnings.add('Image trop petite (résolution insuffisante)');
    }

    // Vérifier la taille maximale (10 MB)
    if (fileSize > 10 * 1024 * 1024) {
      warnings.add('Image très volumineuse — sera compressée');
    }

    // Décoder pour vérifier les dimensions
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      if (decoded.width < 400 || decoded.height < 300) {
        warnings.add('Résolution trop faible (min 400×300)');
      }

      // Détection basique de flou via variance du Laplacian
      final blurScore = _computeBlurScore(decoded);
      if (blurScore < 50) {
        warnings.add('Image potentiellement floue — reprenez la photo');
      }
    } else {
      warnings.add('Impossible de lire l\'image');
    }

    return _ImageQualityResult(
      isValid: warnings.isEmpty,
      warnings: warnings,
      fileSize: fileSize,
      width: decoded?.width ?? 0,
      height: decoded?.height ?? 0,
    );
  }

  /// Score de netteté via variance du Laplacian simplifié
  double _computeBlurScore(img.Image image) {
    // Sous-échantillonner pour la performance
    final small = img.copyResize(image, width: 200);
    final gray = img.grayscale(small);

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final center = gray.getPixel(x, y).r.toDouble() * 4;
        final top = gray.getPixel(x, y - 1).r.toDouble();
        final bottom = gray.getPixel(x, y + 1).r.toDouble();
        final left = gray.getPixel(x - 1, y).r.toDouble();
        final right = gray.getPixel(x + 1, y).r.toDouble();
        final laplacian = center - top - bottom - left - right;

        sum += laplacian;
        sumSq += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean); // Variance
  }

  /// Compression intelligente de l'image
  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;

    // Si < 500KB, pas besoin de compresser
    if (fileSize <= 500 * 1024) return file;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    // Redimensionner si > 1600px
    img.Image resized = decoded;
    if (decoded.width > 1600 || decoded.height > 1600) {
      resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 1600 : null,
        height: decoded.height >= decoded.width ? 1600 : null,
      );
    }

    // Déterminer la qualité en fonction de la taille
    int quality = 85;
    if (fileSize > 5 * 1024 * 1024) {
      quality = 60;
    } else if (fileSize > 2 * 1024 * 1024) {
      quality = 70;
    }

    final compressed = img.encodeJpg(resized, quality: quality);

    final tempPath =
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressedFile = File(tempPath);
    await compressedFile.writeAsBytes(compressed);

    return compressedFile;
  }

  /// Définir l'image du document par type
  void _setDocumentImage(String type, File file) {
    setState(() {
      switch (type) {
        case 'id_card_front':
          _idCardFrontImage = file;
        case 'id_card_back':
          _idCardBackImage = file;
        case 'selfie':
          _selfieImage = file;
        case 'driving_license_front':
          _drivingLicenseFrontImage = file;
        case 'driving_license_back':
          _drivingLicenseBackImage = file;
      }
    });
  }

  /// Obtenir le titre d'un type de document
  String _getDocTitle(String type) {
    switch (type) {
      case 'id_card_front':
        return 'CNI (Recto)';
      case 'id_card_back':
        return 'CNI (Verso)';
      case 'selfie':
        return 'Selfie de vérification';
      case 'driving_license_front':
        return 'Permis (Recto)';
      case 'driving_license_back':
        return 'Permis (Verso)';
      default:
        return 'Document';
    }
  }

  /// Obtenir les conseils de capture pour un type de document
  List<String> _getDocumentTips(String type) {
    switch (type) {
      case 'id_card_front':
      case 'id_card_back':
        return [
          'Posez la carte sur un fond uni et clair',
          'Assurez-vous que les 4 coins sont visibles',
          'Évitez les reflets et les ombres',
          'Le texte doit être lisible nettement',
        ];
      case 'selfie':
        return [
          'Tenez votre CNI à côté de votre visage',
          'Regardez directement la caméra',
          'Assurez un bon éclairage (lumière naturelle)',
          'Pas de lunettes de soleil ni de chapeau',
        ];
      case 'driving_license_front':
      case 'driving_license_back':
        return [
          'Posez le permis sur un fond uni',
          'Tous les bords doivent être visibles',
          'La photo et le texte doivent être nets',
          'Pas de reflets sur le document',
        ];
      default:
        return ['Prenez une photo claire et nette'];
    }
  }

  /// Afficher un avertissement de qualité
  void _showImageQualityWarning(
    _ImageQualityResult result,
    VoidCallback onContinue,
  ) {
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2030) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Qualité de l\'image',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                ...result.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            w,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onContinue();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Utiliser quand même',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Reprendre la photo',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Afficher le preview d'un document avec zoom
  void _showDocumentPreview(File file, String type, String title) {
    final isDark = context.isDark;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2030) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.preview_rounded,
                    color: DesignTokens.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.secondaryText,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Preview avec zoom
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2030) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showImagePickerDialog(type, title);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Reprendre',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _setDocumentImage(type, file);
                        _showSuccess('Document ajouté ✓');
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        'Valider',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le preview plein écran (tap sur un document existant)
  void _showFullScreenPreview(File file, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog(String type, String title) {
    final isDark = context.isDark;
    final tips = _getDocumentTips(type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2030) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez une source pour le document',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),

                // ── Conseils de capture ──
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignTokens.info.withValues(alpha: 0.1)
                        : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? DesignTokens.info.withValues(alpha: 0.2)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: isDark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Conseils pour une bonne photo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blue.shade400
                                      : Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    height: 1.3,
                                    color: isDark
                                        ? Colors.blue.shade200
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        isDark: isDark,
                        icon: Icons.camera_alt_rounded,
                        label: 'Caméra',
                        subtitle: 'Recommandé',
                        color: DesignTokens.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera, type);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildPickerOption(
                        isDark: isDark,
                        icon: Icons.photo_library_rounded,
                        label: 'Galerie',
                        subtitle: 'Photo existante',
                        color: DesignTokens.info,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery, type);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
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
      _uploadProgress = 0.0;
      _error = null;
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .resubmitKycDocuments(
            idCardFrontImage: _idCardFrontImage,
            idCardBackImage: _idCardBackImage,
            selfieImage: _selfieImage,
            drivingLicenseFrontImage: _drivingLicenseFrontImage,
            drivingLicenseBackImage: _drivingLicenseBackImage,
            onSendProgress: (sent, total) {
              if (total > 0 && mounted) {
                setState(() {
                  _uploadProgress = sent / total;
                });
              }
            },
          );

      if (mounted) {
        final kycStatus = result['kyc_status'] as String?;

        if (kycStatus == 'pending_review') {
          // Documents soumis, rediriger vers l'écran d'attente
          context.go(
            AppRoutes.pendingApproval,
            extra: {
              'status': 'pending_approval',
              'message':
                  'Vos documents ont été soumis avec succès. Votre dossier est maintenant en cours de vérification par notre équipe.',
            },
          );
        } else {
          // Documents pas encore complets
          _showSuccess(
            'Documents téléchargés. Veuillez soumettre tous les documents obligatoires.',
          );
          _loadKycStatus(); // Recharger le statut
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
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
    final isDark = context.isDark;
    final completedCount = _getCompletedCount();
    const totalRequired = 3; // CNI recto, verso, selfie

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            // ── Header avec gradient ──
            SliverToBoxAdapter(
              child: _buildHeader(
                context,
                isDark,
                completedCount,
                totalRequired,
              ),
            ),

            // ── Contenu ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Message de rejet
                  if (widget.rejectionReason != null &&
                      widget.rejectionReason!.isNotEmpty) ...[
                    _buildRejectionBanner(context, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Erreur
                  if (_error != null) ...[
                    _buildErrorBanner(context, isDark),
                    const SizedBox(height: 16),
                  ],

                  // Section: Pièce d'identité
                  _buildSectionTitle(
                    context,
                    isDark,
                    'Pièce d\'identité',
                    Icons.badge_rounded,
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    context,
                    isDark,
                    title: 'Recto de la CNI',
                    subtitle: 'Face avant de votre carte d\'identité',
                    icon: Icons.credit_card_rounded,
                    image: _idCardFrontImage,
                    hasExisting: _existingDocs['id_card_front'] ?? false,
                    onTap: () =>
                        _showImagePickerDialog('id_card_front', 'CNI (Recto)'),
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    context,
                    isDark,
                    title: 'Verso de la CNI',
                    subtitle: 'Face arrière de votre carte d\'identité',
                    icon: Icons.credit_card_rounded,
                    image: _idCardBackImage,
                    hasExisting: _existingDocs['id_card_back'] ?? false,
                    onTap: () =>
                        _showImagePickerDialog('id_card_back', 'CNI (Verso)'),
                    isRequired: true,
                  ),

                  const SizedBox(height: 28),

                  // Section: Selfie
                  _buildSectionTitle(
                    context,
                    isDark,
                    'Photo de vérification',
                    Icons.camera_front_rounded,
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    context,
                    isDark,
                    title: 'Selfie avec CNI',
                    subtitle: 'Tenez votre CNI à côté de votre visage',
                    icon: Icons.face_retouching_natural_rounded,
                    image: _selfieImage,
                    hasExisting: _existingDocs['selfie'] ?? false,
                    onTap: () => _showImagePickerDialog(
                      'selfie',
                      'Selfie de vérification',
                    ),
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),

                  // Liveness verification
                  _buildLivenessCard(context, isDark),

                  const SizedBox(height: 28),

                  // Section: Permis (optionnel)
                  _buildSectionTitle(
                    context,
                    isDark,
                    'Permis de conduire',
                    Icons.drive_eta_rounded,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    context,
                    isDark,
                    title: 'Recto du permis',
                    subtitle: 'Face avant de votre permis de conduire',
                    icon: Icons.drive_eta_rounded,
                    image: _drivingLicenseFrontImage,
                    hasExisting:
                        _existingDocs['driving_license_front'] ?? false,
                    onTap: () => _showImagePickerDialog(
                      'driving_license_front',
                      'Permis (Recto)',
                    ),
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    context,
                    isDark,
                    title: 'Verso du permis',
                    subtitle: 'Face arrière de votre permis de conduire',
                    icon: Icons.drive_eta_outlined,
                    image: _drivingLicenseBackImage,
                    hasExisting: _existingDocs['driving_license_back'] ?? false,
                    onTap: () => _showImagePickerDialog(
                      'driving_license_back',
                      'Permis (Verso)',
                    ),
                    isRequired: false,
                  ),

                  const SizedBox(height: 28),

                  // Info box
                  _buildInfoBox(context, isDark),

                  const SizedBox(height: 28),

                  // Bouton de soumission
                  _buildSubmitButton(
                    context,
                    isDark,
                    completedCount,
                    totalRequired,
                  ),

                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCompletedCount() {
    int count = 0;
    if (_idCardFrontImage != null ||
        (_existingDocs['id_card_front'] ?? false)) {
      count++;
    }
    if (_idCardBackImage != null || (_existingDocs['id_card_back'] ?? false)) {
      count++;
    }
    if (_selfieImage != null || (_existingDocs['selfie'] ?? false)) {
      count++;
    }
    return count;
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    int completed,
    int total,
  ) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2940), const Color(0xFF0D1B2A)]
              : [DesignTokens.primary, const Color(0xFF0A5236)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Déconnexion',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Shield icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Vérification d\'identité',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Soumettez vos documents pour activer votre compte livreur',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              '$completed / $total obligatoires',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completed == total
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildRejectionBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade50.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documents à corriger',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.rejectionReason!,
                  style: GoogleFonts.inter(
                    color: Colors.orange.shade800,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon, {
    required bool isRequired,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.primary.withValues(alpha: 0.2)
                : DesignTokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? DesignTokens.primaryLight : DesignTokens.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
        ),
        if (isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.shade900.withValues(alpha: 0.3)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Obligatoire',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Optionnel',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required bool hasExisting,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    final hasNewImage = image != null;
    final isComplete = hasNewImage || hasExisting;

    final Color cardBg;
    final Color borderColor;
    final Color iconBg;
    final Color iconColor;

    if (hasNewImage) {
      cardBg = isDark ? const Color(0xFF0F2818) : const Color(0xFFF0FDF4);
      borderColor = isDark ? Colors.green.shade700 : Colors.green.shade300;
      iconBg = isDark
          ? Colors.green.shade800.withValues(alpha: 0.5)
          : Colors.green.shade100;
      iconColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (hasExisting) {
      cardBg = isDark
          ? DesignTokens.primary.withValues(alpha: 0.1)
          : const Color(0xFFF0FAF5);
      borderColor = isDark
          ? DesignTokens.primary.withValues(alpha: 0.4)
          : DesignTokens.primary.withValues(alpha: 0.3);
      iconBg = isDark
          ? DesignTokens.primary.withValues(alpha: 0.2)
          : DesignTokens.primary.withValues(alpha: 0.1);
      iconColor = isDark ? DesignTokens.primaryLight : DesignTokens.primary;
    } else {
      cardBg = isDark ? const Color(0xFF1A2030) : Colors.white;
      borderColor = isDark ? const Color(0xFF2D3E4E) : const Color(0xFFE2E8F0);
      iconBg = isDark ? const Color(0xFF252D3D) : const Color(0xFFF1F5F9);
      iconColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail ou icône
              if (hasNewImage)
                GestureDetector(
                  onLongPress: () => _showFullScreenPreview(image, title),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasExisting ? Icons.check_circle_rounded : icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

              const SizedBox(width: 14),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: context.primaryText,
                            ),
                          ),
                        ),
                        if (isRequired && !isComplete)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasNewImage
                          ? '✓ Nouveau document ajouté'
                          : hasExisting
                          ? '✓ Document existant — tap pour modifier'
                          : subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: hasNewImage
                            ? (isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700)
                            : hasExisting
                            ? (isDark
                                  ? DesignTokens.primaryLight
                                  : DesignTokens.primary)
                            : context.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isComplete
                      ? (isDark
                            ? Colors.green.shade800.withValues(alpha: 0.3)
                            : Colors.green.shade50)
                      : (isDark
                            ? const Color(0xFF252D3D)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isComplete ? Icons.check_rounded : Icons.add_a_photo_rounded,
                  size: 18,
                  color: isComplete
                      ? (isDark ? Colors.green.shade300 : Colors.green.shade600)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivenessCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: _livenessVerified
          ? null
          : () async {
              final result = await context.push<bool>(
                AppRoutes.livenessVerification,
              );
              if (result == true && mounted) {
                setState(() => _livenessVerified = true);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _livenessVerified
              ? (isDark
                    ? DesignTokens.success.withValues(alpha: 0.1)
                    : DesignTokens.success.withValues(alpha: 0.05))
              : (isDark
                    ? DesignTokens.primary.withValues(alpha: 0.1)
                    : DesignTokens.primary.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: _livenessVerified
                ? DesignTokens.success.withValues(alpha: 0.4)
                : DesignTokens.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _livenessVerified
                      ? [
                          DesignTokens.success,
                          DesignTokens.success.withValues(alpha: 0.7),
                        ]
                      : [DesignTokens.primary, DesignTokens.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                _livenessVerified
                    ? Icons.verified_rounded
                    : Icons.face_retouching_natural_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vérification de vie',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _livenessVerified
                        ? 'Vérification réussie ✓'
                        : 'Appuyez pour vérifier votre identité en direct',
                    style: TextStyle(
                      fontSize: 12,
                      color: _livenessVerified
                          ? DesignTokens.success
                          : (isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            if (!_livenessVerified)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.info.withValues(alpha: 0.1)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? DesignTokens.info.withValues(alpha: 0.3)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.info.withValues(alpha: 0.2)
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bon à savoir',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les documents obligatoires (*) doivent être soumis pour activer votre compte. La vérification prend 24-48h ouvrées.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    bool isDark,
    int completed,
    int total,
  ) {
    final canSubmit =
        _idCardFrontImage != null ||
        _idCardBackImage != null ||
        _selfieImage != null ||
        _drivingLicenseFrontImage != null ||
        _drivingLicenseBackImage != null;

    return Column(
      children: [
        // ── Barre de progression d'upload ──
        if (_isLoading && _uploadProgress > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.primary.withValues(alpha: 0.1)
                  : DesignTokens.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DesignTokens.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _uploadProgress,
                            color: DesignTokens.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Envoi en cours...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DesignTokens.primaryLight
                                : DesignTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 6,
                    backgroundColor: DesignTokens.primary.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DesignTokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: canSubmit && !_isLoading
                  ? LinearGradient(
                      colors: [DesignTokens.primary, DesignTokens.primaryDark],
                    )
                  : null,
              color: canSubmit && !_isLoading
                  ? null
                  : (isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              boxShadow: canSubmit && !_isLoading
                  ? [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _submitDocuments,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Envoi des documents...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Soumettre les documents',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),

        if (completed < total) ...[
          const SizedBox(height: 10),
          Text(
            'Il manque ${total - completed} document${total - completed > 1 ? 's' : ''} obligatoire${total - completed > 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Résultat de la validation qualité d'une image
class _ImageQualityResult {
  final bool isValid;
  final List<String> warnings;
  final int fileSize;
  final int width;
  final int height;

  const _ImageQualityResult({
    required this.isValid,
    required this.warnings,
    required this.fileSize,
    required this.width,
    required this.height,
  });
}
