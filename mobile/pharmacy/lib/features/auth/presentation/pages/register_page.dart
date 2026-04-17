import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';
import '../widgets/form_fields.dart';
import '../widgets/registration_step_indicator.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // ── Étapes ──────────────────────────────────────────────────────────────
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Étape 1 : Identité
  final _formKey1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Étape 2 : Pharmacie
  final _formKey2 = GlobalKey<FormState>();
  final _pharmacyNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Étape 3 : Localisation GPS
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationError;

  bool _hasSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pharmacyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// Get server error for a field if exists
  String? _getServerError(String fieldName) {
    final authState = ref.read(authProvider);
    return authState.getFieldError(fieldName);
  }
  
  /// Clear server error when user starts typing
  void _onFieldChanged(String fieldName) {
    if (_hasSubmitted) {
      ref.read(authProvider.notifier).clearFieldError(fieldName);
    }
  }

  /// Détecter automatiquement les coordonnées GPS
  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Activez les services de localisation sur votre téléphone';
          _isLocating = false;
        });
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permission refusée définitivement. Activez-la dans les paramètres du téléphone.';
          _isLocating = false;
        });
        return;
      }

      // Obtenir la position
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // Fallback basse précision
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocating = false;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Impossible de détecter votre position. Réessayez.';
        _isLocating = false;
      });
    }
  }

  void _submit() {
    setState(() => _hasSubmitted = true);
    
    final authState = ref.read(authProvider);
    
    if (authState.status == AuthStatus.loading) {
      ErrorSnackBar.showWarning(context, 'Inscription en cours, veuillez patienter...');
      return;
    }
    
    if (_latitude == null || _longitude == null) {
      ErrorSnackBar.showWarning(context, 'Veuillez détecter la position GPS de votre pharmacie');
      return;
    }
    
    // Revalider les deux étapes précédentes avant soumission finale
    final step1Valid = _formKey1.currentState?.validate() ?? false;
    final step2Valid = _formKey2.currentState?.validate() ?? false;

    if (step1Valid && step2Valid) {
      ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            pName: _pharmacyNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            licenseNumber: _licenseController.text.trim(),
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            password: _passwordController.text,
            latitude: _latitude!,
            longitude: _longitude!,
          );
    } else {
      ErrorSnackBar.showWarning(context, 'Veuillez corriger les erreurs du formulaire');
    }
  }

  /// Convertit les messages d'erreur techniques en messages lisibles pour l'utilisateur
  String _getReadableErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    // Email déjà utilisé
    if (errorLower.contains('email') && (errorLower.contains('taken') || errorLower.contains('already') || errorLower.contains('existe'))) {
      return 'Cette adresse email est déjà utilisée.\n\nUtilisez une autre adresse ou connectez-vous avec votre compte existant.';
    }
    
    // Numéro de téléphone déjà utilisé
    if (errorLower.contains('phone') && (errorLower.contains('taken') || errorLower.contains('already') || errorLower.contains('existe'))) {
      return 'Ce numéro de téléphone est déjà associé à un compte.\n\nUtilisez un autre numéro ou contactez le support.';
    }
    
    // Numéro de licence déjà utilisé
    if (errorLower.contains('license') && (errorLower.contains('taken') || errorLower.contains('already') || errorLower.contains('existe'))) {
      return 'Ce numéro de licence est déjà enregistré.\n\nVérifiez le numéro ou contactez le support.';
    }
    
    // Mot de passe trop court
    if (errorLower.contains('password') && (errorLower.contains('short') || errorLower.contains('minimum') || errorLower.contains('caractères'))) {
      return 'Le mot de passe est trop court.\n\nIl doit contenir au moins 8 caractères.';
    }
    
    // Email invalide
    if (errorLower.contains('email') && errorLower.contains('invalid')) {
      return 'L\'adresse email n\'est pas valide.\n\nVérifiez le format de l\'email.';
    }
    
    // Erreur réseau
    if (errorLower.contains('network') || errorLower.contains('connexion') || errorLower.contains('internet')) {
      return 'Problème de connexion internet.\n\nVérifiez votre connexion et réessayez.';
    }
    
    // Erreur serveur
    if (errorLower.contains('server') || errorLower.contains('500')) {
      return 'Le serveur est temporairement indisponible.\n\nVeuillez réessayer dans quelques instants.';
    }
    
    return error;
  }

  void _showSuccessDialog(BuildContext context) {
    // Fermer uniquement les dialogues ouverts, pas les pages de navigation
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst || route is! DialogRoute);

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false, // Empêcher la fermeture avec le bouton retour
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 60,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Inscription réussie !',
                  style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre demande a été envoyée avec succès.\n\nL\'administrateur doit approuver votre compte avant que vous puissiez vous connecter. Vous serez notifié par email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Délai d\'approbation : 24-48h',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      // Réinitialiser l'état d'auth AVANT la navigation
                      ref.read(authProvider.notifier).resetToUnauthenticated();
                      Navigator.of(dialogContext).pop();
                      context.go('/login');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retour à la connexion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      // Éviter les doublons - ne traiter que si l'état a changé
      if (previous?.status == next.status) return;
      
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Fermer uniquement les dialogues ouverts, jamais les pages
          Navigator.of(context, rootNavigator: true)
              .popUntil((route) => route.isFirst || route is! DialogRoute);

          // Revalider le formulaire pour afficher les erreurs de champ serveur
          if (next.hasFieldErrors) {
            _formKey1.currentState?.validate();
            _formKey2.currentState?.validate();
          }

          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Échec de l\'inscription')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getReadableErrorMessage(next.errorMessage!),
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  if (next.hasFieldErrors) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Corrigez les champs en erreur indiqués en rouge',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(authProvider.notifier).clearError();
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Compris'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).then((_) {
            if (ref.read(authProvider).status == AuthStatus.error) {
              ref.read(authProvider.notifier).clearError();
            }
          });
        }); // fin addPostFrameCallback
      } else if (next.status == AuthStatus.registered) {
        // Inscription réussie - afficher le dialogue de succès
        _showSuccessDialog(context);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.teal[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Logo + titre
              _buildPageHeader(context, isDark),
              const SizedBox(height: 20),

              // Indicateur d'étapes
              _buildStepIndicator(context, isDark),
              const SizedBox(height: 20),

              // Carte contenu des étapes (IndexedStack = toutes en mémoire)
              Card(
                elevation: isDark ? 0 : 4,
                color: isDark ? AppColors.darkCard : Colors.white,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildStep1(context, isDark),
                      _buildStep2(context, isDark),
                      _buildStep3(context, isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Boutons de navigation
              _buildNavigationButtons(context, isDark, isLoading),
              const SizedBox(height: 16),

              // Lien "Déjà un compte ?"
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Vous avez déjà un compte ?",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════
  Widget _buildPageHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Création de compte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.teal[900],
                ),
              ),
              Text(
                'Rejoignez le réseau DR-PHARMA',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.teal[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // INDICATEUR D'ÉTAPES
  // ═══════════════════════════════════════════════════
  Widget _buildStepIndicator(BuildContext context, bool isDark) {
    return RegistrationStepIndicator(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      stepLabels: const ['Identité', 'Pharmacie', 'Localisation'],
      isDark: isDark,
    );
  }

  // ═══════════════════════════════════════════════════
  // ÉTAPE 1 : IDENTITÉ
  // ═══════════════════════════════════════════════════
  Widget _buildStep1(BuildContext context, bool isDark) {
    return Form(
      key: _formKey1,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Votre identité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.teal[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informations personnelles du pharmacien titulaire',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration('Nom complet', Icons.person_outline,
                serverError: _getServerError('name')),
            onChanged: (_) => _onFieldChanged('name'),
            validator: (value) {
              final serverError = _getServerError('name');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer votre nom complet';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration('Adresse email', Icons.email_outlined,
                serverError: _getServerError('email')),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onFieldChanged('email'),
            validator: (value) {
              final serverError = _getServerError('email');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer un email';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          PharmacyPasswordField(
            controller: _passwordController,
            labelText: 'Mot de passe',
            showStrengthIndicator: true,
            minLength: 8,
            validator: (value) {
              final serverError = _getServerError('password');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez choisir un mot de passe';
              if (value.length < 8) return 'Le mot de passe doit faire au moins 8 caractères';
              return null;
            },
          ),
          const SizedBox(height: 16),

          PharmacyPasswordField(
            controller: _confirmPasswordController,
            labelText: 'Confirmer le mot de passe',
            showStrengthIndicator: false,
            validator: (value) {
              if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ÉTAPE 2 : PHARMACIE
  // ═══════════════════════════════════════════════════
  Widget _buildStep2(BuildContext context, bool isDark) {
    return Form(
      key: _formKey2,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Votre pharmacie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.teal[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informations officielles de l\'établissement',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _pharmacyNameController,
            decoration: _buildInputDecoration('Nom de la pharmacie', Icons.store_rounded,
                serverError: _getServerError('pharmacy_name')),
            onChanged: (_) => _onFieldChanged('pharmacy_name'),
            validator: (value) {
              final serverError = _getServerError('pharmacy_name');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer le nom de la pharmacie';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _licenseController,
            decoration: _buildInputDecoration('Numéro de licence', Icons.badge_outlined,
                serverError: _getServerError('license')),
            onChanged: (_) => _onFieldChanged('license'),
            validator: (value) {
              final serverError = _getServerError('license');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer le numéro de licence';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            decoration: _buildInputDecoration('Numéro de téléphone', Icons.phone_outlined,
                serverError: _getServerError('phone')).copyWith(
              prefixText: '+225 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              hintText: '07 00 00 00 00',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _onFieldChanged('phone'),
            validator: (value) {
              final serverError = _getServerError('phone');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer un numéro de téléphone';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _cityController,
            decoration: _buildInputDecoration('Ville', Icons.location_city,
                serverError: _getServerError('city')),
            onChanged: (_) => _onFieldChanged('city'),
            validator: (value) {
              final serverError = _getServerError('city');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer la ville';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: _buildInputDecoration('Adresse complète', Icons.location_on_outlined,
                serverError: _getServerError('address')),
            maxLines: 2,
            onChanged: (_) => _onFieldChanged('address'),
            validator: (value) {
              final serverError = _getServerError('address');
              if (serverError != null) return serverError;
              if (value == null || value.isEmpty) return 'Veuillez entrer une adresse';
              return null;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ÉTAPE 3 : LOCALISATION GPS
  // ═══════════════════════════════════════════════════
  Widget _buildStep3(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Localisation de la pharmacie',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.teal[900],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Placez-vous dans votre pharmacie et détectez automatiquement sa position GPS.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 24),

        // Illustration / icône GPS grande
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _latitude != null
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _latitude != null ? Icons.check_circle_rounded : Icons.location_on_rounded,
              size: 56,
              color: _latitude != null ? Colors.green : Colors.teal,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Bouton de détection
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _detectLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_latitude != null ? Icons.refresh : Icons.gps_fixed, size: 20),
            label: Text(
              _isLocating
                  ? 'Détection en cours...'
                  : _latitude != null
                      ? 'Actualiser la position'
                      : 'Détecter ma position',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _latitude != null ? Colors.green : Colors.teal,
              side: BorderSide(color: _latitude != null ? Colors.green : Colors.teal, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Coordonnées détectées
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Position enregistrée : ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 13, color: Colors.green[800]),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Erreur de localisation
        if (_locationError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_locationError!,
                      style: TextStyle(fontSize: 13, color: Colors.red[700])),
                ),
              ],
            ),
          ),
        ],

        if (_hasSubmitted && _latitude == null && _locationError == null) ...[
          const SizedBox(height: 12),
          Text(
            'La position GPS est obligatoire pour finaliser l\'inscription',
            style: TextStyle(fontSize: 12, color: Colors.red[600]),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // BOUTONS DE NAVIGATION
  // ═══════════════════════════════════════════════════
  Widget _buildNavigationButtons(BuildContext context, bool isDark, bool isLoading) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _totalSteps - 1;

    return Row(
      children: [
        // Bouton Précédent
        if (!isFirstStep) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Précédent'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Bouton Suivant ou S'inscrire
        Expanded(
          flex: isFirstStep ? 1 : 2,
          child: FilledButton.icon(
            onPressed: isLoading ? null : () {
              if (isLastStep) {
                _submit();
              } else {
                _goToNextStep();
              }
            },
            icon: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(
              isLoading
                  ? 'Inscription...'
                  : isLastStep
                      ? "S'inscrire"
                      : 'Suivant',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _goToNextStep() {
    bool valid = false;
    switch (_currentStep) {
      case 0:
        valid = _formKey1.currentState?.validate() ?? false;
        break;
      case 1:
        valid = _formKey2.currentState?.validate() ?? false;
        break;
      default:
        valid = true;
    }
    if (valid) {
      setState(() => _currentStep++);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {String? serverError}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = serverError != null;
    
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: hasError 
            ? Colors.red[700] 
            : (isDark ? Colors.grey[400] : null),
      ),
      prefixIcon: Icon(
        icon, 
        color: hasError 
            ? Colors.red[600] 
            : (isDark ? Colors.teal[300] : Colors.teal[600]),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: isDark,
      fillColor: hasError 
          ? Colors.red.withValues(alpha: 0.05) 
          : (isDark ? AppColors.darkSurface : null),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError 
              ? Colors.red.shade400 
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: hasError ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.teal, 
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

