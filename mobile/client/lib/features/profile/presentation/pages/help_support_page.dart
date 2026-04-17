import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/messaging/messaging.dart';
import '../../../../config/providers.dart';

// ─── FAQ Model ───────────────────────────────────────────────────────────────

class _FAQItem {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});
}

// ─── Support Settings Model ──────────────────────────────────────────────────

class _SupportSettings {
  final String phone;
  final String email;
  final String whatsapp;

  const _SupportSettings({
    required this.phone,
    required this.email,
    required this.whatsapp,
  });
}

// ─── Default FAQ (fallback si l'API échoue) ──────────────────────────────────

const _defaultFaqItems = [
  _FAQItem(
    question: 'Comment suivre ma commande ?',
    answer:
        'Allez dans l\'onglet "Commandes" en bas de l\'écran pour voir toutes vos commandes en cours et leur statut.',
  ),
  _FAQItem(
    question: 'Comment payer ?',
    answer:
        'Nous acceptons les paiements par Mobile Money (Orange, MTN, Moov) et les paiements à la livraison.',
  ),
  _FAQItem(
    question: 'Comment annuler une commande ?',
    answer:
        'Vous pouvez annuler une commande tant qu\'elle n\'a pas été confirmée par la pharmacie. Allez dans les détails de la commande pour voir l\'option.',
  ),
  _FAQItem(
    question: 'J\'ai un problème avec ma livraison',
    answer:
        'Si le coursier a du retard ou un problème, vous pouvez le contacter directement depuis la page de suivi de commande.',
  ),
  _FAQItem(
    question: 'Comment uploader une ordonnance ?',
    answer:
        'Dans l\'onglet "Ordonnances" ou lors d\'une commande, appuyez sur "Ajouter une ordonnance" et prenez une photo de votre prescription.',
  ),
];

// ─── FAQ Provider ─────────────────────────────────────────────────────────────

final customerFaqProvider = FutureProvider<List<_FAQItem>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.supportFaqCustomer);
    final data = response.data;

    if (data['success'] == true && data['data'] is List) {
      final items = (data['data'] as List)
          .map((json) {
            return _FAQItem(
              question: json['question'] as String? ?? '',
              answer: json['answer'] as String? ?? '',
            );
          })
          .where((item) => item.question.isNotEmpty)
          .toList();

      if (items.isNotEmpty) return items;
    }
  } catch (_) {
    // Fallback silencieux
  }
  return _defaultFaqItems;
});

// ─── Support Settings Provider ────────────────────────────────────────────────

final supportSettingsProvider = FutureProvider<_SupportSettings>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(ApiConstants.supportSettings);
    final data = response.data;

    if (data['success'] == true && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      return _SupportSettings(
        phone: (d['support_phone'] as String?) ?? EnvConfig.supportPhone,
        email: (d['support_email'] as String?) ?? EnvConfig.supportEmail,
        whatsapp:
            (d['support_whatsapp'] as String?)?.replaceAll(
              RegExp(r'[^0-9+]'),
              '',
            ) ??
            EnvConfig.supportWhatsApp,
      );
    }
  } catch (_) {
    // Fallback silencieux aux valeurs build-time
  }
  return _SupportSettings(
    phone: EnvConfig.supportPhone,
    email: EnvConfig.supportEmail,
    whatsapp: EnvConfig.supportWhatsApp,
  );
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class HelpSupportPage extends ConsumerWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqAsync = ref.watch(customerFaqProvider);
    final settingsAsync = ref.watch(supportSettingsProvider);

    // Resolve support settings (show data or fallback, never block UI)
    final settings =
        settingsAsync.valueOrNull ??
        _SupportSettings(
          phone: EnvConfig.supportPhone,
          email: EnvConfig.supportEmail,
          whatsapp: EnvConfig.supportWhatsApp,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section FAQ
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          faqAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, s) => Column(
              children: _defaultFaqItems
                  .map((item) => _buildFAQItem(item.question, item.answer))
                  .toList(),
            ),
            data: (items) => Column(
              children: items
                  .map((item) => _buildFAQItem(item.question, item.answer))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Section Contact
          Text(
            'Contactez-nous',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: settings.email,
            color: Colors.blue,
            onTap: () async {
              final uri = Uri.parse('mailto:${settings.email}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const SizedBox(height: 8),

          // Téléphone
          _buildContactCard(
            context,
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            subtitle: settings.phone,
            color: Colors.green,
            onTap: () async {
              final uri = Uri.parse('tel:${settings.phone}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const SizedBox(height: 8),

          // WhatsApp
          _buildContactCard(
            context,
            icon: Icons.chat_outlined,
            title: 'WhatsApp',
            subtitle: 'Chat en direct avec le support',
            color: const Color(0xFF25D366),
            onTap: () async {
              final messaging = ref.read(messagingServiceProvider);
              final result = await messaging.contactSupport(
                supportNumber: settings.whatsapp,
                message:
                    'Bonjour, j\'ai besoin d\'aide avec l\'application DR-PHARMA.',
              );
              result.fold((failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(failure.message)));
                }
              }, (_) {});
            },
          ),

          const SizedBox(height: 24),

          // Note horaires
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horaires du support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notre équipe est disponible 7j/7 de 8h à 22h',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
