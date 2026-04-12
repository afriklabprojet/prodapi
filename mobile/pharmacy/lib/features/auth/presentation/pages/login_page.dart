import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';
import '../providers/login_form_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/biometric_login_button.dart';
import '../../../../core/presentation/widgets/indicators.dart';
import '../widgets/login_form_widgets.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE (Refactored)
// ══════════════════════════════════════════════════════════════════════════════

/// Login page for DR-PHARMA Pharmacy application.
///
/// Refactorisé pour une meilleure maintenabilité :
/// - Logique métier dans [LoginFormNotifier]
/// - Widgets extraits dans [login_form_widgets.dart]
/// - Page réduite à ~250 lignes au lieu de ~950
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════
  static const _primaryColor = AppColors.primary;
  static const _primaryDark = AppColors.primaryDark;
  static const _savedEmailKey = 'pharmacy_saved_email';

  // ══════════════════════════════════════════════════════════════════════════
  // CONTROLLERS & FOCUS NODES
  // ══════════════════════════════════════════════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ══════════════════════════════════════════════════════════════════════════
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  // ══════════════════════════════════════════════════════════════════════════
  // LOCAL STATE (minimal - most state is in provider)
  // ══════════════════════════════════════════════════════════════════════════
  bool _isShowingError = false;
  bool _disposed = false;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupControllerSync();
  }

  @override
  void dispose() {
    _disposed = true;
    _animController.dispose();
    _passwordFocus.dispose();
    _emailFocus.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && mounted) {
        _animController.forward();
      }
    });
  }

  /// Synchronise les controllers avec le provider au chargement.
  void _setupControllerSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_disposed || !mounted) return;

      // Attendre que le provider charge les credentials sauvegardés
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed || !mounted) return;

      final formState = ref.read(loginFormProvider);
      if (formState.hasPrefilledEmail && formState.email.isNotEmpty) {
        _emailController.text = formState.email;
        _passwordFocus.requestFocus();
      } else {
        _emailFocus.requestFocus();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH STATE HANDLING
  // ══════════════════════════════════════════════════════════════════════════

  void _onAuthStateChanged(AuthState? prev, AuthState next) {
    if (_disposed || !mounted) return;

    final notifier = ref.read(loginFormProvider.notifier);

    if (next.status != AuthStatus.loading) {
      notifier.endSubmission();
    }

    switch (next.status) {
      case AuthStatus.error:
        if (next.errorMessage != null || next.originalError != null) {
          _handleError(next.errorMessage, originalError: next.originalError);
        }
      case AuthStatus.authenticated:
        _handleAuthenticated(next);
      case AuthStatus.loading:
        notifier.showLoading();
      case AuthStatus.initial:
      case AuthStatus.unauthenticated:
      case AuthStatus.registered:
        break;
    }
  }

  void _handleError(String? message, {Object? originalError}) {
    if (_disposed || !mounted || _isShowingError) return;

    _isShowingError = true;

    final displayMessage = (message != null && message.isNotEmpty)
        ? message
        : (originalError != null
              ? SnackBarHelper.parseNetworkError(originalError)
              : 'Une erreur est survenue');

    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _showErrorSnackBar(displayMessage);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && mounted) {
          _showErrorSnackBar(displayMessage);
        } else {
          _isShowingError = false;
        }
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!_disposed && mounted) {
      SnackBarHelper.showError(context, message);
      _isShowingError = false;

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_disposed) {
          ref.read(authProvider.notifier).clearError();
        }
      });
    }
  }

  void _handleAuthenticated(AuthState state) {
    final formState = ref.read(loginFormProvider);
    if (formState.isNavigating || _disposed || !mounted) return;

    ref.read(loginFormProvider.notifier).startNavigation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_disposed || !mounted) return;

      final userName = state.user?.name ?? state.user?.email ?? '';
      SnackBarHelper.showSuccess(context, 'Bienvenue $userName !');

      await Future.delayed(const Duration(milliseconds: 300));

      if (!_disposed && mounted) {
        context.go('/dashboard');
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  void _handleLogin() {
    final formState = ref.read(loginFormProvider);
    if (formState.isLoginDisabled) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(loginFormProvider.notifier);
    notifier.startSubmission();
    unawaited(notifier.saveCredentials());

    ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  Future<void> _handleBiometricLogin() async {
    final formState = ref.read(loginFormProvider);
    if (formState.isBiometricAuthenticating) return;

    final notifier = ref.read(loginFormProvider.notifier);
    notifier.startBiometricAuth();

    try {
      final securityService = ref.read(securityServiceProvider);
      final result = await securityService.authenticateWithBiometric(
        reason: 'Connectez-vous à DR-PHARMA',
      );

      if (!_disposed && mounted) {
        if (result.success) {
          final prefs = await SharedPreferences.getInstance();
          final savedEmail = prefs.getString(_savedEmailKey);

          if (savedEmail != null && savedEmail.isNotEmpty) {
            notifier.showLoading();
            ref.read(authProvider.notifier).loginWithBiometric(savedEmail);
          } else {
            SnackBarHelper.showWarning(
              context,
              'Aucun compte sauvegardé. Connectez-vous d\'abord avec email/mot de passe.',
            );
          }
        } else if (result.errorCode != 'userCanceled' &&
            result.errorCode != 'systemCanceled') {
          SnackBarHelper.showError(context, result.message);
        }
      }
    } finally {
      if (!_disposed && mounted) {
        notifier.endBiometricAuth();
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    final result = await context.push<bool>(
      '/forgot-password',
      extra: email.isNotEmpty ? {'email': email} : null,
    );

    if (!context.mounted) return;

    if (result == true && mounted && !_disposed) {
      SnackBarHelper.showSuccess(
        context,
        'Un email de réinitialisation a été envoyé. Vérifiez votre boîte de réception.',
      );
    }
  }

  void _smoothTransitionToPassword() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed && mounted) {
        _passwordFocus.requestFocus();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ══════════════════════════════════════════════════════════════════════════

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    return ref
        .read(loginFormProvider.notifier)
        .validateEmail(
          value,
          emptyMessage: l10n.enterEmail,
          invalidMessage: l10n.invalidEmailFormat,
        );
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    return ref
        .read(loginFormProvider.notifier)
        .validatePassword(
          value,
          emptyMessage: l10n.enterPassword,
          minLengthMessage: l10n.passwordMinLength,
        );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, _onAuthStateChanged);

    final formState = ref.watch(loginFormProvider);
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.height < 760 || screenSize.width < 380;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: formState.showLoadingOverlay,
        message: 'Connexion en cours...',
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _primaryDark, Colors.teal.shade900],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isCompact ? 20 : 32,
                ),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimated(
                        child: AuthHeader(logoSize: isCompact ? 64 : 80),
                      ),
                      SizedBox(height: isCompact ? 24 : 36),
                      _buildAnimated(
                        withSlide: true,
                        child: _buildLoginCard(isCompact: isCompact),
                      ),
                      SizedBox(height: isCompact ? 24 : 32),
                      _buildCopyright(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimated({required Widget child, bool withSlide = false}) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final slideOffset = withSlide ? _slideAnim.value : Offset.zero;

        return Transform.translate(
          offset: Offset(
            slideOffset.dx * MediaQuery.of(context).size.width,
            slideOffset.dy * MediaQuery.of(context).size.height * 0.3,
          ),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: withSlide ? 1.0 : _scaleAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildLoginCard({bool isCompact = false}) {
    final formState = ref.watch(loginFormProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.all(isCompact ? 22 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).connectionTitle,
              style: TextStyle(
                fontSize: isCompact ? 24 : 26,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous à votre espace pharmacie',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isCompact ? 24 : 28),

            // Email field
            LoginEmailField(
              controller: _emailController,
              focusNode: _emailFocus,
              onFieldSubmitted: _smoothTransitionToPassword,
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),

            // Password field
            LoginPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              onFieldSubmitted: _handleLogin,
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),

            // Remember me + Forgot password
            LoginRememberMeRow(onForgotPassword: _handleForgotPassword),
            const SizedBox(height: 28),

            // Login button
            LoginSubmitButton(onPressed: _handleLogin),

            // Biometric button
            if (formState.canUseBiometric) ...[
              const SizedBox(height: 16),
              BiometricLoginButton(
                biometricLabel: formState.biometricLabel,
                isAuthenticating: formState.isBiometricAuthenticating,
                isDisabled: formState.isLoginDisabled,
                onPressed: _handleBiometricLogin,
              ),
            ],
            const SizedBox(height: 20),

            // Register link
            LoginRegisterLink(onPressed: () => context.push('/register')),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Text(
        '© ${DateTime.now().year} DR-PHARMA',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
    );
  }
}
