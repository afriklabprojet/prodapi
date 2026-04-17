import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/presentation/widgets/success_animation.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/responsive_builder.dart';
import '../../data/models/prescription_model.dart';
import '../providers/prescription_detail_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/prescription_dispense_section.dart' show PrescriptionDispenseSection, buildMedicationList;
import 'package:go_router/go_router.dart';
import '../widgets/prescription_image_viewer.dart' show ImageCropSheet;
import '../widgets/fulfillment_status_banner.dart';
import '../widgets/duplicate_warning_banner.dart';
import 'package:intl/intl.dart';

class PrescriptionDetailsPage extends ConsumerStatefulWidget {
  final PrescriptionModel prescription;

  const PrescriptionDetailsPage({super.key, required this.prescription});

  @override
  ConsumerState<PrescriptionDetailsPage> createState() => _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState extends ConsumerState<PrescriptionDetailsPage> {
  late TextEditingController _notesController;
  
  // GlobalKeys pour le tutoriel contextuel
  final _prescriptionImageKey = GlobalKey();
  final _productsListKey = GlobalKey();
  final _validateButtonKey = GlobalKey();

  /// Accès rapide à l'état du provider
  PrescriptionDetailState get _state => ref.read(prescriptionDetailProvider(widget.prescription));
  /// Accès rapide au notifier
  PrescriptionDetailNotifier get _notifier => ref.read(prescriptionDetailProvider(widget.prescription).notifier);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.prescription.adminNotes);
    // Provider _init() gère le chargement du token et des doublons
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrescriptionTutorial());
  }
  
  Future<void> _showPrescriptionTutorial() async {
    if (!mounted) return;
    // Ne montrer que pour les ordonnances en attente (première action de validation)
    if (_state.prescription.status != 'pending') return;
    
    final tutorialService = ref.read(tutorialServiceProvider);
    final targets = TutorialService.buildPrescriptionValidationTargets(
      prescriptionImageKey: _prescriptionImageKey,
      productsListKey: _productsListKey,
      validateButtonKey: _validateButtonKey,
    );
    
    await tutorialService.showTutorialIfNeeded(
      context: context,
      tutorialKey: TutorialKeys.prescriptionValidation,
      targets: targets,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _analyzePrescription() async {
    final success = await _notifier.analyzePrescription();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyse terminée')),
      );
    } else {
      final error = _state.ocrError ?? 'Échec de l\'analyse OCR';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _dispenseMedications() async {
    final selected = _state.selectedMedications.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un médicament à délivrer')),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    
    // Récupérer les détails des médicaments sélectionnés
    final medList = buildMedicationList(_state);
    final selectedMeds = medList.where((m) => selected.contains(m.name)).toList();

    // Confirm dispense avec liste détaillée des médicaments
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.confirmDispensation)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Médicaments à dispenser :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedMeds.map((med) {
                      final hasLowConfidence = med.confidence != null && med.confidence! < 0.7;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '× ${med.remaining} unité(s)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasLowConfidence)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber, size: 12, color: Colors.orange.shade700),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${(med.confidence! * 100).toInt()}%',
                                      style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Total : ${selectedMeds.length} médicament(s)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Build medications payload via notifier
    final medications = _notifier.buildMedicationsPayload(selected);

    try {
      final result = await _notifier.dispenseMedications(medications);
      if (mounted && result != null) {
        final message = result.fulfillmentStatus == 'full' 
            ? 'Ordonnance complète !' 
            : 'Dispensation partielle';
        await showSuccessAnimation(
          context,
          message: message,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la dispensation')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    final success = await _notifier.updateStatus(status, notes: _notesController.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour: $status')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')),
      );
    }
  }

  Future<void> _showQuoteDialog() async {
    final amountController = TextEditingController();

    try {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text('Faire un devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez saisir le montant total du devis pour cette ordonnance.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
                prefixText: 'FCFA ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Veuillez entrer un montant valide')),
                 );
                 return;
              }
              Navigator.pop(context);

              try {
                final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
                
                final success = await _notifier.sendQuote(
                  amount,
                  notes: notes,
                );
                
                if (!mounted) return;
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devis envoyé avec succès')),
                  );
                  Navigator.pop(context); // Go back to list
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'envoi du devis')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    } finally {
      amountController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Souscription réactive au provider — déclenche rebuild à chaque changement d'état
    final state = ref.watch(prescriptionDetailProvider(widget.prescription));
    final prescription = state.prescription;
    final baseUrl = AppConstants.storageBaseUrl;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        title: Text('Détails Ordonnance #${prescription.id}'),
      ),
      body: ResponsiveBuilder(
        builder: (context, responsive) => SingleChildScrollView(
        padding: EdgeInsets.all(responsive.horizontalPadding - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fulfillment status banner
            _buildFulfillmentBanner(isDark),
            // Duplicate warning
            if (state.duplicateInfo != null) ...[
              const SizedBox(height: 8),
              _buildDuplicateWarning(isDark),
            ],
            const SizedBox(height: 16),
            _buildCustomerInfo(isDark),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _prescriptionImageKey,
              child: _buildImages(baseUrl, isDark),
            ),
            const SizedBox(height: 16),
            _buildAnalyzeButton(isDark),
            if (state.analysisResult != null || prescription.isAnalyzed) ...[
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _productsListKey,
                child: _buildAnalysisResults(isDark),
              ),
              const SizedBox(height: 16),
              PrescriptionDispenseSection(
                detailState: state,
                medList: buildMedicationList(state),
                isDispensing: state.isDispensing,
                onToggleMedication: (entry) => _notifier.toggleMedication(entry.key, entry.value),
                onDispense: _dispenseMedications,
              ),
            ],
            // Dispensing history
            if (prescription.dispensingCount > 0) ...[
              const SizedBox(height: 16),
              _buildDispensingHistory(isDark),
            ],
            const SizedBox(height: 16),
            _buildNotes(isDark),
            const SizedBox(height: 24),
            if (prescription.status == 'pending') 
              KeyedSubtree(
                key: _validateButtonKey,
                child: _buildActionButtons(),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFulfillmentBanner(bool isDark) {
    return FulfillmentStatusBanner(
      fulfillmentStatus: _state.prescription.fulfillmentStatus,
      dispensingCount: _state.prescription.dispensingCount,
      firstDispensedAt: _state.prescription.firstDispensedAt,
    );
  }

  Widget _buildDuplicateWarning(bool isDark) {
    return DuplicateWarningBanner(duplicateInfo: _state.duplicateInfo!);
  }

  Widget _buildDispensingHistory(bool isDark) {
    final dispensings = _state.prescription.dispensings ?? [];
    if (dispensings.isEmpty) return const SizedBox.shrink();

    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Historique de dispensation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(),
            for (final d in dispensings)
              if (d is Map) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.medication, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d['medication_name'] ?? ''} — x${d['quantity_dispensed'] ?? 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Par: ${d['dispensed_by'] ?? 'Inconnu'} • ${d['dispensed_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(d['dispensed_at']) ?? DateTime.now()) : ''}',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
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

  Widget _buildAnalyzeButton(bool isDark) {
    if (_state.prescription.isAnalyzed && _state.analysisResult == null && _state.ocrError == null) {
      return Card(
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Ordonnance déjà analysée', style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
      );
    }

    if (_state.ocrError != null) {
      return Card(
        color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
        elevation: isDark ? 0 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Échec de l\'analyse OCR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _state.ocrError!,
                          style: TextStyle(
                            color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _state.isAnalyzing ? null : () => _showImageCropDialog(),
                      icon: const Icon(Icons.crop, size: 18),
                      label: const Text('Recadrer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _state.isAnalyzing ? null : _analyzePrescription,
                      icon: _state.isAnalyzing 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(_state.isAnalyzing ? 'Analyse...' : 'Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _state.isAnalyzing ? null : _analyzePrescription,
      icon: _state.isAnalyzing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.document_scanner),
      label: Text(_state.isAnalyzing ? 'Analyse en cours...' : 'Analyser l\'ordonnance (OCR)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _showImageCropDialog() {
    final images = _state.prescription.images;
    if (images == null || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune image disponible à recadrer')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImageCropSheet(
        images: images,
        authToken: _state.authToken,
        onCropComplete: (croppedImagePath) {
          Navigator.pop(ctx);
          // Re-run analysis after crop
          _analyzePrescription();
        },
      ),
    );
  }

  Widget _buildAnalysisResults(bool isDark) {
    final result = _state.analysisResult;
    
    // Use stored data if no live analysis result
    final medications = result?.extractedMedications ?? _state.prescription.extractedMedications ?? [];
    final medicalExams = result?.medicalExams ?? [];
    final rawConfidence = result?.confidence ?? _state.prescription.ocrConfidence ?? 0;
    final confidence = rawConfidence <= 1.0 ? rawConfidence * 100 : rawConfidence;
    final hasHandwriting = result?.hasHandwriting ?? false;

    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge manuscrit si détecté
            if (hasHandwriting)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.purple[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Écriture manuscrite détectée',
                      style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                    ),
                  ],
                ),
              ),
              
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Médicaments détectés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${medications.length} trouvé${medications.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (medications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucun médicament détecté',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              )
            else
              for (final med in medications.take(20))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.medication, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          med is Map ? (med['name'] ?? med['matched_text'] ?? 'Médicament') : med.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[200] : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            
            // Section examens médicaux (si présents)
            if (medicalExams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Examens médicaux',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${medicalExams.length} trouvé${medicalExams.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final exam in medicalExams.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 18, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam is Map ? (exam['name'] ?? 'Examen') : exam.toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[200] : Colors.black87,
                              ),
                            ),
                            if (exam is Map && exam['zones'] != null && (exam['zones'] as List).isNotEmpty)
                              Text(
                                'Zone: ${(exam['zones'] as List).join(', ')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            
            // Conseil pour ordonnances manuscrites à faible confiance
            if (confidence < 70)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pour les ordonnances manuscrites, assurez-vous d\'avoir un bon éclairage et une image nette. Vous pouvez recadrer l\'image ci-dessous pour améliorer la détection.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.amber[200] : Colors.amber[900],
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCustomerInfo(bool isDark) {
    final customer = _state.prescription.customer;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'prescription_icon_${_state.prescription.id}',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nom: ${customer?['name'] ?? 'Inconnu'}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            Text('Email: ${customer?['email'] ?? 'Non spécifié'}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(_state.prescription.createdAt) ?? DateTime.now())}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            if (_state.prescription.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes du client:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(_state.prescription.notes!, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImages(String baseUrl, bool isDark) {
    final images = _state.prescription.images;
    if (images == null || images.isEmpty) {
      return Card(
        color: isDark ? AppColors.darkCard : Colors.white,
        elevation: isDark ? 0 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Aucune image jointe', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black87)),
        ),
      );
    }

    // Build image URLs via secure document endpoint
    final documentsBaseUrl = '${AppConstants.apiBaseUrl}/documents/';

    // Build list of URLs
    final urls = <String>[];
    for (var path in images) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
      } else {
        if (path.startsWith('public/')) {
          path = path.replaceFirst('public/', '');
        }
        urls.add('$documentsBaseUrl$path');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ordonnance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            TextButton.icon(
              onPressed: () => _openFullscreenImage(urls, 0),
              icon: const Icon(Icons.fullscreen, size: 20),
              label: const Text('Plein écran'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: urls.length,
            itemBuilder: (context, index) {
              if (_state.authToken == null) {
                return const Card(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return GestureDetector(
                onTap: () => _openFullscreenImage(urls, index),
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: urls[index],
                          cacheKey: '${urls[index]}_auth',
                          fit: BoxFit.contain,
                          httpHeaders: {'Authorization': 'Bearer ${_state.authToken}'},
                          errorWidget: (c, u, e) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, size: 50),
                                const SizedBox(height: 8),
                                Text(
                                  'Erreur de chargement',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          progressIndicatorBuilder: (c, u, progress) =>
                            const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      // Watermark overlay for fully dispensed prescriptions
                      if (_state.prescription.isFullyDispensed)
                        Center(
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Text(
                                'DÉLIVRÉE ✓',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Tap hint
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Pincez pour zoomer', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (urls.length > 1)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${urls.length} images — Glissez pour voir', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
            ),
          ),
      ],
    );
  }

  /// Ouvre l'image en plein écran avec zoom
  void _openFullscreenImage(List<String> urls, int initialIndex) {
    context.push('/prescription-image', extra: {
      'urls': urls,
      'initialIndex': initialIndex,
      'authToken': _state.authToken!,
      'isFullyDispensed': _state.prescription.isFullyDispensed,
    });
  }

  Widget _buildNotes(bool isDark) {
    return TextField(
      controller: _notesController,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: 'Notes Pharmacien / Commentaire Devis',
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        hintText: 'Ajouter des détails sur le devis ou instructions...',
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
        filled: isDark,
        fillColor: isDark ? AppColors.darkCard : null,
      ),
      maxLines: 3,
      enabled: _state.prescription.status == 'pending',
    );
  }

  Widget _buildActionButtons() {
    return _state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Row(
                children: [
                   Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showQuoteDialog,
                      icon: const Icon(Icons.request_quote),
                      label: const Text('Faire un Devis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Soft red
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('validated'),
                      icon: const Icon(Icons.check),
                      label: const Text('Valider (Direct)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // De-emphasize direct validation
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
