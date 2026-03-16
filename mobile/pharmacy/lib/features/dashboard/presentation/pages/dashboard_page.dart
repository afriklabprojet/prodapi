import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/connectivity_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../orders/presentation/pages/orders_list_page.dart';
import '../../../prescriptions/presentation/pages/prescriptions_list_page.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../providers/dashboard_tab_provider.dart';
import '../widgets/home_dashboard_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboardWidget(), // Index 0 - Nouveau tableau de bord
    const OrdersListPage(), // Index 1
    const PrescriptionsListPage(), // Index 2
    const InventoryPage(), // Index 3
    const WalletScreen(), // Index 4
    const ProfilePage(), // Index 5
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for tab changes from child widgets (e.g. KPI cards)
    ref.listen<int>(dashboardTabProvider, (prev, next) {
      if (next >= 0 && next != _currentIndex) {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = next);
      }
      // Always reset to sentinel so the same tab can be requested again
      if (next >= 0) {
        Future.microtask(() => ref.read(dashboardTabProvider.notifier).state = -1);
      }
    });

    // Récupérer le nombre de notifications non lues
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    
    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex, 
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNav(unreadCount),
      ),
    );
  }

  Widget _buildBottomNav(int unreadNotifications) {
    final isDark = AppColors.isDark(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: isDark ? Border(top: BorderSide(color: Colors.grey.shade800)) : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Accueil',
                isSelected: _currentIndex == 0,
                onTap: () => _selectTab(0),
                badgeCount: unreadNotifications,
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag_rounded,
                label: 'Commandes',
                isSelected: _currentIndex == 1,
                onTap: () => _selectTab(1),
              ),
              _NavItem(
                icon: Icons.medical_services_outlined,
                selectedIcon: Icons.medical_services_rounded,
                label: 'Ordos',
                isSelected: _currentIndex == 2,
                onTap: () => _selectTab(2),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'Stock',
                isSelected: _currentIndex == 3,
                onTap: () => _selectTab(3),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                isSelected: _currentIndex == 4,
                onTap: () => _selectTab(4),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person_rounded,
                label: 'Profil',
                isSelected: _currentIndex == 5,
                onTap: () => _selectTab(5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? primaryColor : textSecondary,
                    size: 24,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount! > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? primaryColor : textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
