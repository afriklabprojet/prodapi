import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../products/presentation/providers/products_state.dart';
import '../../domain/entities/treatment_entity.dart';
import '../providers/treatments_provider.dart';

class AddTreatmentPage extends ConsumerStatefulWidget {
  final ProductEntity? initialProduct;
  final TreatmentEntity? initialTreatment;

  const AddTreatmentPage({
    super.key,
    this.initialProduct,
    this.initialTreatment,
  }) : assert(
         initialProduct == null || initialTreatment == null,
         'Provide either initialProduct or initialTreatment, not both',
       );

  @override
  ConsumerState<AddTreatmentPage> createState() => _AddTreatmentPageState();
}

class _AddTreatmentPageState extends ConsumerState<AddTreatmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _customDaysController = TextEditingController();

  ProductEntity? _selectedProduct;
  String? _selectedFrequency;
  RenewalPeriod _selectedPeriod = RenewalPeriod.oneMonth;
  int _reminderDaysBefore = 3;
  bool _reminderEnabled = true;
  bool _isSearching = false;
  bool _isSaving = false;

  final List<String> _frequencies = [
    '1 fois par jour',
    '2 fois par jour',
    '3 fois par jour',
    '4 fois par jour',
    '1 fois par semaine',
    'Au besoin',
  ];

  bool get _isEditMode => widget.initialTreatment != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _selectedProduct = widget.initialProduct;
    }
    if (widget.initialTreatment != null) {
      final t = widget.initialTreatment!;
      _dosageController.text = t.dosage ?? '';
      _quantityController.text = (t.quantityPerRenewal ?? 1).toString();
      _notesController.text = t.notes ?? '';
      _selectedFrequency = t.frequency;
      _reminderEnabled = t.reminderEnabled;
      _reminderDaysBefore = t.reminderDaysBefore;
      _selectedPeriod = RenewalPeriod.values.firstWhere(
        (p) => p != RenewalPeriod.custom && p.days == t.renewalPeriodDays,
        orElse: () => RenewalPeriod.custom,
      );
      if (_selectedPeriod == RenewalPeriod.custom) {
        _customDaysController.text = t.renewalPeriodDays.toString();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Modifier le traitement' : 'Ajouter un traitement',
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section 1: Sélection du produit
            _buildSectionTitle('Médicament', Icons.medication_rounded),
            const SizedBox(height: 12),

            if (_isEditMode) ...[
              _buildLockedProduct(widget.initialTreatment!.productName),
            ] else if (_selectedProduct == null) ...[
              _buildProductSearch(),
            ] else ...[
              _buildSelectedProduct(),
            ],

            const SizedBox(height: 24),

            // Section 2: Détails du traitement
            _buildSectionTitle('Détails du traitement', Icons.info_outline),
            const SizedBox(height: 12),

            // Dosage
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (optionnel)',
                hintText: 'ex: 500mg, 2 comprimés',
                prefixIcon: Icon(Icons.science_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Fréquence
            DropdownButtonFormField<String>(
              initialValue: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence de prise',
                prefixIcon: Icon(Icons.schedule_outlined),
                border: OutlineInputBorder(),
              ),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedFrequency = value),
            ),
            const SizedBox(height: 16),

            // Quantité par renouvellement
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité par commande',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                final n = int.tryParse(value);
                if (n == null || n < 1) return 'Quantité invalide';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Section 3: Renouvellement
            _buildSectionTitle('Renouvellement', Icons.autorenew),
            const SizedBox(height: 12),

            // Période de renouvellement
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RenewalPeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return ChoiceChip(
                  label: Text(period.label),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPeriod = period);
                    }
                  },
                );
              }).toList(),
            ),

            // Jours personnalisés
            if (_selectedPeriod == RenewalPeriod.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de jours',
                  suffixText: 'jours',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedPeriod == RenewalPeriod.custom) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final n = int.tryParse(value);
                    if (n == null || n < 1) return 'Nombre invalide';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Section 4: Rappels
            _buildSectionTitle('Rappels', Icons.notifications_active_outlined),
            const SizedBox(height: 12),

            SwitchListTile(
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              title: const Text('Activer les rappels'),
              subtitle: const Text(
                'Recevez une notification avant le renouvellement',
              ),
              secondary: Icon(
                _reminderEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _reminderEnabled ? AppColors.primary : Colors.grey,
              ),
            ),

            if (_reminderEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Me rappeler '),
                  DropdownButton<int>(
                    value: _reminderDaysBefore,
                    underline: Container(height: 1, color: AppColors.primary),
                    items: [1, 2, 3, 5, 7, 14]
                        .map(
                          (days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _reminderDaysBefore = value!),
                  ),
                  Text(' jour${_reminderDaysBefore > 1 ? 's' : ''} avant'),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Instructions particulières, remarques...',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    (_isEditMode || _selectedProduct != null) && !_isSaving
                    ? _saveTreatment
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Enregistrement...'
                      : _isEditMode
                      ? 'Enregistrer les modifications'
                      : 'Enregistrer le traitement',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProductSearch() {
    final productsState = ref.watch(productsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un médicament...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onSearchChanged,
        ),

        // Résultats de recherche
        if (productsState.status == ProductsStatus.loaded &&
            productsState.products.isNotEmpty &&
            _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: productsState.products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = productsState.products[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medication, color: AppColors.primary),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    product.pharmacy.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () => _selectProduct(product),
                );
              },
            ),
          ),
        ],

        if (productsState.status == ProductsStatus.loaded &&
            productsState.products.isEmpty &&
            _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildLockedProduct(String name) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Médicament (non modifiable)'),
        trailing: const Icon(Icons.lock_outline, color: Colors.grey),
      ),
    );
  }

  Widget _buildSelectedProduct() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          _selectedProduct!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_selectedProduct!.pharmacy.name),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _selectedProduct = null;
            _searchController.clear();
          }),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      setState(() => _isSearching = true);
      ref.read(productsProvider.notifier).searchProducts(query);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isSearching = false);
      });
    }
  }

  void _selectProduct(ProductEntity product) {
    setState(() {
      _selectedProduct = product;
      _searchController.clear();
    });
    // Clear search results
    ref.read(productsProvider.notifier).clearSearch();
  }

  Future<void> _saveTreatment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditMode && _selectedProduct == null) return;

    setState(() => _isSaving = true);

    final renewalDays = _selectedPeriod == RenewalPeriod.custom
        ? int.parse(_customDaysController.text)
        : _selectedPeriod.days;

    bool success;
    String productName;

    if (_isEditMode) {
      final original = widget.initialTreatment!;
      final updated = original.copyWith(
        dosage: _dosageController.text.isNotEmpty
            ? _dosageController.text
            : null,
        frequency: _selectedFrequency,
        quantityPerRenewal: int.tryParse(_quantityController.text) ?? 1,
        renewalPeriodDays: renewalDays,
        reminderEnabled: _reminderEnabled,
        reminderDaysBefore: _reminderDaysBefore,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      productName = original.productName;
      success = await ref
          .read(treatmentsProvider.notifier)
          .updateTreatment(updated);
    } else {
      final treatment = TreatmentEntity(
        id: const Uuid().v4(),
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        productImage: _selectedProduct!.imageUrl,
        dosage: _dosageController.text.isNotEmpty
            ? _dosageController.text
            : null,
        frequency: _selectedFrequency,
        quantityPerRenewal: int.tryParse(_quantityController.text) ?? 1,
        renewalPeriodDays: renewalDays,
        nextRenewalDate: DateTime.now().add(Duration(days: renewalDays)),
        reminderEnabled: _reminderEnabled,
        reminderDaysBefore: _reminderDaysBefore,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isActive: true,
        createdAt: DateTime.now(),
      );
      productName = treatment.productName;
      success = await ref
          .read(treatmentsProvider.notifier)
          .addTreatment(treatment);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      final msg = _isEditMode
          ? '$productName mis à jour'
          : '$productName ajouté à vos traitements';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
