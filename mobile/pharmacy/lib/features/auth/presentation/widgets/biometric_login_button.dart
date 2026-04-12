import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// A button for biometric authentication (Face ID / Touch ID).
/// Shows appropriate icon and label based on the biometric type available.
class BiometricLoginButton extends StatelessWidget {
  final String? biometricLabel;
  final bool isAuthenticating;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const BiometricLoginButton({
    super.key,
    this.biometricLabel,
    this.isAuthenticating = false,
    this.isDisabled = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveDisabled = isDisabled || isAuthenticating;
    final icon = biometricLabel == 'Face ID'
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;

    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: effectiveDisabled ? null : onPressed,
        icon: isAuthenticating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 24),
        label: Text(
          isAuthenticating
              ? l10n.verification
              : l10n.loginWithBiometric(biometricLabel ?? ''),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
