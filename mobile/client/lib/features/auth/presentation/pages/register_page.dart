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

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI state moved to Riverpod providers:
  // - _obscurePassword -> toggleProvider(_obscurePasswordId)
  // - _obscureConfirmPassword -> toggleProvider(_obscureConfirmId)
  // - _acceptTerms -> toggleProvider(_acceptTermsId) with initialValue: false

  @override
  void initState() {
    super.initState();
    // Initialiser les toggles de mot de passe à true (obscurcir par défaut)
    // acceptTerms reste à false par défaut (comportement sécurisé)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(toggleProvider(_obscurePasswordId).notifier).set(true);
      ref.read(toggleProvider(_obscureConfirmId).notifier).set(true);
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
      if (errorLower.contains('short') || errorLower.contains('minimum') || errorLower.contains('length')) {
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
    if (!_formKey.currentState!.validate()) return;

    final acceptTerms = ref.read(toggleProvider(_acceptTermsId));
    if (!acceptTerms) {
      ErrorHandler.showWarningSnackBar(
        context, 
        "Veuillez accepter les conditions d'utilisation",
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
      // Convertir le message technique en message utilisateur explicite
      final userFriendlyMessage = _getReadableErrorMessage(authState.errorMessage);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, userFriendlyMessage);
      }
    } else if (authState.status == AuthStatus.authenticated) {
      // Navigation gérée automatiquement par le router redirect
      // (authenticated + phone non vérifiée → OTP page)
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Inscription réussie ! Bienvenue');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _getPasswordStrength();
    
    // Watch UI state providers
    final obscurePassword = ref.watch(toggleProvider(_obscurePasswordId));
    final obscureConfirm = ref.watch(toggleProvider(_obscureConfirmId));
    final acceptTerms = ref.watch(toggleProvider(_acceptTermsId));

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
        body: Stack(
        children: [
          // Background Design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
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
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
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
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Créer un compte',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Remplissez vos informations pour commencer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 30),

                              _buildNameField(isDark),
                              const SizedBox(height: 20),
                              _buildEmailField(isDark),
                              const SizedBox(height: 20),
                              _buildPhoneField(isDark),
                              const SizedBox(height: 20),
                              _buildAddressField(isDark),
                              const SizedBox(height: 20),
                              _buildPasswordField(isDark, obscurePassword),
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildPasswordStrengthIndicator(
                                  passwordStrength,
                                  isDark,
                                ),
                              ],
                              const SizedBox(height: 20),
                              _buildConfirmPasswordField(isDark, obscureConfirm),
                              const SizedBox(height: 24),
                              _buildTermsCheckbox(isDark, acceptTerms),
                              const SizedBox(height: 32),
                              _buildRegisterButton(
                                authState.status == AuthStatus.loading,
                              ),
                              const SizedBox(height: 24),
                              _buildLoginLink(isDark),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ), // Closing Stack
      ), // Closing Scaffold
    ); // Closing PopScope
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
            ),
          ),
          Expanded(
            child: Text(
              'DR-PHARMA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return _buildTextField(
      controller: _nameController,
      label: 'Nom complet',
      icon: Icons.person_outline,
      isDark: isDark,
      validator: (value) => FormValidators.validateName(
        value, 
        fieldName: 'Le nom',
        minLength: 2,
      ),
    );
  }

  Widget _buildEmailField(bool isDark) {
    return _buildTextField(
      controller: _emailController,
      label: 'Adresse email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      isDark: isDark,
      validator: FormValidators.validateEmail,
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: FormValidators.validatePhone,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Téléphone',
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_outlined,
                color: isDark ? Colors.grey[400] : AppColors.primary,
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
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
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
      onChanged: (_) => ref.invalidate(toggleProvider(_obscurePasswordId)), // Trigger rebuild for password strength
      suffixIcon: IconButton(
        icon: Icon(
          obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        onPressed: () => ref.read(toggleProvider(_obscurePasswordId).notifier).toggle(),
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
      suffixIcon: IconButton(
        icon: Icon(
          obscureConfirm
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        onPressed: () => ref.read(toggleProvider(_obscureConfirmId).notifier).toggle(),
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
            onChanged: (value) => ref.read(toggleProvider(_acceptTermsId).notifier).set(value ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => ref.read(toggleProvider(_acceptTermsId).notifier).toggle(),
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
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Créer mon compte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : AppColors.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
