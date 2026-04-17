import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/scanned_document.dart';
import '../../../data/services/document_scanner_service.dart';
import '../scanner/document_scanner_widgets.dart';

/// Section documents scannés dans le détail de livraison
class DeliveryDocumentSection extends ConsumerWidget {
  final Delivery delivery;

  const DeliveryDocumentSection({super.key, required this.delivery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final scannerState = ref.watch(documentScannerStateProvider);
    final deliveryDocuments = scannerState.scannedDocuments
        .where((d) => d.deliveryId == delivery.id)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.document_scanner,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (deliveryDocuments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deliveryDocuments.length}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick scan buttons
          Row(
            children: [
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.medical_services,
                  label: 'Ordonnance',
                  color: Colors.blue,
                  onTap: () => _openScanner(context, DocumentType.prescription),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.receipt_long,
                  label: 'Reçu',
                  color: Colors.green,
                  onTap: () => _openScanner(context, DocumentType.receipt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.verified,
                  label: 'Preuve',
                  color: Colors.purple,
                  onTap: () =>
                      _openScanner(context, DocumentType.deliveryProof),
                ),
              ),
            ],
          ),

          if (deliveryDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deliveryDocuments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = deliveryDocuments[index];
                  return _DocumentThumbnail(
                    document: doc,
                    onTap: () => _viewDocument(context, doc),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _viewAllDocuments(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir tous les documents',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openScanner(BuildContext context, DocumentType type) async {
    final result = await context.push<ScannedDocument>(
      AppRoutes.deliveryScanner,
      extra: {
        'deliveryId': delivery.id,
        'preselectedType': type,
        'autoStartCapture': true,
      },
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.label} scanné avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewDocument(BuildContext context, ScannedDocument doc) {
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(doc.type.icon, color: doc.type.color),
                        const SizedBox(width: 8),
                        Text(
                          doc.type.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: doc.quality.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doc.quality.label,
                            style: TextStyle(
                              color: doc.quality.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(doc.displayImage),
                    ),
                    if (doc.ocrResult != null) ...[
                      const SizedBox(height: 16),
                      OcrResultsCard(
                        result: doc.ocrResult!,
                        documentType: doc.type,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewAllDocuments(BuildContext context) {
    context.push(
      AppRoutes.deliveryDocuments,
      extra: {
        'deliveryId': delivery.id,
        'deliveryReference': delivery.reference,
      },
    );
  }
}

/// Bouton rapide pour scanner un type de document
class _DocumentQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DocumentQuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature d'un document scanné
class _DocumentThumbnail extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback onTap;

  const _DocumentThumbnail({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 70,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: document.type.color.withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(document.displayImage, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: document.type.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    document.type.icon,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
              if (document.isUploaded)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
