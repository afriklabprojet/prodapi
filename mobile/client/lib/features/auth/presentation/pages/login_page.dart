import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/providers.dart'; // Import pour notificationService + deepLinkService
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/validators/form_validators.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/biometric_provider.dart';

// Provider IDs pour cette page
const _obscurePasswordId = 'login_obscure_password';
const _useEmailId = 'login_use_email';

/// Écran de connexion premium pour DR-PHARMA
/// Design moderne, minimaliste et professionnel
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // UI state:
  // - obscurePassword -> toggleProvider(_obscurePasswordId)
  // - useEmail -> toggleProvider(_useEmailId)
  // - isRedirecting -> local state (toggleProvider defaults to true, causing loader to show on init)

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Local state for redirecting - not using toggleProvider to avoid default true issue
  bool _isRedirecting = false;

  // Erreurs de champs (pour afficher les erreurs serveur sous les champs)
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Check authorization on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated && mounted) {
        final user = authState.user;
        if (user != null && !user.isPhoneVerified) {
          // Rediriger vers OTP si téléphone non vérifié
          context.goToOtpVerification(user.phone);
        } else {
          // Rediriger vers Home si téléphone vérifié
          context.goToHome();
        }
      }

      // Initialiser les toggles de mot de passe à true (obscurcir par défaut)
      ref.read(toggleProvider(_obscurePasswordId).notifier).set(true);
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Consomme le deep link en attente (storé avant login)
  Future<String?> _consumePendingDeepLink() async {
    try {
      final pendingDeepLink = await ref.read(pendingDeepLinkProvider.future);
      if (pendingDeepLink != null) {
        AppLogger.info(
          '🔗 Consuming pending deep link: ${pendingDeepLink.path}',
        );
        return pendingDeepLink.path;
      }
    } catch (e) {
      AppLogger.warning('Error consuming pending deep link: $e');
    }
    return null;
  }

  void _handleLogin() {
    // Prevent double-tap / multiple submissions
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading || _isRedirecting) {
      return;
    }

    // Réinitialiser les erreurs
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Validation locale d'abord
    final useEmail = ref.read(toggleProvider(_useEmailId));
    final identifier = _phoneController.text.trim();
    final password = _passwordController.text;

    // Validation du champ email/téléphone
    if (identifier.isEmpty) {
      setState(() {
        _emailError = useEmail
            ? 'Veuillez entrer votre adresse email'
            : 'Veuillez entrer votre numéro de téléphone';
      });
      _phoneFocusNode.requestFocus();
      return;
    }

    // Validation du format email/téléphone
    if (useEmail) {
      final emailError = FormValidators.validateEmail(identifier);
      if (emailError != null) {
        setState(() => _emailError = emailError);
        _phoneFocusNode.requestFocus();
        return;
      }
    } else {
      final phoneError = FormValidators.validatePhone(identifier);
      if (phoneError != null) {
        setState(() => _emailError = phoneError);
        _phoneFocusNode.requestFocus();
        return;
      }
    }

    // Validation du mot de passe
    if (password.isEmpty) {
      setState(() => _passwordError = 'Veuillez entrer votre mot de passe');
      _passwordFocusNode.requestFocus();
      return;
    }

    if (password.length < 6) {
      setState(
        () => _passwordError =
            'Le mot de passe doit contenir au moins 6 caractères',
      );
      _passwordFocusNode.requestFocus();
      return;
    }

    // Si validation locale OK, envoyer au serveur
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(email: identifier, password: password);
    }
  }

  /// Connexion avec biométrie (empreinte digitale / Face ID)
  Future<void> _handleBiometricLogin() async {
    // Prevent double-tap
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading || _isRedirecting) {
      return;
    }

    // Réinitialiser les erreurs
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Effectuer la connexion biométrique
    final credentials = await ref
        .read(biometricProvider.notifier)
        .performBiometricLogin();

    if (credentials == null) {
      // L'utilisateur a annulé ou erreur
      final biometricState = ref.read(biometricProvider);
      if (biometricState.error != null) {
        setState(() => _generalError = biometricState.error);
      }
      return;
    }

    // Connexion avec les credentials récupérés
    ref
        .read(authProvider.notifier)
        .login(email: credentials.identifier, password: credentials.password);
  }

  /// Analyse l'erreur serveur et détermine quel champ est concerné
  void _handleServerError(String? error) {
    debugPrint('🔐 [LoginPage] _handleServerError called with: $error');

    if (error == null || error.isEmpty) {
      setState(
        () => _generalError = 'Une erreur est survenue. Veuillez réessayer.',
      );
      return;
    }

    final errorLower = error.toLowerCase();

    // Erreurs d'identifiants (email/téléphone incorrect)
    if (errorLower.contains('invalid') ||
        errorLower.contains('credentials') ||
        errorLower.contains('incorrect') ||
        errorLower.contains('identifiants') ||
        errorLower.contains('unauthorized') ||
        errorLower.contains('401')) {
      setState(() {
        _generalError = 'Email ou mot de passe incorrect';
      });
      return;
    }

    // Compte non trouvé
    if (errorLower.contains('not found') ||
        errorLower.contains('introuvable') ||
        errorLower.contains('n\'existe pas') ||
        errorLower.contains('no user')) {
      final useEmail = ref.read(toggleProvider(_useEmailId));
      setState(() {
        _emailError = useEmail
            ? 'Aucun compte associé à cet email'
            : 'Aucun compte associé à ce numéro';
      });
      _phoneFocusNode.requestFocus();
      return;
    }

    // Erreur de mot de passe spécifique
    if (errorLower.contains('password') ||
        errorLower.contains('mot de passe')) {
      setState(() => _passwordError = 'Mot de passe incorrect');
      _passwordFocusNode.requestFocus();
      return;
    }

    // Compte désactivé/suspendu
    if (errorLower.contains('disabled') ||
        errorLower.contains('suspended') ||
        errorLower.contains('blocked') ||
        errorLower.contains('désactivé') ||
        errorLower.contains('suspendu') ||
        errorLower.contains('bloqué')) {
      setState(
        () => _generalError =
            'Votre compte a été désactivé. Contactez le support.',
      );
      return;
    }

    // Erreurs réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connexion') ||
        errorLower.contains('internet') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket') ||
        errorLower.contains('connection')) {
      setState(
        () => _generalError =
            'Problème de connexion internet. Vérifiez votre connexion.',
      );
      return;
    }

    // Erreurs serveur
    if (errorLower.contains('server') ||
        errorLower.contains('500') ||
        errorLower.contains('503') ||
        errorLower.contains('serveur')) {
      setState(
        () => _generalError =
            'Service temporairement indisponible. Réessayez plus tard.',
      );
      return;
    }

    // Trop de tentatives
    if (errorLower.contains('too many') ||
        errorLower.contains('rate limit') ||
        errorLower.contains('throttle') ||
        errorLower.contains('tentatives')) {
      setState(
        () => _generalError = 'Trop de tentatives. Patientez quelques minutes.',
      );
      return;
    }

    // Erreur par défaut
    setState(
      () => _generalError =
          'Identifiants incorrects. Vérifiez votre email et mot de passe.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch UI state providers
    final obscurePassword = ref.watch(toggleProvider(_obscurePasswordId));
    final useEmail = ref.watch(toggleProvider(_useEmailId));
    // Use local state for isRedirecting instead of provider (to avoid default true issue)

    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) async {
      debugPrint('🔐 [LoginPage] Auth state changed: ${next.status}');
      debugPrint('🔐 [LoginPage] Error message: ${next.errorMessage}');

      if (next.status == AuthStatus.authenticated && !_isRedirecting) {
        // Prevent multiple redirections and keep loader visible
        if (mounted) {
          setState(() => _isRedirecting = true);
        }

        // Small delay to ensure UI shows loading state
        await Future.delayed(const Duration(milliseconds: 50));

        try {
          // Initialiser les notifications après authentification
          await ref.read(notificationServiceProvider).initNotifications();
        } catch (e) {
          // Continue even if notification init fails
          AppLogger.warning('Notification init error: $e');
        }

        if (mounted) {
          // Vérifier si le téléphone est vérifié
          final user = next.user;
          if (user != null && !user.isPhoneVerified) {
            // Rediriger vers OTP si téléphone non vérifié
            // ignore: use_build_context_synchronously
            context.goToOtpVerification(user.phone);
          } else {
            // Vérifier s'il y a un deep link en attente
            final pendingPath = await _consumePendingDeepLink();
            if (pendingPath != null && mounted) {
              // ignore: use_build_context_synchronously
              context.go(pendingPath);
            } else if (mounted) {
              // Rediriger vers Home par défaut
              // ignore: use_build_context_synchronously
              context.goToHome();
            }
          }
        }
      } else if (next.status == AuthStatus.error) {
        // Reset redirecting state on error
        if (_isRedirecting && mounted) {
          setState(() => _isRedirecting = false);
        }
        if (mounted) {
          // Afficher l'erreur sous les champs au lieu d'un snackbar
          _handleServerError(next.errorMessage);
        }
      }
    });

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // Background élégant avec logo intégré
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Motif géométrique élégant - cercle principal
                    Positioned(
                      top: -80,
                      right: -60,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Cercle secondaire
                    Positioned(
                      top: 40,
                      left: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Ligne décorative subtile
                    Positioned(
                      bottom: 60,
                      right: 40,
                      child: Container(
                        width: 80,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Courbe élégante en bas du header
            Positioned(
              top: size.height * 0.32 - 40,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Titre dans le header vert
                  SizedBox(height: size.height * 0.08),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'DR-PHARMA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre santé, notre priorité',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Espace pour le logo ancré
                  SizedBox(height: size.height * 0.12),
                  Expanded(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141414)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.08,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Titre simple et élégant
                                      Text(
                                        'Connexion',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accédez à votre espace santé',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.grey[600]
                                              : AppColors.textHint,
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Toggle Phone/Email
                                      _buildToggleMethod(isDark, useEmail),
                                      const SizedBox(height: 20),

                                      // Phone/Email Field
                                      _buildPhoneField(isDark, useEmail),
                                      const SizedBox(height: 16),

                                      // Password Field
                                      _buildPasswordField(
                                        isDark,
                                        obscurePassword,
                                      ),

                                      // Erreur générale (identifiants incorrects)
                                      // Afficher l'erreur locale OU l'erreur du serveur
                                      Builder(
                                        builder: (context) {
                                          final errorToShow =
                                              _generalError ??
                                              (authState.status ==
                                                      AuthStatus.error
                                                  ? _parseErrorMessage(
                                                      authState.errorMessage,
                                                    )
                                                  : null);
                                          if (errorToShow != null) {
                                            return Column(
                                              children: [
                                                const SizedBox(height: 16),
                                                _buildGeneralErrorBannerWithMessage(
                                                  isDark,
                                                  errorToShow,
                                                ),
                                              ],
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),

                                      // Forgot Password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              context.goToForgotPassword(),
                                          child: Text(
                                            'Mot de passe oublié ?',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Login Button
                                      _buildLoginButton(
                                        authState,
                                        isDark,
                                        _isRedirecting,
                                      ),

                                      // Biometric Login Button (conditionnel)
                                      _buildBiometricButton(authState, isDark),

                                      const SizedBox(height: 16),

                                      // Register Link
                                      _buildRegisterLink(),

                                      const SizedBox(height: 12),

                                      // Security Badge compact
                                      _buildSecurityBadge(isDark),

                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Logo centré et ancré - RENDU EN DERNIER pour être au-dessus
            Positioned(
              top: size.height * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: 0.98 + (_pulseAnimation.value - 1) * 0.3,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo DR-PHARMA',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMethod(bool isDark, bool useEmail) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.primarySurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : AppColors.primary).withValues(
            alpha: 0.1,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Téléphone',
              icon: Icons.phone_android_rounded,
              isSelected: !useEmail,
              onTap: () =>
                  ref.read(toggleProvider(_useEmailId).notifier).set(false),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildToggleButton(
              label: 'Email',
              icon: Icons.email_outlined,
              isSelected: useEmail,
              onTap: () =>
                  ref.read(toggleProvider(_useEmailId).notifier).set(true),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? AppColors.primary : Colors.black)
                          .withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  size: 18,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white38 : AppColors.textHint),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white54 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDark = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: hasError
                  ? Colors.red.shade400
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? Colors.red.shade400
                  : (isDark ? Colors.grey[400] : AppColors.primary),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: hasError
                ? Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 1.0)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? BorderSide(color: Colors.red.shade400, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
          validator: validator,
        ),
        // Message d'erreur sous le champ
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneField(bool isDark, bool useEmail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          label: useEmail ? 'Adresse email' : 'Numéro de téléphone',
          icon: useEmail ? Icons.email_outlined : Icons.phone_android_rounded,
          isDark: isDark,
          keyboardType: useEmail
              ? TextInputType.emailAddress
              : TextInputType.phone,
          inputFormatters: useEmail
              ? null
              : [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          onChanged: (_) {
            // Effacer l'erreur quand l'utilisateur tape
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
            if (_generalError != null) {
              setState(() => _generalError = null);
            }
          },
          errorText: _emailError,
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDark, bool obscurePassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Mot de passe',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          onChanged: (_) {
            // Effacer l'erreur quand l'utilisateur tape
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
            if (_generalError != null) {
              setState(() => _generalError = null);
            }
          },
          suffixIcon: IconButton(
            tooltip: obscurePassword
                ? 'Afficher le mot de passe'
                : 'Masquer le mot de passe',
            onPressed: () =>
                ref.read(toggleProvider(_obscurePasswordId).notifier).toggle(),
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          errorText: _passwordError,
        ),
      ],
    );
  }

  /// Parse le message d'erreur serveur pour l'afficher de manière claire
  String _parseErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    final errorLower = error.toLowerCase();

    // Erreurs d'identifiants
    if (errorLower.contains('invalid') ||
        errorLower.contains('credentials') ||
        errorLower.contains('incorrect') ||
        errorLower.contains('identifiants') ||
        errorLower.contains('unauthorized') ||
        errorLower.contains('401')) {
      return 'Email ou mot de passe incorrect';
    }

    // Compte non trouvé
    if (errorLower.contains('not found') ||
        errorLower.contains('introuvable') ||
        errorLower.contains('n\'existe pas') ||
        errorLower.contains('no user')) {
      return 'Aucun compte associé à ces identifiants';
    }

    // Compte désactivé
    if (errorLower.contains('disabled') ||
        errorLower.contains('suspended') ||
        errorLower.contains('blocked') ||
        errorLower.contains('désactivé')) {
      return 'Votre compte a été désactivé. Contactez le support.';
    }

    // Erreurs réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connexion') ||
        errorLower.contains('internet') ||
        errorLower.contains('timeout') ||
        errorLower.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    }

    // Erreurs serveur
    if (errorLower.contains('server') ||
        errorLower.contains('500') ||
        errorLower.contains('503')) {
      return 'Service temporairement indisponible. Réessayez plus tard.';
    }

    // Retourner le message original s'il est déjà en français et lisible
    if (error.length < 100 && !error.contains('Exception')) {
      return error;
    }

    return 'Identifiants incorrects. Vérifiez votre email et mot de passe.';
  }

  /// Widget pour afficher une erreur générale avec un message personnalisé
  Widget _buildGeneralErrorBannerWithMessage(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Fermer le message d\'erreur',
            child: GestureDetector(
              onTap: () {
                setState(() => _generalError = null);
                // Clear error state in auth notifier
                ref.read(authProvider.notifier).clearError();
              },
              child: Icon(Icons.close, size: 18, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(
    AuthState authState,
    bool isDark,
    bool isRedirecting,
  ) {
    // Show loader during login AND during post-login operations (redirecting)
    final isLoading = authState.status == AuthStatus.loading || isRedirecting;
    final loadingText = isRedirecting ? 'Connexion...' : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isLoading ? 0.98 : 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                  const Color(0xFF134E13),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _handleLogin,
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Container(
                  alignment: Alignment.center,
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            if (loadingText != null) ...[
                              const SizedBox(width: 14),
                              Text(
                                loadingText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
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

  /// Bouton de connexion biométrique (empreinte / Face ID)
  Widget _buildBiometricButton(AuthState authState, bool isDark) {
    // Vérifier si la biométrie est disponible et configurée
    final biometricState = ref.watch(biometricProvider);

    // Ne pas afficher si pas disponible ou pas configuré
    if (!biometricState.canUseBiometricLogin) {
      return const SizedBox.shrink();
    }

    final isLoading =
        authState.status == AuthStatus.loading ||
        _isRedirecting ||
        biometricState.isLoading;
    final typeName = biometricState.biometricTypeName;
    final isFaceId = typeName.toLowerCase().contains('face');

    return Column(
      children: [
        const SizedBox(height: 16),

        // Séparateur "ou"
        Row(
          children: [
            Expanded(
              child: Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textHint,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bouton biométrique
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : _handleBiometricLogin,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.primarySurface.withValues(alpha: 0.3),
            ),
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                  )
                : Icon(
                    isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded,
                    size: 24,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
            label: Text(
              isLoading ? 'Vérification...' : 'Connexion avec $typeName',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : [
                  AppColors.primarySurface.withValues(alpha: 0.7),
                  AppColors.primarySurface.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : AppColors.primary).withValues(
            alpha: 0.1,
          ),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 16,
              color: isDark ? Colors.white70 : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connexion sécurisée',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Chiffrement SSL 256-bit',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nouveau sur DR-PHARMA ? ',
            style: TextStyle(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Semantics(
            button: true,
            label: 'Créer un compte',
            child: GestureDetector(
              onTap: () => context.goToRegister(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
