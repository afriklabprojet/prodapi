import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/connectivity_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../providers/dashboard_tab_provider.dart';
import '../widgets/home_dashboard_widget.dart';
import 'activity_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Pages créées à la demande (lazy loading)
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeDashboardWidget();
      case 1:
        return const ActivityPage();
      case 2:
        return const InventoryPage();
      case 3:
        return const WalletScreen();
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab changes from child widgets (e.g. KPI cards)
    ref.listen<int>(dashboardTabProvider, (prev, next) {
      if (next >= 0 && next != _currentIndex) {
        HapticFeedback.selectionClick();
        _pageController.jumpToPage(next);
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
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Désactive le swipe
          itemCount: 5,
          itemBuilder: (context, index) => _buildPage(index),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
        ),
        bottomNavigationBar: Platform.isIOS 
            ? _buildCupertinoBottomNav(unreadCount) 
            : _buildBottomNav(unreadCount),
      ),
    );
  }

  /// Bottom navigation pour iOS - utilise CupertinoTabBar pour respecter HIG
  Widget _buildCupertinoBottomNav(int unreadNotifications) {
    return CupertinoTabBar(
      currentIndex: _currentIndex,
      onTap: _selectTab,
      activeColor: AppColors.primary,
      inactiveColor: CupertinoColors.systemGrey,
      items: [
        BottomNavigationBarItem(
          icon: _buildCupertinoNavIcon(CupertinoIcons.home, 0, unreadNotifications),
          activeIcon: _buildCupertinoNavIcon(CupertinoIcons.house_fill, 0, unreadNotifications),
          label: 'Accueil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.arrow_right_arrow_left),
          activeIcon: Icon(CupertinoIcons.arrow_right_arrow_left_circle_fill),
          label: 'Activité',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.cube_box),
          activeIcon: Icon(CupertinoIcons.cube_box_fill),
          label: 'Stock',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.creditcard),
          activeIcon: Icon(CupertinoIcons.creditcard_fill),
          label: 'Finances',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: 'Profil',
        ),
      ],
    );
  }

  Widget _buildCupertinoNavIcon(IconData icon, int index, int badgeCount) {
    if (index == 0 && badgeCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Icon(icon);
  }

  /// Bottom navigation pour Android - Material Design
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
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz_rounded,
                label: 'Activité',
                isSelected: _currentIndex == 1,
                onTap: () => _selectTab(1),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'Stock',
                isSelected: _currentIndex == 2,
                onTap: () => _selectTab(2),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                isSelected: _currentIndex == 3,
                onTap: () => _selectTab(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person_rounded,
                label: 'Profil',
                isSelected: _currentIndex == 4,
                onTap: () => _selectTab(4),
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
      _pageController.jumpToPage(index);
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
    
    final badgeText = badgeCount != null && badgeCount! > 0
        ? ', $badgeCount notifications non lues'
        : '';
    
    return Semantics(
      button: true,
      enabled: true,
      selected: isSelected,
      label: 'Onglet $label${isSelected ? ', sélectionné' : ''}$badgeText',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            // Touch target minimum 48x48 (WCAG)
            width: 64,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ),
      ),
    );
  }
}
