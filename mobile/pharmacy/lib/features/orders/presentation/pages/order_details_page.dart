import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/action_button.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/presentation/widgets/success_animation.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../providers/order_list_provider.dart';
import '../widgets/order_section_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/phone_masker.dart';
import '../../../../l10n/app_localizations.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final OrderEntity order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  bool _isLoading = false;
  late OrderEntity _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _markAsReady() async {
    setState(() => _isLoading = true);
    HapticService.onAction(); // Feedback immédiat
    try {
      await ref.read(orderListProvider.notifier).markOrderReady(_order.id);
      setState(() {
        _order = _order.copyWith(status: OrderStatus.ready);
      });
      if (mounted) {
        HapticService.onSuccess(); // Feedback succès
        // Animation de succès pour commande prête
        await showSuccessAnimation(context, message: 'Commande prête !');
      }
    } catch (e) {
      if (mounted) {
        HapticService.onError(); // Feedback erreur
        ErrorSnackBar.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectOrder(String reason) async {
    setState(() => _isLoading = true);
    HapticService.onDelete(); // Feedback immédiat pour rejet
    try {
      await ref
          .read(orderListProvider.notifier)
          .rejectOrder(_order.id, reason: reason);
      setState(() {
        _order = _order.copyWith(status: OrderStatus.cancelled);
      });
      if (mounted) {
        ErrorSnackBar.showWarning(context, 'Commande refusée');
      }
    } catch (e) {
      if (mounted) {
        HapticService.onError();
        ErrorSnackBar.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(BuildContext context) {
    final reasons = [
      'Produit en rupture de stock',
      'Ordonnance invalide',
      'Pharmacie fermée',
      'Délai de préparation impossible',
      'Autre',
    ];
    String? selectedReason;
    final otherController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final isDarkLocal = AppColors.isDark(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        color: isDarkLocal
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Refuser la commande',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkLocal ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sélectionnez un motif de refus :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkLocal
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map(
                    (r) => InkWell(
                      onTap: () => setSheetState(() => selectedReason = r),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selectedReason == r
                              ? Colors.red.withValues(
                                  alpha: isDarkLocal ? 0.2 : 0.08,
                                )
                              : (isDarkLocal
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedReason == r
                                ? Colors.red
                                : (isDarkLocal
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedReason == r
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selectedReason == r
                                  ? Colors.red
                                  : (isDarkLocal
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selectedReason == r
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selectedReason == r
                                      ? Colors.red
                                      : (isDarkLocal
                                            ? Colors.white
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedReason == 'Autre') ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: otherController,
                      style: TextStyle(
                        color: isDarkLocal ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Précisez le motif...',
                        hintStyle: TextStyle(
                          color: isDarkLocal
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Refuser la commande'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.red.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      onPressed: selectedReason == null
                          ? null
                          : () {
                              Navigator.pop(sheetCtx);
                              final reason = selectedReason == 'Autre'
                                  ? otherController.text.trim().isEmpty
                                        ? 'Autre'
                                        : otherController.text.trim()
                                  : selectedReason!;
                              _rejectOrder(reason);
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => otherController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(title: Text('Commande #${_order.reference}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildOrderContent(currencyFormat, isDark),
                  ),
                ),
                _buildActionButtons(context, ref),
              ],
            ),
    );
  }

  Widget _buildOrderContent(NumberFormat currencyFormat, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero header avec icône animée
        Center(
          child: Hero(
            tag: 'order_icon_${_order.id}',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: primaryColor,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Payment warning banner for unpaid orders
        if (_order.isPendingUnpaid) ...[
          _buildPaymentWarningBanner(isDark),
          const SizedBox(height: 16),
        ],

        // Status Card
        _buildStatusCard(isDark),
        const SizedBox(height: 16),

        // Payment Info Card (always visible)
        _buildPaymentStatusCard(isDark),
        const SizedBox(height: 16),

        // Courier Info (if assigned)
        if (_order.courierId != null) ...[
          _buildCourierCard(isDark),
          const SizedBox(height: 16),
        ],

        // Customer Info
        _buildSectionCard(
          title: 'Informations Client',
          icon: Icons.person,
          isDark: isDark,
          children: [
            _buildInfoRow('Nom', _order.customerName, isDark: isDark),
            _buildInfoRow(
              'Téléphone',
              PhoneMasker.maskForDisplay(_order.customerPhone),
              isDark: isDark,
            ),
            if (_order.deliveryAddress != null)
              _buildInfoRow('Adresse', _order.deliveryAddress!, isDark: isDark),
          ],
        ),
        const SizedBox(height: 16),

        // Order Items
        if (_order.items != null && _order.items!.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Produits commandés',
            icon: Icons.shopping_bag,
            isDark: isDark,
            children: [
              ..._order.items!.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(item.totalPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Order Summary
        _buildSectionCard(
          title: 'Résumé',
          icon: Icons.receipt,
          isDark: isDark,
          children: [
            if (_order.subtotal != null)
              _buildInfoRow(
                'Sous-total',
                currencyFormat.format(_order.subtotal),
                isDark: isDark,
              ),
            if (_order.deliveryFee != null)
              _buildInfoRow(
                'Frais de livraison',
                currencyFormat.format(_order.deliveryFee),
                isDark: isDark,
              ),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            _buildInfoRow(
              'Total',
              currencyFormat.format(_order.totalAmount),
              isBold: true,
              isDark: isDark,
            ),
            _buildInfoRow(
              'Mode de paiement',
              _getPaymentModeLabel(),
              isDark: isDark,
            ),
            _buildInfoRow(
              'Statut paiement',
              _getPaymentStatusLabel(),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Notes
        if (_order.customerNotes != null && _order.customerNotes!.isNotEmpty)
          _buildSectionCard(
            title: 'Notes du client',
            icon: Icons.note,
            isDark: isDark,
            children: [
              Text(
                _order.customerNotes!,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Card(
      color: isDark
          ? _getStatusColor().withValues(alpha: 0.2)
          : _getStatusColor().withValues(alpha: 0.1),
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_getStatusIcon(), color: _getStatusColor(), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  Text(
                    'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(_order.createdAt)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierCard(bool isDark) {
    return Card(
      color: isDark
          ? Colors.orange.shade900.withValues(alpha: 0.3)
          : Colors.orange.shade50,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 20,
                  child: const Icon(Icons.delivery_dining, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livreur assigné',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.orange[300] : Colors.orange,
                        ),
                      ),
                      Text(
                        _order.courierName ?? 'Coursier',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_order.courierPhone != null)
                        Text(
                          _order.courierPhone!,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Chat button with courier
            if (_order.deliveryId != null && _order.courierId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('💬 Chat avec le livreur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    context.push(
                      '/chat',
                      extra: {
                        'deliveryId': _order.deliveryId!,
                        'participantType': 'courier',
                        'participantId': _order.courierId!,
                        'participantName': _order.courierName ?? 'Livreur',
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isDark = false,
  }) {
    return OrderSectionCard(
      title: title,
      icon: icon,
      isDark: isDark,
      children: children,
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDark = false,
  }) {
    return OrderInfoRow(
      label: label,
      value: value,
      isBold: isBold,
      isDark: isDark,
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    // Block all actions for unpaid pending orders
    if (_order.isPendingUnpaid) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous pourrez traiter cette commande une fois le paiement du client valid\u00e9.',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Pending confirmed orders (payment received or COD) → Confirm + Reject
    if (_order.status == OrderStatus.pending && !_order.isPendingUnpaid) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ActionButtonExpanded(
              onPressed: () async {
                try {
                  await ref
                      .read(orderListProvider.notifier)
                      .confirmOrder(_order.id);
                  if (mounted) {
                    setState(() {
                      _order = _order.copyWith(status: OrderStatus.confirmed);
                    });
                  }
                  return true;
                } catch (e) {
                  if (mounted) ErrorSnackBar.showError(context, 'Erreur: $e');
                  return false;
                }
              },
              label: AppLocalizations.of(context).confirmOrder,
              icon: Icons.check_circle,
              backgroundColor: Colors.green,
              onSuccess: () {
                if (mounted) {
                  CelebrationService.celebrate(
                    context: context,
                    type: CelebrationType.orderConfirmed,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Refuser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showRejectDialog(context),
              ),
            ),
          ],
        ),
      );
    }

    // Confirmed → Mark as ready
    if (_order.status == OrderStatus.confirmed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ActionButtonExpanded(
          onPressed: () async {
            try {
              await _markAsReady();
              return true;
            } catch (e) {
              return false;
            }
          },
          label: 'Marquer comme prête',
          icon: Icons.inventory_2,
          backgroundColor: Colors.blue,
          onSuccess: () {
            if (context.mounted) {
              CelebrationService.celebrate(
                context: context,
                type: CelebrationType.orderReady,
              );
            }
          },
        ),
      );
    }

    if (_order.status == 'paid') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ActionButtonExpanded(
              onPressed: () async {
                try {
                  await ref
                      .read(orderListProvider.notifier)
                      .updateOrderStatus(_order.id, OrderStatus.ready);
                  if (mounted) {
                    setState(() {
                      _order = _order.copyWith(status: OrderStatus.ready);
                    });
                  }
                  return true;
                } catch (e) {
                  return false;
                }
              },
              label: 'Commande Prête (Retrait)',
              icon: Icons.check_circle,
              backgroundColor: Colors.green,
              onSuccess: () {
                if (context.mounted) {
                  CelebrationService.celebrate(
                    context: context,
                    type: CelebrationType.orderReady,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            ActionButtonExpanded(
              onPressed: () async {
                try {
                  await ref
                      .read(orderListProvider.notifier)
                      .markOrderReady(_order.id);
                  if (mounted) {
                    setState(() {
                      _order = _order.copyWith(status: OrderStatus.ready);
                    });
                  }
                  return true;
                } catch (e) {
                  if (context.mounted)
                    ErrorSnackBar.showError(context, 'Erreur: $e');
                  return false;
                }
              },
              label: 'Demander un Coursier',
              icon: Icons.motorcycle,
              backgroundColor: Colors.orange,
              onSuccess: () {
                if (context.mounted) {
                  CelebrationService.quickCelebrate(
                    context: context,
                    message: "Recherche de coursier lancée ! 🏍️",
                    color: Colors.orange,
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    if (_order.status == OrderStatus.ready) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ActionButtonExpanded(
          onPressed: () async {
            try {
              await ref
                  .read(orderListProvider.notifier)
                  .markOrderDelivered(_order.id);
              if (mounted) {
                setState(() {
                  _order = _order.copyWith(status: OrderStatus.delivered);
                });
              }
              return true;
            } catch (e) {
              if (context.mounted)
                ErrorSnackBar.showError(context, 'Erreur: $e');
              return false;
            }
          },
          label: 'Confirmer le Retrait Client',
          icon: Icons.handshake,
          backgroundColor: Colors.blue,
          onSuccess: () {
            if (context.mounted) {
              CelebrationService.celebrate(
                context: context,
                type: CelebrationType.orderDelivered,
              );
            }
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getStatusLabel() {
    final l10n = AppLocalizations.of(context);
    return switch (_order.status) {
      OrderStatus.pending => l10n.statusPendingConfirmation,
      OrderStatus.confirmed => l10n.statusConfirmed,
      OrderStatus.ready => l10n.statusReadyForPickup,
      OrderStatus.inDelivery => l10n.statusInProgress,
      OrderStatus.delivered => l10n.statusDelivered,
      OrderStatus.cancelled => l10n.statusCancelled,
      OrderStatus.rejected => l10n.statusRejected,
    };
  }

  Color _getStatusColor() {
    return _order.status.color;
  }

  IconData _getStatusIcon() {
    return _order.status.icon;
  }

  String _getPaymentModeLabel() {
    switch (_order.paymentMode) {
      case 'platform':
        return 'Paiement en ligne';
      case 'on_delivery':
      case 'cash':
        return 'Paiement à la livraison';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return _order.paymentMode;
    }
  }

  String _getPaymentStatusLabel() {
    if (_order.isPaid) return '\u2705 Pay\u00e9e';
    if (_order.paymentMode == 'cash') return '\ud83d\udcb5 \u00c0 la livraison';
    return '\u274c Non pay\u00e9e';
  }

  Widget _buildPaymentWarningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.4)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.shade800 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.money_off_rounded,
                  color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paiement non re\u00e7u',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? Colors.red.shade200
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Le client n\'a pas encore finalis\u00e9 le paiement. Ne pr\u00e9parez pas cette commande.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard(bool isDark) {
    final isPaid = _order.isPaid;
    final isCash = _order.paymentMode == 'cash';

    Color cardColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isPaid) {
      cardColor = isDark
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : Colors.green.shade50;
      iconColor = Colors.green;
      icon = Icons.check_circle;
      title = 'Paiement valid\u00e9';
      subtitle =
          'Le paiement a \u00e9t\u00e9 re\u00e7u. Vous pouvez traiter la commande.';
    } else if (isCash) {
      cardColor = isDark
          ? Colors.blue.shade900.withValues(alpha: 0.3)
          : Colors.blue.shade50;
      iconColor = Colors.blue;
      icon = Icons.payments_outlined;
      title = 'Paiement \u00e0 la livraison';
      subtitle =
          'Le client paiera en esp\u00e8ces \u00e0 la r\u00e9ception. Vous pouvez traiter la commande.';
    } else {
      cardColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50;
      iconColor = Colors.red;
      icon = Icons.hourglass_top_rounded;
      title = 'En attente de paiement';
      subtitle =
          'Le paiement n\'a pas encore \u00e9t\u00e9 finalis\u00e9 par le client.';
    }

    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
