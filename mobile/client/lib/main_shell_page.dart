import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'home_page.dart';
import 'features/orders/presentation/pages/orders_list_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'l10n/app_localizations.dart';

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
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainShellTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
        body: IndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(mainShellTabProvider.notifier).state = index;
          },
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
              label: l10n.navMyOrders,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogQuitApp),
        content: Text(l10n.dialogQuitAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.btnQuit, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
