import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import '../providers/payment_provider.dart';
import '../providers/payment_state.dart';
import '../providers/cart_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/entities/pharmacy_entity.dart' as products;
import 'payment_webview_page.dart';
import '../widgets/payment_dialogs.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../widgets/order_status_timeline.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../main_shell_page.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final order = ordersState.selectedOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(mainShellTabProvider.notifier).state = 1;
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          if (order != null && order.canBeCancelled)
            IconButton(
              onPressed: () => _showCancelDialog(order),
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Annuler la commande',
            ),
        ],
      ),
      body: ordersState.status == OrdersStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : ordersState.status == OrdersStatus.error
          ? _buildError(ordersState.errorMessage)
          : order == null
          ? _buildError('Commande non trouvée')
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(ordersProvider.notifier)
                    .loadOrderDetails(widget.orderId);
              },
              child: _buildOrderDetails(order),
            ),
      bottomNavigationBar: (order != null && order.needsPayment)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => _initiatePayment(order.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Payer maintenant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Une erreur s\'est produite',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(ordersProvider.notifier)
                      .loadOrderDetails(widget.orderId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(OrderEntity order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(order),
          const SizedBox(height: 16),

          // Timeline de statuts
          OrderStatusTimeline(
            order: order,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: 16),

          // Order Info
          _buildSectionCard('Informations', [
            _buildInfoRow('Référence', order.reference),
            _buildInfoRow(
              'Date',
              DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(order.createdAt),
            ),
            _buildInfoRow('Paiement', order.paymentMode.displayName),
            if (order.paidAt != null)
              _buildInfoRow(
                'Payé le',
                DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(order.paidAt!),
              ),
          ]),
          const SizedBox(height: 16),

          // Pharmacy Info
          _buildSectionCard('Pharmacie', [
            _buildInfoRow('Nom', order.pharmacyName),
            if (order.pharmacyPhone != null)
              _buildPhoneRow('Téléphone', order.pharmacyPhone!),
            if (order.pharmacyAddress != null)
              _buildAddressRow('Adresse', order.pharmacyAddress!),
          ]),
          const SizedBox(height: 8),

          // Pharmacy chat button
          if (order.pharmacyId != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Contacter la pharmacie'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        orderId: order.id,
                        deliveryId: order.deliveryId,
                        participantId: order.pharmacyId,
                        participantName: order.pharmacyName,
                        participantType: 'pharmacy',
                        participantPhone: order.pharmacyPhone,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Courier chat button — visible when courier is assigned
          if (order.courierId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delivery_dining_outlined, size: 18),
                  label: const Text('Contacter le livreur'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        orderId: order.id,
                        deliveryId: order.deliveryId,
                        participantId: order.courierId!,
                        participantName: order.courierName ?? 'Livreur',
                        participantType: 'courier',
                        participantPhone: order.courierPhone,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Items
          _buildItemsCard(order, currencyFormat),
          const SizedBox(height: 16),

          // Delivery Address
          _buildSectionCard('Adresse de livraison', [
            _buildAddressRow('Adresse', order.deliveryAddress.fullAddress),
            if (order.deliveryAddress.phone != null)
              _buildPhoneRow('Téléphone', order.deliveryAddress.phone!),
          ]),
          const SizedBox(height: 16),

          // Delivery Code — always visible until delivered/cancelled
          if (order.deliveryCode != null &&
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled &&
              order.status != OrderStatus.failed) ...[
            _buildDeliveryCodeSection(order),
            const SizedBox(height: 16),
          ],

          // Notes
          if (order.customerNotes != null) ...[
            _buildSectionCard('Notes', [
              Text(
                order.customerNotes!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // Cancellation Info
          if (order.isCancelled) ...[
            _buildSectionCard('Annulation', [
              if (order.cancelledAt != null)
                _buildInfoRow(
                  'Annulée le',
                  DateFormat(
                    'dd/MM/yyyy à HH:mm',
                    'fr_FR',
                  ).format(order.cancelledAt!),
                ),
              if (order.cancellationReason != null)
                _buildInfoRow('Raison', order.cancellationReason!),
            ]),
            const SizedBox(height: 16),
          ],

          // Total Summary
          _buildTotalCard(order, currencyFormat),

          // Buttons for delivered orders
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 20),
            // Recommander cette commande
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _reorderItems(order),
                icon: const Icon(Icons.replay),
                label: const Text(
                  'Recommander cette commande',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Évaluer la commande
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRatingSheet(order),
                icon: const Icon(Icons.star_rate_rounded),
                label: const Text(
                  'Évaluer la commande',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderEntity order) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (order.status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        icon = Icons.schedule;
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.check_circle;
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        icon = Icons.restaurant_menu;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.inventory;
        break;
      case OrderStatus.delivering:
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        icon = Icons.cancel;
        break;
    }

    final card = Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Statut',
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                      if (order.isPaid) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Payé',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (order.deliveryCode != null &&
                      order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled &&
                      order.status != OrderStatus.failed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: textColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.key, size: 16, color: textColor),
                          const SizedBox(width: 8),
                          Text(
                            'Code: ${order.deliveryCode}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (order.status == OrderStatus.delivering) {
      return Column(
        children: [
          card,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.goToOrderTracking(
                  orderId: order.id,
                  deliveryAddress: order.deliveryAddress,
                  pharmacyAddress: order.pharmacyAddress,
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Suivre la livraison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }

  Widget _buildDeliveryCodeSection(OrderEntity order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.warning, size: 28),
          const SizedBox(height: 8),
          Text(
            'Code de livraison',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryCode!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Communiquez ce code au livreur pour confirmer la réception',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne avec téléphone cliquable
  Widget _buildPhoneRow(String label, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _launchPhone(phone),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      phone,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne avec adresse cliquable (ouvre Maps)
  Widget _buildAddressRow(String label, String address) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _launchMaps(address),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      address,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppSnackbar.error(context, 'Impossible d\'ouvrir le téléphone');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Erreur lors de l\'appel');
      }
    }
  }

  Future<void> _launchMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackbar.error(context, 'Impossible d\'ouvrir Maps');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Erreur lors de l\'ouverture de Maps');
      }
    }
  }

  Widget _buildItemsCard(OrderEntity order, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Articles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(OrderEntity order, NumberFormat currencyFormat) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total'),
                Text(currencyFormat.format(order.subtotal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frais de livraison'),
                Text(currencyFormat.format(order.deliveryFee)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(OrderEntity order) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (obligatoire)',
                hintText: 'Ex: Plus besoin, erreur...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.length < 3) {
                AppSnackbar.error(
                  context,
                  'La raison doit contenir au moins 3 caractères',
                );
                return;
              }

              // Close the dialog first
              Navigator.of(context).pop();

              // Await the cancel operation
              final error = await ref
                  .read(ordersProvider.notifier)
                  .cancelOrder(order.id, reason);

              if (!context.mounted) return;

              if (error != null) {
                AppSnackbar.error(
                  context,
                  'Impossible d\'annuler la commande. Réessayez.',
                );
              } else {
                // Refresh orders list so status is updated
                ref.read(ordersProvider.notifier).loadOrders();

                // Navigate back with confirmation
                if (context.mounted) {
                  AppSnackbar.success(context, 'Commande annulée avec succès ✓');
                  context.pop();
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    ).whenComplete(() => reasonController.dispose());
  }

  Future<void> _initiatePayment(int orderId) async {
    if (!mounted) return;

    // Récupérer le solde wallet et le montant de la commande pour le dialogue
    final walletState = ref.read(walletProvider);
    final order = ref.read(ordersProvider).selectedOrder;
    final orderTotal = order?.totalAmount;
    final orderReference = order?.reference ?? orderId.toString();

    // Show payment method selection dialog (Wave, Orange, MTN, Moov, Djamo + Portefeuille)
    final selection = await PaymentProviderDialog.show(
      context,
      walletBalance: walletState.wallet?.balance,
      orderAmount: orderTotal,
    );
    if (selection == null) return; // User cancelled

    final provider = selection['provider'] ?? 'jeko';
    final paymentMethod = selection['payment_method'] ?? 'orange';

    if (!mounted) return;

    // ── Paiement par portefeuille ──────────────────────────────────────────────
    if (provider == 'wallet') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Paiement en cours...'),
                ],
              ),
            ),
          ),
        ),
      );
      final success = await ref
          .read(walletProvider.notifier)
          .payOrder(amount: orderTotal ?? 0, orderReference: orderReference);
      if (!mounted) return;
      Navigator.pop(context); // fermer loading
      ref.read(ordersProvider.notifier).loadOrderDetails(orderId);
      if (success) {
        AppSnackbar.success(context, 'Paiement effectué avec succès !');
      } else {
        AppSnackbar.error(context, 'Paiement échoué. Vérifiez votre solde.');
      }
      return;
    }
    // ─────────────────────────────────────────────────────────────────────────

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initialisation du paiement...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Call initiatePayment with selected payment method
    await ref
        .read(paymentProvider.notifier)
        .initiatePayment(
          orderId: orderId,
          provider: provider,
          paymentMethod: paymentMethod,
        );

    // Hide loading
    if (mounted) Navigator.pop(context);

    final paymentState = ref.read(paymentProvider);

    if (paymentState.status == PaymentStatus.success &&
        paymentState.result != null) {
      final paymentUrl = paymentState.result!.paymentUrl;

      // Open WebView for better mobile experience
      if (!mounted) return;
      final paymentResult = await PaymentWebViewPage.show(
        context,
        paymentUrl: paymentUrl,
        orderId: orderId.toString(),
      );

      // Refresh order details to show updated payment status
      if (mounted) {
        ref.read(ordersProvider.notifier).loadOrderDetails(orderId);

        if (paymentResult == true) {
          AppSnackbar.success(context, 'Paiement effectué avec succès !');
        } else if (paymentResult == false) {
          AppSnackbar.error(context, 'Le paiement a échoué. Veuillez réessayer.');
        }
        // If paymentResult is null, user just closed the page - no message needed
      }
    } else {
      if (mounted) {
        final errorMsg =
            paymentState.errorMessage ??
            'Erreur lors de l\'initialisation du paiement';
        AppSnackbar.error(context, errorMsg);
        // Refresh order details to get latest payment status from server
        ref.read(ordersProvider.notifier).loadOrderDetails(orderId);
      }
    }
  }

  void _showRatingSheet(OrderEntity order) {
    RatingBottomSheet.show(
      context,
      orderId: order.id,
      pharmacyName: order.pharmacyName,
      courierName: 'Livreur', // Courier name
    );
  }

  /// Ajoute tous les articles de la commande au panier pour recommander
  void _reorderItems(OrderEntity order) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    int addedCount = 0;
    final now = DateTime.now();

    for (final item in order.items) {
      // Créer un ProductEntity minimal à partir des données de l'item
      final product = ProductEntity(
        id: item.productId ?? 0,
        name: item.name,
        description: '',
        price: item.unitPrice,
        stockQuantity: 100, // Disponibilité inconnue, on suppose disponible
        imageUrl: null, // Pas d'image disponible dans OrderItemEntity
        pharmacy: products.PharmacyEntity(
          id: order.pharmacyId,
          name: order.pharmacyName,
          address: order.pharmacyAddress ?? '',
          phone: order.pharmacyPhone ?? '',
          status: 'open',
          isOpen: true,
        ),
        requiresPrescription: false, // On ne peut pas savoir
        manufacturer: null,
        createdAt: now,
        updatedAt: now,
      );

      // Ajouter au panier avec la quantité originale
      for (int i = 0; i < item.quantity; i++) {
        cartNotifier.addItem(product);
      }
      addedCount += item.quantity;
    }

    if (!mounted) return;

    AppSnackbar.success(
      context,
      '$addedCount article${addedCount > 1 ? 's' : ''} ajouté${addedCount > 1 ? 's' : ''} au panier',
      actionLabel: 'Voir le panier',
      onAction: () => context.goToCart(),
    );
  }
}
