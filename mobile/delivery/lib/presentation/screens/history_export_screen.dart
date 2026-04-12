import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/delivery_export_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/delivery.dart';
import '../providers/history_providers.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/history/history_filter_sheet.dart';
import '../widgets/history/history_stats_card.dart';

// Couleurs du thème - Executive Dashboard Theme (cohérent avec StatisticsScreen)
const _kNavyDark = Color(0xFF0F1C3F);
const _kNavyMedium = Color(0xFF1A2B52);
const _kAccentGold = Color(0xFFE5C76B);
const _kAccentTeal = Color(0xFF2DD4BF);
const _kDarkBg = Color(0xFF121212);
const _kDarkSurface = Color(0xFF1E1E1E);

/// Écran d'historique avancé avec export
class HistoryExportScreen extends ConsumerStatefulWidget {
  const HistoryExportScreen({super.key});

  @override
  ConsumerState<HistoryExportScreen> createState() =>
      _HistoryExportScreenState();
}

class _HistoryExportScreenState extends ConsumerState<HistoryExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
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
      backgroundColor: isDark ? _kDarkBg : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header navy - même design que StatisticsScreen
          _buildHeader(context, isDark),
          // Onglets
          _buildTabBar(isDark),
          // Contenu
          Expanded(
            child: _isExporting
                ? const AppLoadingWidget(message: 'Export en cours...')
                : TabBarView(
                    controller: _tabController,
                    children: [_HistoryTab(), _ExportsTab()],
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavyDark, _kNavyMedium],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              // Top bar avec titre centré
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Historique & Export',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Menu d'actions
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onSelected: _handleMenuAction,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, 45),
                    itemBuilder: (context) => [
                      _buildPopupMenuItem(
                        'export_pdf',
                        Icons.picture_as_pdf,
                        'Exporter en PDF',
                        Colors.red,
                      ),
                      _buildPopupMenuItem(
                        'export_csv',
                        Icons.table_chart,
                        'Exporter en CSV',
                        Colors.green,
                      ),
                      _buildPopupMenuItem(
                        'print',
                        Icons.print,
                        'Imprimer',
                        Colors.blue,
                      ),
                      const PopupMenuDivider(),
                      _buildPopupMenuItem(
                        'filter',
                        Icons.filter_list_rounded,
                        'Filtrer',
                        _kAccentTeal,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kAccentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: _kAccentGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Consultez et exportez vos livraisons en PDF ou CSV',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? _kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _kNavyDark,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_kNavyDark, _kNavyMedium]),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: _tabController.index == 0 ? Colors.white : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historique',
                  style: TextStyle(
                    color: _tabController.index == 0 ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_rounded,
                  size: 18,
                  color: _tabController.index == 1 ? Colors.white : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exports',
                  style: TextStyle(
                    color: _tabController.index == 1 ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickExportSheet(),
      backgroundColor: _kNavyDark,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.download_rounded),
      label: Text(
        'Export rapide',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showQuickExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.isDark ? _kDarkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export rapide',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un format d\'export',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _QuickExportButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _handleMenuAction('export_pdf');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickExportButton(
                    icon: Icons.table_chart,
                    label: 'CSV',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _handleMenuAction('export_csv');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickExportButton(
                    icon: Icons.print,
                    label: 'Imprimer',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _handleMenuAction('print');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    // Cas spécial pour le filtre
    if (action == 'filter') {
      HistoryFilterSheet.show(context);
      return;
    }

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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
      final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                return _EmptyHistoryState(hasFilters: hasFilters);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  return _DeliveryHistoryCard(delivery: deliveries[index]);
                },
              );
            },
            loading: () => const AppLoadingWidget(
              message: 'Chargement de l\'historique...',
            ),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(filteredHistoryProvider),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                      (delivery.commission ?? 0).formatCurrency(),
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
          return const _EmptyExportsState();
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
      loading: () =>
          const AppLoadingWidget(message: 'Chargement des exports...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
    );
  }

  Future<void> _shareExport(BuildContext context, ExportedFile export) async {
    try {
      await Share.shareXFiles([XFile(export.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export supprimé')));
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
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide pour l'historique - design amélioré
class _EmptyHistoryState extends ConsumerWidget {
  final bool hasFilters;

  const _EmptyHistoryState({required this.hasFilters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration animée
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kNavyDark.withValues(alpha: 0.15),
                      _kNavyMedium.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kNavyDark.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  hasFilters ? Icons.search_off_rounded : Icons.history_rounded,
                  size: 64,
                  color: _kNavyDark.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              hasFilters ? 'Aucun résultat' : 'Aucune livraison trouvée',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Vos livraisons terminées apparaîtront ici',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(historyFiltersProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Effacer les filtres'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kNavyDark,
                  side: const BorderSide(color: _kNavyDark),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide pour les exports - design amélioré
class _EmptyExportsState extends StatelessWidget {
  const _EmptyExportsState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration avec animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withValues(alpha: 0.15),
                      Colors.blue.shade300.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      size: 64,
                      color: Colors.blue.withValues(alpha: 0.7),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          size: 20,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun export sauvegardé',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Exportez votre historique en PDF ou CSV\npour le sauvegarder ici',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Utilisez le bouton "Export rapide"',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
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
}

/// Bouton d'export rapide pour le bottom sheet
class _QuickExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickExportButton({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
