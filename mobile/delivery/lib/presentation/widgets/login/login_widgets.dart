import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_provider.dart';
import 'login_colors.dart';

/// Champ de formulaire personnalisé pour l'écran de connexion.
class LoginFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? error;
  final bool isPassword;
  final bool obscurePassword;
  final bool autofocus;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTogglePassword;
  final FormFieldValidator<String>? validator;
  final String? requiredFieldMessage;

  const LoginFormField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.error,
    this.isPassword = false,
    this.obscurePassword = true,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTogglePassword,
    this.validator,
    this.requiredFieldMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: hasError ? AppColors.error : LoginColors.labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          obscureText: isPassword && obscurePassword,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: LoginColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: LoginColors.iconColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                icon,
                size: 20,
                color: hasError ? AppColors.error : LoginColors.iconColor,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: LoginColors.iconColor,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: hasError
                ? AppColors.error.withValues(alpha: 0.04)
                : LoginColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: LoginColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withValues(alpha: 0.5)
                    : LoginColors.fieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : LoginColors.primary,
                width: 1.5,
              ),
            ),
          ),
          validator:
              validator ??
              (v) {
                if (v == null || v.isEmpty) {
                  return requiredFieldMessage ?? 'Ce champ est requis';
                }
                return null;
              },
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
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

/// Contrôle segmenté pour basculer entre Email et OTP.
class LoginSegmentedControl extends StatelessWidget {
  final bool isOtpMode;
  final VoidCallback onEmailTap;
  final VoidCallback onOtpTap;

  const LoginSegmentedControl({
    super.key,
    required this.isOtpMode,
    required this.onEmailTap,
    required this.onOtpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LoginColors.segmentBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: 'Email',
            icon: Icons.email_outlined,
            isActive: !isOtpMode,
            onTap: onEmailTap,
          ),
          _SegmentTab(
            label: 'Code OTP',
            icon: Icons.sms_outlined,
            isActive: isOtpMode,
            onTap: onOtpTap,
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(
                    color: LoginColors.fieldBorder.withValues(alpha: 0.6),
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? LoginColors.primary : LoginColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? LoginColors.primary : LoginColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton principal de connexion.
class LoginCtaButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const LoginCtaButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LoginColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bouton de connexion biométrique.
class LoginBiometricButton extends StatelessWidget {
  final String label;
  final String orLabel;
  final VoidCallback onPressed;

  const LoginBiometricButton({
    super.key,
    required this.label,
    required this.orLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: LoginColors.fieldBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                orLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: LoginColors.textMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: LoginColors.fieldBorder)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.fingerprint_rounded, size: 22),
            label: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: LoginColors.primary,
              side: BorderSide(
                color: LoginColors.primary.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bannière d'erreur pour l'écran de connexion.
class LoginErrorBanner extends StatelessWidget {
  final String message;

  const LoginErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isConnection = message.toLowerCase().contains('connexion');
    final color = isConnection ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isConnection ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
