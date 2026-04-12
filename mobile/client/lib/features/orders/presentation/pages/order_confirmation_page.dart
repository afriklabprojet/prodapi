import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/celebration_service.dart';
import '../../../../main_shell_page.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import 'order_details_page.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  final int orderId;
  final bool isPaid;

  const OrderConfirmationPage({
    super.key,
    required this.orderId,
    this.isPaid = false,
  });

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  int _pollCount = 0;
  int _elapsedSeconds = 0;
  bool _isChecking = false;
  bool _hasTimedOut = false;
  bool _celebrationTriggered = false;
  static const int _maxPollCount = 24; // 2 minutes max (24 * 5s)
  static const int _timeoutSeconds =
      60; // Show alternative actions after 60s (was 90s)
  static const int _expectedSeconds = 30; // Temps moyen attendu (was 45s)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulsing animation pour l'icône en attente
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Charger les détails de la commande
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrderDetails(widget.orderId);
      // Si le paiement n'est pas encore confirmé, polling automatique
      if (!widget.isPaid) {
        _startPaymentPolling();
        _startTimeoutTimer();
        _pulseController.repeat(reverse: true);
      } else {
        // Si déjà payé, déclencher la célébration
        _triggerCelebration();
      }
    });
  }

  /// Déclenche la célébration de confirmation de commande
  void _triggerCelebration() {
    if (_celebrationTriggered) return;
    _celebrationTriggered = true;
    HapticFeedback.heavyImpact();
    // Petit délai pour laisser l'animation de la page se terminer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(celebrationProvider.notifier).triggerOrderCelebration();
      }
    });
  }

  /// Timer pour tracker le temps écoulé et déclencher le timeout
  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _timeoutSeconds && !_hasTimedOut) {
          _hasTimedOut = true;
        }
      });
    });
  }

  /// Poll le serveur toutes les 5s pour détecter quand le webhook Jeko
  /// a mis à jour le statut de paiement.
  void _startPaymentPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      final order = ref.read(ordersProvider).selectedOrder;
      if (order?.paymentStatus == 'paid') {
        _stopAllTimers();
        _triggerCelebration();
        return;
      }

      _pollCount++;
      if (_pollCount >= _maxPollCount) {
        _stopAllTimers();
        if (mounted) {
          setState(() => _hasTimedOut = true);
        }
        return;
      }

      setState(() => _isChecking = true);
      try {
        await ref
            .read(ordersProvider.notifier)
            .loadOrderDetails(widget.orderId);
      } catch (_) {
        // Ignore errors during polling, just keep trying
      }
      if (mounted) {
        setState(() => _isChecking = false);
      }
    });
  }

  void _stopAllTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isChecking = true);
    try {
      await ref.read(ordersProvider.notifier).loadOrderDetails(widget.orderId);
    } catch (_) {
      // Show error handled by provider
    }
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _stopAllTimers();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final order = ordersState.selectedOrder;

    // Le paiement est considéré comme effectué si :
    // 1. Le serveur confirme payment_status == 'paid', OU
    // 2. Le flow de paiement (WebView) a retourné isPaid = true
    //    (le webhook Jeko peut avoir du retard)
    final bool isActuallyPaid = order?.paymentStatus == 'paid' || widget.isPaid;

    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final titleFontSize = isCompact ? 24.0 : 28.0;
    final descriptionFontSize = isCompact ? 15.0 : 16.0;
    final horizontalPadding = isCompact ? 16.0 : 24.0;
    final heroCircleSize = isCompact ? 96.0 : 120.0;
    final heroIconSize = isCompact ? 64.0 : 80.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goToHome();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child:
              ordersState.status == OrdersStatus.loading &&
                  ordersState.selectedOrder == null
              ? _buildLoadingState()
              : ordersState.status == OrdersStatus.error &&
                    ordersState.selectedOrder == null
              ? _buildErrorState(ordersState.errorMessage)
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isCompact ? 24 : 40),
                      // Success Animation
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: isActuallyPaid
                                  ? Container(
                                      width: heroCircleSize,
                                      height: heroCircleSize,
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: heroIconSize,
                                        color: AppColors.success,
                                      ),
                                    )
                                  : AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: heroCircleSize,
                                            height: heroCircleSize,
                                            decoration: BoxDecoration(
                                              color: AppColors.warning
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.hourglass_top,
                                              size: heroIconSize,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          isActuallyPaid
                              ? 'Paiement réussi !'
                              : 'Vérification en cours...',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: context.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          isActuallyPaid
                              ? 'Votre paiement a été effectué avec succès'
                              : 'Votre paiement a été reçu.\nConfirmation en cours...',
                          style: TextStyle(
                            fontSize: descriptionFontSize,
                            color: context.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Progress indicator pour payment pending
                      if (!isActuallyPaid) ...[
                        const SizedBox(height: 24),
                        _buildPaymentProgressSection(),
                      ],

                      const SizedBox(height: 32),

                      // Order Details Card
                      if (order != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildOrderCard(order, currencyFormat),
                        ),

                      const SizedBox(height: 24),

                      // Delivery Code Section
                      if (order?.deliveryCode != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildDeliveryCodeCard(order!),
                        ),

                      const SizedBox(height: 24),

                      // Actions rapides si timeout - UX améliorée
                      if (!isActuallyPaid && _hasTimedOut)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Icône rassurante
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: AppColors.info,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Message principal
                                Text(
                                  'Vérification en cours',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Votre paiement est en cours de traitement. '
                                  'Nous vous enverrons une notification dès qu\'il sera confirmé.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.secondaryText,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 20),

                                // Garanties
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Votre argent est en sécurité. Aucun risque de double paiement.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.primaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Bouton principal - Continuer
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _goToHome,
                                    icon: const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('Continuer mes achats'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Actions secondaires
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isChecking
                                            ? null
                                            : _manualRefresh,
                                        icon: _isChecking
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.refresh,
                                                size: 18,
                                              ),
                                        label: const Text('Actualiser'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _contactSupport(order),
                                        icon: const Icon(
                                          Icons.support_agent,
                                          size: 18,
                                        ),
                                        label: const Text('Support'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              context.secondaryText,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Action Buttons
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Voir les détails
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _goToOrderDetails(),
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Voir les détails'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Voir mes commandes
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _goToOrders(),
                                icon: const Icon(Icons.list_alt),
                                label: const Text('Mes commandes'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Retour à l'accueil
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  debugPrint('Retour à l\'accueil pressed');
                                  _goToHome();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  'Retour à l\'accueil',
                                  style: TextStyle(
                                    color: context.secondaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Section de progression du paiement avec étapes visuelles
  Widget _buildPaymentProgressSection() {
    // Calcul du progrès (0 à 1)
    final progress = (_elapsedSeconds / _expectedSeconds).clamp(0.0, 1.0);
    final bool isDelayed = _elapsedSeconds > _expectedSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelayed
              ? AppColors.warning.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _hasTimedOut ? null : progress, // Indeterminate si timeout
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDelayed ? AppColors.warning : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 16),

          // Étapes
          Row(
            children: [
              _buildProgressStep(
                icon: Icons.payment,
                label: 'Paiement reçu',
                isCompleted: true,
                isActive: false,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: _elapsedSeconds > 5
                      ? AppColors.success
                      : Colors.grey.shade300,
                ),
              ),
              _buildProgressStep(
                icon: Icons.verified,
                label: 'Vérification',
                isCompleted: _elapsedSeconds > 20,
                isActive: _elapsedSeconds <= 20,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: _elapsedSeconds > 35
                      ? AppColors.success
                      : Colors.grey.shade300,
                ),
              ),
              _buildProgressStep(
                icon: Icons.check_circle,
                label: 'Confirmé',
                isCompleted: false,
                isActive: _elapsedSeconds > 30,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Message rassurant
          Text(
            _hasTimedOut
                ? 'La vérification prend plus de temps que prévu.\nVous pouvez continuer vos achats.'
                : 'Confirmation en cours...\nVous serez notifié dès validation.',
            style: TextStyle(
              fontSize: 13,
              color: _hasTimedOut ? AppColors.info : context.secondaryText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Temps écoulé
          if (!_hasTimedOut) ...[
            const SizedBox(height: 8),
            Text(
              '${_elapsedSeconds}s écoulées',
              style: TextStyle(
                fontSize: 12,
                color: context.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    final color = isCompleted
        ? AppColors.success
        : isActive
        ? AppColors.primary
        : Colors.grey.shade400;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.1)
                : isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Icon(isCompleted ? Icons.check : icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderEntity order, NumberFormat currencyFormat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Reference
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Référence',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                order.reference,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Pharmacy
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacie',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      order.pharmacyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Items count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Articles',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                '${order.itemCount} article(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                currencyFormat.format(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCodeCard(OrderEntity order) {
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
          const Icon(Icons.lock_outline, color: AppColors.warning, size: 32),
          const SizedBox(height: 12),
          Text(
            'Code de livraison',
            style: TextStyle(color: context.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryCode!,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Communiquez ce code au livreur\npour confirmer la réception',
            style: TextStyle(color: context.secondaryText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Chargement de votre commande...',
              style: TextStyle(fontSize: 16, color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre commande #${widget.orderId} a bien été créée',
              style: TextStyle(
                fontSize: 14,
                color: context.secondaryText.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Problème de connexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ??
                  'Impossible de charger les détails. Votre commande a bien été créée.',
              style: TextStyle(fontSize: 14, color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(ordersProvider.notifier)
                    .loadOrderDetails(widget.orderId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _goToOrders,
              child: const Text('Voir mes commandes'),
            ),
          ],
        ),
      ),
    );
  }

  void _contactSupport(OrderEntity? order) {
    final reference = order?.reference ?? 'CMD-${widget.orderId}';

    // Open WhatsApp or show dialog for support contact
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contacter le support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Référence: $reference',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Contactez-nous par WhatsApp ou par téléphone :'),
            const SizedBox(height: 8),
            SelectableText(
              '+225 07 00 00 00',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _goToOrderDetails() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: widget.orderId),
      ),
    );
  }

  void _goToOrders() {
    if (!mounted) return;
    debugPrint('Navigating to orders');
    if (kIsWeb) {
      context.pushReplacement(AppRoutes.orders);
    } else {
      // Navigate to the shell (/home) with the orders tab active so that the
      // back button inside OrdersListPage works (MainShellPage is in the tree).
      ref.read(mainShellTabProvider.notifier).state = 1;
      context.go(AppRoutes.home);
    }
  }

  void _goToHome() {
    if (!mounted) return;
    debugPrint('Navigating to home');
    if (kIsWeb) {
      context.pushReplacement(AppRoutes.home);
    } else {
      ref.read(mainShellTabProvider.notifier).state = 0;
      context.go(AppRoutes.home);
    }
  }
}
