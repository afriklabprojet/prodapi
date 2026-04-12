import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// Bouton en bas de l'écran pour passer en ligne / hors ligne
/// Design premium avec gradient et animations fluides
class GoOnlineButton extends StatelessWidget {
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;

  const GoOnlineButton({
    super.key,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 32,
      right: 32,
      child: Semantics(
        label: isToggling
            ? 'Changement de statut en cours'
            : (isOnline
                  ? 'Bouton passer hors ligne. Vous êtes actuellement disponible pour les livraisons. Appuyez pour vous mettre hors ligne.'
                  : 'Bouton passer en ligne. Vous êtes actuellement hors ligne. Appuyez pour commencer à recevoir des commandes.'),
        button: true,
        enabled: !isToggling,
        child: GestureDetector(
          onTap: isToggling
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  onToggle();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            height: 64,
            decoration: BoxDecoration(
              gradient: isToggling
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isOnline
                          ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)]
                          : [DesignTokens.primaryLight, DesignTokens.primary],
                    ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: isToggling
                      ? Colors.grey.withValues(alpha: 0.3)
                      : (isOnline
                            ? const Color(0xFFEF5350).withValues(alpha: 0.4)
                            : DesignTokens.primary.withValues(alpha: 0.4)),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                if (!isToggling)
                  BoxShadow(
                    color: isOnline
                        ? const Color(0xFFEF5350).withValues(alpha: 0.2)
                        : DesignTokens.primary.withValues(alpha: 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Effet de brillance subtil
                if (!isToggling)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Contenu
                Center(
                  child: isToggling
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'CHANGEMENT EN COURS...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOnline
                                    ? Icons.power_settings_new
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isOnline
                                  ? 'PASSER HORS LIGNE'
                                  : 'PASSER EN LIGNE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
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
