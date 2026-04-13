import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/master_detail_layout.dart';
import '../../../../core/presentation/widgets/voice_search_widget.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_state.dart';
import '../../../../core/presentation/widgets/skeleton_screens.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/inventory_provider.dart';
import '../providers/state/inventory_state.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/categories_management_sheet.dart';
import '../widgets/delivery_reception_sheet.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/stock_alerts_widget.dart';
import 'enhanced_scanner_page.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  /// GlobalKeys pour le tutoriel first-run
  final _searchKey = GlobalKey();
  final _voiceSearchKey = GlobalKey();
  final _scannerKey = GlobalKey();
  final _addProductKey = GlobalKey();
  final _filtersKey = GlobalKey();

  /// Produit sélectionné pour le mode master-detail sur tablette
  ProductEntity? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInventoryTutorial();
    });
  }

  /// Affiche le tutoriel de l'inventaire au premier lancement
  Future<void> _showInventoryTutorial() async {
    if (!mounted) return;

    final tutorialService = ref.read(tutorialServiceProvider);
    final targets = TutorialService.buildInventoryTargets(
      searchKey: _searchKey,
      filtersKey: _filtersKey,
      addProductKey: _addProductKey,
      productCardKey: GlobalKey(), // placeholder car optionnel
      voiceSearchKey: _voiceSearchKey,
      scannerKey: _scannerKey,
    );

    await tutorialService.showTutorialIfNeeded(
      context: context,
      tutorialKey: TutorialKeys.inventory,
      targets: targets,
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final String? res = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const EnhancedScannerPage()),
      );

      if (res != null && res != '-1' && mounted) {
        // Recherche vocale : chercher par nom au lieu de barcode
        if (res.startsWith('voice:')) {
          final query = res.substring(6);
          _searchController.text = query;
          ref.read(inventoryProvider.notifier).search(query);
          return;
        }

        final existingProduct = ref
            .read(inventoryProvider.notifier)
            .findProductByBarcode(res);

        if (existingProduct != null) {
          if (mounted) {
            _showUpdateStockDialog(context, existingProduct);
          }
        } else {
          if (mounted) {
            // OUVERTURE DE LA NOUVELLE MODALE PROFESSIONNELLE
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddProductSheet(scannedBarcode: res),
            );
          }
        }
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

  /// Démarre la recherche vocale
  Future<void> _startVoiceSearch() async {
    final result = await VoiceSearchModal.show(
      context,
      hintText: 'Recherche vocale',
    );

    if (result != null && result.isNotEmpty && mounted) {
      _searchController.text = result;
      ref.read(inventoryProvider.notifier).search(result);

      ErrorSnackBar.showInfo(context, 'Recherche: "$result"');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUpdateStockDialog(BuildContext context, ProductEntity product) {
    final currentStock = product.stockQuantity;
    final quantityController = TextEditingController(
      text: currentStock.toString(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setSheetState) {
            final isDark = AppColors.isDark(context);
            final entered =
                int.tryParse(quantityController.text) ?? currentStock;
            final delta = entered - currentStock;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Product header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.teal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Current stock badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: currentStock > 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentStock > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            'Stock actuel : $currentStock',
                            style: TextStyle(
                              color: currentStock > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Nouvelle quantité',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Stepper row
                    Row(
                      children: [
                        // Decrement
                        Material(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final cur =
                                  int.tryParse(quantityController.text) ??
                                  currentStock;
                              if (cur > 0) {
                                quantityController.text = (cur - 1).toString();
                                setSheetState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setSheetState(() {}),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              fillColor: isDark
                                  ? Colors.grey.shade900
                                  : Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Increment
                        Material(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final cur =
                                  int.tryParse(quantityController.text) ??
                                  currentStock;
                              quantityController.text = (cur + 1).toString();
                              setSheetState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.teal.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.teal,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Delta indicator
                    if (quantityController.text.isNotEmpty && delta != 0) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: delta > 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${delta > 0 ? '+' : ''}$delta unité${delta.abs() > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: delta > 0 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final newQty = int.tryParse(quantityController.text);
                          if (newQty != null && newQty >= 0) {
                            ref
                                .read(inventoryProvider.notifier)
                                .updateStock(product.id, newQty);
                            Navigator.of(sheetCtx).pop();
                            ErrorSnackBar.showSuccess(
                              context,
                              'Stock de ${product.name} mis à jour : $newQty unité${newQty != 1 ? 's' : ''}.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Mettre à jour le stock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => quantityController.dispose());
  }

  void _showStockAlerts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alertes de Stock',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Produits nécessitant votre attention',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppLocalizations.of(context).close,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              const Expanded(
                child: StockAlertsWidget(showHeader: false, maxAlerts: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final isDark = AppColors.isDark(context);

    // Filtrage avancé via le provider
    final filteredProducts = ref
        .read(inventoryProvider.notifier)
        .getFilteredProducts();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: MasterDetailLayout<ProductEntity>(
          selectedItem: _selectedProduct,
          detailFraction: 0.45,
          detailBuilder: (context, product) => ProductDetailsSheet(
            key: ValueKey(product.id),
            product: product,
            embedded: true,
          ),
          masterBuilder: (context, isCompact) => Column(
            children: [
              Container(
                color: AppColors.cardColor(context),
                padding: const EdgeInsets.only(top: 16, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête amélioré
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authProvider);
                        final pharmacyName =
                            authState.user?.pharmacies.isNotEmpty == true
                            ? (authState.user!.pharmacies.firstOrNull?.name)
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Icône avec fond dégradé
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal, Colors.teal.shade300],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.teal.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Titre et sous-titre
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gestion Stock',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pharmacyName ?? 'Inventaire et produits',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Notification
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[50],
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Consumer(
                                    builder: (context, ref, child) {
                                      final unreadCount = ref.watch(
                                        unreadNotificationCountProvider,
                                      );
                                      return Badge(
                                        isLabelVisible: unreadCount > 0,
                                        backgroundColor: Colors.redAccent,
                                        label: Text('$unreadCount'),
                                        child: Icon(
                                          Icons.notifications_none_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          size: 28,
                                        ),
                                      );
                                    },
                                  ),
                                  onPressed: () =>
                                      context.push('/notifications'),
                                  tooltip: 'Notifications',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Barre de recherche et scanneur
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: _searchKey,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher un produit...',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey,
                                    ),
                                    suffixIcon: KeyedSubtree(
                                      key: _voiceSearchKey,
                                      child: IconButton(
                                        onPressed: () => _startVoiceSearch(),
                                        icon: Icon(
                                          Icons.mic,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        tooltip: 'Recherche vocale',
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    ref
                                        .read(inventoryProvider.notifier)
                                        .search(value);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          KeyedSubtree(
                            key: _scannerKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner, size: 24),
                                tooltip: 'Scanner un produit',
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Réception de livraison
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const DeliveryReceptionSheet(),
                                );
                              },
                              icon: const Icon(
                                Icons.local_shipping_rounded,
                                size: 24,
                                color: Colors.teal,
                              ),
                              tooltip: 'Réceptionner une livraison',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const CategoriesManagementSheet(),
                                );
                              },
                              icon: const Icon(
                                Icons.category_outlined,
                                size: 24,
                                color: AppColors.info,
                              ), // Hardcoded color to avoid const error with dynamic theme color
                              tooltip: 'Gérer les catégories',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _showStockAlerts,
                              icon: const Icon(
                                Icons.warning_amber_rounded,
                                size: 24,
                                color: Colors.orange,
                              ),
                              tooltip: 'Alertes stock',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // -- Filtres avancés (chips défilants) --
                    KeyedSubtree(
                      key: _filtersKey,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Indicateur de filtres actifs
                            if (state.hasActiveFilters)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red.shade400,
                                  ),
                                  label: Text(
                                    'Effacer (${state.activeFilterCount})',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Colors.red.shade50,
                                  side: BorderSide(color: Colors.red.shade200),
                                  onPressed: () {
                                    ref
                                      .read(inventoryProvider.notifier)
                                      .clearAllFilters();
                                  _searchController.clear();
                                },
                              ),
                            ),

                          // Filtre Stock
                          _InventoryFilterChip(
                            label: _stockFilterLabel(state.stockFilter),
                            icon: Icons.inventory_2_outlined,
                            isActive: state.stockFilter != StockFilter.all,
                            onTap: () => _showStockFilterMenu(context, ref),
                          ),
                          const SizedBox(width: 8),

                          // Filtre Catégorie
                          _InventoryFilterChip(
                            label: state.selectedCategory ?? 'Catégorie',
                            icon: Icons.category_outlined,
                            isActive: state.selectedCategory != null,
                            onTap: () => _showCategoryFilterMenu(
                              context,
                              ref,
                              state.categories,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Filtre Ordonnance
                          _InventoryFilterChip(
                            label: state.requiresPrescriptionFilter == null
                                ? 'Ordonnance'
                                : (state.requiresPrescriptionFilter!
                                      ? 'Avec ordo.'
                                      : 'Sans ordo.'),
                            icon: Icons.medical_information_outlined,
                            isActive: state.requiresPrescriptionFilter != null,
                            onTap: () =>
                                _showPrescriptionFilterMenu(context, ref),
                          ),
                          const SizedBox(width: 8),

                          // Tri
                          _InventoryFilterChip(
                            label: _sortByLabel(state.sortBy),
                            icon: Icons.sort,
                            isActive: state.sortBy != ProductSortBy.name,
                            onTap: () => _showSortMenu(context, ref),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.status == InventoryStatus.loading &&
                        state.products.isEmpty) {
                      return SkeletonListBuilder.products();
                    }

                    if (state.status == InventoryStatus.error) {
                      return AppErrorState.loadFailed(
                        onRetry: () => ref
                            .read(inventoryProvider.notifier)
                            .fetchProducts(),
                        what: 'le stock',
                      );
                    }

                    if (filteredProducts.isEmpty) {
                      return AppEmptyState.inventory(
                        onAdd: () => ref
                            .read(inventoryProvider.notifier)
                            .fetchProducts(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(inventoryProvider.notifier)
                            .fetchProducts();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          Color statusColor;
                          Color bgColor;
                          IconData statusIcon;
                          String statusLabel;

                          if (product.isOutOfStock) {
                            statusColor = isDark
                                ? const Color(0xFFEF5350)
                                : AppColors.urgent; // Red
                            bgColor = isDark
                                ? const Color(0xFF3D1B1B)
                                : AppColors.errorBg;
                            statusIcon = Icons.warning_rounded;
                            statusLabel = 'Rupture';
                          } else if (product.isLowStock) {
                            statusColor = isDark
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFE65100); // Orange
                            bgColor = isDark
                                ? const Color(0xFF3D2E1B)
                                : AppColors.warningBg;
                            statusIcon = Icons.warning_amber_rounded;
                            statusLabel = 'Faible';
                          } else {
                            statusColor = isDark
                                ? const Color(0xFF81C784)
                                : AppColors.primary; // Green
                            bgColor = isDark
                                ? const Color(0xFF1B3D20)
                                : AppColors.primaryLight;
                            statusIcon = Icons.check_circle_outline_rounded;
                            statusLabel = 'En Stock';
                          }

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 20,
                              left: 4,
                              right: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : const Color(
                                          0xFF8D8D8D,
                                        ).withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Sur tablette: sélectionner dans le panneau de détails
                                  // Sur mobile: ouvrir en modal
                                  final width = MediaQuery.of(
                                    context,
                                  ).size.width;
                                  final isTablet = width >= 600;

                                  if (isTablet) {
                                    setState(() => _selectedProduct = product);
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          ProductDetailsSheet(product: product),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icone de statut ou Image Produit
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF2A2A2A)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: product.imageUrl != null
                                              ? Border.all(
                                                  color: isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.grey.shade200,
                                                  width: 1,
                                                )
                                              : null,
                                        ),
                                        child: ClipOval(
                                          child: product.imageUrl != null
                                              ? CachedNetworkImage(
                                                  imageUrl: product.imageUrl!,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, url, error) {
                                                    if (kDebugMode)
                                                      debugPrint(
                                                        "ERREUR IMAGE PROJET: ${product.imageUrl} - $error",
                                                      );
                                                    return Container(
                                                      color: Colors.red.shade50,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: Colors.indigo,
                                                        size: 24,
                                                      ),
                                                    );
                                                  },
                                                  progressIndicatorBuilder:
                                                      (context, url, progress) {
                                                        return Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12.0,
                                                                ),
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  value: progress
                                                                      .progress,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                )
                                              : Container(
                                                  color: bgColor,
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    statusIcon,
                                                    color: statusColor,
                                                    size: 24,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: bgColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.description.isEmpty
                                                  ? 'Aucune description'
                                                  : product.description,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF2A2A2A,
                                                          )
                                                        : const Color(
                                                            0xFFF5F7FA,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    NumberFormat.currency(
                                                      symbol: 'FCFA',
                                                      decimalDigits: 0,
                                                      locale: 'fr_FR',
                                                    ).format(product.price),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: 'Qte: ',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                    .grey[600],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '${product.stockQuantity}',
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _addProductKey,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddProductSheet(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // -- Helpers pour les labels des filtres --

  String _stockFilterLabel(StockFilter filter) => switch (filter) {
    StockFilter.all => 'Tout stock',
    StockFilter.inStock => 'En stock',
    StockFilter.lowStock => 'Stock bas',
    StockFilter.outOfStock => 'Rupture',
  };

  String _sortByLabel(ProductSortBy sortBy) => switch (sortBy) {
    ProductSortBy.name => 'Tri: Nom',
    ProductSortBy.priceAsc => 'Prix ↑',
    ProductSortBy.priceDesc => 'Prix ↓',
    ProductSortBy.stockAsc => 'Stock ↑',
    ProductSortBy.stockDesc => 'Stock ↓',
  };

  // -- Menus de filtrage --

  void _showStockFilterMenu(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtrer par stock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            for (final filter in StockFilter.values)
              ListTile(
                leading: Icon(
                  filter == StockFilter.all
                      ? Icons.inventory_2_outlined
                      : filter == StockFilter.inStock
                      ? Icons.check_circle_outline
                      : filter == StockFilter.lowStock
                      ? Icons.warning_amber_rounded
                      : Icons.remove_circle_outline,
                  color: filter == StockFilter.inStock
                      ? Colors.green
                      : filter == StockFilter.lowStock
                      ? Colors.orange
                      : filter == StockFilter.outOfStock
                      ? Colors.red
                      : null,
                ),
                title: Text(_stockFilterLabel(filter)),
                trailing: ref.watch(inventoryProvider).stockFilter == filter
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  ref.read(inventoryProvider.notifier).setStockFilter(filter);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterMenu(
    BuildContext context,
    WidgetRef ref,
    List<CategoryEntity> categories,
  ) {
    final isDark = AppColors.isDark(context);
    final currentCategory = ref.read(inventoryProvider).selectedCategory;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtrer par catégorie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Toutes les catégories'),
              trailing: currentCategory == null
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref.read(inventoryProvider.notifier).setCategoryFilter(null);
                Navigator.pop(ctx);
              },
            ),
            ...categories.map(
              (cat) => ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(cat.name),
                trailing: currentCategory == cat.name
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  ref
                      .read(inventoryProvider.notifier)
                      .setCategoryFilter(cat.name);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionFilterMenu(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final currentFilter = ref
        .read(inventoryProvider)
        .requiresPrescriptionFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtrer par ordonnance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tous les produits'),
              trailing: currentFilter == null
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref
                    .read(inventoryProvider.notifier)
                    .setPrescriptionFilter(null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_information, color: Colors.red),
              title: const Text('Avec ordonnance'),
              trailing: currentFilter == true
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref
                    .read(inventoryProvider.notifier)
                    .setPrescriptionFilter(true);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.green,
              ),
              title: const Text('Sans ordonnance'),
              trailing: currentFilter == false
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref
                    .read(inventoryProvider.notifier)
                    .setPrescriptionFilter(false);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final currentSort = ref.read(inventoryProvider).sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trier par',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            for (final sort in ProductSortBy.values)
              ListTile(
                leading: Icon(
                  sort == ProductSortBy.name
                      ? Icons.sort_by_alpha
                      : sort == ProductSortBy.priceAsc ||
                            sort == ProductSortBy.priceDesc
                      ? Icons.attach_money
                      : Icons.inventory_2_outlined,
                ),
                title: Text(_sortByLabel(sort)),
                trailing: currentSort == sort
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  ref.read(inventoryProvider.notifier).setSortBy(sort);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// -- Widget FilterChip personnalisé pour l'inventaire --
class _InventoryFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _InventoryFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: isActive
          ? primaryColor.withValues(alpha: 0.12)
          : (isDark ? Colors.grey[800] : Colors.grey[100]),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
