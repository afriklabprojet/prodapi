import "package:flutter/foundation.dart";
import 'dart:async' show unawaited;
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/state/auth_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SNACKBAR HELPER - Centralized message display
// ══════════════════════════════════════════════════════════════════════════════

/// Helper class for displaying consistent SnackBars throughout the app
class SnackBarHelper {
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: const Color(0xFF1B8F6F),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Parses network errors into user-friendly messages
  static String parseNetworkError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connexion lente. Vérifiez votre connexion internet.';
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Le serveur met trop de temps à répondre. Réessayez.';
        case DioExceptionType.connectionError:
          return 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) return 'Email ou mot de passe incorrect.';
          if (statusCode == 403) return 'Accès refusé. Compte peut-être désactivé.';
          if (statusCode == 404) return 'Service non disponible.';
          if (statusCode == 422) return 'Données invalides. Vérifiez vos informations.';
          if (statusCode != null && statusCode >= 500) {
            return 'Erreur serveur. Réessayez plus tard.';
          }
          return 'Erreur de communication avec le serveur.';
        case DioExceptionType.cancel:
          return 'Requête annulée.';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'Pas de connexion internet.';
          }
          return 'Erreur réseau inattendue.';
        default:
          return 'Erreur de connexion.';
      }
    }
    if (error is SocketException) {
      return 'Pas de connexion internet.';
    }
    return error?.toString() ?? 'Une erreur est survenue.';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PASSWORD STRENGTH ENUM
// ══════════════════════════════════════════════════════════════════════════════

/// Internal enum for password strength visualization
/// Provides color, label, icon, progress and border styling for each level
enum _PasswordStrength {
  empty,
  tooShort,
  weak,
  medium,
  strong;

  /// Main color for progress bar and text
  Color get color => switch (this) {
    _PasswordStrength.empty => Colors.grey.shade300,
    _PasswordStrength.tooShort => Colors.red.shade400,
    _PasswordStrength.weak => Colors.orange.shade400,
    _PasswordStrength.medium => Colors.amber.shade600,
    _PasswordStrength.strong => const Color(0xFF1B8F6F), // _primaryColor
  };

  /// Border color for password field (slightly lighter than main color)
  Color get borderColor => switch (this) {
    _PasswordStrength.empty => Colors.grey.shade200,
    _PasswordStrength.tooShort => Colors.red.shade300,
    _PasswordStrength.weak => Colors.orange.shade300,
    _PasswordStrength.medium => Colors.amber.shade400,
    _PasswordStrength.strong => const Color(0xFF1B8F6F),
  };

  /// User-friendly label in French
  String get label => switch (this) {
    _PasswordStrength.empty => '',
    _PasswordStrength.tooShort => 'Trop court',
    _PasswordStrength.weak => 'Faible',
    _PasswordStrength.medium => 'Moyen',
    _PasswordStrength.strong => 'Fort',
  };

  /// Icon to display next to the label
  IconData? get icon => switch (this) {
    _PasswordStrength.empty => null,
    _PasswordStrength.tooShort => Icons.error_outline,
    _PasswordStrength.weak => Icons.warning_amber_rounded,
    _PasswordStrength.medium => Icons.info_outline,
    _PasswordStrength.strong => Icons.check_circle,
  };

  /// Progress value for LinearProgressIndicator (0.0 to 1.0)
  double get progress => switch (this) {
    _PasswordStrength.empty => 0.0,
    _PasswordStrength.tooShort => 0.15,
    _PasswordStrength.weak => 0.35,
    _PasswordStrength.medium => 0.65,
    _PasswordStrength.strong => 1.0,
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Login page for DR-PHARMA Pharmacy application.
/// Uses Riverpod for state management and GoRouter for navigation.
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
  static const _primaryColor = Color(0xFF1B8F6F);
  static const _primaryDark = Color(0xFF0D5C46);
  
  // High contrast colors for accessibility (WCAG AA compliant)
  static const _rememberMeKey = 'pharmacy_remember_me';
  static const _savedEmailKey = 'pharmacy_saved_email';
  static const _minPasswordLength = 6;

  // RFC 5322 compliant email regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

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
  // STATE
  // ══════════════════════════════════════════════════════════════════════════
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isNavigating = false;
  bool _isShowingError = false;
  bool _isSubmitting = false;
  bool _showLoadingOverlay = false;
  bool _isEmailValid = false;
  bool _disposed = false;
  bool _shouldAutofocusEmail = true; // Will be set to false if email is pre-filled
  
  // Password strength tracking
  _PasswordStrength _passwordStrength = _PasswordStrength.empty;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedCredentials();
    _setupEmailValidationListener();
    _setupPasswordStrengthListener();
    // Auth listener is now setup via ref.listen in build() method
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Dispose animations
    _animController.dispose();
    
    // Dispose focus nodes (in reverse order of creation)
    _passwordFocus.dispose();
    _emailFocus.dispose();
    
    // Dispose controllers (in reverse order of creation)
    _passwordController.dispose();
    _emailController.dispose();
    
    super.dispose();
  }

  /// Safe setState that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS SETUP
  // ══════════════════════════════════════════════════════════════════════════
  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade animation for general appearance
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Scale animation for logo
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Slide animation for form card
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && mounted) {
        _animController.forward();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMAIL VALIDATION LISTENER
  // ══════════════════════════════════════════════════════════════════════════
  void _setupEmailValidationListener() {
    _emailController.addListener(() {
      final email = _emailController.text.trim();
      final isValid = _emailRegex.hasMatch(email);
      if (_isEmailValid != isValid) {
        _safeSetState(() => _isEmailValid = isValid);
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PASSWORD STRENGTH LISTENER
  // ══════════════════════════════════════════════════════════════════════════
  void _setupPasswordStrengthListener() {
    _passwordController.addListener(() {
      final password = _passwordController.text;
      final newStrength = _calculatePasswordStrength(password);
      if (_passwordStrength != newStrength) {
        _safeSetState(() => _passwordStrength = newStrength);
      }
    });
  }

  _PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.empty;
    if (password.length < _minPasswordLength) return _PasswordStrength.tooShort;
    
    int score = 0;
    // Length bonus
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    // Complexity checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return _PasswordStrength.weak;
    if (score <= 4) return _PasswordStrength.medium;
    return _PasswordStrength.strong;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH STATE CHANGE HANDLER
  // ══════════════════════════════════════════════════════════════════════════
  void _onAuthStateChanged(AuthState? prev, AuthState next) {
    if (kDebugMode) debugPrint('👂 [LoginPage] _onAuthStateChanged appelé: ${prev?.status} -> ${next.status}');
    if (kDebugMode) debugPrint('👂 [LoginPage] errorMessage: ${next.errorMessage}');
    
    if (_disposed || !mounted) return;

    // Reset submit flag when leaving loading state
    if (next.status != AuthStatus.loading) {
      _safeSetState(() {
        _isSubmitting = false;
        _showLoadingOverlay = false;
      });
    }

    switch (next.status) {
      case AuthStatus.error:
        if (kDebugMode) debugPrint('🚨 [LoginPage] État ERROR détecté!');
        if (next.errorMessage != null || next.originalError != null) {
          _handleError(next.errorMessage, originalError: next.originalError);
        }
      case AuthStatus.authenticated:
        _handleAuthenticated(next);
      case AuthStatus.loading:
        _safeSetState(() => _showLoadingOverlay = true);
      case AuthStatus.initial:
      case AuthStatus.unauthenticated:
      case AuthStatus.registered:
        break;
    }
  }

  void _handleError(String? message, {Object? originalError}) {
    if (kDebugMode) debugPrint('🚨 [LoginPage] _handleError appelé: $message');
    
    if (_disposed || !mounted || _isShowingError) {
      if (kDebugMode) debugPrint('⚠️ [LoginPage] _handleError ignoré: disposed=$_disposed, mounted=$mounted, isShowingError=$_isShowingError');
      return;
    }
    
    _isShowingError = true;

    // Priorité au message de l'API (plus spécifique) plutôt qu'au parsing générique
    final displayMessage = (message != null && message.isNotEmpty)
        ? message
        : (originalError != null
            ? SnackBarHelper.parseNetworkError(originalError)
            : 'Une erreur est survenue');

    if (kDebugMode) debugPrint('📢 [LoginPage] Message à afficher: $displayMessage');

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
      
      // Clear error state after showing
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_disposed) {
          ref.read(authProvider.notifier).clearError();
        }
      });
    }
  }

  void _handleAuthenticated(AuthState state) {
    if (_isNavigating || _disposed || !mounted) return;
    _isNavigating = true;

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
  // CREDENTIALS PERSISTENCE (Only email, never password)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || !mounted) return;

      final remember = prefs.getBool(_rememberMeKey) ?? false;
      final email = prefs.getString(_savedEmailKey) ?? '';

      if (remember && email.isNotEmpty) {
        _safeSetState(() {
          _rememberMe = true;
          _emailController.text = email;
          _isEmailValid = _emailRegex.hasMatch(email);
          _shouldAutofocusEmail = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!_disposed && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
            if (!_disposed && mounted) {
              _passwordFocus.requestFocus();
            }
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed && mounted && _shouldAutofocusEmail) {
            _emailFocus.requestFocus();
          }
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && mounted) {
          SnackBarHelper.showWarning(context, 'Impossible de récupérer vos préférences.');
          if (_shouldAutofocusEmail) {
            _emailFocus.requestFocus();
          }
        }
      });
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_savedEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_savedEmailKey);
      }
    } catch (_) {
      if (_rememberMe && !_disposed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed && mounted) {
            SnackBarHelper.showWarning(context, 'Vos préférences n\'ont pas pu être sauvegardées.');
          }
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM HANDLING
  // ══════════════════════════════════════════════════════════════════════════
  void _handleLogin() {
    if (_isSubmitting || _showLoadingOverlay) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    _safeSetState(() {
      _isSubmitting = true;
      _showLoadingOverlay = true;
    });

    unawaited(_saveCredentials());

    ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  /// Navigate to forgot password page and show success SnackBar on return
  Future<void> _handleForgotPassword(BuildContext context) async {
    // Pre-fill email if available
    final email = _emailController.text.trim();
    final result = await context.push<bool>(
      '/forgot-password',
      extra: email.isNotEmpty ? {'email': email} : null,
    );

    if (!context.mounted) return;

    // Show success SnackBar if reset email was sent
    if (result == true && mounted && !_disposed) {
      SnackBarHelper.showSuccess(
        context,
        'Un email de réinitialisation a été envoyé. Vérifiez votre boîte de réception.',
      );
    }
  }

  /// Smooth transition from email field to password field
  /// Called when user submits email field (presses Enter/Done)
  void _smoothTransitionToPassword() {
    // Small delay for smoother visual transition
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed && mounted) {
        _passwordFocus.requestFocus();
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < _minPasswordLength) {
      return 'Le mot de passe doit contenir au moins $_minPasswordLength caractères';
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (kDebugMode) debugPrint('👂 [LoginPage] ref.listen callback: ${prev?.status} -> ${next.status}');
      _onAuthStateChanged(prev, next);
    });
    
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    
    // Handle error state directly in build as backup
    if (authState.status == AuthStatus.error && !_isShowingError) {
      if (kDebugMode) debugPrint('🔴 [LoginPage] Error detected in build: ${authState.errorMessage}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed && !_isShowingError) {
          _handleError(authState.errorMessage, originalError: authState.originalError);
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildLoginCard(isLoading),
                        const SizedBox(height: 32),
                        _buildCopyright(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Loading overlay
          if (_showLoadingOverlay) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING OVERLAY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoadingOverlay() {
    return AnimatedOpacity(
      opacity: _showLoadingOverlay ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connexion en cours...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Builds an animated widget combining fade, scale, and optional slide effects
  Widget _buildAnimated({
    required Widget child,
    bool withSlide = false,
  }) {
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

  Widget _buildHeader() {
    return _buildAnimated(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
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
          const SizedBox(height: 20),
          const Text(
            'DR-PHARMA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Espace Pharmacie',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return _buildAnimated(
      withSlide: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
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
              const Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez à votre espace pharmacie',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRememberMeRow(),
              const SizedBox(height: 28),
              _buildLoginButton(isLoading),
              const SizedBox(height: 20),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.email],
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
      onFieldSubmitted: (_) => _smoothTransitionToPassword(),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintText: 'exemple@pharmacie.com',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(
          Icons.email_outlined, 
          color: _primaryColor,
          semanticLabel: 'Icône email',
        ),
        // Show check icon when email is valid
        suffixIcon: _isEmailValid
            ? const Icon(
                Icons.check_circle, 
                color: _primaryColor, 
                size: 22,
                semanticLabel: 'Email valide',
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    final hasInput = _passwordController.text.isNotEmpty;
    final strengthColor = _passwordStrength.borderColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _handleLogin(),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            labelStyle: TextStyle(color: Colors.grey.shade600),
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.lock_outlined, 
              color: hasInput ? strengthColor : _primaryColor,
              semanticLabel: 'Icône mot de passe',
            ),
            suffixIcon: Semantics(
              label: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
              button: true,
              child: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  semanticLabel: _obscurePassword ? 'Mot de passe masqué' : 'Mot de passe visible',
                ),
                onPressed: () => _safeSetState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasInput ? strengthColor : Colors.grey.shade200,
                width: hasInput ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasInput ? strengthColor : _primaryColor, 
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          validator: _validatePassword,
        ),
        // Password strength indicator
        if (hasInput) ...[
          const SizedBox(height: 10),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrength.color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          // Label with icon
          Row(
            children: [
              if (_passwordStrength.icon != null) ...[
                Icon(
                  _passwordStrength.icon,
                  size: 14,
                  color: _passwordStrength.color,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                _passwordStrength.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _passwordStrength.color,
                ),
              ),
              const Spacer(),
              if (_passwordStrength == _PasswordStrength.tooShort)
                Text(
                  'Min. $_minPasswordLength caractères',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _safeSetState(() => _rememberMe = !_rememberMe),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => _safeSetState(() => _rememberMe = v ?? false),
                      activeColor: _primaryColor,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: _rememberMe ? _primaryColor : Colors.grey.shade500,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Se souvenir de moi',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: () => _handleForgotPassword(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    final isDisabled = isLoading || _isSubmitting || _showLoadingOverlay;

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
          elevation: isDisabled ? 0 : 3,
          shadowColor: _primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading || _isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  key: ValueKey('text'),
                  'Se connecter',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Vous n'avez pas de compte ?",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            "S'inscrire",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return _buildAnimated(
      child: Text(
        '© ${DateTime.now().year} DR-PHARMA • Tous droits réservés',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}


