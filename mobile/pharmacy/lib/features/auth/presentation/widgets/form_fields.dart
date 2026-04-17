import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CONSTANTS & THEMING
// ══════════════════════════════════════════════════════════════════════════════

/// Default border radius for form fields
const double _kBorderRadius = 14.0;

/// Default primary color (DR-PHARMA brand)
const Color _kPrimaryColor = AppColors.primary;

// ══════════════════════════════════════════════════════════════════════════════
// INPUT BORDER HELPER
// ══════════════════════════════════════════════════════════════════════════════

/// Creates a consistent OutlineInputBorder with customizable color and width.
/// 
/// This helper reduces code duplication across form fields while ensuring
/// consistent border radius throughout the app.
OutlineInputBorder buildInputBorder({
  Color? color,
  double width = 1.0,
  double radius = _kBorderRadius,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: color == null
        ? BorderSide.none
        : BorderSide(color: color, width: width),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PASSWORD STRENGTH ENUM
// ══════════════════════════════════════════════════════════════════════════════

/// Represents password strength levels for visual feedback
enum PasswordStrength {
  empty,
  tooShort,
  weak,
  medium,
  strong;

  Color get color => switch (this) {
    PasswordStrength.empty => Colors.grey.shade300,
    PasswordStrength.tooShort => Colors.red.shade400,
    PasswordStrength.weak => Colors.orange.shade400,
    PasswordStrength.medium => Colors.amber.shade600,
    PasswordStrength.strong => _kPrimaryColor,
  };

  Color get borderColor => switch (this) {
    PasswordStrength.empty => Colors.grey.shade200,
    PasswordStrength.tooShort => Colors.red.shade300,
    PasswordStrength.weak => Colors.orange.shade300,
    PasswordStrength.medium => Colors.amber.shade400,
    PasswordStrength.strong => _kPrimaryColor,
  };

  String get label => switch (this) {
    PasswordStrength.empty => '',
    PasswordStrength.tooShort => 'Trop court',
    PasswordStrength.weak => 'Faible',
    PasswordStrength.medium => 'Moyen',
    PasswordStrength.strong => 'Fort',
  };

  IconData? get icon => switch (this) {
    PasswordStrength.empty => null,
    PasswordStrength.tooShort => Icons.error_outline,
    PasswordStrength.weak => Icons.warning_amber_rounded,
    PasswordStrength.medium => Icons.info_outline,
    PasswordStrength.strong => Icons.check_circle,
  };

  double get progress => switch (this) {
    PasswordStrength.empty => 0.0,
    PasswordStrength.tooShort => 0.15,
    PasswordStrength.weak => 0.35,
    PasswordStrength.medium => 0.65,
    PasswordStrength.strong => 1.0,
  };

  /// Calculate password strength from a password string
  static PasswordStrength calculate(String password, {int minLength = 6}) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < minLength) return PasswordStrength.tooShort;
    
    int score = 0;
    // Length bonus
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    // Complexity checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHARMACY EMAIL FIELD
// ══════════════════════════════════════════════════════════════════════════════

/// A reusable, accessible email field for pharmacy authentication.
/// 
/// Features:
/// - RFC 5322 compliant email validation
/// - Accessibility labels for screen readers
/// - Consistent styling with DR-PHARMA design system
/// - Visual feedback for valid email state
/// 
/// Example usage:
/// ```dart
/// PharmacyEmailField(
///   controller: _emailController,
///   focusNode: _emailFocus,
///   onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
///   validator: (value) => value?.isEmpty == true ? 'Required' : null,
/// )
/// ```
class PharmacyEmailField extends StatelessWidget {
  const PharmacyEmailField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFieldSubmitted,
    this.validator,
    this.isValid = false,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Controller for the email text field
  final TextEditingController controller;
  
  /// Focus node for managing focus state
  final FocusNode? focusNode;
  
  /// Callback when user submits the field (e.g., presses Enter)
  final ValueChanged<String>? onFieldSubmitted;
  
  /// Validation function for the email
  final FormFieldValidator<String>? validator;
  
  /// Whether the current email value is valid (shows check icon)
  final bool isValid;
  
  /// Whether the field is enabled for input
  final bool enabled;
  
  /// Whether this field should autofocus on mount
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Champ email',
      hint: 'Entrez votre adresse email professionnelle',
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: const [AutofillHints.email],
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
        ],
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'exemple@pharmacie.com',
          prefixIcon: Semantics(
            label: 'Icône email',
            excludeSemantics: true,
            child: const Icon(Icons.email_outlined, color: _kPrimaryColor),
          ),
          suffixIcon: isValid
              ? Semantics(
                  label: 'Email valide',
                  excludeSemantics: true,
                  child: const Icon(
                    Icons.check_circle,
                    color: _kPrimaryColor,
                    size: 22,
                    semanticLabel: 'Email validé',
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: buildInputBorder(),
          enabledBorder: buildInputBorder(color: Colors.grey.shade200),
          focusedBorder: buildInputBorder(color: _kPrimaryColor, width: 2),
          errorBorder: buildInputBorder(color: Colors.red.shade400),
          focusedErrorBorder: buildInputBorder(color: Colors.red.shade400, width: 2),
          disabledBorder: buildInputBorder(color: Colors.grey.shade300),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHARMACY PASSWORD FIELD
// ══════════════════════════════════════════════════════════════════════════════

/// A reusable, accessible password field with strength indicator.
/// 
/// Features:
/// - Password visibility toggle with accessibility labels
/// - Real-time password strength indicator
/// - Color-coded borders based on strength
/// - Consistent styling with DR-PHARMA design system
/// 
/// Example usage:
/// ```dart
/// PharmacyPasswordField(
///   controller: _passwordController,
///   focusNode: _passwordFocus,
///   onFieldSubmitted: (_) => _handleLogin(),
///   validator: (value) => value?.isEmpty == true ? 'Required' : null,
///   showStrengthIndicator: true,
/// )
/// ```
class PharmacyPasswordField extends StatefulWidget {
  const PharmacyPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
    this.showStrengthIndicator = true,
    this.minLength = 6,
    this.labelText = 'Mot de passe',
    this.hintText = '••••••••',
  });

  /// Controller for the password text field
  final TextEditingController controller;
  
  /// Focus node for managing focus state
  final FocusNode? focusNode;
  
  /// Callback when user submits the field
  final ValueChanged<String>? onFieldSubmitted;
  
  /// Validation function for the password
  final FormFieldValidator<String>? validator;
  
  /// Whether the field is enabled for input
  final bool enabled;
  
  /// Whether to show the password strength indicator
  final bool showStrengthIndicator;
  
  /// Minimum password length for strength calculation
  final int minLength;
  
  /// Custom label text
  final String labelText;
  
  /// Custom hint text
  final String hintText;

  @override
  State<PharmacyPasswordField> createState() => _PharmacyPasswordFieldState();
}

class _PharmacyPasswordFieldState extends State<PharmacyPasswordField> {
  bool _obscurePassword = true;
  PasswordStrength _strength = PasswordStrength.empty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateStrength);
    _updateStrength();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateStrength);
    super.dispose();
  }

  void _updateStrength() {
    final newStrength = PasswordStrength.calculate(
      widget.controller.text,
      minLength: widget.minLength,
    );
    if (_strength != newStrength) {
      setState(() => _strength = newStrength);
    }
  }

  void _toggleVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = widget.controller.text.isNotEmpty;
    final strengthColor = _strength.borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Champ mot de passe',
          hint: 'Entrez votre mot de passe sécurisé',
          textField: true,
          obscured: _obscurePassword,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            enabled: widget.enabled,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: widget.onFieldSubmitted,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: Semantics(
                label: 'Icône mot de passe',
                excludeSemantics: true,
                child: Icon(
                  Icons.lock_outlined,
                  color: hasInput ? strengthColor : _kPrimaryColor,
                  semanticLabel: 'Mot de passe',
                ),
              ),
              suffixIcon: Semantics(
                label: _obscurePassword 
                    ? 'Afficher le mot de passe' 
                    : 'Masquer le mot de passe',
                button: true,
                child: IconButton(
                  icon: Icon(
                    _obscurePassword 
                        ? Icons.visibility_off_outlined 
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                    semanticLabel: _obscurePassword 
                        ? 'Mot de passe masqué, appuyez pour afficher'
                        : 'Mot de passe visible, appuyez pour masquer',
                  ),
                  tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  onPressed: _toggleVisibility,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: buildInputBorder(),
              enabledBorder: buildInputBorder(
                color: hasInput ? strengthColor : Colors.grey.shade200,
                width: hasInput ? 1.5 : 1,
              ),
              focusedBorder: buildInputBorder(
                color: hasInput ? strengthColor : _kPrimaryColor,
                width: 2,
              ),
              errorBorder: buildInputBorder(color: Colors.red.shade400),
              focusedErrorBorder: buildInputBorder(color: Colors.red.shade400, width: 2),
              disabledBorder: buildInputBorder(color: Colors.grey.shade300),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            validator: widget.validator,
          ),
        ),
        // Password strength indicator
        if (widget.showStrengthIndicator && hasInput) ...[
          const SizedBox(height: 10),
          _PasswordStrengthIndicator(
            strength: _strength,
            minLength: widget.minLength,
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PASSWORD STRENGTH INDICATOR
// ══════════════════════════════════════════════════════════════════════════════

/// Visual indicator for password strength with progress bar and label.
class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({
    required this.strength,
    required this.minLength,
  });

  final PasswordStrength strength;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Indicateur de force du mot de passe: ${strength.label}',
      value: '${(strength.progress * 100).round()}%',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength.progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            // Label with icon
            Row(
              children: [
                if (strength.icon != null) ...[
                  Icon(
                    strength.icon,
                    size: 14,
                    color: strength.color,
                    semanticLabel: strength.label,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  strength.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: strength.color,
                  ),
                ),
                const Spacer(),
                if (strength == PasswordStrength.tooShort)
                  Text(
                    'Min. $minLength caractères',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
