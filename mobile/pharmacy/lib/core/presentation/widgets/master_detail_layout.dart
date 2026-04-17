import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'responsive_builder.dart';

/// Configuration pour le layout master-detail
typedef MasterDetailConfig = ({
  double detailFraction,
  double minMasterWidth,
  double dividerWidth,
});

/// Layout master-detail adaptatif pour tablette et desktop.
///
/// Sur mobile (isCompact=true) : affiche uniquement le master.
/// Sur tablette/desktop : affiche master à gauche et detail à droite.
///
/// Supporte deux modes d'utilisation :
/// 1. API simple avec masterBuilder/detailBuilder pour contrôle total
/// 2. API items-based pour listes avec sélection automatique
class MasterDetailLayout<T> extends StatelessWidget {
  /// Builder pour le panneau master. Reçoit isCompact pour adapter l'UI.
  final Widget Function(BuildContext context, bool isCompact) masterBuilder;

  /// Builder pour le panneau de détail. Appelé quand selectedItem != null.
  final Widget Function(BuildContext context, T item)? detailBuilder;

  /// Élément actuellement sélectionné (pour mode externe)
  final T? selectedItem;

  /// Widget à afficher quand aucun élément n'est sélectionné
  final Widget? emptyDetailPlaceholder;

  /// Fraction de largeur pour le panneau de détails (0.0 à 1.0)
  final double detailFraction;

  /// Largeur minimale du panneau master en pixels
  final double minMasterWidth;

  /// Affiche un diviseur entre les panneaux
  final bool showDivider;

  /// Configuration personnalisée (remplace detailFraction, minMasterWidth)
  final MasterDetailConfig? config;

  const MasterDetailLayout({
    super.key,
    required this.masterBuilder,
    this.detailBuilder,
    this.selectedItem,
    this.emptyDetailPlaceholder,
    this.detailFraction = 0.4,
    this.minMasterWidth = 300,
    this.showDivider = true,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConfig =
        config ??
        (
          detailFraction: detailFraction,
          minMasterWidth: minMasterWidth,
          dividerWidth: 1.0,
        );

    return ResponsiveBuilder(
      builder: (context, responsive) {
        final isCompact = responsive.isMobile;

        // Mobile: only show master
        if (isCompact) {
          return masterBuilder(context, true);
        }

        // Tablet/Desktop: show master + detail side by side
        return Row(
          children: [
            // Master panel (liste)
            Expanded(
              flex: ((1 - effectiveConfig.detailFraction) * 100).round(),
              child: masterBuilder(context, false),
            ),

            // Divider
            if (showDivider)
              VerticalDivider(
                width: effectiveConfig.dividerWidth,
                thickness: effectiveConfig.dividerWidth,
                color: AppColors.isDark(context)
                    ? Colors.grey[800]
                    : Colors.grey[300],
              ),

            // Detail panel
            Expanded(
              flex: (effectiveConfig.detailFraction * 100).round(),
              child: _buildDetailPanel(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailPanel(BuildContext context) {
    final item = selectedItem;

    if (item != null && detailBuilder != null) {
      return detailBuilder!(context, item);
    }

    return emptyDetailPlaceholder ?? _DefaultEmptyDetail();
  }
}

/// Widget par défaut quand aucun élément n'est sélectionné
class _DefaultEmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      color: AppColors.backgroundColor(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un élément',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les détails s\'afficheront ici',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// API ALTERNATIVE : MasterDetailListLayout pour listes avec gestion auto
// ============================================================================

/// Layout master-detail avec gestion automatique de la liste et sélection.
///
/// Usage pour cas plus complexes avec listes d'éléments.
class MasterDetailListLayout<T> extends StatefulWidget {
  /// Liste des éléments à afficher dans le master
  final List<T> items;

  /// Builder pour chaque élément de la liste master
  final Widget Function(BuildContext context, T item, bool isSelected)
  masterItemBuilder;

  /// Builder pour le panel de détail
  final Widget Function(BuildContext context, T item) detailBuilder;

  /// Widget à afficher quand aucun élément n'est sélectionné (tablette/desktop)
  final Widget? emptyDetailWidget;

  /// Callback quand un élément est sélectionné sur mobile (navigation)
  final void Function(T item)? onMobileItemTap;

  /// Header optionnel au-dessus de la liste master
  final Widget? masterHeader;

  /// Padding de la liste master
  final EdgeInsets masterPadding;

  /// Ratio de largeur du master (0.0 à 1.0)
  final double masterWidthRatio;

  /// Élément initialement sélectionné
  final T? initialSelectedItem;

  /// Comparateur pour déterminer si deux éléments sont égaux
  final bool Function(T a, T b)? itemEquals;

  /// Callback quand la sélection change
  final void Function(T? item)? onSelectionChanged;

  /// Widget de chargement
  final Widget? loadingWidget;

  /// Widget d'état vide
  final Widget? emptyWidget;

  /// Est en chargement ?
  final bool isLoading;

  const MasterDetailListLayout({
    super.key,
    required this.items,
    required this.masterItemBuilder,
    required this.detailBuilder,
    this.emptyDetailWidget,
    this.onMobileItemTap,
    this.masterHeader,
    this.masterPadding = const EdgeInsets.symmetric(vertical: 8),
    this.masterWidthRatio = 0.4,
    this.initialSelectedItem,
    this.itemEquals,
    this.onSelectionChanged,
    this.loadingWidget,
    this.emptyWidget,
    this.isLoading = false,
  });

  @override
  State<MasterDetailListLayout<T>> createState() =>
      _MasterDetailListLayoutState<T>();
}

class _MasterDetailListLayoutState<T> extends State<MasterDetailListLayout<T>> {
  T? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialSelectedItem;
  }

  @override
  void didUpdateWidget(MasterDetailListLayout<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'élément sélectionné n'existe plus dans la liste, le désélectionner
    if (_selectedItem != null && !_itemExistsInList(_selectedItem as T)) {
      _selectedItem = null;
    }
  }

  bool _itemExistsInList(T item) {
    return widget.items.any((i) => _areItemsEqual(i, item));
  }

  bool _areItemsEqual(T a, T b) {
    if (widget.itemEquals != null) {
      return widget.itemEquals!(a, b);
    }
    return a == b;
  }

  void _selectItem(T item, bool isCompact) {
    if (isCompact) {
      // Sur mobile, appeler le callback de navigation
      widget.onMobileItemTap?.call(item);
    } else {
      // Sur tablette/desktop, mettre à jour la sélection
      setState(() => _selectedItem = item);
      widget.onSelectionChanged?.call(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        final isCompact = responsive.isMobile;

        if (isCompact) {
          return _buildMasterList(context, isCompact);
        }

        // Tablette/Desktop : layout côte à côte
        return Row(
          children: [
            // Panel master (liste)
            Expanded(
              flex: ((1 - widget.masterWidthRatio) * 100).round(),
              child: _buildMasterList(context, isCompact),
            ),

            // Diviseur vertical
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.isDark(context)
                  ? Colors.grey[800]
                  : Colors.grey[300],
            ),

            // Panel de détail
            Expanded(
              flex: (widget.masterWidthRatio * 100).round(),
              child: _buildDetailPanel(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasterList(BuildContext context, bool isCompact) {
    // État de chargement
    if (widget.isLoading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Liste vide
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _DefaultEmptyDetail();
    }

    return Column(
      children: [
        // Header optionnel
        if (widget.masterHeader != null) widget.masterHeader!,

        // Liste des éléments
        Expanded(
          child: ListView.builder(
            padding: widget.masterPadding,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected =
                  !isCompact &&
                  _selectedItem != null &&
                  _areItemsEqual(item, _selectedItem as T);

              return GestureDetector(
                onTap: () => _selectItem(item, isCompact),
                child: widget.masterItemBuilder(context, item, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(BuildContext context) {
    final item = _selectedItem;

    if (item != null) {
      return widget.detailBuilder(context, item);
    }

    return widget.emptyDetailWidget ?? _DefaultEmptyDetail();
  }
}
