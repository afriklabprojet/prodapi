import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../pages/delivery_zone_page.dart';

/// Widget de menu paramètres pour la page profil
class SettingsMenuWidget extends StatefulWidget {
  const SettingsMenuWidget({super.key});

  @override
  State<SettingsMenuWidget> createState() => _SettingsMenuWidgetState();
}

class _SettingsMenuWidgetState extends State<SettingsMenuWidget> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsMenuItem(
                icon: Icons.shield_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Sécurité',
                subtitle: 'Biométrie, PIN, session',
                onTap: () => context.push('/security-settings'),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: Colors.orange,
                title: 'Notifications',
                subtitle: 'Gérer les alertes',
                onTap: () => context.push('/notification-settings'),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsMenuItem(
                icon: Icons.map_outlined,
                iconColor: Colors.green,
                title: 'Zone de livraison',
                subtitle: 'Définir votre périmètre',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryZonePage()),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsMenuItem(
                icon: Icons.language,
                iconColor: Colors.blue,
                title: 'Langue',
                subtitle: 'Français',
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onTap: () => _showLanguageDialog(context),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsMenuItem(
                icon: Icons.help_outline,
                iconColor: Colors.purple,
                title: 'Aide & Support',
                subtitle: 'FAQ, contact',
                onTap: () => context.push('/help-support'),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsMenuItem(
                icon: Icons.info_outline,
                iconColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                title: 'À propos',
                subtitle: 'Version $_appVersion',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              language: 'Français',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
            _LanguageOption(
              language: 'English',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('English coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_pharmacy_rounded,
                size: 48,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DR-PHARMA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            Text(
              'Espace Pharmacien',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version $_appVersion',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 DR-PHARMA',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
