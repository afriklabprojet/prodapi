import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../data/models/scanned_document.dart';
import '../../data/services/document_scanner_service.dart';
import '../widgets/scanner/document_scanner_widgets.dart';

/// Écran complet de scanner de documents
class DocumentScannerScreen extends ConsumerStatefulWidget {
  final int? deliveryId;
  final DocumentType? preselectedType;
  final bool autoStartCapture;

  const DocumentScannerScreen({
    super.key,
    this.deliveryId,
    this.preselectedType,
    this.autoStartCapture = false,
  });

  @override
  ConsumerState<DocumentScannerScreen> createState() =>
      _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends ConsumerState<DocumentScannerScreen> {
  DocumentType? _selectedType;
  ScannedDocument? _capturedDocument;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;

    // Initialisation et auto-capture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentScannerStateProvider.notifier).initialize();

      if (widget.autoStartCapture && _selectedType != null) {
        _startCapture();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentScannerStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showPreview ? 'Aperçu du document' : 'Scanner un document',
        ),
        actions: [
          if (_showPreview)
            IconButton(
              onPressed: _resetCapture,
              icon: const Icon(Icons.close),
              tooltip: 'Annuler',
            ),
        ],
      ),
      body: state.isProcessing
          ? _buildLoadingState()
          : (_showPreview && _capturedDocument != null)
          ? _buildPreviewState()
          : _buildCaptureState(isDark),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Traitement en cours...'),
        ],
      ),
    );
  }

  Widget _buildCaptureState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection du type
          DocumentTypeSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() => _selectedType = type);
              ref
                  .read(documentScannerStateProvider.notifier)
                  .selectDocumentType(type);
            },
          ),
          const SizedBox(height: 32),

          // Instructions
          _InstructionsCard(documentType: _selectedType),
          const SizedBox(height: 24),

          // Guide visuel du cadrage
          if (_selectedType != null)
            Center(
              child: AspectRatio(
                aspectRatio: _selectedType == DocumentType.idCard
                    ? 1.586
                    : 1 / 1.414,
                child: ScannerGuideFrame(
                  aspectRatio: _selectedType == DocumentType.idCard
                      ? 1.586
                      : 1 / 1.414,
                  hintText: _selectedType == DocumentType.idCard
                      ? 'Cadrez la pièce d\'identité ici'
                      : 'Cadrez le document ici',
                  frameColor: _selectedType!.color,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Boutons de capture
          Row(
            children: [
              Expanded(
                child: _CaptureButton(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  enabled: _selectedType != null,
                  onPressed: _startCapture,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CaptureButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  enabled: _selectedType != null,
                  onPressed: _selectFromGallery,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Documents déjà scannés pour cette livraison
          if (widget.deliveryId != null) ...[
            Text(
              'Documents scannés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ScannedDocumentsList(deliveryId: widget.deliveryId),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: ScannedDocumentPreview(
              document: _capturedDocument!,
              onRetake: _resetCapture,
              onOcr: _performOcr,
              onConfirm: _confirmDocument,
            ),
          ),
          const SizedBox(height: 16),

          // Résultats OCR si disponibles
          if (_capturedDocument!.ocrResult != null)
            OcrResultsCard(
              result: _capturedDocument!.ocrResult!,
              documentType: _capturedDocument!.type,
            ),
        ],
      ),
    );
  }

  Future<void> _startCapture() async {
    if (_selectedType == null) return;

    final scanner = ref.read(documentScannerStateProvider.notifier);
    final doc = await scanner.scanDocument(
      type: _selectedType!,
      deliveryId: widget.deliveryId,
    );

    if (doc != null && mounted) {
      setState(() {
        _capturedDocument = doc;
        _showPreview = true;
      });
    }
  }

  Future<void> _selectFromGallery() async {
    if (_selectedType == null) return;

    final scanner = ref.read(documentScannerStateProvider.notifier);
    final doc = await scanner.scanDocument(
      type: _selectedType!,
      deliveryId: widget.deliveryId,
      fromGallery: true,
    );

    if (doc != null && mounted) {
      setState(() {
        _capturedDocument = doc;
        _showPreview = true;
      });
    }
  }

  Future<void> _performOcr() async {
    if (_capturedDocument == null) return;

    final scanner = ref.read(documentScannerStateProvider.notifier);
    final updated = await scanner.performOcrOnDocument(_capturedDocument!);

    if (updated != null && mounted) {
      setState(() => _capturedDocument = updated);
    }
  }

  Future<void> _confirmDocument() async {
    if (_capturedDocument == null) return;

    final scanner = ref.read(documentScannerStateProvider.notifier);

    // Upload le document
    final uploaded = await scanner.uploadDocument(_capturedDocument!);

    if (uploaded != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_capturedDocument!.type.label} enregistré'),
          backgroundColor: Colors.green,
        ),
      );

      // Retour avec le document
      Navigator.pop(context, uploaded);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document enregistré localement'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context, _capturedDocument);
    }
  }

  void _resetCapture() {
    // Supprime le document temporaire
    if (_capturedDocument != null) {
      ref
          .read(documentScannerStateProvider.notifier)
          .removeDocument(_capturedDocument!.id);
    }

    setState(() {
      _capturedDocument = null;
      _showPreview = false;
    });
  }
}

/// Carte d'instructions
class _InstructionsCard extends StatelessWidget {
  final DocumentType? documentType;

  const _InstructionsCard({this.documentType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (documentType == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sélectionnez un type de document pour commencer',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final instructions = _getInstructions(documentType!);

    return Card(
      color: documentType!.color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(documentType!.icon, color: documentType!.color),
                const SizedBox(width: 12),
                Text(
                  'Comment scanner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: documentType!.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: documentType!.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<String> _getInstructions(DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return [
          'Placez l\'ordonnance sur une surface plate',
          'Assurez-vous que tous les textes sont lisibles',
          'Évitez les reflets et les ombres',
          'Cadrez l\'ordonnance entière dans l\'écran',
        ];

      case DocumentType.receipt:
        return [
          'Placez le reçu sur une surface sombre',
          'Capturez le numéro de commande et le montant',
          'Vérifiez que la date est visible',
        ];

      case DocumentType.idCard:
        return [
          'Placez la pièce d\'identité à plat',
          'Assurez-vous que la photo est visible',
          'Capturez les deux faces si nécessaire',
        ];

      case DocumentType.deliveryProof:
        return [
          'Photographiez le colis devant l\'adresse',
          'Incluez un repère visuel si possible',
          'Ajoutez la signature si le client est présent',
        ];

      case DocumentType.insurance:
        return [
          'Capturez la carte d\'assurance recto-verso',
          'Vérifiez que le numéro est lisible',
          'Incluez la date de validité',
        ];

      case DocumentType.other:
        return [
          'Centrez le document dans le cadre',
          'Assurez-vous d\'un bon éclairage',
          'Évitez les reflets',
        ];
    }
  }
}

/// Bouton de capture
class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isPrimary;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Écran de visualisation des documents d'une livraison
class DeliveryDocumentsScreen extends ConsumerWidget {
  final int deliveryId;
  final String? deliveryReference;

  const DeliveryDocumentsScreen({
    super.key,
    required this.deliveryId,
    this.deliveryReference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentScannerStateProvider);
    final documents = state.scannedDocuments
        .where((d) => d.deliveryId == deliveryId)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deliveryReference != null
              ? 'Documents #$deliveryReference'
              : 'Documents de livraison',
        ),
      ),
      body: documents.isEmpty
          ? _buildEmptyState(context)
          : _buildDocumentsList(documents, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanner(context),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scanner'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun document',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scannez des documents pour cette livraison',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(List<ScannedDocument> documents, bool isDark) {
    // Group by type
    final grouped = <DocumentType, List<ScannedDocument>>{};
    for (final doc in documents) {
      grouped.putIfAbsent(doc.type, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics
        _DocumentsStats(documents: documents),
        const SizedBox(height: 24),

        // Documents by type
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(type: entry.key, count: entry.value.length),
              const SizedBox(height: 12),
              ...entry.value.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScannedDocumentCard(document: doc),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  void _openScanner(BuildContext context) {
    context.push(AppRoutes.deliveryScanner, extra: {'deliveryId': deliveryId});
  }
}

class _DocumentsStats extends StatelessWidget {
  final List<ScannedDocument> documents;

  const _DocumentsStats({required this.documents});

  @override
  Widget build(BuildContext context) {
    final uploaded = documents.where((d) => d.isUploaded).length;
    final withOcr = documents.where((d) => d.hasOcr).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.description,
              value: '${documents.length}',
              label: 'Documents',
              color: Colors.blue,
            ),
            _StatItem(
              icon: Icons.cloud_done,
              value: '$uploaded',
              label: 'Uploadés',
              color: Colors.green,
            ),
            _StatItem(
              icon: Icons.document_scanner,
              value: '$withOcr',
              label: 'Analysés',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final DocumentType type;
  final int count;

  const _SectionHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(type.icon, color: type.color, size: 20),
        const SizedBox(width: 8),
        Text(
          type.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: type.color,
            ),
          ),
        ),
      ],
    );
  }
}
