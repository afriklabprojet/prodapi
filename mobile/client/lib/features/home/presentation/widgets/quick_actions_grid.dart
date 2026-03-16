import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Grille des actions rapides sur la page d'accueil
class QuickActionsGrid extends StatelessWidget {
  final bool isDark;

  const QuickActionsGrid({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final columns = r.value(mobile: 2, tablet: 3, desktop: 4);
    final aspectRatio = r.value(mobile: 1.5, tablet: 1.4, desktop: 1.3);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: r.gridSpacing,
      crossAxisSpacing: r.gridSpacing,
      childAspectRatio: aspectRatio,
      children: [
        QuickActionCard(
          icon: Icons.medication_outlined,
          title: 'Médicaments',
          subtitle: 'Tous les produits',
          color: AppColors.primary,
          isDark: isDark,
          onTap: () => context.goToProducts(), // Navigate to all products page
        ),
        QuickActionCard(
          icon: Icons.emergency_outlined,
          title: 'Garde',
          subtitle: 'Pharmacies de garde',
          color: const Color(0xFFFF5722),
          isDark: isDark,
          onTap: () => context.goToOnDutyPharmacies(),
        ),
        QuickActionCard(
          icon: Icons.local_pharmacy_outlined,
          title: 'Pharmacies',
          subtitle: 'Trouver à proximité',
          color: AppColors.accent,
          isDark: isDark,
          onTap: () => context.goToPharmacies(),
        ),
        QuickActionCard(
          icon: Icons.upload_file_outlined,
          title: 'Ordonnance',
          subtitle: 'Mes ordonnances',
          color: const Color(0xFF9C27B0),
          isDark: isDark,
          onTap: () => context.goToPrescriptions(),
        ),
      ],
    );
  }
}

/// Carte d'action rapide individuelle
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
