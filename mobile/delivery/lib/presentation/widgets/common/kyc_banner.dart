import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/kyc_guard_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/router/route_names.dart';

/// Bannière persistante affichée dans le dashboard quand le KYC n'est pas vérifié.
/// Le livreur peut naviguer librement mais est informé qu'il ne peut pas recevoir de commandes.
class KycBanner extends ConsumerStatefulWidget {
  const KycBanner({super.key});

  @override
  ConsumerState<KycBanner> createState() => _KycBannerState();
}

class _KycBannerState extends ConsumerState<KycBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(kycStatusProvider);
    final isDark = context.isDark;

    // Rien à afficher si vérifié ou si le statut n'est pas encore résolu
    if (status.isVerified || status == KycStatus.unknown) {
      return const SizedBox.shrink();
    }

    final isPending = status == KycStatus.pendingReview;
    final isRejected = status == KycStatus.rejected;

    final Color accentColor = isPending
        ? Colors.orange.shade600
        : isRejected
        ? Colors.red.shade600
        : DesignTokens.primary;
    final IconData icon = isPending
        ? Icons.hourglass_top_rounded
        : isRejected
        ? Icons.warning_amber_rounded
        : Icons.verified_user_outlined;

    final String message = isPending
        ? 'Documents en cours de vérification'
        : isRejected
        ? 'Documents refusés — veuillez les soumettre à nouveau'
        : 'Complétez votre vérification pour recevoir des commandes';

    final String? subtitle = isPending
        ? 'Validation sous 24-48h ouvrées'
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
            accentColor.withValues(alpha: isDark ? 0.06 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Icône animée
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) =>
                Opacity(opacity: _pulseAnimation.value, child: child),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPending) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push(AppRoutes.kycResubmission),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRejected
                        ? [Colors.red.shade600, Colors.red.shade700]
                        : [DesignTokens.primary, DesignTokens.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isRejected ? 'Corriger' : 'Vérifier',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
