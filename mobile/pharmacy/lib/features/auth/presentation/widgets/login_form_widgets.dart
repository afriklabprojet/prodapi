import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/login_form_provider.dart';

/// Champ email du formulaire de connexion.
///
/// Widget extrait pour réduire la taille de login_page.dart
/// et améliorer la lisibilité.
class LoginEmailField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final String? Function(String?) validator;

  const LoginEmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
    required this.validator,
  });

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmailValid = ref.watch(
      loginFormProvider.select((s) => s.isEmailValid),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.email],
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      onChanged: (value) {
        ref.read(loginFormProvider.notifier).updateEmail(value);
      },
      onFieldSubmitted: (_) => onFieldSubmitted(),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintText: 'exemple@pharmacie.com',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: _primaryColor,
          semanticLabel: 'Icône email',
        ),
        suffixIcon: isEmailValid
            ? const Icon(
                Icons.check_circle,
                color: _primaryColor,
                size: 22,
                semanticLabel: 'Email valide',
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      validator: validator,
    );
  }
}

/// Champ mot de passe du formulaire de connexion.
///
/// Inclut l'indicateur de force du mot de passe.
class LoginPasswordField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final String? Function(String?) validator;

  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onFieldSubmitted,
    required this.validator,
  });

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);

    final hasInput = controller.text.isNotEmpty;
    final strengthColor = formState.passwordStrength.borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: formState.obscurePassword,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          autofillHints: const [AutofillHints.password],
          onChanged: (value) => notifier.updatePassword(value),
          onFieldSubmitted: (_) => onFieldSubmitted(),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            labelText: l10n.password,
            labelStyle: TextStyle(color: Colors.grey.shade700),
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: hasInput ? strengthColor : _primaryColor,
              semanticLabel: 'Icône mot de passe',
            ),
            suffixIcon: Semantics(
              label: formState.obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              button: true,
              child: IconButton(
                icon: Icon(
                  formState.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: notifier.togglePasswordVisibility,
                tooltip: formState.obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasInput ? strengthColor : Colors.grey.shade200,
                width: hasInput ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasInput ? strengthColor : _primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// Ligne "Se souvenir de moi" + "Mot de passe oublié".
class LoginRememberMeRow extends ConsumerWidget {
  final VoidCallback onForgotPassword;

  const LoginRememberMeRow({super.key, required this.onForgotPassword});

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rememberMe = ref.watch(loginFormProvider.select((s) => s.rememberMe));
    final notifier = ref.read(loginFormProvider.notifier);

    final rememberMeControl = Semantics(
      toggled: rememberMe,
      label: l10n.rememberMe,
      child: InkWell(
        onTap: notifier.toggleRememberMe,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (v) => notifier.setRememberMe(v ?? false),
                  activeColor: _primaryColor,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: rememberMe ? _primaryColor : Colors.grey.shade500,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.rememberMe,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final forgotPasswordButton = TextButton(
      onPressed: onForgotPassword,
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        l10n.forgotPassword,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 360;

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rememberMeControl,
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: forgotPasswordButton,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: rememberMeControl),
            forgotPasswordButton,
          ],
        );
      },
    );
  }
}

/// Bouton de connexion avec état de chargement.
class LoginSubmitButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const LoginSubmitButton({super.key, required this.onPressed});

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDisabled = ref.watch(
      loginFormProvider.select((s) => s.isLoginDisabled),
    );
    final isSubmitting = ref.watch(
      loginFormProvider.select((s) => s.isSubmitting),
    );

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
          elevation: isDisabled ? 0 : 3,
          shadowColor: _primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  key: const ValueKey('text'),
                  l10n.login,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Lien vers l'inscription.
class LoginRegisterLink extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginRegisterLink({super.key, required this.onPressed});

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).noAccountYetQuestion,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            AppLocalizations.of(context).createAccount,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
