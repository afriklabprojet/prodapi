import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../config/providers.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/cart_state.dart';

/// AppBar personnalisée pour la page d'accueil
class HomeAppBar extends ConsumerWidget {
  final CartState cartState;
  final bool isDark;

  const HomeAppBar({super.key, required this.cartState, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DR-PHARMA',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        NotificationButton(isDark: isDark),
        CartButton(cartState: cartState, isDark: isDark),
        ProfileMenuButton(isDark: isDark),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Bouton de notifications avec badge
class NotificationButton extends ConsumerWidget {
  final bool isDark;

  const NotificationButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => context.goToNotifications(),
        ),
        Consumer(
          builder: (context, ref, _) {
            final unreadCount = ref.watch(unreadCountProvider);
            if (unreadCount > 0) {
              return Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// Bouton panier avec badge
class CartButton extends StatelessWidget {
  final CartState cartState;
  final bool isDark;

  const CartButton({super.key, required this.cartState, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.shopping_bag_outlined,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => context.pushToCart(),
        ),
        if (cartState.itemCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${cartState.itemCount}',
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
    );
  }
}

/// Menu profil déroulant
class ProfileMenuButton extends ConsumerWidget {
  final bool isDark;

  const ProfileMenuButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      onSelected: (value) => _handleMenuSelection(context, ref, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Mon Profil'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'orders',
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 20),
              SizedBox(width: 12),
              Text('Mes Commandes'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'profile':
        context.goToProfile();
        break;
      case 'orders':
        context.goToOrders();
        break;
      case 'logout':
        // Supprimer le token FCM du backend avant déconnexion
        await removeFcmTokenOnLogout(ref);
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.goToLogin();
        break;
    }
  }
}

/// Section de bienvenue avec nom utilisateur et animation
class WelcomeSection extends StatefulWidget {
  final String? userName;
  final bool isDark;

  const WelcomeSection({super.key, this.userName, required this.isDark});

  @override
  State<WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.nightlight_round;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 18) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getGreetingIcon(),
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getGreeting()},',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.userName ?? 'Cher Client',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comment allez-vous aujourd\'hui ?',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDark
                          ? Colors.grey[500]
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Avatar décoratif
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (widget.userName?.isNotEmpty == true)
                      ? widget.userName![0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section réutilisable avec design premium
class SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? trailing;
  final bool showAccent;

  const SectionTitle({
    super.key,
    required this.title,
    required this.isDark,
    this.trailing,
    this.showAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showAccent) ...[
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
