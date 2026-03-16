import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/entities/pharmacy_entity.dart';
import '../../../on_call/presentation/pages/on_call_page.dart';
import 'edit_pharmacy_page.dart';
import 'edit_profile_page.dart';


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header amélioré
              Container(
                color: isDark ? AppColors.darkSurface : Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icône avec dégradé
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo,
                                Colors.indigo.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Titre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mon Profil',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gérez votre compte et préférences',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Consumer(
                                  builder: (context, ref, child) {
                                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                                    return Badge(
                                      isLabelVisible: unreadCount > 0,
                                      label: Text(unreadCount.toString()),
                                      child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black87, size: 24),
                                    );
                                  },
                                ),
                                onPressed: () => context.push('/notifications'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22),
                                onPressed: () => _confirmLogout(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Header centered
                    _buildProfileHeader(user),
                  ],
                ),
              ),
              
              // Contenu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Infos Contact
                    _buildSectionTitle('Coordonnées', isDark: isDark),
                    const SizedBox(height: 12),
                    _buildInfoSection(context, user),

                    const SizedBox(height: 32),

                    // Pharmacies
                    if (user.pharmacies.isNotEmpty) ...[
                      _buildSectionTitle('Ma Pharmacie', isDark: isDark),
                      const SizedBox(height: 12),
                      _buildPharmacyCard(context, user.pharmacies.first),
                    ] else if (user.role?.toLowerCase() == 'pharmacy') ...[
                      _buildSectionTitle('Ma Pharmacie', isDark: isDark),
                      const SizedBox(height: 12),
                      _buildEmptyState(context),
                    ],

                    const SizedBox(height: 32),

                    // Section Paramètres & Outils
                    _buildSectionTitle('Paramètres & Outils', isDark: isDark),
                    const SizedBox(height: 12),
                    _buildSettingsSection(context),

                    const SizedBox(height: 32),

                    // Bouton Déconnexion
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _confirmLogout(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.2), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Se déconnecter',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          children: [
            _buildAvatar(user),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _getFormattedRoleAndLocation(user),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, {bool isDark = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     return Card(
        elevation: 0,
        color: isDark ? AppColors.darkCard : Colors.grey[50],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey[200]!)
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
               Icon(Icons.store_mall_directory_outlined, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey),
               const SizedBox(height: 12),
               Text(
                "Aucune pharmacie associée",
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.analytics_outlined,
            iconColor: Colors.blue,
            title: 'Rapports & Analytics',
            subtitle: 'Statistiques de vente et performance',
            onTap: () => context.push('/reports'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            title: 'Apparence',
            subtitle: 'Thème, couleurs et mode sombre',
            onTap: () => context.push('/appearance-settings'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            iconColor: Colors.orange,
            title: 'Sécurité',
            subtitle: 'Mot de passe et connexion',
            onTap: () => context.push('/security-settings'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            iconColor: Colors.teal,
            title: 'Notifications',
            subtitle: 'Gérer vos alertes et préférences',
            onTap: () => context.push('/notification-settings'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            iconColor: Colors.indigo,
            title: 'Aide & Support',
            subtitle: 'FAQ, contact et ressources',
            onTap: () => context.push('/help-support'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            iconColor: Colors.blueGrey,
            title: 'Conditions d\'utilisation',
            subtitle: 'CGU et mentions légales',
            onTap: () => context.push('/terms'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.cyan,
            title: 'Politique de confidentialité',
            subtitle: 'Protection de vos données',
            onTap: () => context.push('/privacy'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Me déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
         await ref.read(authProvider.notifier).logout();
         
         if (context.mounted) {
           context.go('/login');
         }
      }
    }
  }

  String _getFormattedRoleAndLocation(UserEntity user) {
    // 1. Format Role
    String roleDisplay = 'Utilisateur';
    if (user.role != null) {
      switch (user.role!.toLowerCase()) {
        case 'pharmacy':
          roleDisplay = 'Pharmacien';
          break;
        case 'admin':
          roleDisplay = 'Administrateur';
          break;
        case 'courier':
          roleDisplay = 'Livreur';
          break;
        default:
          // Capitalize first letter
          if (user.role!.isNotEmpty) {
            roleDisplay = user.role![0].toUpperCase() + user.role!.substring(1);
          }
      }
    }

    // 2. Add Location (if available from pharmacies)
    String? location;
    if (user.pharmacies.isNotEmpty) {
      // Use the city of the first pharmacy primarily
      location = user.pharmacies.firstOrNull?.city;
    }

    if (location != null && location.isNotEmpty) {
      return '$roleDisplay • $location';
    }

    return roleDisplay;
  }

  Widget _buildAvatar(UserEntity user) {
    // 2. Try Pharmacy Name/Logo (Concepts) -> Fallback to Initials
    // If no user avatar, we use initials with dynamic color
    final String displayName = user.name.isNotEmpty ? user.name : '?';
    final Color dynamicColor = _getDynamicColor(displayName);
    final String initials = _getInitials(displayName);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: user.avatar != null && user.avatar!.isNotEmpty 
            ? Colors.transparent 
            : dynamicColor.withValues(alpha: 0.1),
        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty 
            ? CachedNetworkImageProvider(user.avatar!) 
            : null,
        child: user.avatar != null && user.avatar!.isNotEmpty 
            ? null
            : Text(
                initials,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: dynamicColor,
                ),
              ),
      ),
    );
  }

  Color _getDynamicColor(String text) {
    if (text.isEmpty) return Colors.blue;
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepOrange,
    ];
    return colors[text.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    
    if (parts.length == 1) {
      // Just one name, take up to 2 chars if possible, or just 1
      return parts[0].length > 1 
          ? parts[0].substring(0, 2).toUpperCase() 
          : parts[0][0].toUpperCase();
    }
    
    // First and Last name initials - check last part is not empty
    final lastPart = parts.last;
    if (lastPart.isEmpty) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${lastPart[0]}'.toUpperCase();
  }


  Widget _buildInfoSection(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContactRow(
                context: context,
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
                onTap: () => _launchEmail(user.email),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 60),
              _buildContactRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: user.phone,
                onTap: () => _launchPhone(user.phone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36, // Hauteur fixe réduite
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(user: user),
                ),
              );
            },
            icon: Icon(Icons.edit_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            label: Text(
              'Modifier mes informations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Match container
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.grey[600] : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Could not launch email: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Could not launch phone: $e');
    }
  }

  Widget _buildPharmacyCard(BuildContext context, PharmacyEntity pharmacy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.go('/dashboard');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: isDark ? 0.2 : 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_mall_directory_outlined, color: Colors.blueGrey, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                pharmacy.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(pharmacy.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (pharmacy.address != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              pharmacy.address!,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (pharmacy.city != null)
                          Text(
                            pharmacy.city!,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),

              Row(
                children: [
                   Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditPharmacyPage(pharmacy: pharmacy),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OnCallPage()),
                          );
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: const Text('Gardes', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        label = 'Validé';
        break;
      case 'pending':
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        label = 'En attente';
        break;
      case 'rejected':
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        label = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
