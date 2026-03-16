import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../../orders/presentation/pages/orders_list_page.dart';
import '../../../prescriptions/presentation/pages/prescriptions_list_page.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../widgets/dashboard_stats_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;
  bool _showStats = true;

  // Page pour afficher les stats (nouvelle page d'accueil)
  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 0,
              flexibleSpace: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenu
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Widget de statistiques
                  const DashboardStatsWidget(),
                  const SizedBox(height: 32),
                  
                  // Actions rapides
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                  
                  // Dernières activités
                  _buildRecentActivitySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: _buildActionCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventaire',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: _buildActionCard(
                  icon: Icons.medical_services_outlined,
                  label: 'Ordonnances',
                  color: Colors.purple,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: _buildActionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Finances',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 400),
                child: _buildActionCard(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 0),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 100),
          child: ListItemCard(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
            ),
            title: 'Commande #12345',
            subtitle: 'Confirmée • Il y a 5 min',
            trailing: '45 000 FCFA',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 200),
          child: ListItemCard(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_outlined,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: 'Stock faible',
            subtitle: 'Paracétamol 500mg',
            trailingWidget: Icon(
              Icons.chevron_right,
              color: Colors.grey.shade600,
            ),
            onTap: () => setState(() => _currentIndex = 2),
          ),
        ),
      ],
    );
  }

  final List<Widget> _pages = [
    const OrdersListPage(),
    const PrescriptionsListPage(),
    const InventoryPage(),
    const WalletScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _showStats ? 5 : _currentIndex,
        children: [
          ..._pages,
          _buildHomePage(), // Index 5 - Page d'accueil avec stats
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _showStats ? 5 : _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              if (index == 5) {
                _showStats = true;
              } else {
                _showStats = false;
                _currentIndex = index;
              }
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Commandes',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services_rounded),
              label: 'Ordos',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Stock',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Finances',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Accueil',
            ),
          ],
        ),
      ),
    );
  }
}
