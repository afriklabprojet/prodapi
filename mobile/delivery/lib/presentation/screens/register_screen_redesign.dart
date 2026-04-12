import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../core/router/route_names.dart';
import '../../data/repositories/auth_repository.dart';
import 'otp_verification_screen.dart';
import '../widgets/common/password_strength_indicator.dart';

/// Écran d'inscription redesign — Design "Split Élégant"
/// Informations de base + véhicule en 2 étapes.
class RegisterScreenRedesign extends ConsumerStatefulWidget {
  const RegisterScreenRedesign({super.key});

  @override
  ConsumerState<RegisterScreenRedesign> createState() =>
      _RegisterScreenRedesignState();
}

class _RegisterScreenRedesignState extends ConsumerState<RegisterScreenRedesign>
    with TickerProviderStateMixin {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleRegistrationController = TextEditingController();

  // State
  String _selectedVehicleType = 'motorcycle';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  Map<String, String?> _fieldErrors = {};
  String? _generalError;
  int _currentStep = 0; // 0 = Identité, 1 = Véhicule

  // Animation Controllers
  late AnimationController _formController;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  // Design Colors
  static const _navyDark = Color(0xFF0F1C3F);
  static const _navyMedium = Color(0xFF1A2B52);
  static const _accentGold = Color(0xFFE5C76B);
  static const _accentTeal = Color(0xFF2DD4BF);
  static const _primaryGreen = Color(0xFF0D6644);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  void _initAnimations() {
    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _formSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    _formController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseNumberController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _fieldErrors = {};
      _generalError = null;
    });

    if (_currentStep == 0) {
      return _validateStep0();
    }

    if (!_validateStep0()) {
      setState(() => _currentStep = 0);
      return false;
    }
    return _validateStep1();
  }

  bool _validateStep0() {
    final nameResult = Validators.validateName(_nameController.text);
    if (!nameResult.isValid) {
      setState(() => _fieldErrors['name'] = nameResult.errorMessage);
      return false;
    }

    if (_emailController.text.trim().isNotEmpty) {
      final emailResult = Validators.validateEmail(_emailController.text);
      if (!emailResult.isValid) {
        setState(() => _fieldErrors['email'] = emailResult.errorMessage);
        return false;
      }
    }

    final phoneResult = Validators.validatePhone(_phoneController.text);
    if (!phoneResult.isValid) {
      setState(() => _fieldErrors['phone'] = phoneResult.errorMessage);
      return false;
    }

    final passwordResult = Validators.validatePassword(
      _passwordController.text,
    );
    if (!passwordResult.isValid) {
      setState(() => _fieldErrors['password'] = passwordResult.errorMessage);
      return false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(
        () => _fieldErrors['confirm_password'] =
            'Veuillez confirmer le mot de passe',
      );
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(
        () => _fieldErrors['confirm_password'] =
            'Les mots de passe ne correspondent pas',
      );
      return false;
    }

    return true;
  }

  bool _validateStep1() {
    final vehicleResult = Validators.validateVehicleRegistration(
      _vehicleRegistrationController.text,
    );
    if (!vehicleResult.isValid) {
      setState(
        () => _fieldErrors['vehicle_registration'] = vehicleResult.errorMessage,
      );
      return false;
    }

    final licenseResult = Validators.validateLicenseNumber(
      _licenseNumberController.text,
    );
    if (!licenseResult.isValid) {
      setState(() => _fieldErrors['license'] = licenseResult.errorMessage);
      return false;
    }

    if (!_acceptedTerms) {
      setState(
        () => _fieldErrors['terms'] =
            'Vous devez accepter les conditions d\'utilisation',
      );
      return false;
    }

    return true;
  }

  void _submit() {
    HapticFeedback.lightImpact();

    if (_currentStep == 0) {
      if (_validateStep0()) {
        HapticFeedback.mediumImpact();
        setState(() => _currentStep = 1);
      } else {
        HapticFeedback.heavyImpact();
      }
      return;
    }

    if (!_validateForm()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _register();
  }

  void _goBack() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep = 0);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _fieldErrors = {};
      _generalError = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .registerCourier(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            vehicleType: _selectedVehicleType,
            vehicleRegistration: _vehicleRegistrationController.text.trim(),
            licenseNumber: _licenseNumberController.text.trim(),
          );

      HapticFeedback.heavyImpact();
      if (mounted) _showSuccessDialog();
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) _parseAndShowErrors(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseAndShowErrors(String error) {
    final errorMessage = error.replaceAll('Exception:', '').trim();
    final errorLower = errorMessage.toLowerCase();

    setState(() {
      if (errorLower.contains('email') &&
          (errorLower.contains('existe') ||
              errorLower.contains('taken') ||
              errorLower.contains('unique'))) {
        _fieldErrors['email'] = 'Cet email est déjà utilisé';
      } else if (errorLower.contains('phone') ||
          errorLower.contains('téléphone')) {
        _fieldErrors['phone'] = errorLower.contains('existe')
            ? 'Ce numéro est déjà utilisé'
            : 'Numéro invalide';
      } else if (errorLower.contains('dioexception') ||
          errorLower.contains('socketexception')) {
        _generalError =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (errorLower.contains('timeout')) {
        _generalError = 'La connexion a pris trop de temps. Réessayez.';
      } else {
        _generalError = errorMessage.length > 200
            ? 'Une erreur est survenue. Réessayez.'
            : errorMessage;
      }
    });
  }

  void _showSuccessDialog() {
    final phone = _phoneController.text.trim();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        onConfirm: () {
          context.go(
            AppRoutes.otpVerification,
            extra: {'identifier': phone, 'purpose': OtpPurpose.verification},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1C) : Colors.white,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // SPLIT HEADER — Navy section with decorative elements
          // ═══════════════════════════════════════════════════════════════════
          _buildSplitHeader(isDark),

          // ═══════════════════════════════════════════════════════════════════
          // FORM SECTION — White scrollable area
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: AnimatedBuilder(
              animation: _formController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _formSlide.value),
                  child: Opacity(opacity: _formFade.value, child: child),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A0F1C) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_generalError != null) _buildErrorBanner(isDark),
                        _buildElegantFormFields(isDark),
                        const SizedBox(height: 28),
                        _buildElegantCTAButton(isDark),
                        const SizedBox(height: 20),
                        _buildElegantLoginLink(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header split navy avec badge d'étape et décorations
  Widget _buildSplitHeader(bool isDark) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: 260 + statusBarHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDark, _navyMedium],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentGold.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            top: 80 + statusBarHeight,
            right: 30,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _accentGold.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accentTeal.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Decorative lines
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              260 + statusBarHeight,
            ),
            painter: _HeaderLinesPainter(),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStepBadge(),
                    ],
                  ),

                  const Spacer(),

                  // Step indicator dots
                  _buildStepIndicator(),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _currentStep == 0
                        ? 'Parlez-nous de vous'
                        : 'Votre véhicule',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0
                        ? 'Vos informations personnelles'
                        : 'Détails de votre moyen de transport',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _currentStep == 0
                ? Icons.person_outline_rounded
                : Icons.two_wheeler_rounded,
            color: _accentGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'ÉTAPE ${_currentStep + 1}/2',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _accentGold, shape: BoxShape.circle),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentGold,
                  _currentStep >= 1
                      ? _accentGold
                      : Colors.white.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _currentStep >= 1
                ? _accentGold
                : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: _currentStep < 1
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 120),
      ],
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generalError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantFormFields(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _currentStep == 0
          ? _buildElegantStep0(isDark)
          : _buildElegantStep1(isDark),
    );
  }

  Widget _buildElegantStep0(bool isDark) {
    return Column(
      key: const ValueKey('elegant_step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: _primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildElegantField(
          controller: _nameController,
          label: 'Nom complet',
          hint: 'Jean Kouamé',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          fieldKey: 'name',
        ),
        const SizedBox(height: 16),
        _buildElegantField(
          controller: _phoneController,
          label: 'Téléphone',
          hint: '+225 07 00 00 00 00',
          icon: Icons.phone_outlined,
          isDark: isDark,
          fieldKey: 'phone',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildElegantField(
          controller: _emailController,
          label: 'Email (optionnel)',
          hint: 'jean@email.com',
          icon: Icons.email_outlined,
          isDark: isDark,
          fieldKey: 'email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildElegantField(
          controller: _passwordController,
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          fieldKey: 'password',
          isPassword: true,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PasswordStrengthIndicator(
              password: _passwordController.text,
              showCriteria: _passwordController.text.length >= 4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildElegantField(
          controller: _confirmPasswordController,
          label: 'Confirmer mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          fieldKey: 'confirm_password',
          isPassword: true,
          obscure: _obscureConfirmPassword,
          onToggleObscure: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
      ],
    );
  }

  Widget _buildElegantStep1(bool isDark) {
    return Column(
      key: const ValueKey('elegant_step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.two_wheeler_rounded,
                color: _primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Votre véhicule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Type de véhicule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildElegantVehicleCard(
              'bicycle',
              Icons.pedal_bike_rounded,
              'Vélo',
              isDark,
            ),
            const SizedBox(width: 12),
            _buildElegantVehicleCard(
              'motorcycle',
              Icons.two_wheeler_rounded,
              'Moto',
              isDark,
            ),
            const SizedBox(width: 12),
            _buildElegantVehicleCard(
              'car',
              Icons.directions_car_rounded,
              'Voiture',
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildElegantField(
          controller: _vehicleRegistrationController,
          label: 'Immatriculation',
          hint: 'ABC 1234 CI',
          icon: Icons.badge_outlined,
          isDark: isDark,
          fieldKey: 'vehicle_registration',
        ),
        const SizedBox(height: 16),
        _buildElegantField(
          controller: _licenseNumberController,
          label: 'N° Permis (optionnel pour vélo)',
          hint: 'AB123456',
          icon: Icons.credit_card_outlined,
          isDark: isDark,
          fieldKey: 'license',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _primaryGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vos documents d\'identité seront demandés lors de votre première mise en ligne.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _acceptedTerms ? _primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _acceptedTerms
                        ? _primaryGreen
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: _acceptedTerms
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'J\'accepte les ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => _openUrl(AppConfig.termsUrl),
                          child: Text(
                            'Conditions d\'utilisation',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryGreen,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => _openUrl(AppConfig.privacyUrl),
                          child: Text(
                            'Politique de confidentialité',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryGreen,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_fieldErrors['terms'] != null) ...[
          const SizedBox(height: 8),
          Text(
            _fieldErrors['terms']!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildElegantVehicleCard(
    String type,
    IconData icon,
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedVehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedVehicleType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [_navyDark, _navyMedium])
                : null,
            color: isSelected
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _navyDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? _accentGold
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? fieldKey,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscure = true,
    VoidCallback? onToggleObscure,
  }) {
    final hasError = fieldKey != null && _fieldErrors[fieldKey] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasError
                ? Colors.red.shade400
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: hasError
                ? Colors.red.withValues(alpha: 0.05)
                : _primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? Colors.red.shade300
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && obscure,
            onChanged: (_) {
              if (fieldKey != null && _fieldErrors[fieldKey] != null) {
                setState(() => _fieldErrors.remove(fieldKey));
              }
            },
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  icon,
                  color: hasError ? Colors.red : _primaryGreen,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 50),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              _fieldErrors[fieldKey]!,
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildElegantCTAButton(bool isDark) {
    final isLastStep = _currentStep == 1;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, const Color(0xFF15A865)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _submit,
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
                          Text(
                            isLastStep ? 'Créer mon compte' : 'Continuer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isLastStep
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (_currentStep > 0) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _currentStep = 0);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Retour aux informations',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: _primaryGreen),
          ),
        ],
      ],
    );
  }

  Widget _buildElegantLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Se connecter',
              style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _SuccessDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inscription réussie !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre compte a été créé. Vérifions maintenant votre numéro de téléphone pour sécuriser votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D8C57), Color(0xFF54AB70)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Text(
                        'Vérifier mon téléphone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

/// Lignes décoratives pour le header
class _HeaderLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5C76B).withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Ligne diagonale 1
    final path1 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.5, size.height * 0.4);
    canvas.drawPath(path1, paint);

    // Ligne diagonale 2
    final path2 = Path()
      ..moveTo(size.width * 0.85, size.height * 0.1)
      ..lineTo(size.width * 0.65, size.height * 0.5);
    canvas.drawPath(
      path2,
      paint..color = const Color(0xFF2DD4BF).withValues(alpha: 0.12),
    );

    // Ligne courbe subtile
    final path3 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.8,
      );
    canvas.drawPath(path3, paint..color = Colors.white.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
