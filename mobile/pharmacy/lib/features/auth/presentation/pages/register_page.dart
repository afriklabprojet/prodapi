import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Owner Name
  final _pharmacyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // GPS coordinates
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationError;
  
  // Track if the form has been submitted at least once
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
    
    // Empêcher les soumissions multiples
    if (authState.status == AuthStatus.loading) {
      ErrorSnackBar.showWarning(
        context,
        'Inscription en cours, veuillez patienter...',
      );
      return;
    }
    
    // Vérifier les coordonnées GPS obligatoires
    if (_latitude == null || _longitude == null) {
      ErrorSnackBar.showWarning(
        context,
        'Veuillez détecter la position GPS de votre pharmacie',
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
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
      // Afficher un message pour les erreurs de validation
      ErrorSnackBar.showWarning(
        context,
        'Veuillez corriger les erreurs du formulaire',
      );
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
    // S'assurer qu'aucun dialogue n'est ouvert
    if (Navigator.of(context).canPop()) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    }
    
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
        // Fermer tout dialogue existant d'abord
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst || route is! DialogRoute);
        
        // ✅ Revalider le formulaire pour afficher les erreurs de champ serveur
        if (next.hasFieldErrors) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _formKey.currentState?.validate();
          });
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
                  // ✅ FIX: Réinitialiser l'état d'erreur pour permettre de réessayer
                  // sans que le routeur ne redirige vers login
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
          // ✅ FIX: Aussi réinitialiser si le dialogue est fermé autrement (tap outside)
          if (ref.read(authProvider).status == AuthStatus.error) {
            ref.read(authProvider.notifier).clearError();
          }
        });
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48), // Top spacing
              // Header with Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Création de compte',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : Colors.teal[900],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rejoignez le réseau DR-PHARMA',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.teal[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Form
              Card(
                elevation: isDark ? 0 : 4,
                color: isDark ? AppColors.darkCard : Colors.white,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nom du propriétaire
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration(
                            'Nom du pharmacien titulaire',
                            Icons.person_outline,
                            serverError: _getServerError('name'),
                          ),
                          onChanged: (_) => _onFieldChanged('name'),
                          validator: (value) {
                            final serverError = _getServerError('name');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre nom complet';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Nom de la pharmacie
                        TextFormField(
                          controller: _pharmacyNameController,
                          decoration: _buildInputDecoration(
                            'Nom de la pharmacie',
                            Icons.store_rounded,
                            serverError: _getServerError('pharmacy_name'),
                          ),
                          onChanged: (_) => _onFieldChanged('pharmacy_name'),
                          validator: (value) {
                            final serverError = _getServerError('pharmacy_name');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom de la pharmacie';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // License Number
                        TextFormField(
                          controller: _licenseController,
                          decoration: _buildInputDecoration(
                            'Numéro de licence',
                            Icons.badge_outlined,
                            serverError: _getServerError('license'),
                          ),
                          onChanged: (_) => _onFieldChanged('license'),
                          validator: (value) {
                            final serverError = _getServerError('license');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le numéro de licence';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration(
                            'Adresse Email',
                            Icons.email_outlined,
                            serverError: _getServerError('email'),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _onFieldChanged('email'),
                          validator: (value) {
                            final serverError = _getServerError('email');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Téléphone
                        TextFormField(
                          controller: _phoneController,
                          decoration: _buildInputDecoration(
                            'Numéro de téléphone',
                            Icons.phone_outlined,
                            serverError: _getServerError('phone'),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => _onFieldChanged('phone'),
                          validator: (value) {
                            final serverError = _getServerError('phone');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un numéro de téléphone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Ville
                        TextFormField(
                          controller: _cityController,
                          decoration: _buildInputDecoration(
                            'Ville',
                            Icons.location_city,
                            serverError: _getServerError('city'),
                          ),
                          onChanged: (_) => _onFieldChanged('city'),
                          validator: (value) {
                            final serverError = _getServerError('city');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la ville';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Adresse
                        TextFormField(
                          controller: _addressController,
                          decoration: _buildInputDecoration(
                            'Adresse complète',
                            Icons.location_on_outlined,
                            serverError: _getServerError('address'),
                          ),
                          maxLines: 2,
                          onChanged: (_) => _onFieldChanged('address'),
                          validator: (value) {
                            final serverError = _getServerError('address');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une adresse';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // === LOCALISATION GPS ===
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _latitude != null 
                                ? Colors.green.withValues(alpha: 0.05)
                                : (_hasSubmitted && _latitude == null)
                                    ? Colors.red.withValues(alpha: 0.05)
                                    : Colors.teal.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _latitude != null 
                                  ? Colors.green.shade300
                                  : (_hasSubmitted && _latitude == null)
                                      ? Colors.red.shade400
                                      : Colors.teal.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _latitude != null ? Icons.check_circle : Icons.my_location,
                                    color: _latitude != null ? Colors.green : Colors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Position GPS de la pharmacie *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _latitude != null 
                                            ? Colors.green[800]
                                            : (_hasSubmitted && _latitude == null)
                                                ? Colors.red[700]
                                                : Colors.teal[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Placez-vous dans votre pharmacie et appuyez sur le bouton pour détecter automatiquement la position.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Bouton de détection
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _isLocating ? null : _detectLocation,
                                  icon: _isLocating
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(
                                          _latitude != null ? Icons.refresh : Icons.gps_fixed,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _isLocating
                                        ? 'Détection en cours...'
                                        : _latitude != null
                                            ? 'Actualiser la position'
                                            : 'Détecter ma position',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _latitude != null ? Colors.green : Colors.teal,
                                    side: BorderSide(
                                      color: _latitude != null ? Colors.green : Colors.teal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              // Coordonnées détectées
                              if (_latitude != null && _longitude != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check, color: Colors.green, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[800],
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Erreur de localisation
                              if (_locationError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _locationError!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                              // Message d'erreur si pas de GPS à la soumission
                              if (_hasSubmitted && _latitude == null && _locationError == null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'La position GPS est obligatoire pour l\'inscription',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration(
                            'Mot de passe',
                            Icons.lock_outline,
                            serverError: _getServerError('password'),
                          ),
                          obscureText: true,
                          onChanged: (_) => _onFieldChanged('password'),
                          validator: (value) {
                            final serverError = _getServerError('password');
                            if (serverError != null) return serverError;
                            if (value == null || value.isEmpty) {
                              return 'Veuillez choisir un mot de passe';
                            }
                            if (value.length < 8) {
                              return 'Le mot de passe doit faire au moins 8 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmation Mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: _buildInputDecoration(
                            'Confirmer le mot de passe',
                            Icons.lock_outline,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Bouton Valider
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Inscription en cours...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "S'inscrire",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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

