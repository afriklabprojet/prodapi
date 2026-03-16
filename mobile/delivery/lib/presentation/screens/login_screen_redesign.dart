import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/biometric_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'dashboard_screen.dart';
import 'register_screen_redesign.dart';

/// Écran de connexion redesigné avec animations modernes
/// Design: Glassmorphism + Animations fluides + UX améliorée
class LoginScreenRedesign extends ConsumerStatefulWidget {
  const LoginScreenRedesign({super.key});

  @override
  ConsumerState<LoginScreenRedesign> createState() => _LoginScreenRedesignState();
}

class _LoginScreenRedesignState extends ConsumerState<LoginScreenRedesign>
    with TickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // State
  String _appVersion = '1.0.0';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadVersion();
    _checkBiometric();
  }

  void _initAnimations() {
    // Wave animation pour le header
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Logo bounce animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    // Form slide-up animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });

    // Button pulse animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _checkBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final canCheck = await biometricService.canCheckBiometrics();
    final isEnabled = ref.read(biometricSettingsProvider);

    if (mounted) {
      setState(() {
        _biometricAvailable = canCheck;
        _biometricEnabled = isEnabled;
      });

      if (canCheck && isEnabled) {
        Future.delayed(const Duration(milliseconds: 800), _loginWithBiometric);
      }
    }
  }

  Future<void> _loginWithBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);

    try {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();

      final authenticated = await biometricService.authenticate(
        reason: 'Authentifiez-vous pour accéder à l\'application',
      );

      if (authenticated) {
        final authRepository = ref.read(authRepositoryProvider);
        final hasStoredCredentials = await authRepository.hasStoredCredentials();

        if (hasStoredCredentials) {
          await authRepository.loginWithStoredCredentials();
          if (mounted) {
            _navigateToDashboard();
          }
        } else {
          _showSnackBar('Veuillez d\'abord vous connecter avec vos identifiants',
              isWarning: true);
        }
      }
    } catch (e) {
      _showSnackBar('Erreur biométrique: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    _buttonController.repeat(reverse: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .login(_emailController.text.trim(), _passwordController.text);

      HapticFeedback.mediumImpact();
      if (mounted) _navigateToDashboard();
    } catch (e) {
      HapticFeedback.heavyImpact();
      _handleLoginError(e);
    } finally {
      if (mounted) {
        _buttonController.stop();
        _buttonController.reset();
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLoginError(dynamic e) {
    String errorMessage = e.toString()
        .replaceAll('Exception:', '')
        .replaceAll('Exception', '')
        .trim();
    
    final errorLower = errorMessage.toLowerCase();

    if (_isNetworkError(errorLower)) {
      setState(() => _generalError = 'Connexion impossible. Vérifiez votre connexion internet.');
    } else if (_isCredentialsError(errorLower)) {
      setState(() {
        _emailError = 'Identifiants incorrects';
        _passwordError = 'Vérifiez votre email et mot de passe';
      });
    } else if (_isAccountStatusError(errorLower)) {
      setState(() => _generalError = errorMessage);
    } else {
      setState(() => _generalError = _getReadableError(errorMessage));
    }
  }

  bool _isNetworkError(String error) =>
      error.contains('xmlhttprequest') ||
      error.contains('connection') ||
      error.contains('dioexception') ||
      error.contains('socketexception') ||
      error.contains('network') ||
      error.contains('timeout');

  bool _isCredentialsError(String error) =>
      error.contains('password') ||
      error.contains('credentials') ||
      error.contains('invalid') ||
      error.contains('unauthorized') ||
      error.contains('401');

  bool _isAccountStatusError(String error) =>
      error.contains('attente') ||
      error.contains('pending') ||
      error.contains('suspendu') ||
      error.contains('suspended') ||
      error.contains('kyc');

  String _getReadableError(String error) {
    if (error.length > 200) return 'Une erreur est survenue. Veuillez réessayer.';
    return error;
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const DashboardScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false, // Supprimer toute la pile de navigation
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : isWarning
                ? Colors.orange.shade700
                : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F9F7),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(size, isDark),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                child: Column(
                  children: [
                    // Header avec logo animé
                    _buildHeader(isDark),

                    // Formulaire avec glassmorphism
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlide.value),
                          child: Opacity(
                            opacity: _formFade.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildLoginForm(isDark),
                    ),

                    // Footer
                    _buildFooter(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size, bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _WaveBackgroundPainter(
            animation: _waveController.value,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    final r = context.r;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: r.dp(200)),
      child: Padding(
      padding: r.padH(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animé
          ScaleTransition(
            scale: _logoScale,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF54AB70).withValues(alpha: 0.2),
                    const Color(0xFF3D8C57).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF54AB70).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF54AB70).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(r.dp(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: r.dp(60),
                  height: r.dp(60),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(height: r.dp(24)),

          // App Name avec gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF3D8C57), Color(0xFF6EC889)],
            ).createShader(bounds),
            child: Text(
              'DR-PHARMA',
              style: TextStyle(
                fontSize: r.sp(32),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: r.dp(8)),

          // Subtitle avec icône
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF54AB70).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: Color(0xFF54AB70),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ESPACE LIVREUR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    final r = context.r;
    return Container(
      margin: r.padH(20),
      padding: r.pad(28),
      decoration: BoxDecoration(
        // Glassmorphism effect
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Connexion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.sp(26),
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour accéder à vos livraisons',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 28),

            // Error Banner
            if (_generalError != null) _buildErrorBanner(isDark),

            // Email/Phone Field
            _buildTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email ou Téléphone',
              hint: '+225 07 00 00 00 00',
              icon: Icons.person_outline_rounded,
              error: _emailError,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearError('email'),
            ),
            const SizedBox(height: 18),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              error: _passwordError,
              isDark: isDark,
              isPassword: true,
              obscurePassword: _obscurePassword,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              onChanged: (_) => _clearError('password'),
            ),
            const SizedBox(height: 28),

            // Login Button
            _buildLoginButton(isDark),

            // Biometric Option
            if (_biometricAvailable && _biometricEnabled && !_isLoading)
              _buildBiometricOption(isDark),

            const SizedBox(height: 24),

            // Register Link
            _buildRegisterLink(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    final isConnectionError = _generalError!.toLowerCase().contains('connexion');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnectionError
              ? [Colors.orange.shade400.withValues(alpha: 0.15), Colors.orange.shade600.withValues(alpha: 0.1)]
              : [Colors.red.shade400.withValues(alpha: 0.15), Colors.red.shade600.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnectionError
              ? Colors.orange.shade300.withValues(alpha: 0.5)
              : Colors.red.shade300.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnectionError
                  ? Colors.orange.shade100
                  : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnectionError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              color: isConnectionError ? Colors.orange.shade700 : Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _generalError!,
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : (isConnectionError ? Colors.orange.shade800 : Colors.red.shade800),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? error,
    bool isPassword = false,
    bool obscurePassword = true,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    const primaryColor = Color(0xFF54AB70);
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!hasError)
                BoxShadow(
                  color: primaryColor.withValues(alpha: focusNode.hasFocus ? 0.15 : 0),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: isPassword && obscurePassword,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: hasError
                    ? Colors.red.shade400
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: hasError ? Colors.red.shade400 : primaryColor,
                  size: 22,
                ),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        size: 22,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? (hasError
                      ? Colors.red.shade900.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05))
                  : (hasError ? Colors.red.shade50 : Colors.grey.shade50),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red.shade300
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade400 : primaryColor,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            },
          ),
        ),
        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _clearError(String field) {
    setState(() {
      if (field == 'email') _emailError = null;
      if (field == 'password') _passwordError = null;
    });
  }

  Widget _buildLoginButton(bool isDark) {
    final r = context.r;
    const primaryColor = Color(0xFF54AB70);

    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        final scale = 1.0 + (_buttonController.value * 0.02);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        height: r.dp(56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.dp(16)),
          gradient: const LinearGradient(
            colors: [Color(0xFF3D8C57), Color(0xFF54AB70)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _login,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'SE CONNECTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricOption(bool isDark) {
    final r = context.r;
    return Column(
      children: [
        SizedBox(height: r.dp(20)),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
          ],
        ),
        SizedBox(height: r.dp(20)),
        Container(
          height: r.dp(56),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.dp(16)),
            border: Border.all(
              color: const Color(0xFF54AB70).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loginWithBiometric,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF54AB70).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: Color(0xFF54AB70),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Connexion biométrique',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF3D8C57),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreenRedesign()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF54AB70).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Devenir livreur',
              style: TextStyle(
                color: isDark ? const Color(0xFF6EC889) : const Color(0xFF3D8C57),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    final r = context.r;
    return Padding(
      padding: r.padV(24),
      child: Column(
        children: [
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTrustBadge(Icons.security_rounded, 'Sécurisé', isDark),
              const SizedBox(width: 20),
              _buildTrustBadge(Icons.verified_user_outlined, 'Certifié', isDark),
              const SizedBox(width: 20),
              _buildTrustBadge(Icons.support_agent_rounded, 'Support 24/7', isDark),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Version $_appVersion',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Custom painter pour l'arrière-plan animé avec vagues
class _WaveBackgroundPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  _WaveBackgroundPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF1B3A4B),
                const Color(0xFF0D1B2A),
              ]
            : [
                const Color(0xFF54AB70).withValues(alpha: 0.15),
                const Color(0xFFF5F9F7),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Dessiner les vagues
    _drawWave(
      canvas,
      size,
      amplitude: 30,
      frequency: 1.5,
      phase: animation * 2 * math.pi,
      yOffset: size.height * 0.35,
      color: isDark
          ? const Color(0xFF54AB70).withValues(alpha: 0.1)
          : const Color(0xFF54AB70).withValues(alpha: 0.08),
    );

    _drawWave(
      canvas,
      size,
      amplitude: 25,
      frequency: 2,
      phase: animation * 2 * math.pi + math.pi / 3,
      yOffset: size.height * 0.38,
      color: isDark
          ? const Color(0xFF3D8C57).withValues(alpha: 0.08)
          : const Color(0xFF3D8C57).withValues(alpha: 0.06),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double frequency,
    required double phase,
    required double yOffset,
    required Color color,
  }) {
    final path = Path();
    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      final y = yOffset + amplitude * math.sin((x / size.width) * frequency * 2 * math.pi + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WaveBackgroundPainter oldDelegate) =>
      animation != oldDelegate.animation || isDark != oldDelegate.isDark;
}
