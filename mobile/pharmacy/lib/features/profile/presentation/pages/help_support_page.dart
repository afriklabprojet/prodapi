import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/support_settings_provider.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class HelpSupportPage extends ConsumerWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportSettingsAsync = ref.watch(supportSettingsProvider);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : null,
      appBar: AppBar(title: const Text('Aide & Support')),
      body: supportSettingsAsync.when(
        data: (settings) => _buildContent(context, settings, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _buildContent(context, SupportSettings.defaults(), isDark),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SupportSettings settings,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Contact
        _buildSectionCard(
          context,
          title: 'Nous contacter',
          children: [
            _buildContactTile(
              context,
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: settings.supportEmail,
              onTap: () => _launchUrl(settings.emailUrl),
            ),
            const Divider(height: 1),
            _buildContactTile(
              context,
              icon: Icons.phone_outlined,
              title: 'Téléphone',
              subtitle: settings.supportPhone,
              onTap: () => _launchUrl(settings.phoneUrl),
            ),
            const Divider(height: 1),
            _buildContactTile(
              context,
              icon: Icons.chat_outlined,
              title: 'WhatsApp',
              subtitle: 'Chat en direct',
              onTap: () => WhatsAppService.contactSupport(
                supportNumber: settings.supportWhatsapp,
                message:
                    'Bonjour, je suis pharmacien partenaire DR-PHARMA et j\'ai besoin d\'aide.',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // FAQ Section
        _buildSectionCard(
          context,
          title: 'Questions fréquentes',
          children: [
            _buildFaqItem(
              context,
              question: 'Comment ajouter un produit à mon inventaire ?',
              answer:
                  'Allez dans l\'onglet "Stock", appuyez sur le bouton "+", puis scannez le code-barres ou entrez les informations manuellement.',
            ),
            const Divider(height: 1),
            _buildFaqItem(
              context,
              question: 'Comment traiter une commande ?',
              answer:
                  'Dans l\'onglet "Commandes", appuyez sur une commande en attente, puis utilisez les boutons "Confirmer" ou "Préparer" selon l\'état de la commande.',
            ),
            const Divider(height: 1),
            _buildFaqItem(
              context,
              question: 'Comment modifier les informations de ma pharmacie ?',
              answer:
                  'Allez dans "Profil" > "Ma Pharmacie" > appuyez sur l\'icône de modification pour éditer les informations.',
            ),
            const Divider(height: 1),
            _buildFaqItem(
              context,
              question: 'Comment activer le mode garde ?',
              answer:
                  'Dans "Profil" > "Mode Garde", vous pouvez activer/désactiver le mode garde et définir vos horaires de garde.',
            ),
            const Divider(height: 1),
            _buildFaqItem(
              context,
              question: 'Comment voir mes statistiques de vente ?',
              answer:
                  'Accédez à "Rapports & Analytics" depuis le menu profil pour voir vos statistiques détaillées.',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Ressources
        _buildSectionCard(
          context,
          title: 'Ressources',
          children: [
            if (settings.tutorialsUrl.isNotEmpty) ...[
              _buildResourceTile(
                context,
                icon: Icons.play_circle_outline,
                title: 'Tutoriels vidéo',
                onTap: () =>
                    _launchUrl(settings.tutorialsUrl, context: context),
              ),
              const Divider(height: 1),
            ],
            if (settings.guideUrl.isNotEmpty) ...[
              _buildResourceTile(
                context,
                icon: Icons.menu_book_outlined,
                title: 'Guide d\'utilisation',
                onTap: () => _launchUrl(settings.guideUrl, context: context),
              ),
              const Divider(height: 1),
            ],
            if (settings.faqUrl.isNotEmpty) ...[
              _buildResourceTile(
                context,
                icon: Icons.help_outline,
                title: 'FAQ en ligne',
                onTap: () => _launchUrl(settings.faqUrl, context: context),
              ),
              const Divider(height: 1),
            ],
            _buildResourceTile(
              context,
              icon: Icons.update_outlined,
              title: 'Notes de mise à jour',
              onTap: () => _showChangelogDialog(context),
            ),
            if (settings.websiteUrl.isNotEmpty) ...[
              const Divider(height: 1),
              _buildResourceTile(
                context,
                icon: Icons.language_outlined,
                title: 'Site web',
                onTap: () => _launchUrl(settings.websiteUrl, context: context),
              ),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // Liens légaux
        _buildSectionCard(
          context,
          title: 'Informations légales',
          children: [
            _buildResourceTile(
              context,
              icon: Icons.article_outlined,
              title: 'Conditions d\'utilisation',
              onTap: () => context.push('/terms'),
            ),
            const Divider(height: 1),
            _buildResourceTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Politique de confidentialité',
              onTap: () => context.push('/privacy'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Report Bug
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signaler un problème',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Aidez-nous à améliorer l\'application',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onPressed: () => _showReportBugDialog(context, settings),
                tooltip: 'Signaler un problème',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDark = AppColors.isDark(context);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url, {BuildContext? context}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
      );
    }
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes de mise à jour'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVersionItem('1.0.0', 'Janvier 2026', [
                'Version initiale',
                'Gestion des commandes',
                'Inventaire et scanner',
                'Notifications push',
                'Mode garde',
                'Rapports et analytics',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem(String version, String date, List<String> changes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Version $version',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              date,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...changes.map(
          (c) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(c, style: const TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReportBugDialog(BuildContext context, SupportSettings settings) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Décrivez le problème rencontré :'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Description du problème...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Envoyer par email
                final subject = Uri.encodeComponent(
                  'Bug Report - DR-PHARMA Pharmacy App',
                );
                final body = Uri.encodeComponent(controller.text);
                _launchUrl(
                  'mailto:${settings.supportEmail}?subject=$subject&body=$body',
                );
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Merci pour votre signalement !')),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    ).whenComplete(() => controller.dispose());
  }
}
