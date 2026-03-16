import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/prescription_model.dart';
import '../../data/datasources/prescription_remote_datasource.dart';
import '../providers/prescription_provider.dart';
import 'package:intl/intl.dart';

class PrescriptionDetailsPage extends ConsumerStatefulWidget {
  final PrescriptionModel prescription;

  const PrescriptionDetailsPage({super.key, required this.prescription});

  @override
  ConsumerState<PrescriptionDetailsPage> createState() => _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState extends ConsumerState<PrescriptionDetailsPage> {
  late TextEditingController _notesController;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  AnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.prescription.adminNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _analyzePrescription() async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await ref.read(prescriptionListProvider.notifier).analyzePrescription(
        widget.prescription.id,
      );
      if (mounted && result != null) {
        setState(() {
          _analysisResult = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse terminée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(prescriptionListProvider.notifier).updateStatus(
        widget.prescription.id,
        status,
        notes: _notesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour: $status')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            child: const Text('Annuler'),
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

              setState(() => _isLoading = true);
              try {
                // Determine notes to send. Uses text from the main page controller.
                final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
                
                await ref.read(prescriptionListProvider.notifier).sendQuote(
                  widget.prescription.id,
                  amount,
                  notes: notes,
                );
                
                if (!mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devis envoyé avec succès')),
                  );
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
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
    // Uses centralized base URL
    final baseUrl = AppConstants.storageBaseUrl;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        title: Text('Détails Ordonnance #${widget.prescription.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerInfo(isDark),
            const SizedBox(height: 16),
            _buildImages(baseUrl, isDark),
            const SizedBox(height: 16),
            _buildAnalyzeButton(isDark),
            if (_analysisResult != null || widget.prescription.isAnalyzed) ...[
              const SizedBox(height: 16),
              _buildAnalysisResults(isDark),
            ],
            const SizedBox(height: 16),
            _buildNotes(isDark),
            const SizedBox(height: 24),
            if (widget.prescription.status == 'pending') _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isDark) {
    if (widget.prescription.isAnalyzed && _analysisResult == null) {
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

    return ElevatedButton.icon(
      onPressed: _isAnalyzing ? null : _analyzePrescription,
      icon: _isAnalyzing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.document_scanner),
      label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Analyser l\'ordonnance (OCR)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildAnalysisResults(bool isDark) {
    final result = _analysisResult;
    
    // Use stored data if no live analysis result
    final medications = result?.extractedMedications ?? widget.prescription.extractedMedications ?? [];
    final matched = result?.matchedProducts ?? widget.prescription.matchedProducts ?? [];
    final unmatched = result?.unmatchedMedications ?? widget.prescription.unmatchedMedications ?? [];
    final confidence = result?.confidence ?? widget.prescription.ocrConfidence ?? 0;
    final estimatedTotal = result?.estimatedTotal ?? 0;
    final alerts = result?.alerts ?? [];

    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résultat de l\'analyse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Confiance: ${confidence.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Alerts
            if (alerts.isNotEmpty) ...[
              for (final alert in alerts)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alert['type'] == 'stock_alert' ? Colors.orange.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: alert['type'] == 'stock_alert' ? Colors.orange : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alert['type'] == 'stock_alert' ? Icons.warning : Icons.error,
                        color: alert['type'] == 'stock_alert' ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(alert['message'] ?? '', style: TextStyle(color: alert['type'] == 'stock_alert' ? Colors.orange.shade900 : Colors.red.shade900))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            
            // Medications extracted
            Text(
              'Médicaments détectés (${medications.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Matched products
            if (matched.isNotEmpty) ...[
              Text(
                '✅ En stock (${matched.length})',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              for (final item in matched.take(10))
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item['product_name'] ?? item['medication'] ?? 'Produit'}',
                          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
                        ),
                      ),
                      Text(
                        '${(item['price'] ?? 0).toStringAsFixed(0)} FCFA',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            
            // Unmatched products
            if (unmatched.isNotEmpty) ...[
              Text(
                '❌ Non disponibles (${unmatched.length})',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              for (final item in unmatched.take(10))
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    '• ${item['medication'] ?? item['product_name'] ?? 'Médicament'}',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            
            // Estimated total
            if (estimatedTotal > 0) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total estimé:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${estimatedTotal.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
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
    final customer = widget.prescription.customer;
    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Nom: ${customer?['name'] ?? 'Inconnu'}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            Text('Email: ${customer?['email'] ?? 'Non spécifié'}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(widget.prescription.createdAt) ?? DateTime.now())}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            if (widget.prescription.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes du client:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(widget.prescription.notes!, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImages(String baseUrl, bool isDark) {
    final images = widget.prescription.images;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              // Ensure path format
              var path = images[index];
              if (path.startsWith('public/')) {
                 path = path.replaceFirst('public/', '');
              }
              final url = '$baseUrl$path';
              return Card(
                clipBehavior: Clip.hardEdge,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Center(child: Icon(Icons.broken_image, size: 50)),
                  progressIndicatorBuilder: (c, u, progress) =>
                    const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Center(child: Text('${images.length} images (Swipe pour voir)', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))),
      ],
    );
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
      enabled: widget.prescription.status == 'pending',
    );
  }

  Widget _buildActionButtons() {
    return _isLoading
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
