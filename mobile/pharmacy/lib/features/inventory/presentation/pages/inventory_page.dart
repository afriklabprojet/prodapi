import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/voice_search_widget.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/inventory_provider.dart';
import '../providers/state/inventory_state.dart';
import '../widgets/add_product_sheet.dart'; 
import '../widgets/categories_management_sheet.dart';
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

  Future<void> _scanBarcode() async {
    try {
      final String? res = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const EnhancedScannerPage(),
        ),
      );

      if (res != null && res != '-1' && mounted) {
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
    final quantityController = TextEditingController(
      text: product.stockQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Mettre à jour le stock: ${product.name}'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nouvelle quantité',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  ref
                      .read(inventoryProvider.notifier)
                      .updateStock(product.id, newQuantity);
                  Navigator.pop(context);
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
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
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              const Expanded(
                child: StockAlertsWidget(
                  showHeader: false,
                  maxAlerts: 20,
                ),
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

    // Filter products based on search query
    final filteredProducts = state.products.where((product) {
      final query = state.searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: Column(
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
                      final pharmacyName = authState.user?.pharmacies.isNotEmpty == true 
                          ? (authState.user!.pharmacies.firstOrNull?.name) 
                          : null;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            // Icône avec fond dégradé
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal,
                                    Colors.teal.shade300,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isDark ? [] : [
                                  BoxShadow(
                                    color: Colors.teal.withValues(alpha: 0.3),
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
                                      color: isDark ? Colors.white : Colors.black87,
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
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Notification
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[50],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Consumer(
                                  builder: (context, ref, child) {
                                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                                    return Badge(
                                      isLabelVisible: unreadCount > 0,
                                      backgroundColor: Colors.redAccent,
                                      smallSize: 10,
                                      label: unreadCount > 0 ? null : null, 
                                      child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : Colors.black87, size: 28),
                                    );
                                  },
                                ),
                                onPressed: () => context.push('/notifications'),
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Rechercher un produit...',
                                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : Colors.grey),
                                suffixIcon: IconButton(
                                  onPressed: () => _startVoiceSearch(),
                                  icon: Icon(
                                    Icons.mic,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  tooltip: 'Recherche vocale',
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onChanged: (value) {
                                ref.read(inventoryProvider.notifier).search(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: IconButton(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner, size: 24),
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
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
                              )
                            ]
                          ),
                          child: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const CategoriesManagementSheet(),
                              );
                            },
                            icon: const Icon(Icons.category_outlined, size: 24, color: Color(0xFF1E88E5)), // Hardcoded color to avoid const error with dynamic theme color
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
                              )
                            ]
                          ),
                          child: IconButton(
                            onPressed: _showStockAlerts,
                            icon: const Icon(Icons.warning_amber_rounded, size: 24, color: Colors.orange),
                            tooltip: 'Alertes stock',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.status == InventoryStatus.loading &&
                      state.products.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }

                  if (state.status == InventoryStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${state.errorMessage}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .fetchProducts();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucun produit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre stock est vide ou aucun\nproduit ne correspond à la recherche.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(inventoryProvider.notifier).fetchProducts();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      Color statusColor;
                      Color bgColor;
                      IconData statusIcon;
                      String statusLabel;

                      if (product.isOutOfStock) {
                        statusColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828); // Red
                        bgColor = isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFFEBEE);
                        statusIcon = Icons.warning_rounded;
                        statusLabel = 'Rupture';
                      } else if (product.isLowStock) {
                        statusColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100); // Orange
                        bgColor = isDark ? const Color(0xFF3D2E1B) : const Color(0xFFFFF3E0);
                        statusIcon = Icons.warning_amber_rounded;
                        statusLabel = 'Faible';
                      } else {
                        statusColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32); // Green
                        bgColor = isDark ? const Color(0xFF1B3D20) : const Color(0xFFE8F5E9);
                        statusIcon = Icons.check_circle_outline_rounded;
                        statusLabel = 'En Stock';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                  ? Colors.black.withValues(alpha: 0.3) 
                                  : const Color(0xFF8D8D8D).withValues(alpha: 0.1),
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
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ProductDetailsSheet(product: product),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icone de statut ou Image Produit
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: product.imageUrl != null 
                                          ? Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1)
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
                                                if (kDebugMode) debugPrint("ERREUR IMAGE PROJET: ${product.imageUrl} - $error");
                                                return Container(
                                                  color: Colors.red.shade50,
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.broken_image_rounded, color: Colors.indigo, size: 24),
                                                );
                                              },
                                              progressIndicatorBuilder: (context, url, progress) {
                                                return Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: progress.progress,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: bgColor,
                                              alignment: Alignment.center,
                                              child: Icon(statusIcon, color: statusColor, size: 24),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description.isEmpty ? 'Aucune description' : product.description,
                                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0, locale: 'fr_FR').format(product.price),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : Colors.black87,
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
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${product.stockQuantity}',
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w800,
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
      floatingActionButton: FloatingActionButton(
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
}
