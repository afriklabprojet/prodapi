import 'package:flutter/material.dart';
import '../../domain/enums/password_strength.dart';

/// Indicateur visuel de la robustesse du mot de passe.
///
/// Affiche une barre de progression colorée et un label textuel.
/// Conçu pour être placé sous un champ mot de passe.
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final bool showMinLengthHint;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.showMinLengthHint = true,
  });

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength.progress,
              backgroundColor: Colors.grey.shade200,
              color: strength.color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          // Label + icône
          Row(
            children: [
              if (strength.icon != null) ...[
                Icon(strength.icon, size: 14, color: strength.color),
                const SizedBox(width: 4),
              ],
              Text(
                strength.label,
                style: TextStyle(
                  color: strength.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (showMinLengthHint && strength == PasswordStrength.tooShort)
                Text(
                  'Min. ${PasswordStrength.minLength} caractères',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
