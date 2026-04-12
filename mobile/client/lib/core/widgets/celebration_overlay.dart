import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../services/celebration_service.dart';
import '../constants/app_colors.dart';

/// Overlay de célébration qui affiche des animations et des confettis
class CelebrationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const CelebrationOverlay({super.key, required this.child});

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(celebrationProvider);

    ref.listen<CelebrationState>(celebrationProvider, (previous, next) {
      if (next.isShowing && next.currentCelebration != null) {
        _animController.forward(from: 0);
        if (next.currentCelebration!.showConfetti) {
          _confettiController.play();
        }
      } else {
        _animController.reverse();
      }
    });

    return Stack(
      children: [
        widget.child,

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),

        // Celebration card
        if (state.isShowing && state.currentCelebration != null)
          _buildCelebrationCard(context, state.currentCelebration!),
      ],
    );
  }

  Widget _buildCelebrationCard(BuildContext context, CelebrationData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: data.gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: data.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Badge (if any)
                if (data.badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: data.gradientColors),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          data.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  data.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(celebrationProvider.notifier).dismissCelebration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.gradientColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Super !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de badge débloqué à afficher dans le profil
class UnlockedBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final bool isUnlocked;

  const UnlockedBadge({
    super.key,
    required this.title,
    required this.icon,
    required this.colors,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? colors[0].withValues(alpha: 0.15)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? colors[0].withValues(alpha: 0.3)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: isUnlocked ? LinearGradient(colors: colors) : null,
              color: isUnlocked ? null : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.lock_outline,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ],
      ),
    );
  }
}

/// Grille des badges pour le profil
class BadgesGrid extends ConsumerWidget {
  const BadgesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(celebrationProvider);
    final badges = state.unlockedBadges;

    final allBadges = [
      _BadgeInfo(
        id: 'first_order',
        title: 'Nouveau client',
        icon: Icons.celebration_rounded,
        colors: [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      ),
      _BadgeInfo(
        id: 'fifth_order',
        title: 'Client fidèle',
        icon: Icons.star_rounded,
        colors: [const Color(0xFFF39C12), const Color(0xFFE74C3C)],
      ),
      _BadgeInfo(
        id: 'vip',
        title: 'VIP',
        icon: Icons.workspace_premium_rounded,
        colors: [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
      ),
      _BadgeInfo(
        id: 'first_renewal',
        title: 'Traitement suivi',
        icon: Icons.medication_rounded,
        colors: [const Color(0xFF00B894), const Color(0xFF55EFC4)],
      ),
      _BadgeInfo(
        id: 'first_wallet',
        title: 'Wallet activé',
        icon: Icons.account_balance_wallet_rounded,
        colors: [const Color(0xFFF39C12), const Color(0xFFE67E22)],
      ),
      _BadgeInfo(
        id: 'first_scan',
        title: 'Scanner Pro',
        icon: Icons.document_scanner_rounded,
        colors: [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        return UnlockedBadge(
          title: badge.title,
          icon: badge.icon,
          colors: badge.colors,
          isUnlocked: badges.contains(badge.id),
        );
      },
    );
  }
}

class _BadgeInfo {
  final String id;
  final String title;
  final IconData icon;
  final List<Color> colors;

  _BadgeInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.colors,
  });
}
