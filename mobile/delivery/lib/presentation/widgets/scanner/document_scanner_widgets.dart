import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/scanned_document.dart';
import '../../../data/services/document_scanner_service.dart';

/// Sélecteur de type de document
class DocumentTypeSelector extends StatelessWidget {
  final DocumentType? selectedType;
  final ValueChanged<DocumentType> onTypeSelected;
  final List<DocumentType> availableTypes;

  const DocumentTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
    this.availableTypes = DocumentType.values,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Type de document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableTypes.map((type) {
            final isSelected = type == selectedType;
            return _DocumentTypeChip(
              type: type,
              isSelected: isSelected,
              onTap: () => onTypeSelected(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DocumentTypeChip extends StatelessWidget {
  final DocumentType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocumentTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? type.color.withValues(alpha: 0.15)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? type.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                color: isSelected
                    ? type.color
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  color: isSelected
                      ? type.color
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadre de guidage pour le scanner
class ScannerGuideFrame extends StatelessWidget {
  final double aspectRatio;
  final Color frameColor;
  final String? hintText;

  const ScannerGuideFrame({
    super.key,
    this.aspectRatio = 1.414, // A4 ratio
    this.frameColor = Colors.white,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.85;
        final height = width / aspectRatio;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Cadre de guidage
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: frameColor, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Coins accentués
                  ..._buildCorners(frameColor),
                ],
              ),
            ),
            
            // Hint text
            if (hintText != null)
              Positioned(
                bottom: -40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hintText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners(Color color) {
    const cornerSize = 24.0;
    const cornerWidth = 4.0;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),

      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),

      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),

      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
    ];
  }
}

/// Aperçu du document scanné avec actions
class ScannedDocumentPreview extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback? onRetake;
  final VoidCallback? onConfirm;
  final VoidCallback? onOcr;
  final bool showOcrButton;

  const ScannedDocumentPreview({
    super.key,
    required this.document,
    this.onRetake,
    this.onConfirm,
    this.onOcr,
    this.showOcrButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  document.displayImage,
                  fit: BoxFit.contain,
                ),
                
                // Quality badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: _QualityBadge(quality: document.quality),
                ),

                // Document type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: document.type.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(document.type.icon, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          document.type.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            if (onRetake != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reprendre'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onRetake != null && showOcrButton && onOcr != null)
              const SizedBox(width: 12),
            if (showOcrButton && onOcr != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOcr,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Analyser'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if ((onRetake != null || showOcrButton) && onConfirm != null)
              const SizedBox(width: 12),
            if (onConfirm != null)
              Expanded(
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final ScanQuality quality;

  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: quality.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            quality.stars,
            (_) => const Icon(Icons.star, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 4),
          Text(
            quality.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de document dans une liste
class ScannedDocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onUpload;

  const ScannedDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
    this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Hero(
                tag: 'doc_${document.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    document.displayImage,
                    width: 70,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(document.type.icon, 
                            color: document.type.color, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          document.type.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.contentSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(
                          icon: document.isUploaded
                              ? Icons.cloud_done
                              : Icons.cloud_upload,
                          label: document.isUploaded ? 'Uploadé' : 'Local',
                          color: document.isUploaded ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          icon: document.quality.stars >= 3
                              ? Icons.high_quality
                              : Icons.sd,
                          label: document.quality.label,
                          color: document.quality.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!document.isUploaded && onUpload != null)
                    IconButton(
                      onPressed: onUpload,
                      icon: Icon(Icons.cloud_upload,
                          color: isDark ? Colors.blue.shade300 : Colors.blue),
                      tooltip: 'Uploader',
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline,
                          color: isDark ? Colors.red.shade300 : Colors.red),
                      tooltip: 'Supprimer',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Affichage des résultats OCR
class OcrResultsCard extends StatelessWidget {
  final OcrResult result;
  final DocumentType documentType;

  const OcrResultsCard({
    super.key,
    required this.result,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!result.isSuccess) {
      return _ErrorCard(message: result.errorMessage ?? 'Analyse échouée');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner, color: documentType.color),
                const SizedBox(width: 8),
                Text(
                  'Résultats de l\'analyse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                _ConfidenceBadge(confidence: result.confidence),
              ],
            ),
            const Divider(height: 24),

            // Extracted fields
            if (result.extractedFields.isNotEmpty) ...[
              ...result.extractedFields.entries.map((entry) {
                return _FieldRow(
                  label: _formatFieldLabel(entry.key),
                  value: entry.value,
                );
              }),
            ] else if (result.rawText.isNotEmpty) ...[
              Text(
                'Texte extrait:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.rawText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucun texte détecté',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFieldLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? Colors.green
        : (confidence >= 0.5 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percentage% confiance',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action rapide pour scanner
class QuickScanButton extends ConsumerWidget {
  final int? deliveryId;
  final List<DocumentType> allowedTypes;
  final ValueChanged<ScannedDocument>? onDocumentScanned;

  const QuickScanButton({
    super.key,
    this.deliveryId,
    this.allowedTypes = const [
      DocumentType.prescription,
      DocumentType.receipt,
      DocumentType.deliveryProof,
    ],
    this.onDocumentScanned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showScanOptions(context, ref),
      icon: const Icon(Icons.document_scanner),
      label: const Text('Scanner'),
      backgroundColor: Colors.blue,
    );
  }

  void _showScanOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Scanner un document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...allowedTypes.map((type) {
                  return _ScanOptionTile(
                    type: type,
                    onTap: () {
                      Navigator.pop(context);
                      _startScanning(context, ref, type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startScanning(
    BuildContext context,
    WidgetRef ref,
    DocumentType type,
  ) async {
    final scanner = ref.read(documentScannerStateProvider.notifier);
    scanner.selectDocumentType(type);

    final document = await scanner.scanDocument(
      type: type,
      deliveryId: deliveryId,
    );

    if (document != null && onDocumentScanned != null) {
      onDocumentScanned!(document);
    }
  }
}

class _ScanOptionTile extends StatelessWidget {
  final DocumentType type;
  final VoidCallback onTap;

  const _ScanOptionTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(type.icon, color: type.color),
      ),
      title: Text(
        type.label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
    );
  }
}

/// Liste des documents scannés
class ScannedDocumentsList extends ConsumerWidget {
  final int? deliveryId;
  final bool showUploadStatus;

  const ScannedDocumentsList({
    super.key,
    this.deliveryId,
    this.showUploadStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentScannerStateProvider);
    final documents = deliveryId != null
        ? state.scannedDocuments
            .where((d) => d.deliveryId == deliveryId)
            .toList()
        : state.scannedDocuments;

    if (documents.isEmpty) {
      return _EmptyDocumentsList();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = documents[index];
        return ScannedDocumentCard(
          document: doc,
          onTap: () => _showDocumentDetail(context, doc),
          onDelete: () => _confirmDelete(context, ref, doc),
          onUpload: doc.isUploaded
              ? null
              : () => _uploadDocument(context, ref, doc),
        );
      },
    );
  }

  void _showDocumentDetail(BuildContext context, ScannedDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                    Hero(
                      tag: 'doc_${doc.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(doc.displayImage),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (doc.ocrResult != null)
                      OcrResultsCard(
                        result: doc.ocrResult!,
                        documentType: doc.type,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ce ${doc.type.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(documentScannerStateProvider.notifier)
                  .removeDocument(doc.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument doc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await ref
        .read(documentScannerStateProvider.notifier)
        .uploadDocument(doc);

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${doc.type.label} uploadé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'upload'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _EmptyDocumentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document scanné',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez le bouton scanner pour ajouter des documents',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
