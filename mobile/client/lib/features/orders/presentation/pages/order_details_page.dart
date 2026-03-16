import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import '../../domain/entities/order_entity.dart';
import 'payment_webview_page.dart';
import '../widgets/payment_dialogs.dart';
import '../widgets/rating_bottom_sheet.dart';

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
          : _buildOrderDetails(order),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message ?? 'Une erreur s\'est produite',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(order),
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
              _buildInfoRow('Téléphone', order.pharmacyPhone!),
            if (order.pharmacyAddress != null)
              _buildInfoRow('Adresse', order.pharmacyAddress!),
          ]),
          const SizedBox(height: 16),

          // Items
          _buildItemsCard(order, currencyFormat),
          const SizedBox(height: 16),

          // Delivery Address
          _buildSectionCard('Adresse de livraison', [
            _buildInfoRow('Adresse', order.deliveryAddress.fullAddress),
            if (order.deliveryAddress.phone != null)
              _buildInfoRow('Téléphone', order.deliveryAddress.phone!),
          ]),
          const SizedBox(height: 16),

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

          // Rate order button (only for delivered orders)
          if (order.status == OrderStatus.delivered) ...[            const SizedBox(height: 20),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, size: 12, color: Colors.white),
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
                      (order.status == OrderStatus.delivering ||
                          order.status == OrderStatus.ready ||
                          order.status == OrderStatus.confirmed)) ...[
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La raison doit contenir au moins 3 caractères',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              // Close the dialog first
              Navigator.of(context).pop();

              // Await the cancel operation
              await ref.read(ordersProvider.notifier).cancelOrder(order.id, reason);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Commande annulée'),
                  backgroundColor: AppColors.success,
                ),
              );

              // Navigate back using GoRouter
              context.pop();
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

    // Show payment method selection dialog (Wave, Orange, MTN, Moov, Djamo)
    final selection = await PaymentProviderDialog.show(context);
    if (selection == null) return; // User cancelled

    final provider = selection['provider'] ?? 'jeko';
    final paymentMethod = selection['payment_method'] ?? 'orange';

    if (!mounted) return;

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
    final result = await ref
        .read(ordersProvider.notifier)
        .initiatePayment(orderId: orderId, provider: provider, paymentMethod: paymentMethod);

    // Hide loading
    if (mounted) Navigator.pop(context);

    if (result != null && result.containsKey('payment_url')) {
      final paymentUrl = result['payment_url'] as String;
      
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement effectué avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (paymentResult == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le paiement a échoué. Veuillez réessayer.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        // If paymentResult is null, user just closed the page - no message needed
      }
    } else {
      if (mounted) {
        // Extract error message from result or use generic message
        final errorMsg = (result != null && result.containsKey('_error'))
            ? result['_error'] as String
            : 'Erreur lors de l\'initialisation du paiement';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
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
}
