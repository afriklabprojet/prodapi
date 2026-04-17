import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/responsive_builder.dart';
import '../../../inventory/presentation/widgets/add_product_sheet.dart';
import '../../../inventory/presentation/widgets/delivery_reception_sheet.dart';

import '../providers/dashboard_tab_provider.dart';
import '../providers/activity_sub_tab_provider.dart';

/// Section des actions rapides du dashboard.
class DashboardQuickActions extends ConsumerWidget {
  /// GlobalKey optionnel pour le tutorial (scanner)
  final GlobalKey? scannerKey;
  
  const DashboardQuickActions({
    super.key,
    this.scannerKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    
    final actions = [
      QuickActionButton(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scanner',
        color: Colors.teal,
        onTap: () => context.push('/scanner'),
      ),
      QuickActionButton(
        icon: Icons.add_box_rounded,
        label: 'Ajouter produit',
        color: Colors.indigo,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddProductSheet(),
          );
        },
      ),
      QuickActionButton(
        icon: Icons.analytics_rounded,
        label: 'Rapports',
        color: Colors.deepOrange,
        onTap: () => context.push('/reports'),
      ),
      QuickActionButton(
        icon: Icons.medical_services_rounded,
        label: 'Ordonnances',
        color: Colors.teal,
        onTap: () {
          ref.read(activitySubTabProvider.notifier).state = 1;
          ref.read(dashboardTabProvider.notifier).state = 1;
        },
      ),
      QuickActionButton(
        icon: Icons.shield_rounded,
        label: 'Mode Garde',
        color: Colors.purple,
        onTap: () {
          context.push('/on-call');
        },
      ),
      QuickActionButton(
        icon: Icons.local_shipping_rounded,
        label: 'Réception',
        color: Colors.teal.shade700,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const DeliveryReceptionSheet(),
          );
        },
      ),
    ];
    
    return ResponsiveBuilder(
      builder: (context, responsive) {
        final itemsPerRow = responsive.isMobile ? 3 : responsive.isTablet ? 4 : 6;
        final rows = <List<Widget>>[];
        for (var i = 0; i < actions.length; i += itemsPerRow) {
          rows.add(actions.sublist(i, (i + itemsPerRow).clamp(0, actions.length)));
        }
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) SizedBox(height: responsive.cardSpacing),
                Row(
                  children: [
                    for (var j = 0; j < rows[i].length; j++) ...[
                      if (j > 0) SizedBox(width: responsive.cardSpacing),
                      Expanded(
                        child: j == 0 && scannerKey != null
                            ? KeyedSubtree(key: scannerKey!, child: rows[i][j])
                            : rows[i][j],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Bouton d'action rapide réutilisable
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Semantics(
      button: true,
      label: 'Action rapide: $label',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          focusColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.2),
          splashColor: color.withValues(alpha: 0.3),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? color.withValues(alpha: 0.9) : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
