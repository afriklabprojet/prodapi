import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Grille des actions rapides avec animations staggerées
class QuickActionsGrid extends StatefulWidget {
  final bool isDark;

  const QuickActionsGrid({super.key, this.isDark = false});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final columns = r.value(mobile: 2, tablet: 3, desktop: 4);
    final aspectRatio = r.value(mobile: 1.4, tablet: 1.3, desktop: 1.2);

    final actions = [
      _QuickActionData(
        icon: Icons.medication_rounded,
        title: 'Médicaments',
        subtitle: 'Tous les produits',
        color: AppColors.primary,
        onTap: () => context.goToProducts(),
      ),
      _QuickActionData(
        icon: Icons.emergency_rounded,
        title: 'Garde',
        subtitle: 'Pharmacies de garde',
        color: const Color(0xFFFF5722),
        onTap: () => context.goToOnDutyPharmacies(),
      ),
      _QuickActionData(
        icon: Icons.local_pharmacy_rounded,
        title: 'Pharmacies',
        subtitle: 'Trouver à proximité',
        color: AppColors.accent,
        onTap: () => context.goToPharmacies(),
      ),
      _QuickActionData(
        icon: Icons.file_upload_rounded,
        title: 'Ordonnance',
        subtitle: 'Mes ordonnances',
        color: const Color(0xFF9C27B0),
        onTap: () => context.goToPrescriptions(),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: r.gridSpacing,
      crossAxisSpacing: r.gridSpacing,
      childAspectRatio: aspectRatio,
      children: List.generate(actions.length, (index) {
        final action = actions[index];
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.15;
            final start = delay;
            final end = (delay + 0.4).clamp(0.0, 1.0);

            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: QuickActionCard(
            icon: action.icon,
            title: action.title,
            subtitle: action.subtitle,
            color: action.color,
            isDark: widget.isDark,
            onTap: action.onTap,
          ),
        );
      }),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// Carte d'action rapide avec design premium et animation au tap
class QuickActionCard extends StatefulWidget {
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
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.isDark
                  ? null
                  : LinearGradient(
                      colors: [
                        Colors.white,
                        widget.color.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : widget.color.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: widget.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
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
                // Icon container avec gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.15),
                        widget.color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 26),
                ),
                const Spacer(),
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle avec icône flèche
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: widget.color.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
