import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/liveness_verification_widget.dart';
import 'login_screen_redesign.dart';

/// Écran d'inscription redesigné avec animations modernes
/// Design: Glassmorphism + Steps animés + UX améliorée
class RegisterScreenRedesign extends ConsumerStatefulWidget {
  const RegisterScreenRedesign({super.key});

  @override
  ConsumerState<RegisterScreenRedesign> createState() => _RegisterScreenRedesignState();
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
  File? _idCardFrontImage;
  File? _idCardBackImage;
  File? _selfieImage;
  File? _drivingLicenseFrontImage;
  File? _drivingLicenseBackImage;
  bool _livenessVerified = false;
  // ignore: unused_field
  String? _livenessSessionId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  Map<String, String?> _fieldErrors = {};
  String? _generalError;

  final ImagePicker _picker = ImagePicker();

  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _stepController;
  late AnimationController _formController;

  // Animations
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  // Constants
  static const primaryColor = Color(0xFF54AB70);
  static const gradientColors = [Color(0xFF3D8C57), Color(0xFF6EC889)];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _formSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _stepController.dispose();
    _formController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseNumberController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        HapticFeedback.lightImpact();
        setState(() {
          switch (type) {
            case 'id_card_front':
              _idCardFrontImage = File(image.path);
              break;
            case 'id_card_back':
              _idCardBackImage = File(image.path);
              break;
            case 'selfie':
              _selfieImage = File(image.path);
              break;
            case 'driving_license_front':
              _drivingLicenseFrontImage = File(image.path);
              break;
            case 'driving_license_back':
              _drivingLicenseBackImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection de l\'image', isError: true);
    }
  }

  void _showImagePickerModal(String type, String title) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImagePickerModal(
        title: title,
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera, type);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery, type);
        },
      ),
    );
  }

  void _startLivenessVerification() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Vérification d\'identité'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          body: LivenessVerificationWidget(
            apiBaseUrl: ApiConstants.baseUrl,
            onVerificationComplete: (sessionId) async {
              setState(() {
                _livenessSessionId = sessionId;
                _livenessVerified = true;
                _fieldErrors.remove('selfie');
              });
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              _showSnackBar('Vérification d\'identité réussie!', isSuccess: true);
              _pickImage(ImageSource.camera, 'selfie');
            },
            onVerificationFailed: (error) {
              Navigator.pop(context);
              _showSnackBar('Vérification échouée: $error', isError: true);
            },
            onFallbackSelfie: (Uint8List imageBytes) async {
              // Mode dégradé : le service liveness est indisponible
              // On sauvegarde le selfie simple dans un fichier temporaire
              final tempDir = Directory.systemTemp;
              final tempFile = File('${tempDir.path}/selfie_fallback_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await tempFile.writeAsBytes(imageBytes);
              setState(() {
                _selfieImage = tempFile;
                _fieldErrors.remove('selfie');
                // _livenessVerified reste false : le backend saura que c'est un fallback
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              _showSnackBar('Selfie capturé avec succès', isSuccess: true);
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    
    // Valider l'étape actuelle avant de continuer
    if (!_validateCurrentStep()) {
      HapticFeedback.heavyImpact();
      return;
    }
    
    if (_currentStep < 2) {
      _stepController.forward(from: 0);
      setState(() => _currentStep++);
      _formController.forward(from: 0);
    } else {
      _register();
    }
  }

  bool _validateCurrentStep() {
    setState(() {
      _fieldErrors = {};
      _generalError = null;
    });

    switch (_currentStep) {
      case 0:
        // Étape 1 : Informations personnelles
        if (_nameController.text.trim().isEmpty) {
          setState(() => _fieldErrors['name'] = 'Le nom est requis');
          return false;
        }
        if (_nameController.text.trim().length < 3) {
          setState(() => _fieldErrors['name'] = 'Le nom doit contenir au moins 3 caractères');
          return false;
        }
        if (_emailController.text.trim().isEmpty) {
          setState(() => _fieldErrors['email'] = 'L\'email est requis');
          return false;
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(_emailController.text.trim())) {
          setState(() => _fieldErrors['email'] = 'Format d\'email invalide');
          return false;
        }
        if (_phoneController.text.trim().isEmpty) {
          setState(() => _fieldErrors['phone'] = 'Le numéro de téléphone est requis');
          return false;
        }
        if (_phoneController.text.trim().length < 8) {
          setState(() => _fieldErrors['phone'] = 'Numéro de téléphone invalide');
          return false;
        }
        if (_passwordController.text.isEmpty) {
          setState(() => _fieldErrors['password'] = 'Le mot de passe est requis');
          return false;
        }
        if (_passwordController.text.length < 8) {
          setState(() => _fieldErrors['password'] = 'Le mot de passe doit contenir au moins 8 caractères');
          return false;
        }
        if (_confirmPasswordController.text.isEmpty) {
          setState(() => _fieldErrors['confirm_password'] = 'Veuillez confirmer le mot de passe');
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _fieldErrors['confirm_password'] = 'Les mots de passe ne correspondent pas');
          return false;
        }
        return true;

      case 1:
        // Étape 2 : Informations véhicule
        if (_vehicleRegistrationController.text.trim().isEmpty) {
          setState(() => _fieldErrors['vehicle_registration'] = 'L\'immatriculation est requise');
          return false;
        }
        if (_licenseNumberController.text.trim().isEmpty) {
          setState(() => _fieldErrors['license'] = 'Le numéro de permis est requis');
          return false;
        }
        return true;

      case 2:
        // Étape 3 : Documents KYC (validé dans _register)
        return true;

      default:
        return true;
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _formController.forward(from: 0);
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
    });

    if (_idCardFrontImage == null) {
      setState(() => _fieldErrors['id_card_front'] = 'Veuillez télécharger le RECTO de votre pièce d\'identité');
      HapticFeedback.heavyImpact();
      return;
    }
    if (_idCardBackImage == null) {
      setState(() => _fieldErrors['id_card_back'] = 'Veuillez télécharger le VERSO de votre pièce d\'identité');
      HapticFeedback.heavyImpact();
      return;
    }
    if (_selfieImage == null) {
      setState(() => _fieldErrors['selfie'] = 'Veuillez prendre un selfie de vérification');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).registerCourier(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        vehicleType: _selectedVehicleType,
        vehicleRegistration: _vehicleRegistrationController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        idCardFrontImage: _idCardFrontImage,
        idCardBackImage: _idCardBackImage,
        selfieImage: _selfieImage,
        drivingLicenseFrontImage: _drivingLicenseFrontImage,
        drivingLicenseBackImage: _drivingLicenseBackImage,
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
      if (errorLower.contains('email') && (errorLower.contains('existe') || errorLower.contains('taken') || errorLower.contains('unique') || errorLower.contains('déjà'))) {
        _fieldErrors['email'] = 'Cet email est déjà utilisé';
        _currentStep = 0;
      } else if (errorLower.contains('phone') || errorLower.contains('téléphone')) {
        _fieldErrors['phone'] = errorLower.contains('existe') || errorLower.contains('unique') || errorLower.contains('déjà')
            ? 'Ce numéro est déjà utilisé'
            : 'Numéro invalide';
        _currentStep = 0;
      } else if (errorLower.contains('dioexception') || errorLower.contains('socketexception') || errorLower.contains('connexion')) {
        _generalError = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.';
      } else if (errorLower.contains('server error') || errorLower.contains('erreur serveur') || errorLower.contains('500')) {
        _generalError = 'Erreur serveur temporaire. Appuyez sur "S\'inscrire" pour réessayer.';
      } else if (errorLower.contains('timeout') || errorLower.contains('délai')) {
        _generalError = 'La connexion a pris trop de temps. Vérifiez votre réseau et réessayez.';
      } else if (errorLower.contains('volumineux') || errorLower.contains('413') || errorLower.contains('too large')) {
        _generalError = 'Les fichiers sont trop volumineux. Prenez des photos de qualité standard.';
      } else {
        _generalError = errorMessage.length > 200 ? 'Une erreur est survenue. Veuillez réessayer.' : errorMessage;
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : (isSuccess ? Icons.check_circle : Icons.info_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : (isSuccess ? Colors.green.shade700 : primaryColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        onConfirm: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreenRedesign()),
            (route) => false,
          );
        },
      ),
    );
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
          AnimatedBuilder(
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
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                // Progress Indicator
                _buildProgressIndicator(isDark),

                // Form Content
                Expanded(
                  child: AnimatedBuilder(
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildStepContent(isDark),
                            const SizedBox(height: 24),
                            _buildNavigationButtons(isDark),
                            const SizedBox(height: 24),
                            _buildLoginLink(isDark),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.grey.shade700),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Devenir Livreur',
                  style: TextStyle(
                    fontSize: context.r.sp(24),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: primaryColor, size: 28),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Étape 1/3 - Informations personnelles';
      case 1:
        return 'Étape 2/3 - Véhicule';
      case 2:
        return 'Étape 3/3 - Documents KYC';
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                // Step circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(colors: gradientColors)
                        : null,
                    color: isActive ? null : (isDark ? Colors.white12 : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Connector line
                if (index < 2)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: index < _currentStep
                            ? const LinearGradient(colors: gradientColors)
                            : null,
                        color: index < _currentStep ? null : (isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error banner
          if (_generalError != null) _buildErrorBanner(isDark),

          // Step content
          if (_currentStep == 0) _buildPersonalInfoStep(isDark),
          if (_currentStep == 1) _buildVehicleStep(isDark),
          if (_currentStep == 2) _buildKYCStep(isDark),
        ],
      ),
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

  Widget _buildPersonalInfoStep(bool isDark) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nameController,
          label: 'Nom complet',
          hint: 'Jean Kouamé',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          fieldKey: 'name',
          validator: (v) => v!.isEmpty ? 'Entrez votre nom' : null,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'jean@email.com',
          icon: Icons.email_outlined,
          isDark: isDark,
          fieldKey: 'email',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v!.isEmpty) return 'Entrez votre email';
            if (!v.contains('@')) return 'Email invalide';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _phoneController,
          label: 'Téléphone',
          hint: '+225 07 00 00 00 00',
          icon: Icons.phone_outlined,
          isDark: isDark,
          fieldKey: 'phone',
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Entrez votre téléphone' : null,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _passwordController,
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          fieldKey: 'password',
          isPassword: true,
          obscurePassword: _obscurePassword,
          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (v) {
            if (v!.isEmpty) return 'Entrez un mot de passe';
            if (v.length < 8) return 'Minimum 8 caractères';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          fieldKey: 'confirm_password',
          isPassword: true,
          obscurePassword: _obscureConfirmPassword,
          onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (v) => v != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
        ),
      ],
    );
  }

  Widget _buildVehicleStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de véhicule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildVehicleCard('bicycle', Icons.pedal_bike_rounded, 'Vélo', isDark),
            const SizedBox(width: 12),
            _buildVehicleCard('motorcycle', Icons.two_wheeler_rounded, 'Moto', isDark),
            const SizedBox(width: 12),
            _buildVehicleCard('car', Icons.directions_car_rounded, 'Voiture', isDark),
          ],
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _vehicleRegistrationController,
          label: 'Immatriculation',
          hint: 'ABC 1234 CI',
          icon: Icons.badge_outlined,
          isDark: isDark,
          fieldKey: 'vehicle_registration',
          validator: (v) => v!.isEmpty ? 'Entrez l\'immatriculation' : null,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _licenseNumberController,
          label: 'N° Permis (optionnel pour vélo)',
          hint: 'AB123456',
          icon: Icons.credit_card_outlined,
          isDark: isDark,
          fieldKey: 'license',
        ),
      ],
    );
  }

  Widget _buildVehicleCard(String type, IconData icon, String label, bool isDark) {
    final isSelected = _selectedVehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedVehicleType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: gradientColors) : null,
            color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
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
                size: 32,
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKYCStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents requis pour la vérification',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),

        // ID Card Front
        _buildDocumentCard(
          title: 'Pièce d\'identité (Recto) *',
          subtitle: 'Face avant de votre CNI',
          icon: Icons.badge_rounded,
          image: _idCardFrontImage,
          hasError: _fieldErrors['id_card_front'] != null,
          isDark: isDark,
          onTap: () => _showImagePickerModal('id_card_front', 'CNI (Recto)'),
        ),
        const SizedBox(height: 12),

        // ID Card Back
        _buildDocumentCard(
          title: 'Pièce d\'identité (Verso) *',
          subtitle: 'Face arrière de votre CNI',
          icon: Icons.badge_outlined,
          image: _idCardBackImage,
          hasError: _fieldErrors['id_card_back'] != null,
          isDark: isDark,
          onTap: () => _showImagePickerModal('id_card_back', 'CNI (Verso)'),
        ),
        const SizedBox(height: 12),

        // Liveness Selfie
        _buildLivenessCard(isDark),

        // Driving License (if needed)
        if (_selectedVehicleType != 'bicycle') ...[
          const SizedBox(height: 12),
          _buildDocumentCard(
            title: 'Permis de conduire (Recto)',
            subtitle: 'Face avant de votre permis',
            icon: Icons.drive_eta_rounded,
            image: _drivingLicenseFrontImage,
            isDark: isDark,
            onTap: () => _showImagePickerModal('driving_license_front', 'Permis (Recto)'),
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            title: 'Permis de conduire (Verso)',
            subtitle: 'Face arrière (optionnel)',
            icon: Icons.drive_eta_outlined,
            image: _drivingLicenseBackImage,
            isDark: isDark,
            onTap: () => _showImagePickerModal('driving_license_back', 'Permis (Verso)'),
          ),
        ],

        const SizedBox(height: 20),
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vos documents seront vérifiés sous 24-48h.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required bool isDark,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    final hasImage = image != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: hasImage
              ? LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                )
              : null,
          color: hasImage
              ? null
              : (hasError
                  ? Colors.red.shade50
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? Colors.green.shade400
                : (hasError ? Colors.red.shade300 : (isDark ? Colors.white12 : Colors.grey.shade200)),
            width: hasImage || hasError ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.green.shade100
                    : (hasError ? Colors.red.shade100 : (isDark ? Colors.white12 : Colors.grey.shade100)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: hasError ? Colors.red : primaryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasError ? Colors.red.shade700 : (isDark ? Colors.white : Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasError ? 'Ce document est requis' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasError ? Colors.red.shade600 : (isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: hasImage ? Colors.green : (hasError ? Colors.red : primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivenessCard(bool isDark) {
    final hasError = _fieldErrors['selfie'] != null;
    return GestureDetector(
      onTap: _startLivenessVerification,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: _livenessVerified
              ? LinearGradient(colors: [Colors.green.shade100, Colors.green.shade200])
              : null,
          color: _livenessVerified
              ? null
              : (hasError
                  ? Colors.red.shade50
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.shade50)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _livenessVerified
                ? Colors.green.shade500
                : (hasError ? Colors.red.shade300 : Colors.blue.shade300),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: _livenessVerified
                    ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)])
                    : const LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_livenessVerified ? Colors.green : primaryColor).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _selfieImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selfieImage!, fit: BoxFit.cover),
                          if (_livenessVerified)
                            Container(
                              color: Colors.green.withValues(alpha: 0.4),
                              child: const Icon(Icons.verified, color: Colors.white, size: 28),
                            ),
                        ],
                      ),
                    )
                  : Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Vérification d\'identité *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasError ? Colors.red.shade700 : (isDark ? Colors.white : Colors.grey.shade800),
                          ),
                        ),
                      ),
                      if (_livenessVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Vérifié', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _livenessVerified
                        ? 'Identité vérifiée avec succès'
                        : (hasError ? 'La vérification est requise' : 'Clignez, tournez la tête, souriez'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _livenessVerified
                          ? Colors.green.shade700
                          : (hasError ? Colors.red.shade600 : (isDark ? Colors.white54 : Colors.grey.shade600)),
                    ),
                  ),
                  if (!_livenessVerified && !hasError) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_livenessVerified)
              const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? fieldKey,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscurePassword = true,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    final hasError = fieldKey != null && _fieldErrors[fieldKey] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && obscurePassword,
          validator: validator,
          onChanged: (_) {
            if (fieldKey != null && _fieldErrors[fieldKey] != null) {
              setState(() => _fieldErrors.remove(fieldKey));
            }
          },
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(
              color: hasError ? Colors.red.shade400 : (isDark ? Colors.white54 : Colors.grey.shade600),
            ),
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: hasError ? Colors.red : primaryColor, size: 22),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? (hasError ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05))
                : (hasError ? Colors.red.shade50 : Colors.grey.shade50),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade300 : (isDark ? Colors.white12 : Colors.grey.shade200),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: hasError ? Colors.red : primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6),
            child: Text(
              _fieldErrors[fieldKey]!,
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: Container(
              height: 54,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _previousStep,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Retour',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _nextStep,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 2 ? 'S\'inscrire' : 'Continuer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Se connecter',
              style: TextStyle(
                color: isDark ? const Color(0xFF6EC889) : const Color(0xFF3D8C57),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Helper Widgets ---

class _ImagePickerModal extends StatelessWidget {
  final String title;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImagePickerModal({
    required this.title,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PickerOption(
                icon: Icons.camera_alt_rounded,
                label: 'Caméra',
                color: const Color(0xFF54AB70),
                onTap: onCamera,
              ),
              _PickerOption(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                color: Colors.blue,
                onTap: onGallery,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

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
                gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inscription réussie !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre compte est en attente de validation. Vous recevrez une notification une fois approuvé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3D8C57), Color(0xFF54AB70)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Text(
                        'Retour à la connexion',
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
            ? [const Color(0xFF1B3A4B), const Color(0xFF0D1B2A)]
            : [const Color(0xFF54AB70).withValues(alpha: 0.12), const Color(0xFFF5F9F7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    _drawWave(canvas, size, 25, 1.5, animation * 2 * math.pi, size.height * 0.18,
        isDark ? const Color(0xFF54AB70).withValues(alpha: 0.08) : const Color(0xFF54AB70).withValues(alpha: 0.06));

    _drawWave(canvas, size, 20, 2, animation * 2 * math.pi + math.pi / 4, size.height * 0.22,
        isDark ? const Color(0xFF3D8C57).withValues(alpha: 0.06) : const Color(0xFF3D8C57).withValues(alpha: 0.04));
  }

  void _drawWave(Canvas canvas, Size size, double amplitude, double frequency, double phase, double yOffset, Color color) {
    final path = Path()..moveTo(0, yOffset);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, yOffset + amplitude * math.sin((x / size.width) * frequency * 2 * math.pi + phase));
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
