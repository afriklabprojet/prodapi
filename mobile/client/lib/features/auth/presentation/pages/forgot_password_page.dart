import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../config/providers.dart';

// Provider IDs pour cette page
const _forgotPwdLoadingId = 'forgot_pwd_loading';
const _errorFormId = 'forgot_pwd_error';

enum _ResetStep { email, otp, newPassword, success }

/// Page de récupération de mot de passe — Flux complet en 3 étapes
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  _ResetStep _currentStep = _ResetStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _goToStep(_ResetStep step) {
    ref.read(formFieldsProvider(_errorFormId).notifier).clearAll();
    _animationController.reset();
    setState(() => _currentStep = step);
    _animationController.forward();
  }

  // ─── Step 1: Envoyer l'email ───
  Future<void> _handleSendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(loadingProvider(_forgotPwdLoadingId).notifier).startLoading();
    ref.read(formFieldsProvider(_errorFormId).notifier).clearAll();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
      result.fold(
        (failure) {
          ref.read(formFieldsProvider(_errorFormId).notifier).setError(
            'general',
            _getReadableErrorMessage(failure.message),
          );
        },
        (_) => _goToStep(_ResetStep.otp),
      );
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
        ref.read(formFieldsProvider(_errorFormId).notifier).setError(
          'general',
          'Une erreur est survenue. Veuillez réessayer.',
        );
      }
    }
  }

  // ─── Step 2: Vérifier l'OTP ───
  Future<void> _handleVerifyOtp() async {
    final otp = _otpCode;
    if (otp.length != 4) {
      ref.read(formFieldsProvider(_errorFormId).notifier).setError(
        'general',
        'Veuillez saisir le code à 4 chiffres.',
      );
      return;
    }

    ref.read(loadingProvider(_forgotPwdLoadingId).notifier).startLoading();
    ref.read(formFieldsProvider(_errorFormId).notifier).clearAll();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.verifyResetOtp(
        email: _emailController.text.trim(),
        otp: otp,
      );

      if (!mounted) return;
      ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
      result.fold(
        (failure) {
          ref.read(formFieldsProvider(_errorFormId).notifier).setError(
            'general',
            failure.message.contains('invalide')
                ? 'Code invalide. Vérifiez et réessayez.'
                : _getReadableErrorMessage(failure.message),
          );
        },
        (_) => _goToStep(_ResetStep.newPassword),
      );
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
        ref.read(formFieldsProvider(_errorFormId).notifier).setError(
          'general',
          'Une erreur est survenue. Veuillez réessayer.',
        );
      }
    }
  }

  // ─── Step 3: Réinitialiser le mot de passe ───
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(loadingProvider(_forgotPwdLoadingId).notifier).startLoading();
    ref.read(formFieldsProvider(_errorFormId).notifier).clearAll();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpCode,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;
      ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
      result.fold(
        (failure) {
          ref.read(formFieldsProvider(_errorFormId).notifier).setError(
            'general',
            _getReadableErrorMessage(failure.message),
          );
        },
        (_) => _goToStep(_ResetStep.success),
      );
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
        ref.read(formFieldsProvider(_errorFormId).notifier).setError(
          'general',
          'Une erreur est survenue. Veuillez réessayer.',
        );
      }
    }
  }

  // ─── Renvoyer le code OTP ───
  Future<void> _handleResendOtp() async {
    ref.read(loadingProvider(_forgotPwdLoadingId).notifier).startLoading();
    ref.read(formFieldsProvider(_errorFormId).notifier).clearAll();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.forgotPassword(email: _emailController.text.trim());
      if (mounted) {
        ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nouveau code envoyé !'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear OTP fields
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider(_forgotPwdLoadingId).notifier).stopLoading();
      }
    }
  }

  String _getReadableErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
    final errorLower = error.toLowerCase();
    if (errorLower.contains('not found') ||
        errorLower.contains('introuvable') ||
        errorLower.contains('no user')) {
      return 'Aucun compte n\'existe avec cet email.';
    }
    if (errorLower.contains('network') ||
        errorLower.contains('connexion') ||
        errorLower.contains('internet') ||
        errorLower.contains('timeout')) {
      return 'Problème de connexion internet.\nVérifiez votre connexion et réessayez.';
    }
    if (errorLower.contains('too many') ||
        errorLower.contains('rate limit') ||
        errorLower.contains('throttle')) {
      return 'Trop de tentatives.\nVeuillez patienter quelques minutes.';
    }
    if (errorLower.contains('invalide') || errorLower.contains('invalid')) {
      return 'Code invalide ou expiré.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(loadingProvider(_forgotPwdLoadingId)).isLoading;
    final errorMessage = ref.watch(formFieldsProvider(_errorFormId))['general'];

    return PopScope(
      canPop: _currentStep == _ResetStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Go back one step
          if (_currentStep == _ResetStep.otp) {
            _goToStep(_ResetStep.email);
          } else if (_currentStep == _ResetStep.newPassword) {
            _goToStep(_ResetStep.otp);
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
        body: Stack(
          children: [
            // Background
            Positioned(
              top: 0, left: 0, right: 0,
              height: size.height * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50, right: -50,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50, left: -30,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.12),
                    // Header
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _currentStep == _ResetStep.success
                                    ? Icons.check_circle_outline_rounded
                                    : _currentStep == _ResetStep.otp
                                        ? Icons.pin_outlined
                                        : _currentStep == _ResetStep.newPassword
                                            ? Icons.vpn_key_rounded
                                            : Icons.lock_reset_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _currentStep == _ResetStep.email
                                  ? 'Mot de passe oublié ?'
                                  : _currentStep == _ResetStep.otp
                                      ? 'Vérification'
                                      : _currentStep == _ResetStep.newPassword
                                          ? 'Nouveau mot de passe'
                                          : 'Succès !',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentStep == _ResetStep.email
                                  ? 'Ne vous inquiétez pas, ça arrive aux meilleurs.'
                                  : _currentStep == _ResetStep.otp
                                      ? 'Entrez le code reçu par email'
                                      : _currentStep == _ResetStep.newPassword
                                          ? 'Choisissez un mot de passe sécurisé'
                                          : 'Votre mot de passe a été réinitialisé',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF252540) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _buildStepContent(isDark, isLoading, errorMessage),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: IconButton(
                onPressed: () {
                  if (_currentStep == _ResetStep.email || _currentStep == _ResetStep.success) {
                    context.go(AppRoutes.login);
                  } else if (_currentStep == _ResetStep.otp) {
                    _goToStep(_ResetStep.email);
                  } else if (_currentStep == _ResetStep.newPassword) {
                    _goToStep(_ResetStep.otp);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),

            // Step indicator
            if (_currentStep != _ResetStep.success)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Étape ${_currentStep == _ResetStep.email ? '1' : _currentStep == _ResetStep.otp ? '2' : '3'}/3',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark, bool isLoading, String? errorMessage) {
    switch (_currentStep) {
      case _ResetStep.email:
        return _buildEmailStep(isDark, isLoading, errorMessage);
      case _ResetStep.otp:
        return _buildOtpStep(isDark, isLoading, errorMessage);
      case _ResetStep.newPassword:
        return _buildNewPasswordStep(isDark, isLoading, errorMessage);
      case _ResetStep.success:
        return _buildSuccessStep(isDark);
    }
  }

  // ─── STEP 1: Email ───
  Widget _buildEmailStep(bool isDark, bool isLoading, String? errorMessage) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Réinitialisation',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre email pour recevoir un code de vérification.',
            style: TextStyle(
              fontSize: 14, height: 1.5,
              color: isDark ? Colors.white60 : const Color(0xFF6B7C8E),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'exemple@email.com',
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email requis';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(errorMessage),
          ],
          const SizedBox(height: 32),
          _buildActionButton(
            label: 'Envoyer le code',
            icon: Icons.send_rounded,
            isLoading: isLoading,
            onTap: _handleSendEmail,
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: OTP ───
  Widget _buildOtpStep(bool isDark, bool isLoading, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code de vérification',
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A2B3C),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14, height: 1.5,
              color: isDark ? Colors.white60 : const Color(0xFF6B7C8E),
            ),
            children: [
              const TextSpan(text: 'Entrez le code à 4 chiffres envoyé à\n'),
              TextSpan(
                text: _emailController.text.trim(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 60,
              height: 64,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A2B3C),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE8ECF0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  // Auto submit when all 4 digits entered
                  if (_otpCode.length == 4) {
                    _handleVerifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(errorMessage),
        ],
        const SizedBox(height: 32),
        _buildActionButton(
          label: 'Vérifier le code',
          icon: Icons.verified_rounded,
          isLoading: isLoading,
          onTap: _handleVerifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _handleResendOtp,
            child: Text(
              'Renvoyer le code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF6B7C8E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: New Password ───
  Widget _buildNewPasswordStep(bool isDark, bool isLoading, String? errorMessage) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un nouveau mot de passe',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre mot de passe doit comporter au moins 8 caractères.',
            style: TextStyle(
              fontSize: 14, height: 1.5,
              color: isDark ? Colors.white60 : const Color(0xFF6B7C8E),
            ),
          ),
          const SizedBox(height: 32),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Nouveau mot de passe',
            hint: '••••••••',
            isDark: isDark,
            obscure: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Mot de passe requis';
              if (value.length < 8) return 'Minimum 8 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            isDark: isDark,
            obscure: _obscureConfirmPassword,
            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirmation requise';
              if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(errorMessage),
          ],
          const SizedBox(height: 32),
          _buildActionButton(
            label: 'Réinitialiser',
            icon: Icons.lock_reset_rounded,
            isLoading: isLoading,
            onTap: _handleResetPassword,
          ),
        ],
      ),
    );
  }

  // ─── STEP 4: Success ───
  Widget _buildSuccessStep(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Mot de passe réinitialisé !',
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A2B3C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15, height: 1.5,
            color: isDark ? Colors.white60 : const Color(0xFF6B7C8E),
          ),
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          label: 'Se connecter',
          icon: Icons.login_rounded,
          isLoading: false,
          onTap: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }

  // ─── Shared Widgets ───
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: Colors.white, letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF5A6B7D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A2B3C),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : const Color(0xFFAEB9C5),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 22,
                color: isDark ? Colors.white54 : const Color(0xFF8A99A8)),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE8ECF0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF5A6B7D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A2B3C),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : const Color(0xFFAEB9C5),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.lock_outline, size: 22,
                color: isDark ? Colors.white54 : const Color(0xFF8A99A8)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : const Color(0xFF8A99A8),
              ),
              onPressed: toggleObscure,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE8ECF0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
