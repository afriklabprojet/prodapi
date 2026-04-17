import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/env_config.dart';

class LegalNoticesPage extends StatelessWidget {
  const LegalNoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentions Légales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              isDark: isDark,
              icon: Icons.business,
              title: 'Éditeur',
              content: 'L\'application DR-PHARMA est éditée par la société AFRIK LAB, '
                  'société à responsabilité limitée.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDark: isDark,
              icon: Icons.location_on_outlined,
              title: 'Siège social',
              content: 'Abidjan, Côte d\'Ivoire',
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDark: isDark,
              icon: Icons.contact_mail_outlined,
              title: 'Contact',
              content: 'Email : ${EnvConfig.supportEmail}\n'
                  'Téléphone : ${EnvConfig.supportPhone}',
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDark: isDark,
              icon: Icons.dns_outlined,
              title: 'Hébergement',
              content: 'L\'infrastructure technique est hébergée sur des serveurs sécurisés.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDark: isDark,
              icon: Icons.copyright_outlined,
              title: 'Propriété intellectuelle',
              content: 'Tous les contenus de l\'application (textes, images, logos) '
                  'sont protégés par le droit d\'auteur et ne peuvent être reproduits '
                  'sans autorisation préalable.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
