import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../../core/services/earnings_export_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/repositories/delivery_repository.dart';

/// Provider pour l'export des revenus
final exportLoadingProvider = StateProvider<bool>((ref) => false);

/// Bottom sheet pour exporter les revenus
class EarningsExportSheet extends ConsumerStatefulWidget {
  final String courierName;

  const EarningsExportSheet({
    super.key,
    required this.courierName,
  });

  static Future<void> show(BuildContext context, {required String courierName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EarningsExportSheet(courierName: courierName),
    );
  }

  @override
  ConsumerState<EarningsExportSheet> createState() => _EarningsExportSheetState();
}

class _EarningsExportSheetState extends ConsumerState<EarningsExportSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  ExportType _exportType = ExportType.csv;
  ExportData _exportData = ExportData.deliveries;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Par défaut: ce mois
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = now;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.download_rounded, color: Colors.green.shade700),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exporter mes revenus',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Téléchargez un relevé de vos gains',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 0, color: Colors.grey.shade200),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Période
                  _buildSectionTitle('Période'),
                  const SizedBox(height: 12),
                  _buildPeriodPresets(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Du',
                          value: _dateFrom,
                          onChanged: (date) => setState(() => _dateFrom = date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'Au',
                          value: _dateTo,
                          onChanged: (date) => setState(() => _dateTo = date),
                          minDate: _dateFrom,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Données à exporter
                  _buildSectionTitle('Données'),
                  const SizedBox(height: 12),
                  _buildDataSelection(),
                  
                  const SizedBox(height: 24),
                  
                  // Format
                  _buildSectionTitle('Format'),
                  const SizedBox(height: 12),
                  _buildFormatSelection(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: EdgeInsets.fromLTRB(
              20, 
              16, 
              20, 
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_isExporting ? 'Export en cours...' : 'Exporter'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.secondaryText,
      ),
    );
  }

  Widget _buildPeriodPresets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPresetChip('Ce mois', _setThisMonth),
        _buildPresetChip('Mois dernier', _setLastMonth),
        _buildPresetChip('3 derniers mois', _setLast3Months),
        _buildPresetChip('Cette année', _setThisYear),
        _buildPresetChip('Tout', _setAll),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _dateFrom = DateTime(now.year, now.month, 1);
      _dateTo = now;
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    setState(() {
      _dateFrom = lastMonth;
      _dateTo = DateTime(now.year, now.month, 0); // Dernier jour du mois précédent
    });
  }

  void _setLast3Months() {
    final now = DateTime.now();
    setState(() {
      _dateFrom = DateTime(now.year, now.month - 3, 1);
      _dateTo = now;
    });
  }

  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _dateFrom = DateTime(now.year, 1, 1);
      _dateTo = now;
    });
  }

  void _setAll() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Widget _buildDataSelection() {
    return Row(
      children: [
        Expanded(
          child: _SelectionCard(
            icon: Icons.delivery_dining,
            title: 'Livraisons',
            subtitle: 'Historique des courses',
            isSelected: _exportData == ExportData.deliveries,
            onTap: () => setState(() => _exportData = ExportData.deliveries),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionCard(
            icon: Icons.receipt_long,
            title: 'Transactions',
            subtitle: 'Mouvements wallet',
            isSelected: _exportData == ExportData.transactions,
            onTap: () => setState(() => _exportData = ExportData.transactions),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Row(
      children: [
        Expanded(
          child: _SelectionCard(
            icon: Icons.table_chart_outlined,
            title: 'CSV',
            subtitle: 'Excel / Tableur',
            isSelected: _exportType == ExportType.csv,
            onTap: () => setState(() => _exportType = ExportType.csv),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionCard(
            icon: Icons.share_outlined,
            title: 'Texte',
            subtitle: 'Partager relevé',
            isSelected: _exportType == ExportType.text,
            onTap: () => setState(() => _exportType = ExportType.text),
          ),
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    
    try {
      final exportService = EarningsExportService.instance;
      String? result;
      
      if (_exportData == ExportData.deliveries) {
        // Récupérer les livraisons
        final repository = ref.read(deliveryRepositoryProvider);
        final allDeliveries = await repository.getDeliveries(status: 'history');
        
        // Filtrer par date
        final filtered = allDeliveries.where((d) {
          final date = d.createdAt != null ? DateTime.tryParse(d.createdAt!) : null;
          if (date == null) return true;
          if (_dateFrom != null && date.isBefore(_dateFrom!)) return false;
          if (_dateTo != null && date.isAfter(_dateTo!.add(const Duration(days: 1)))) return false;
          return true;
        }).toList();
        
        if (_exportType == ExportType.csv) {
          result = await exportService.exportToCSV(
            deliveries: filtered,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          );
          
          if (result != null && mounted) {
            await exportService.shareFile(result, subject: 'Revenus DR-PHARMA - Livraisons');
          }
        } else {
          final report = exportService.generateEarningsReport(
            deliveries: filtered,
            courierName: widget.courierName,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          );
          await exportService.shareReport(report);
        }
      } else {
        // Transactions - fonctionnalité en développement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('L\'export des transactions sera disponible dans une prochaine mise à jour.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return; // Ne pas afficher le message de succès
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Export réussi !'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
}

enum ExportType { csv, text }
enum ExportData { deliveries, transactions }

/// Champ de sélection de date
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? minDate;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('fr', 'FR'),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null 
                      ? DateFormat('dd/MM/yyyy').format(value!)
                      : '—',
                    style: TextStyle(
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

/// Carte de sélection
class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.green.shade900 : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
