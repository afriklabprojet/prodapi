import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'home_page.dart';
import 'features/orders/presentation/pages/orders_list_page.dart';
import 'features/orders/presentation/providers/orders_provider.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';

/// Provider pour le tab actif, global pour permettre la navigation depuis n'importe où
final mainShellTabProvider = StateProvider<int>((ref) => 0);

/// Shell principal avec BottomNavigationBar
/// Utilise IndexedStack pour préserver l'état de chaque onglet
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  // Non-const car OrdersListPage et ProfilePage ont des constructeurs runtime
  final List<Widget> _pages = [
    const HomePage(),
    const OrdersListPage(),
    const WalletPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainShellTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeOrdersCount = ref.watch(activeOrdersCountProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Si on n'est pas sur le tab Accueil, y revenir
          final current = ref.read(mainShellTabProvider);
          if (current != 0) {
            ref.read(mainShellTabProvider.notifier).state = 0;
          } else {
            // Sur le tab Accueil, demander confirmation de sortie
            _showExitConfirmation(context);
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            ref.read(mainShellTabProvider.notifier).state = index;
          },
          backgroundColor: isDark ? AppColors.darkBackgroundDeep : Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: _buildIconWithBadge(
                icon: Icons.home_outlined,
                count: ref.watch(unreadCountProvider),
                isDark: isDark,
              ),
              selectedIcon: _buildIconWithBadge(
                icon: Icons.home,
                count: ref.watch(unreadCountProvider),
                isDark: isDark,
                isSelected: true,
              ),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: _buildIconWithBadge(
                icon: Icons.receipt_long_outlined,
                count: activeOrdersCount,
                isDark: isDark,
              ),
              selectedIcon: _buildIconWithBadge(
                icon: Icons.receipt_long,
                count: activeOrdersCount,
                isDark: isDark,
                isSelected: true,
              ),
              label: 'Commandes',
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
              label: 'Portefeuille',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Mon Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required int count,
    required bool isDark,
    bool isSelected = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: isSelected ? AppColors.primary : null),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'application'),
        content: const Text('Voulez-vous vraiment quitter l\'application ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Quitter', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
