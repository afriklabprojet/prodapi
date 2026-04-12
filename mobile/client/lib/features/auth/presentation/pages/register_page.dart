import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/validators/form_validators.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

// Provider IDs pour cette page
const _obscurePasswordId = 'register_obscure_password';
const _obscureConfirmId = 'register_obscure_confirm';
const _acceptTermsId = 'register_accept_terms';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation controllers
  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _pulseController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _pulseAnimation;

  // Current step (0 = info, 1 = sécurité)
  int _currentStep = 0;

  // Erreurs inline
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
        );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _fadeController!.forward();
    _slideController!.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(toggleProvider(_obscurePasswordId).notifier).set(true);
      ref.read(toggleProvider(_obscureConfirmId).notifier).set(true);
    });
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  double _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;

    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.25;

    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.amber;
    return Colors.green;
  }

  String _getStrengthText(double strength) {
    if (strength <= 0.25) return 'Faible';
    if (strength <= 0.5) return 'Moyen';
    if (strength <= 0.75) return 'Bon';
    return 'Fort';
  }

  /// Convertit les messages d'erreur techniques en messages utilisateur explicites
  String _getReadableErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    final errorLower = error.toLowerCase();

    // Email déjà utilisé
    if (errorLower.contains('email') &&
        (errorLower.contains('taken') ||
            errorLower.contains('already') ||
            errorLower.contains('exists') ||
            errorLower.contains('utilisé') ||
            errorLower.contains('existe'))) {
      return 'Cette adresse email est déjà utilisée.\nVeuillez utiliser une autre adresse ou vous connecter.';
    }

    // Téléphone déjà utilisé
    if (errorLower.contains('phone') &&
        (errorLower.contains('taken') ||
            errorLower.contains('already') ||
            errorLower.contains('exists') ||
            errorLower.contains('utilisé'))) {
      return 'Ce numéro de téléphone est déjà utilisé.\nVeuillez utiliser un autre numéro.';
    }

    // Erreurs de validation email
    if (errorLower.contains('email') &&
        (errorLower.contains('invalid') || errorLower.contains('format'))) {
      return 'Le format de l\'email est invalide.\nVeuillez vérifier votre saisie.';
    }

    // Erreurs de mot de passe
    if (errorLower.contains('password')) {
      if (errorLower.contains('confirmation') || errorLower.contains('match')) {
        return 'Les mots de passe ne correspondent pas.\nVeuillez vérifier votre saisie.';
      }
      if (errorLower.contains('short') ||
          errorLower.contains('minimum') ||
          errorLower.contains('length')) {
        return 'Le mot de passe est trop court.\nIl doit contenir au moins 8 caractères.';
      }
      return 'Le mot de passe ne respecte pas les critères requis.';
    }

    // Erreurs réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connexion') ||
        errorLower.contains('internet') ||
        errorLower.contains('timeout')) {
      return 'Problème de connexion internet.\nVérifiez votre connexion et réessayez.';
    }

    // Erreurs serveur
    if (errorLower.contains('server') ||
        errorLower.contains('500') ||
        errorLower.contains('503')) {
      return 'Le service est temporairement indisponible.\nVeuillez réessayer dans quelques instants.';
    }

    // Erreurs de validation génériques
    if (errorLower.contains('validation') || errorLower.contains('required')) {
      return 'Certaines informations sont manquantes ou incorrectes.\nVeuillez vérifier tous les champs.';
    }

    // Message par défaut
    return 'Une erreur s\'est produite lors de l\'inscription.\nVeuillez vérifier vos informations et réessayer.';
  }

  Future<void> _register() async {
    _clearErrors();

    // Valider le formulaire étape 2
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;

    final acceptTerms = ref.read(toggleProvider(_acceptTermsId));
    if (!acceptTerms) {
      setState(
        () => _generalError = "Veuillez accepter les conditions d'utilisation",
      );
      return;
    }

    await ref
        .read(authProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: '+225${_phoneController.text.trim()}',
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.error &&
        authState.errorMessage != null) {
      // Parser l'erreur et l'afficher sous le champ approprié
      _handleRegistrationError(authState.errorMessage!);
    } else if (authState.status == AuthStatus.authenticated) {
      // Navigation gérée automatiquement par le router redirect
      // (authenticated + phone non vérifiée → OTP page)
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Inscription réussie ! Bienvenue',
        );
      }
    }
  }

  /// Parse l'erreur serveur et affiche sous le champ approprié
  void _handleRegistrationError(String error) {
    final errorLower = error.toLowerCase();

    // Email déjà utilisé
    if (errorLower.contains('email') &&
        (errorLower.contains('taken') ||
            errorLower.contains('already') ||
            errorLower.contains('exists') ||
            errorLower.contains('utilisé') ||
            errorLower.contains('existe'))) {
      setState(() => _emailError = 'Cette adresse email est déjà utilisée');
      return;
    }

    // Téléphone déjà utilisé
    if (errorLower.contains('phone') &&
        (errorLower.contains('taken') ||
            errorLower.contains('already') ||
            errorLower.contains('exists') ||
            errorLower.contains('utilisé'))) {
      setState(() => _phoneError = 'Ce numéro est déjà utilisé');
      return;
    }

    // Erreurs de validation email
    if (errorLower.contains('email') &&
        (errorLower.contains('invalid') || errorLower.contains('format'))) {
      setState(() => _emailError = 'Format d\'email invalide');
      return;
    }

    // Erreurs de mot de passe
    if (errorLower.contains('password')) {
      if (errorLower.contains('confirmation') || errorLower.contains('match')) {
        setState(
          () =>
              _confirmPasswordError = 'Les mots de passe ne correspondent pas',
        );
        return;
      }
      if (errorLower.contains('short') ||
          errorLower.contains('minimum') ||
          errorLower.contains('length')) {
        setState(() => _passwordError = 'Minimum 8 caractères requis');
        return;
      }
      setState(() => _passwordError = 'Mot de passe non valide');
      return;
    }

    // Erreurs générales
    setState(() => _generalError = _getReadableErrorMessage(error));
  }

  // Navigation entre les étapes
  void _nextStep() {
    if (_currentStep == 0) {
      // Valider étape 1
      if (_step1FormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
        _slideController?.reset();
        _slideController?.forward();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = 0);
      _slideController?.reset();
      _slideController?.forward();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _loginWithGoogle() async {
    HapticFeedback.selectionClick();
    await ref.read(authProvider.notifier).loginWithGoogle();

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.error &&
        authState.errorMessage != null &&
        authState.errorMessage != 'Connexion Google annulée') {
      setState(() => _generalError = authState.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _getPasswordStrength();

    // Watch UI state providers
    final obscurePassword = ref.watch(toggleProvider(_obscurePasswordId));
    final obscureConfirm = ref.watch(toggleProvider(_obscureConfirmId));
    final acceptTerms = ref.watch(toggleProvider(_acceptTermsId));

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // Background élégant avec dégradé
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.30,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Cercle décoratif
                    Positioned(
                      top: -80,
                      right: -60,
                      child: Container(
                        width: 250,
                        height: 250,
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
                      bottom: 20,
                      left: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Courbe élégante
            Positioned(
              top: size.height * 0.30 - 35,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Header avec titre
                  _buildPremiumHeader(isDark),
                  const SizedBox(height: 10),

                  // Progress Stepper
                  _buildProgressStepper(isDark),
                  const SizedBox(height: 20),

                  // Form Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: FadeTransition(
                            opacity:
                                _fadeAnimation ??
                                const AlwaysStoppedAnimation(1.0),
                            child: SlideTransition(
                              position:
                                  _slideAnimation ??
                                  const AlwaysStoppedAnimation(Offset.zero),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Titre de l'étape
                                  _buildStepTitle(isDark),
                                  const SizedBox(height: 24),

                                  // General error banner
                                  if (_generalError != null) ...[
                                    _buildErrorBanner(isDark),
                                    const SizedBox(height: 20),
                                  ],

                                  // Contenu selon l'étape
                                  if (_currentStep == 0)
                                    _buildStep1Content(isDark)
                                  else
                                    _buildStep2Content(
                                      isDark,
                                      obscurePassword,
                                      obscureConfirm,
                                      acceptTerms,
                                      passwordStrength,
                                      authState,
                                    ),

                                  // Social Login Buttons (dans la card) - étape 1 uniquement
                                  if (_currentStep == 0) ...[
                                    const SizedBox(height: 20),
                                    _buildOrDivider(isDark),
                                    const SizedBox(height: 16),
                                    _buildSocialButtons(isDark),
                                    const SizedBox(height: 20),
                                    _buildLoginLink(isDark),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Logo ancré - positionné au-dessus de la card
            Positioned(
              top: size.height * 0.13,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation:
                      _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
                  builder: (context, child) => Transform.scale(
                    scale: 0.98 + ((_pulseAnimation?.value ?? 1.0) - 1) * 0.3,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
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

  Widget _buildPremiumHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'DR-PHARMA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Créez votre compte',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40), // Balance le bouton retour
        ],
      ),
    );
  }

  Widget _buildProgressStepper(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Étape 1
          _buildStepIndicator(
            stepNumber: 1,
            label: 'Infos',
            isActive: _currentStep >= 0,
            isCompleted: _currentStep > 0,
            isDark: isDark,
          ),
          // Ligne de connexion
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _currentStep > 0
                    ? AppColors.primary
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
            ),
          ),
          // Étape 2
          _buildStepIndicator(
            stepNumber: 2,
            label: 'Sécurité',
            isActive: _currentStep >= 1,
            isCompleted: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required bool isDark,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : (isActive
                      ? AppColors.primary
                      : (isDark ? Colors.grey[800] : Colors.grey[200])),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.white : AppColors.textPrimary)
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStepTitle(bool isDark) {
    final titles = [
      {'title': 'Vos informations', 'subtitle': 'Renseignez vos coordonnées'},
      {
        'title': 'Sécurisez votre compte',
        'subtitle': 'Créez un mot de passe fort',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[_currentStep]['title']!,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titles[_currentStep]['subtitle']!,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[500] : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.shade300.withValues(alpha: 0.5),
          width: 1,
        ),
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
              color: Colors.red.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generalError!,
              style: TextStyle(
                color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Content(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          _buildNameField(isDark),
          const SizedBox(height: 18),
          _buildEmailField(isDark),
          const SizedBox(height: 18),
          _buildPhoneField(isDark),
          const SizedBox(height: 18),
          _buildAddressField(isDark),
          const SizedBox(height: 28),
          _buildNextStepButton(),
        ],
      ),
    );
  }

  Widget _buildStep2Content(
    bool isDark,
    bool obscurePassword,
    bool obscureConfirm,
    bool acceptTerms,
    double passwordStrength,
    AuthState authState,
  ) {
    return Form(
      key: _step2FormKey,
      child: Column(
        children: [
          _buildPasswordField(isDark, obscurePassword),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPasswordStrengthIndicator(passwordStrength, isDark),
          ],
          const SizedBox(height: 18),
          _buildConfirmPasswordField(isDark, obscureConfirm),
          const SizedBox(height: 22),
          _buildTermsCheckbox(isDark, acceptTerms),
          const SizedBox(height: 28),
          _buildRegisterButton(authState.status == AuthStatus.loading),
        ],
      ),
    );
  }

  Widget _buildNextStepButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Continuer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return _buildTextField(
      controller: _nameController,
      label: 'Nom complet',
      icon: Icons.person_outline,
      isDark: isDark,
      errorText: _nameError,
      onChanged: (_) {
        if (_nameError != null) setState(() => _nameError = null);
      },
      validator: (value) =>
          FormValidators.validateName(value, fieldName: 'Le nom', minLength: 2),
    );
  }

  Widget _buildEmailField(bool isDark) {
    return _buildTextField(
      controller: _emailController,
      label: 'Adresse email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      isDark: isDark,
      errorText: _emailError,
      onChanged: (_) {
        if (_emailError != null) setState(() => _emailError = null);
        if (_generalError != null) setState(() => _generalError = null);
      },
      validator: FormValidators.validateEmail,
    );
  }

  Widget _buildPhoneField(bool isDark) {
    final hasError = _phoneError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: FormValidators.validatePhone,
          onChanged: (_) {
            if (_phoneError != null) setState(() => _phoneError = null);
            if (_generalError != null) setState(() => _generalError = null);
          },
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Téléphone',
            labelStyle: TextStyle(
              color: hasError
                  ? Colors.red.shade400
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    color: hasError
                        ? Colors.red.shade400
                        : (isDark ? Colors.grey[400] : AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+225',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: hasError
                ? Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 1.0)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? BorderSide(color: Colors.red.shade400, width: 1.5)
                  : BorderSide.none,
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _phoneError!,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddressField(bool isDark) {
    return _buildTextField(
      controller: _addressController,
      label: 'Adresse (optionnel)',
      icon: Icons.location_on_outlined,
      isDark: isDark,
    );
  }

  Widget _buildPasswordField(bool isDark, bool obscurePassword) {
    return _buildTextField(
      controller: _passwordController,
      label: 'Mot de passe',
      icon: Icons.lock_outline,
      obscureText: obscurePassword,
      isDark: isDark,
      errorText: _passwordError,
      onChanged: (_) {
        ref.invalidate(
          toggleProvider(_obscurePasswordId),
        ); // Trigger rebuild for password strength
        if (_passwordError != null) setState(() => _passwordError = null);
        if (_generalError != null) setState(() => _generalError = null);
      },
      suffixIcon: IconButton(
        icon: Icon(
          obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        onPressed: () =>
            ref.read(toggleProvider(_obscurePasswordId).notifier).toggle(),
      ),
      validator: (value) => FormValidators.validatePassword(
        value,
        strength: PasswordStrength.strong,
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(double strength, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStrengthColor(strength),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getStrengthText(strength),
            style: TextStyle(
              color: _getStrengthColor(strength),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool isDark, bool obscureConfirm) {
    return _buildTextField(
      controller: _confirmPasswordController,
      label: 'Confirmer le mot de passe',
      icon: Icons.lock_outline,
      obscureText: obscureConfirm,
      isDark: isDark,
      errorText: _confirmPasswordError,
      onChanged: (_) {
        if (_confirmPasswordError != null) {
          setState(() => _confirmPasswordError = null);
        }
        if (_generalError != null) setState(() => _generalError = null);
      },
      suffixIcon: IconButton(
        icon: Icon(
          obscureConfirm
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        onPressed: () =>
            ref.read(toggleProvider(_obscureConfirmId).notifier).toggle(),
      ),
      validator: (value) => FormValidators.validatePasswordConfirmation(
        value,
        _passwordController.text,
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isDark, bool acceptTerms) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: acceptTerms,
            onChanged: (value) => ref
                .read(toggleProvider(_acceptTermsId).notifier)
                .set(value ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(toggleProvider(_acceptTermsId).notifier).toggle(),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: "J'accepte les "),
                    TextSpan(
                      text: "Conditions d'utilisation",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' et la '),
                    TextSpan(
                      text: 'Politique de confidentialité',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
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
                  const Text(
                    'Créer mon compte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check, size: 18),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOrDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? Colors.white24 : Colors.grey.shade300,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.white24 : Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(bool isDark) {
    return GestureDetector(
      onTap: _loginWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) => Icon(
                Icons.g_mobiledata,
                size: 24,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continuer avec Google',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous avez déjà un compte ? ',
          style: TextStyle(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Text(
            'Se connecter',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
    void Function(String)? onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
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
}
