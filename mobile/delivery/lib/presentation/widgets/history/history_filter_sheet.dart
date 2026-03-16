import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/delivery_filters.dart';
import '../../providers/history_providers.dart';
import '../../../core/theme/theme_provider.dart';

/// Bottom sheet pour les filtres de l'historique
class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HistoryFilterSheet(),
    );
  }

  @override
  ConsumerState<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late String? _status;
  late String? _pharmacyName;
  late SortBy _sortBy;
  late SortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(historyFiltersProvider);
    _dateFrom = filters.dateFrom;
    _dateTo = filters.dateTo;
    _status = filters.status;
    _pharmacyName = filters.pharmacyName;
    _sortBy = filters.sortBy;
    _sortOrder = filters.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(uniquePharmaciesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                      _status = null;
                      _pharmacyName = null;
                      _sortBy = SortBy.date;
                      _sortOrder = SortOrder.desc;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Préréglages rapides
                  _buildSectionTitle('Période rapide'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('Aujourd\'hui', 'today'),
                      _buildPresetChip('Cette semaine', 'week'),
                      _buildPresetChip('Ce mois', 'month'),
                      _buildPresetChip('Tout', 'all'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Plage de dates personnalisée
                  _buildSectionTitle('Période personnalisée'),
                  const SizedBox(height: 8),
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
                  
                  // Statut
                  _buildSectionTitle('Statut'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip('Tous', null),
                      _buildStatusChip('Livrées', 'delivered', Colors.green),
                      _buildStatusChip('Annulées', 'cancelled', Colors.red),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pharmacie
                  _buildSectionTitle('Pharmacie'),
                  const SizedBox(height: 8),
                  pharmaciesAsync.when(
                    data: (pharmacies) => _PharmacyDropdown(
                      pharmacies: pharmacies,
                      selectedName: _pharmacyName,
                      onChanged: (name) => setState(() => _pharmacyName = name),
                    ),
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => const Text('Erreur de chargement'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tri
                  _buildSectionTitle('Tri'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _SortByDropdown(
                          value: _sortBy,
                          onChanged: (v) => setState(() => _sortBy = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SortOrderToggle(
                          value: _sortOrder,
                          onChanged: (v) => setState(() => _sortOrder = v),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 
              16, 
              16, 
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
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

  Widget _buildPresetChip(String label, String preset) {
    final isSelected = _isPresetSelected(preset);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectPreset(preset),
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }

  bool _isPresetSelected(String preset) {
    if (preset == 'all') {
      return _dateFrom == null && _dateTo == null;
    }
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    switch (preset) {
      case 'today':
        return _dateFrom?.day == startOfDay.day &&
               _dateFrom?.month == startOfDay.month &&
               _dateFrom?.year == startOfDay.year;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return _dateFrom?.day == startOfWeek.day &&
               _dateFrom?.month == startOfWeek.month;
      case 'month':
        return _dateFrom?.day == 1 && _dateFrom?.month == now.month;
      default:
        return false;
    }
  }

  void _selectPreset(String preset) {
    setState(() {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      switch (preset) {
        case 'today':
          _dateFrom = DateTime(now.year, now.month, now.day);
          _dateTo = endOfDay;
          break;
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _dateFrom = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          _dateTo = now;
          break;
        case 'month':
          _dateFrom = DateTime(now.year, now.month, 1);
          _dateTo = now;
          break;
        case 'all':
          _dateFrom = null;
          _dateTo = null;
          break;
      }
    });
  }

  Widget _buildStatusChip(String label, String? status, [Color? color]) {
    final isSelected = _status == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _status = status),
      selectedColor: color?.withValues(alpha: 0.2) ?? Colors.grey.shade200,
      avatar: color != null ? Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ) : null,
    );
  }

  void _applyFilters() {
    final notifier = ref.read(historyFiltersProvider.notifier);
    notifier.setDateRange(_dateFrom, _dateTo);
    notifier.setStatus(_status);
    notifier.setPharmacy(null, _pharmacyName);
    notifier.setSortBy(_sortBy);
    notifier.setSortOrder(_sortOrder);
    Navigator.pop(context);
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null 
                      ? DateFormat('dd/MM/yyyy').format(value!)
                      : 'Sélectionner',
                    style: TextStyle(
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null) 
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
              )
            else
              Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

/// Dropdown pour sélectionner une pharmacie
class _PharmacyDropdown extends StatelessWidget {
  final List<PharmacyOption> pharmacies;
  final String? selectedName;
  final ValueChanged<String?> onChanged;

  const _PharmacyDropdown({
    required this.pharmacies,
    required this.selectedName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedName,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Toutes les pharmacies'),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Toutes les pharmacies'),
            ),
            ...pharmacies.map((p) => DropdownMenuItem<String?>(
              value: p.name,
              child: Text(p.name, overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Dropdown pour le tri
class _SortByDropdown extends StatelessWidget {
  final SortBy value;
  final ValueChanged<SortBy> onChanged;

  const _SortByDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortBy>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: SortBy.values.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.label),
          )).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Toggle pour l'ordre de tri
class _SortOrderToggle extends StatelessWidget {
  final SortOrder value;
  final ValueChanged<SortOrder> onChanged;

  const _SortOrderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(
        value == SortOrder.asc ? SortOrder.desc : SortOrder.asc,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          value == SortOrder.asc 
            ? Icons.arrow_upward 
            : Icons.arrow_downward,
          color: Colors.blue,
        ),
      ),
    );
  }
}
