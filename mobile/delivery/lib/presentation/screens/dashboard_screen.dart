import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/tutorial_service.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../main.dart';
import '../widgets/tutorial/tutorial_widgets.dart';
import 'home_screen.dart';
import 'deliveries_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'challenges_screen.dart';
import 'delivery_details_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Différer les inits lourdes après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Enveloppé dans try-catch pour éviter des crashs silencieux non gérés
      _initNotificationsAndRouting().catchError((e) {
        if (kDebugMode) debugPrint('❌ [Dashboard] Notification init error: $e');
      });
      _checkFirstLaunch().catchError((e) {
        if (kDebugMode) debugPrint('❌ [Dashboard] First launch check error: $e');
      });
    });
  }

  /// Vérifie si c'est le premier lancement et affiche le tutoriel
  Future<void> _checkFirstLaunch() async {
    final service = ref.read(tutorialServiceProvider);
    final isFirst = await service.isFirstLaunch();
    
    if (isFirst && mounted) {
      // Petit délai pour laisser l'UI se charger
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ref.startTutorialIfNeeded(TutorialType.welcome);
      }
    }
  }

  /// Initialise les notifications FCM et le routage au tap
  Future<void> _initNotificationsAndRouting() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initNotifications();

    // Wire up notification tap → navigate to delivery details
    notificationService.onNotificationTapped = (String idStr) {
      _navigateToDeliveryFromNotification(idStr);
    };
  }

  /// Navigue vers les détails d'une livraison depuis une notification tapée
  Future<void> _navigateToDeliveryFromNotification(String idStr) async {
    final id = int.tryParse(idStr);
    if (id == null) return;

    // Vérifier que le widget est toujours monté avant d'utiliser ref
    if (!mounted) return;

    final navigator = MyApp.navigatorKey.currentState;
    if (navigator == null) return;

    try {
      final delivery =
          await ref.read(deliveryRepositoryProvider).getDeliveryById(id);
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DeliveryDetailsScreen(delivery: delivery),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Navigation from notification failed: $e');
    }
  }

  void _onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements de thème pour forcer le rebuild
    ref.watch(themeProvider);
    final isDark = context.isDark;
    
    final screens = [
      const HomeScreen(),
      const DeliveriesScreen(),
      const ChallengesScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return TutorialOverlay(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Défis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      ),
    );
  }
}