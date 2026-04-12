import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../orders/presentation/extensions/order_status_l10n.dart';
import '../../data/models/notification_model.dart';

/// Bottom sheet affichant les détails complets d'une notification.
/// Permet la navigation vers la commande associée si applicable.
class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailSheet({super.key, required this.notification});

  /// Types de notification liés à une commande
  static const _orderTypes = {
    'new_order',
    'new_order_received',
    'order_status',
    'delivery_assigned',
    'courier_arrived',
    'courier_arrived_at_client',
    'delivery_timeout_cancelled',
    'order_delivered',
  };

  /// Vérifie si la notification est liée à une commande
  bool get _isOrderRelated => _orderTypes.contains(notification.type);

  /// Récupère l'ID de la commande depuis les données
  int? get _orderId {
    final data = notification.data;
    if (data == null) return null;
    final id = data['order_id'];
    if (id == null) return null;
    return int.tryParse(id.toString());
  }

  /// Récupère la référence de la commande
  String? get _orderReference {
    return notification.data?['order_reference']?.toString();
  }

  /// Icône et couleur en fonction du type
  ({IconData icon, Color color}) get _style {
    return switch (notification.type) {
      'new_order' || 'new_order_received' => (
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue.shade700,
      ),
      'order_status' => (icon: Icons.sync_outlined, color: Colors.indigo),
      'delivery_assigned' => (
        icon: Icons.delivery_dining_outlined,
        color: Colors.teal,
      ),
      'courier_arrived' || 'courier_arrived_at_client' => (
        icon: Icons.location_on_outlined,
        color: Colors.deepOrange,
      ),
      'delivery_timeout_cancelled' => (
        icon: Icons.timer_off_outlined,
        color: Colors.red,
      ),
      'order_delivered' => (
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ),
      'low_stock' => (icon: Icons.inventory_2_outlined, color: Colors.orange),
      'payment' || 'payout_completed' => (
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green,
      ),
      'new_prescription' || 'prescription_status' => (
        icon: Icons.medical_services_outlined,
        color: Colors.purple,
      ),
      'chat_message' => (icon: Icons.chat_bubble_outline, color: Colors.cyan),
      'kyc_status_update' => (
        icon: Icons.verified_user_outlined,
        color: Colors.amber,
      ),
      _ => (icon: Icons.notifications_outlined, color: Colors.teal),
    };
  }

  /// Label lisible du type
  String get _typeLabel {
    return switch (notification.type) {
      'new_order' || 'new_order_received' => 'Nouvelle commande',
      'order_status' => 'Statut commande',
      'delivery_assigned' => 'Livreur assigné',
      'courier_arrived' => 'Livreur arrivé',
      'courier_arrived_at_client' => 'Livreur chez le client',
      'delivery_timeout_cancelled' => 'Livraison annulée',
      'order_delivered' => 'Commande livrée',
      'low_stock' => 'Alerte stock',
      'payment' || 'payout_completed' => 'Paiement',
      'new_prescription' || 'prescription_status' => 'Ordonnance',
      'chat_message' => 'Message',
      'kyc_status_update' => 'Vérification KYC',
      _ => 'Notification',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final style = _style;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Icône + badge type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: style.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Titre
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Corps / description
              if (notification.body.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),

              // Détails supplémentaires pour les commandes
              if (_isOrderRelated) ...[
                const SizedBox(height: 16),
                _buildOrderDetails(context, isDark),
              ],

              const SizedBox(height: 24),

              // Bouton d'action
              if (_isOrderRelated && _orderId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le bottom sheet
                      context.push('/orders/${_orderId}');
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text(
                      'Voir la commande',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),

              // Bouton fermer
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).close,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la section détails de commande
  Widget _buildOrderDetails(BuildContext context, bool isDark) {
    final data = notification.data ?? {};
    final details = <({String label, String value, IconData icon})>[];

    if (_orderReference != null && _orderReference!.isNotEmpty) {
      // Afficher référence raccourcie
      final shortRef = _orderReference!.length > 8
          ? '#...${_orderReference!.substring(_orderReference!.length - 5)}'
          : '#$_orderReference';
      details.add((label: 'Référence', value: shortRef, icon: Icons.tag));
    }

    final customerName =
        data['customer_name']?.toString() ??
        (data['order_data'] as Map<String, dynamic>?)?['customer_name']
            ?.toString();
    if (customerName != null && customerName.isNotEmpty) {
      details.add((
        label: 'Client',
        value: customerName,
        icon: Icons.person_outline,
      ));
    }

    final totalAmount =
        data['total_amount']?.toString() ??
        (data['order_data'] as Map<String, dynamic>?)?['total_amount']
            ?.toString();
    if (totalAmount != null && totalAmount.isNotEmpty) {
      final currency =
          data['currency']?.toString() ??
          (data['order_data'] as Map<String, dynamic>?)?['currency']
              ?.toString() ??
          'FCFA';
      details.add((
        label: 'Montant',
        value: '$totalAmount $currency',
        icon: Icons.payments_outlined,
      ));
    }

    final itemsCount =
        data['items_count']?.toString() ??
        (data['order_data'] as Map<String, dynamic>?)?['items_count']
            ?.toString();
    if (itemsCount != null && itemsCount.isNotEmpty) {
      details.add((
        label: 'Articles',
        value: '$itemsCount article(s)',
        icon: Icons.shopping_cart_outlined,
      ));
    }

    final paymentMode = data['payment_mode']?.toString();
    if (paymentMode != null && paymentMode.isNotEmpty) {
      final paymentLabel = switch (paymentMode) {
        'cash' => 'Espèces',
        'mobile_money' => 'Mobile Money',
        'card' => 'Carte bancaire',
        'wave' => 'Wave',
        'orange' => 'Orange Money',
        _ => paymentMode,
      };
      details.add((
        label: 'Paiement',
        value: paymentLabel,
        icon: Icons.credit_card_outlined,
      ));
    }

    final deliveryAddress = data['delivery_address']?.toString();
    if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
      details.add((
        label: 'Adresse',
        value: deliveryAddress,
        icon: Icons.location_on_outlined,
      ));
    }

    final status = data['status']?.toString();
    if (status != null && status.isNotEmpty) {
      final statusLabel = OrderStatus.fromApi(
        status,
      ).localizedLabel(AppLocalizations.of(context));
      details.add((
        label: 'Statut',
        value: statusLabel,
        icon: Icons.info_outline,
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withValues(alpha: 0.5)
            : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey[700]!
              : Colors.blue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la commande',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    d.icon,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${d.label}: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
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

  /// Formatage de la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return DateFormat('dd MMMM yyyy à HH:mm', 'fr').format(date);
    }
  }

  /// Affiche le bottom sheet
  static void show(BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) =>
            NotificationDetailSheet(notification: notification),
      ),
    );
  }
}
