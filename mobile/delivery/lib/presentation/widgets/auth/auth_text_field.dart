import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';

/// Widget de champ de texte réutilisable pour les écrans d'authentification.
///
/// Supporte le dark mode automatiquement et inclut toutes les fonctionnalités
/// nécessaires pour les formulaires de login/inscription.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.error,
    this.isPassword = false,
    this.obscureText = true,
    this.onObscureToggle,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  /// Contrôleur du champ
  final TextEditingController controller;

  /// Focus node pour la gestion du focus
  final FocusNode? focusNode;

  /// Label affiché au-dessus du champ (en majuscules)
  final String label;

  /// Placeholder du champ
  final String hint;

  /// Icône préfixe
  final IconData icon;

  /// Message d'erreur (null si pas d'erreur)
  final String? error;

  /// Si true, c'est un champ mot de passe avec toggle visibilité
  final bool isPassword;

  /// État actuel de l'obscurcissement (pour les mots de passe)
  final bool obscureText;

  /// Callback pour toggler l'obscurcissement
  final VoidCallback? onObscureToggle;

  /// Auto-focus au chargement
  final bool autofocus;

  /// Type de clavier
  final TextInputType keyboardType;

  /// Callback à chaque changement
  final ValueChanged<String>? onChanged;

  /// Validateur du champ
  final FormFieldValidator<String>? validator;

  /// Action du bouton texte du clavier
  final TextInputAction? textInputAction;

  /// Callback quand le formulaire est soumis
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs adaptatives
    final labelColor = hasError
        ? AppColors.error
        : (isDark ? DesignTokens.labelColorDarkMode : DesignTokens.labelColor);
    final iconColor = hasError
        ? AppColors.error
        : (isDark ? DesignTokens.iconColorDarkMode : DesignTokens.iconColor);
    final textColor =
        isDark ? DesignTokens.textDarkMode : DesignTokens.textDark;
    final fieldBg =
        isDark ? DesignTokens.fieldBgDark : DesignTokens.fieldBgLight;
    final borderColor =
        isDark ? DesignTokens.fieldBorderDark : DesignTokens.fieldBorderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: DesignTokens.fontSizeCaption,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: labelColor,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm),

        // Champ
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          obscureText: isPassword && obscureText,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: GoogleFonts.inter(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: DesignTokens.fontSizeBody,
              color: iconColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                icon,
                size: DesignTokens.fieldIconSize,
                color: iconColor,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: DesignTokens.fieldIconSize,
                      color: iconColor,
                    ),
                    onPressed: onObscureToggle,
                  )
                : null,
            filled: true,
            fillColor: hasError
                ? AppColors.error.withValues(alpha: 0.04)
                : fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spaceMd,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withValues(alpha: 0.5)
                    : borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : DesignTokens.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),

        // Message d'erreur
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: DesignTokens.spaceMd),
            child: Text(
              error!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton principal pour les actions d'authentification.
///
/// Style cohérent avec le design system DR-PHARMA.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  /// Texte du bouton
  final String label;

  /// Callback d'action
  final VoidCallback? onPressed;

  /// Si true, affiche un spinner
  final bool isLoading;

  /// Icône optionnelle (affichée dans un conteneur à droite)
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DesignTokens.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sora(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Bouton secondaire outline pour les actions alternatives.
class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// Texte du bouton
  final String label;

  /// Callback d'action
  final VoidCallback? onPressed;

  /// Icône optionnelle
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeightSmall,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 22) : const SizedBox.shrink(),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primary,
          side: BorderSide(
            color: DesignTokens.primary.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          ),
        ),
      ),
    );
  }
}
