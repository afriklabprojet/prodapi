import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../prescriptions/presentation/providers/prescription_provider.dart';
import '../../../orders/presentation/pages/orders_list_page.dart';
import '../../../prescriptions/presentation/pages/prescriptions_list_page.dart';
import '../providers/activity_sub_tab_provider.dart';

/// Hub unifié qui regroupe Commandes et Ordonnances sous un seul onglet.
/// Remplace les 2 onglets séparés de la bottom navigation.
class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(activitySubTabProvider);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(activitySubTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final pendingOrders = ref
        .watch(orderListProvider)
        .orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final pendingPrescriptions = ref
        .watch(prescriptionListProvider)
        .prescriptions
        .where((p) => p.status == 'pending')
        .length;

    // Sync external sub-tab requests (e.g. from dashboard shortcuts)
    ref.listen<int>(activitySubTabProvider, (_, next) {
      if (next >= 0 && next <= 1 && _tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    return SafeArea(
      child: Column(
        children: [
          // Header
          _ActivityHeader(isDark: isDark, unreadCount: unreadCount),

          // Segmented toggle tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Commandes'),
                      if (pendingOrders > 0) ...[
                        const SizedBox(width: 6),
                        _BadgePill(count: pendingOrders),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Ordonnances'),
                      if (pendingPrescriptions > 0) ...[
                        const SizedBox(width: 6),
                        _BadgePill(count: pendingPrescriptions),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_OrdersContent(), _PrescriptionsContent()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  final bool isDark;
  final int unreadCount;

  const _ActivityHeader({required this.isDark, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activité',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              Text(
                'Commandes & Ordonnances',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.redAccent,
                label: Text('$unreadCount'),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 26,
                ),
              ),
              onPressed: () => GoRouter.of(context).push('/notifications'),
              tooltip: 'Notifications',
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge count pill widget
class _BadgePill extends StatelessWidget {
  final int count;
  const _BadgePill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Proxy widgets that strip the SafeArea wrapping from inner pages.
/// Orders and Prescriptions pages manage their own body content.
class _OrdersContent extends StatelessWidget {
  const _OrdersContent();

  @override
  Widget build(BuildContext context) {
    // OrdersListPage is a Scaffold; embed directly — Flutter handles nested scaffolds.
    return const OrdersListPage(showActivityHeader: false);
  }
}

class _PrescriptionsContent extends StatelessWidget {
  const _PrescriptionsContent();

  @override
  Widget build(BuildContext context) {
    return const PrescriptionsListPage(showActivityHeader: false);
  }
}
