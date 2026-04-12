import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/delivery_address_entity.dart';
import '../../domain/entities/order_entity.dart';
import 'tracking_page.dart';

/// Wrapper pour TrackingPage qui gère le cas où deliveryAddress n'est pas fourni
/// (e.g., deep link direct vers /orders/:id/tracking)
class TrackingPageWrapper extends ConsumerStatefulWidget {
  final int orderId;
  final DeliveryAddressEntity? deliveryAddress;
  final String? pharmacyAddress;

  const TrackingPageWrapper({
    super.key,
    required this.orderId,
    this.deliveryAddress,
    this.pharmacyAddress,
  });

  @override
  ConsumerState<TrackingPageWrapper> createState() =>
      _TrackingPageWrapperState();
}

class _TrackingPageWrapperState extends ConsumerState<TrackingPageWrapper> {
  late Future<OrderEntity?> _orderFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.deliveryAddress == null) {
      _orderFuture = _fetchOrderDetails();
    } else {
      // Si deliveryAddress est fournie, pas besoin de fetch
      _orderFuture = Future.value(null);
    }
  }

  Future<OrderEntity?> _fetchOrderDetails() async {
    final repository = ref.read(ordersRepositoryProvider);
    final result = await repository.getOrderDetails(widget.orderId);

    return result.fold((failure) {
      setState(() {
        _errorMessage = failure.message;
      });
      return null;
    }, (order) => order);
  }

  Future<void> _retryFetch() async {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      _orderFuture = _fetchOrderDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si l'adresse est déjà fournie, afficher directement TrackingPage
    if (widget.deliveryAddress != null) {
      return TrackingPage(
        orderId: widget.orderId,
        deliveryAddress: widget.deliveryAddress!,
        pharmacyAddress: widget.pharmacyAddress,
      );
    }

    // Sinon, fetch les détails de la commande
    return FutureBuilder<OrderEntity?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Suivi de livraison'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            body: _buildLoadingState(),
          );
        }

        if (_errorMessage != null) {
          return _buildErrorPage(_errorMessage!);
        }

        final order = snapshot.data;
        if (order == null) {
          return _buildErrorPage(
            'Impossible de charger les détails de la commande',
          );
        }

        return TrackingPage(
          orderId: widget.orderId,
          deliveryAddress: order.deliveryAddress,
          pharmacyAddress: order.pharmacyAddress ?? widget.pharmacyAddress,
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkElevated : Colors.grey.shade200;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 20,
          width: 220,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 88,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 88,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chargement du suivi de commande...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorPage(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.warning,
                semanticLabel: 'Erreur de chargement',
              ),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger le suivi',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retryFetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
