import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

void showWalletHelpSheet(BuildContext parentContext) {
  final faqItems = [
    {
      'q': 'Comment demander un retrait ?',
      'a':
          'Appuyez sur le bouton "Retrait" sur la carte de solde, entrez le montant souhaite et confirmez. Le virement sera effectue sous 24-48h.'
    },
    {
      'q': 'Quels sont les frais de retrait ?',
      'a':
          'Les retraits sont gratuits pour les montants superieurs a 50,000 FCFA. En dessous, des frais de 500 FCFA s\'appliquent.'
    },
    {
      'q': 'Comment modifier mes informations bancaires ?',
      'a':
          'Allez dans Parametres > Informations bancaires et modifiez vos coordonnees. Les changements seront verifies sous 24h.'
    },
    {
      'q': 'Pourquoi mon retrait est en attente ?',
      'a':
          'Les retraits sont traites les jours ouvrables. Si votre retrait est en attente depuis plus de 48h, contactez le support.'
    },
    {
      'q': 'Comment contacter le support ?',
      'a':
          'Vous pouvez nous joindre par email a support@drlpharma.com ou par telephone au +225 27 22 XX XX XX.'
    },
  ];

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              Colors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.help_outline_rounded,
                            color: Colors.cyan,
                            size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Aide et support',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AppColors.textPrimary)),
                            Text('Questions frequentes',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ...faqItems.map((faq) =>
                      _buildFaqItem(faq['q']!, faq['a']!)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Nous contacter',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildContactOption(
                    icon: Icons.email_outlined,
                    color: Colors.blue,
                    title: 'Email',
                    subtitle: 'support@drlpharma.com',
                    onTap: () async {
                      final uri = Uri.parse(
                          'mailto:support@drlpharma.com?subject=Support%20Wallet%20Pharmacie');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  _buildContactOption(
                    icon: Icons.phone_outlined,
                    color: Colors.green,
                    title: 'Telephone',
                    subtitle: '+225 27 22 XX XX XX',
                    onTap: () async {
                      final uri =
                          Uri.parse('tel:+22527220000');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  _buildContactOption(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.purple,
                    title: 'Chat en direct',
                    subtitle: 'Disponible 8h - 18h',
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(parentContext)
                          .showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Chat en cours de mise en place'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFaqItem(String question, String answer) {
  return ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(question,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary)),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(answer,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5)),
      ),
    ],
  );
}

Widget _buildContactOption({
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
