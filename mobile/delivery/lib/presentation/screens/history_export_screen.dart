import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/delivery_export_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/delivery.dart';
import '../providers/history_providers.dart';
import '../widgets/history/history_filter_sheet.dart';
import '../widgets/history/history_stats_card.dart';

/// Écran d'historique avancé avec export
class HistoryExportScreen extends ConsumerStatefulWidget {
  const HistoryExportScreen({super.key});

  @override
  ConsumerState<HistoryExportScreen> createState() => _HistoryExportScreenState();
}

class _HistoryExportScreenState extends ConsumerState<HistoryExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Historique & Export', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => HistoryFilterSheet.show(context),
            tooltip: 'Filtres',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Exporter en PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart, color: Colors.green),
                  title: Text('Exporter en CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print, color: Colors.blue),
                  title: Text('Imprimer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Historique'),
            Tab(icon: Icon(Icons.folder), text: 'Exports'),
          ],
        ),
      ),
      body: _isExporting
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _HistoryTab(),
                _ExportsTab(),
              ],
            ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    final deliveries = await ref.read(filteredHistoryProvider.future);
    
    if (deliveries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune livraison à exporter'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filters = ref.read(historyFiltersProvider);
      final periodLabel = _getPeriodLabel(filters);

      switch (action) {
        case 'export_pdf':
          await _exportPdf(deliveries, periodLabel);
          break;
        case 'export_csv':
          await _exportCsv(deliveries);
          break;
        case 'print':
          await _printPdf(deliveries, periodLabel);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _getPeriodLabel(dynamic filters) {
    if (filters.dateFrom != null && filters.dateTo != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(filters.dateFrom!)} - ${dateFormat.format(filters.dateTo!)}';
    }
    return 'Toutes périodes';
  }

  Future<void> _exportPdf(List<Delivery> deliveries, String periodLabel) async {
    final pdfBytes = await DeliveryExportService.generateHistoryPdf(
      deliveries: deliveries,
      courierName: 'Coursier DR PHARMA',
      periodLabel: periodLabel,
    );

    final filename = 'historique_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    // Sauvegarder localement
    await DeliveryExportService.savePdfLocally(pdfBytes, filename);
    
    // Partager
    await DeliveryExportService.sharePdf(pdfBytes, filename);

    // Rafraîchir la liste des exports
    ref.invalidate(savedExportsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF généré et sauvegardé'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportCsv(List<Delivery> deliveries) async {
    final csvContent = await DeliveryExportService.generateHistoryCsv(
      deliveries: deliveries,
    );

    final filename = 'historique_${DateTime.now().millisecondsSinceEpoch}.csv';
    
    await DeliveryExportService.shareCsv(csvContent, filename);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV généré'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _printPdf(List<Delivery> deliveries, String periodLabel) async {
    final pdfBytes = await DeliveryExportService.generateHistoryPdf(
      deliveries: deliveries,
      courierName: 'Coursier DR PHARMA',
      periodLabel: periodLabel,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Historique des livraisons',
    );
  }
}

/// Onglet historique
class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(filteredHistoryProvider);
    final filters = ref.watch(historyFiltersProvider);
    final hasFilters = filters.hasActiveFilters;

    return Column(
      children: [
        // Statistiques
        const HistoryStatsCard(),
        
        // Indicateur de filtres actifs
        if (hasFilters)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFiltersDescription(filters),
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(historyFiltersProvider.notifier).clearFilters();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Effacer'),
                ),
              ],
            ),
          ),
        
        // Liste
        Expanded(
          child: deliveriesAsync.when(
            data: (deliveries) {
              if (deliveries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune livraison trouvée',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hasFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(historyFiltersProvider.notifier).clearFilters();
                          },
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  return _DeliveryHistoryCard(delivery: deliveries[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: $e'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(filteredHistoryProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getFiltersDescription(dynamic filters) {
    final parts = <String>[];
    
    if (filters.dateFrom != null || filters.dateTo != null) {
      parts.add('Période personnalisée');
    }
    if (filters.status != null) {
      parts.add('Statut: ${filters.status}');
    }
    if (filters.pharmacyName != null) {
      parts.add(filters.pharmacyName!);
    }
    
    return parts.isEmpty ? 'Filtres actifs' : parts.join(' • ');
  }
}

/// Carte de livraison historique
class _DeliveryHistoryCard extends StatelessWidget {
  final Delivery delivery;

  const _DeliveryHistoryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final date = delivery.createdAt != null
        ? DateTime.tryParse(delivery.createdAt!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${delivery.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildStatusBadge(delivery.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.pharmacyName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.deliveryAddress,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date != null ? dateFormat.format(date) : '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (delivery.distanceKm != null)
                      Text(
                        '${delivery.distanceKm!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(delivery.commission ?? 0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      'Commission',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'delivered':
        color = Colors.green;
        text = 'Livrée';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulée';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'delivered' ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet des exports sauvegardés
class _ExportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportsAsync = ref.watch(savedExportsProvider);

    return exportsAsync.when(
      data: (exports) {
        if (exports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun export sauvegardé',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les exports PDF seront affichés ici',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exports.length,
          itemBuilder: (context, index) {
            final export = exports[index];
            return _ExportCard(
              export: export,
              onShare: () => _shareExport(context, export),
              onDelete: () => _deleteExport(context, ref, export),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Future<void> _shareExport(BuildContext context, ExportedFile export) async {
    try {
      await Share.shareXFiles([XFile(export.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteExport(
    BuildContext context,
    WidgetRef ref,
    ExportedFile export,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${export.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DeliveryExportService.deleteExport(export.path);
      ref.invalidate(savedExportsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export supprimé')),
        );
      }
    }
  }
}

/// Carte d'export
class _ExportCard extends StatelessWidget {
  final ExportedFile export;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ExportCard({
    required this.export,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (export.type == ExportType.pdf ? Colors.red : Colors.green)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            export.type == ExportType.pdf
                ? Icons.picture_as_pdf
                : Icons.table_chart,
            color: export.type == ExportType.pdf ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          export.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${dateFormat.format(export.createdAt)} • ${export.formattedSize}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              onPressed: onShare,
              tooltip: 'Partager',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
