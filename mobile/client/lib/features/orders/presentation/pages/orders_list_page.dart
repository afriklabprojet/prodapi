import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import '../../domain/entities/order_entity.dart';

class OrdersListPage extends ConsumerStatefulWidget {
  const OrdersListPage({super.key});

  @override
  ConsumerState<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends ConsumerState<OrdersListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: _buildBody(ordersState),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state.status == OrdersStatus.loading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == OrdersStatus.error && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'Erreur de chargement'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (state.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune commande', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return _OrderCard(
            order: order,
            onTap: () => context.push('/orders/${order.id}'),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(order.status),
          child: const Icon(Icons.receipt, color: Colors.white, size: 20),
        ),
        title: Text('Commande #${order.id}'),
        subtitle: Text(
          order.statusLabel,
          style: TextStyle(color: _statusColor(order.status)),
        ),
        trailing: Text(
          '${order.total.toStringAsFixed(0)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.delivering:
        return AppColors.primary;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.failed:
        return Colors.red.shade800;
    }
  }
}
