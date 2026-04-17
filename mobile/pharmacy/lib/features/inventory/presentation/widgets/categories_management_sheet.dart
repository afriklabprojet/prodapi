import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/inventory_provider.dart';

class CategoriesManagementSheet extends ConsumerStatefulWidget {
  const CategoriesManagementSheet({super.key});

  @override
  ConsumerState<CategoriesManagementSheet> createState() =>
      _CategoriesManagementSheetState();
}

class _CategoriesManagementSheetState
    extends ConsumerState<CategoriesManagementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  CategoryEntity? _editingCategory; // null = creating, non-null = editing

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _startCreate() {
    _nameController.clear();
    _descController.clear();
    setState(() {
      _isEditing = true;
      _editingCategory = null;
    });
  }

  void _startEdit(CategoryEntity category) {
    _nameController.text = category.name;
    _descController.text = category.description ?? '';
    setState(() {
      _isEditing = true;
      _editingCategory = category;
    });
  }

  void _cancelEdit() {
    _nameController.clear();
    _descController.clear();
    setState(() {
      _isEditing = false;
      _editingCategory = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    try {
      if (_editingCategory != null) {
        // Update existing category
        await ref
            .read(inventoryProvider.notifier)
            .updateCategory(
              _editingCategory!.id,
              name,
              description.isEmpty ? null : description,
            );
        if (mounted) {
          ErrorSnackBar.showSuccess(
            context,
            "Catégorie modifiée avec succès !",
          );
        }
      } else {
        // Create new category
        await ref
            .read(inventoryProvider.notifier)
            .addCategory(name, description.isEmpty ? null : description);
        if (mounted) {
          ErrorSnackBar.showSuccess(context, "Catégorie ajoutée avec succès !");
        }
      }

      // Reset form
      _nameController.clear();
      _descController.clear();
      setState(() {
        _isEditing = false;
        _editingCategory = null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.showError(
          context,
          ErrorMessages.getInventoryError(e.toString()),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.delete} la catégorie'),
        content: Text('Voulez-vous vraiment supprimer « ${category.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(inventoryProvider.notifier).deleteCategory(category.id);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, "Catégorie supprimée !");
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.showError(
          context,
          ErrorMessages.getInventoryError(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch categories from provider
    final state = ref.watch(inventoryProvider);
    final categories = state.categories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestion des Catégories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor(context),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textColor(context)),
                  onPressed: () => context.pop(),
                  tooltip: AppLocalizations.of(context).close,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.isDark(context)
                ? Colors.grey[700]
                : Colors.grey[300],
          ),

          // List or creation/edit form
          if (_isEditing)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingCategory != null
                            ? 'Modifier la Catégorie'
                            : 'Nouvelle Catégorie',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textColor(context)),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: AppColors.textColor(context)),
                        decoration: InputDecoration(
                          labelText: 'Nom de la catégorie',
                          labelStyle: TextStyle(
                            color: AppColors.textColor(
                              context,
                            ).withValues(alpha: 0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.isDark(context)
                              ? Colors.grey[800]
                              : Colors.grey[50],
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        style: TextStyle(color: AppColors.textColor(context)),
                        decoration: InputDecoration(
                          labelText: 'Description (optionnel)',
                          labelStyle: TextStyle(
                            color: AppColors.textColor(
                              context,
                            ).withValues(alpha: 0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.isDark(context)
                              ? Colors.grey[800]
                              : Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(AppLocalizations.of(context).cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _editingCategory != null
                                          ? AppLocalizations.of(context).save
                                          : AppLocalizations.of(context).add,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune catégorie définie',
                        style: TextStyle(
                          color: AppColors.textColor(
                            context,
                          ).withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final primaryColor = Theme.of(
                          context,
                        ).colorScheme.primary;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardColor(context),
                            border: Border.all(
                              color: AppColors.isDark(context)
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => _startEdit(cat),
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                cat.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              cat.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor(context),
                              ),
                            ),
                            subtitle:
                                cat.description != null &&
                                    cat.description!.isNotEmpty
                                ? Text(
                                    cat.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textColor(
                                        context,
                                      ).withValues(alpha: 0.7),
                                    ),
                                  )
                                : null,
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: AppColors.textColor(context),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _startEdit(cat);
                                } else if (value == 'delete') {
                                  _deleteCategory(cat);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(AppLocalizations.of(context).edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(context).delete,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

          // Add button only when list is shown
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une catégorie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
