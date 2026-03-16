import 'package:flutter/material.dart';

/// Bouton en bas de l'écran pour passer en ligne / hors ligne
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
      left: 40,
      right: 40,
      child: Semantics(
        label: isToggling
            ? 'Changement de statut en cours'
            : (isOnline
                ? 'Bouton passer hors ligne. Vous êtes actuellement disponible pour les livraisons. Appuyez pour vous mettre hors ligne.'
                : 'Bouton passer en ligne. Vous êtes actuellement hors ligne. Appuyez pour commencer à recevoir des commandes.'),
        button: true,
        enabled: !isToggling,
        child: GestureDetector(
          onTap: isToggling ? null : onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            decoration: BoxDecoration(
              color: isToggling
                  ? Colors.grey.shade400
                  : (isOnline ? Colors.red.shade400 : Colors.green.shade600),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: isToggling
                      ? Colors.grey.withValues(alpha: 0.3)
                      : ((isOnline ? Colors.red : Colors.green).withValues(alpha: 0.4)),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: isToggling
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CHANGEMENT EN COURS...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.power_settings_new : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline ? 'PASSER HORS LIGNE' : 'PASSER EN LIGNE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
