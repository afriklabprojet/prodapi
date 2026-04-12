import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../providers/prescription_ocr_provider.dart';

class PrescriptionScannerPage extends ConsumerStatefulWidget {
  const PrescriptionScannerPage({super.key});

  @override
  ConsumerState<PrescriptionScannerPage> createState() =>
      _PrescriptionScannerPageState();
}

class _PrescriptionScannerPageState
    extends ConsumerState<PrescriptionScannerPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(prescriptionOcrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner d\'ordonnance'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Prenez une photo lisible de votre ordonnance. '
                        'Notre IA détectera automatiquement les médicaments.',
                        style: TextStyle(fontSize: 13, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Zone d'image
            _buildImageSection(),
            const SizedBox(height: 24),

            // Boutons de capture
            if (_selectedImage == null) ...[
              _buildCaptureButtons(),
            ] else ...[
              // Boutons après capture
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _clearImage,
                      icon: const Icon(Icons.close),
                      label: const Text('Reprendre'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeImage,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.document_scanner),
                      label: Text(
                        _isAnalyzing ? 'Analyse en cours...' : 'Analyser',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Résultats OCR
            if (ocrState.hasResults) ...[_buildResultsSection(ocrState)],

            // Erreur
            if (ocrState.error != null) ...[
              Card(
                color: AppColors.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ocrState.error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune image sélectionnée',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Prenez une photo ou sélectionnez depuis la galerie',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _selectedImage!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (_isAnalyzing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Détection des médicaments...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _captureImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Prendre une photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _captureImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choisir depuis la galerie'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(PrescriptionOcrState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec confiance
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text(
              'Médicaments détectés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConfidenceColor(
                  state.confidence,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${state.confidence.toStringAsFixed(0)}% confiance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(state.confidence),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Médicaments trouvés
        if (state.matchedProducts.isNotEmpty) ...[
          const Text(
            'Disponibles dans nos pharmacies :',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...state.matchedProducts.map(
            (med) => _buildMedicationCard(
              med,
              isMatched: true,
              onAdd: () => _addToCart(med),
            ),
          ),
        ],

        // Médicaments non trouvés
        if (state.unmatchedMedications.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Non disponibles (${state.unmatchedMedications.length}) :',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...state.unmatchedMedications.map(
            (med) => _buildMedicationCard(
              ExtractedMedication(name: med, dosage: null, confidence: 0),
              isMatched: false,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Bouton ajouter tout au panier
        if (state.matchedProducts.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _addAllToCart(state.matchedProducts),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              'Ajouter ${state.matchedProducts.length} produit${state.matchedProducts.length > 1 ? 's' : ''} au panier',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
      ],
    );
  }

  Widget _buildMedicationCard(
    ExtractedMedication med, {
    required bool isMatched,
    VoidCallback? onAdd,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isMatched
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isMatched ? Icons.medication : Icons.medication_outlined,
            color: isMatched ? AppColors.success : Colors.grey,
          ),
        ),
        title: Text(
          med.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isMatched ? null : Colors.grey,
          ),
        ),
        subtitle: med.dosage != null
            ? Text(med.dosage!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: isMatched && onAdd != null
            ? IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: onAdd,
              )
            : null,
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return AppColors.success;
    if (confidence >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        // Clear previous results
        ref.read(prescriptionOcrProvider.notifier).clear();
      }
    } catch (e) {
      AppLogger.error('Error capturing image', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image ?'),
        content: const Text(
          'L\'image sélectionnée et les résultats d\'analyse seront supprimés.',
        ),
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
      _selectedImage = null;
    });
    ref.read(prescriptionOcrProvider.notifier).clear();
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);
    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(prescriptionOcrProvider.notifier)
          .analyzeImage(_selectedImage!);

      // Déclencher la célébration pour le premier scan réussi
      final ocrState = ref.read(prescriptionOcrProvider);
      if (ocrState.hasResults && ocrState.error == null) {
        ref.read(celebrationProvider.notifier).triggerFirstPrescriptionScan();
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _addToCart(ExtractedMedication med) async {
    if (med.productId == null || med.product == null) return;

    HapticFeedback.lightImpact();
    final success = await ref
        .read(cartProvider.notifier)
        .addItem(med.product!, quantity: med.quantity ?? 1);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} ajouté au panier'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ),
      );
    }
  }

  Future<void> _addAllToCart(List<ExtractedMedication> medications) async {
    int addedCount = 0;

    for (final med in medications) {
      if (med.productId != null && med.product != null) {
        final success = await ref
            .read(cartProvider.notifier)
            .addItem(med.product!, quantity: med.quantity ?? 1);
        if (success) addedCount++;
      }
    }

    if (mounted && addedCount > 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedCount produit${addedCount > 1 ? 's' : ''} ajouté${addedCount > 1 ? 's' : ''} au panier',
          ),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Voir panier',
            textColor: Colors.white,
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.document_scanner, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Scanner d\'ordonnance'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment ça marche ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _HelpStep(number: '1', text: 'Photographiez votre ordonnance'),
            SizedBox(height: 8),
            _HelpStep(number: '2', text: 'Notre IA détecte les médicaments'),
            SizedBox(height: 8),
            _HelpStep(number: '3', text: 'Ajoutez-les au panier en un clic'),
            SizedBox(height: 16),
            Text(
              'Conseils pour une meilleure détection :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Photo bien éclairée'),
            Text('• Ordonnance à plat'),
            Text('• Texte lisible et net'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
