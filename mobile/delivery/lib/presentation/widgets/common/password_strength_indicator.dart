import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';

/// Widget d'indicateur de force du mot de passe.
/// 
/// Affiche une barre de progression colorée et des indicateurs
/// de critères validés/non validés pour guider l'utilisateur.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showCriteria = true,
    this.animated = true,
  });

  /// Le mot de passe à évaluer
  final String password;

  /// Affiche la liste des critères (min 8 chars, majuscule, etc.)
  final bool showCriteria;

  /// Active les animations de transition
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final strengthInfo = _getStrengthInfo(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de force
        _StrengthBar(
          strength: strength,
          color: strengthInfo.color,
          animated: animated,
        ),

        const SizedBox(height: 8),

        // Label de force
        Row(
          children: [
            Icon(
              strengthInfo.icon,
              size: 16,
              color: strengthInfo.color,
            ),
            const SizedBox(width: 6),
            Text(
              strengthInfo.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: strengthInfo.color,
              ),
            ),
          ],
        ),

        // Critères détaillés
        if (showCriteria && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CriteriaList(password: password),
        ],
      ],
    );
  }

  _StrengthInfo _getStrengthInfo(int strength) {
    if (strength >= 80) {
      return _StrengthInfo(
        label: 'Très fort',
        color: const Color(0xFF2E7D32), // Green 800
        icon: Icons.verified_user,
      );
    } else if (strength >= 60) {
      return _StrengthInfo(
        label: 'Fort',
        color: const Color(0xFF4CAF50), // Green 500
        icon: Icons.check_circle,
      );
    } else if (strength >= 40) {
      return _StrengthInfo(
        label: 'Moyen',
        color: const Color(0xFFFFA000), // Amber 700
        icon: Icons.info,
      );
    } else if (strength >= 20) {
      return _StrengthInfo(
        label: 'Faible',
        color: const Color(0xFFFF9800), // Orange 500
        icon: Icons.warning,
      );
    } else {
      return _StrengthInfo(
        label: 'Très faible',
        color: const Color(0xFFE53935), // Red 600
        icon: Icons.error,
      );
    }
  }
}

class _StrengthInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StrengthInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Barre de progression de force
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.strength,
    required this.color,
    required this.animated,
  });

  final int strength;
  final Color color;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * (strength / 100);

          if (animated) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: width,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            );
          }

          return Container(
            width: width,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}

/// Liste des critères de validation du mot de passe
class _CriteriaList extends StatelessWidget {
  const _CriteriaList({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final criteria = [
      _Criterion(
        label: 'Au moins 8 caractères',
        isValid: password.length >= 8,
      ),
      _Criterion(
        label: 'Une lettre minuscule',
        isValid: RegExp(r'[a-z]').hasMatch(password),
      ),
      _Criterion(
        label: 'Une lettre majuscule',
        isValid: RegExp(r'[A-Z]').hasMatch(password),
      ),
      _Criterion(
        label: 'Un chiffre',
        isValid: RegExp(r'\d').hasMatch(password),
      ),
      _Criterion(
        label: 'Un caractère spécial (!@#\$%...)',
        isValid: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteria
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _CriterionRow(criterion: c),
              ))
          .toList(),
    );
  }
}

class _Criterion {
  final String label;
  final bool isValid;

  _Criterion({required this.label, required this.isValid});
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion});

  final _Criterion criterion;

  @override
  Widget build(BuildContext context) {
    final color = criterion.isValid ? Colors.green : Colors.grey;

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            criterion.isValid ? Icons.check_circle : Icons.circle_outlined,
            key: ValueKey(criterion.isValid),
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          criterion.label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Extension helper pour ajouter facilement à un TextField
extension PasswordFieldExtension on TextField {
  /// Ajoute un indicateur de force sous le TextField
  Widget withStrengthIndicator({
    required String password,
    bool showCriteria = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        this,
        const SizedBox(height: 8),
        PasswordStrengthIndicator(
          password: password,
          showCriteria: showCriteria,
        ),
      ],
    );
  }
}
