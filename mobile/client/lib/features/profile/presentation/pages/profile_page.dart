import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile when page opens
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileProvider.notifier).loadProfile();
        },
        child: profileState.isLoading
            ? const ProfileSkeleton()
            : profileState.hasError
            ? _buildErrorState(profileState.errorMessage ?? 'Erreur inconnue')
            : profileState.hasProfile
            ? _buildProfileContent()
            : const Center(child: Text('Aucun profil disponible')),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(profileProvider.notifier).loadProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = ref.watch(profileProvider).profile!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header with avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CachedAvatar(
                    imageUrl: profile.avatar,
                    radius: 60,
                    fallbackText: profile.initials,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  profile.email,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                if (profile.hasPhone) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        profile.phone!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                const SizedBox(height: 8),
                const Text(
                  'Statistiques',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shopping_bag,
                        label: 'Commandes',
                        value: '${profile.totalOrders}',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        label: 'Livrées',
                        value: '${profile.completedOrders}',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.payments,
                  label: 'Total Dépensé',
                  value: '${profile.totalSpent.toStringAsFixed(0)} FCFA',
                  color: AppColors.accent,
                  isWide: true,
                ),

                const SizedBox(height: 32),

                // Actions Section
                const Text(
                  'Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _ActionTile(
                  icon: Icons.edit,
                  title: 'Modifier le profil',
                  subtitle: 'Changer vos informations personnelles',
                  onTap: () => context.goToEditProfile(),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.location_on,
                  title: 'Mes adresses',
                  subtitle: 'Gérer vos adresses de livraison',
                  onTap: () => context.goToAddresses(),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.lock,
                  title: 'Changer le mot de passe',
                  subtitle: 'Mettre à jour votre mot de passe',
                  onTap: () => context.go(AppRoutes.changePassword),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Gérer vos préférences de notification',
                  onTap: () => context.goToNotificationSettings(),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.help_outline,
                  title: 'Aide et Support',
                  subtitle: 'FAQ et contact support',
                  onTap: () => context.push(AppRoutes.help),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.description_outlined,
                  title: 'Mentions légales',
                  subtitle: 'Conditions d\'utilisation et confidentialité',
                  onTap: () => _showLegalMenu(context),
                ),
                const SizedBox(height: 12),

                // Dark Mode Toggle
                _DarkModeToggle(),

                const SizedBox(height: 32),

                // Account Info
                const Text(
                  'Informations du compte',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Membre depuis',
                          value: _formatDate(profile.createdAt),
                        ),
                        if (profile.hasDefaultAddress) ...[
                          const Divider(height: 24),
                          _InfoRow(
                            label: 'Adresse par défaut',
                            value: profile.defaultAddress!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mentions légales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Conditions d\'utilisation'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.terms);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Politique de confidentialité'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.privacy);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Mentions légales'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.legal);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _DarkModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.primary,
          ),
        ),
        title: const Text(
          'Mode sombre',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          themeState.isDarkMode ? 'Activé' : 'Désactivé',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch(
          value: themeState.isDarkMode,
          onChanged: (_) {
            ref.read(themeProvider.notifier).toggleTheme();
          },
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}
