import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget affichant les badges de confiance et garanties
/// Augmente la confiance des utilisateurs et réduit l'abandon de panier
class TrustBadgesSection extends StatelessWidget {
  final bool isCompact;
  final bool showTitle;

  const TrustBadgesSection({
    super.key,
    this.isCompact = false,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return _buildCompactBadges(context, isDark);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF1E2A3F)]
              : [
                  AppColors.primary.withValues(alpha: 0.05),
                  Colors.blue.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Row(
              children: [
                Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Achetez en toute confiance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Grid de badges
          Row(
            children: [
              Expanded(
                child: _buildBadge(
                  context,
                  icon: Icons.verified,
                  iconColor: AppColors.success,
                  title: 'Authentique',
                  subtitle: 'Médicaments certifiés',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBadge(
                  context,
                  icon: Icons.local_shipping_outlined,
                  iconColor: Colors.blue,
                  title: 'Livraison sûre',
                  subtitle: 'Suivi en temps réel',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBadge(
                  context,
                  icon: Icons.replay,
                  iconColor: Colors.orange,
                  title: 'Remboursement',
                  subtitle: 'Garantie 48h',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBadge(
                  context,
                  icon: Icons.support_agent,
                  iconColor: Colors.purple,
                  title: 'Support 24/7',
                  subtitle: 'On vous accompagne',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadges(BuildContext context, bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCompactBadge(
            context,
            icon: Icons.verified,
            label: 'Médicaments authentiques',
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildCompactBadge(
            context,
            icon: Icons.replay,
            label: 'Garantie remboursement',
            color: Colors.orange,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildCompactBadge(
            context,
            icon: Icons.local_shipping_outlined,
            label: 'Livraison rapide',
            color: Colors.blue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget badge simple pour afficher un indicateur de confiance inline
class TrustIndicator extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const TrustIndicator({
    super.key,
    required this.text,
    this.icon = Icons.verified,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.success;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
