import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/secure_token_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/offline_service.dart';
import '../../core/services/background_location_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_manager.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/jeko_payment_service.dart';
import '../../core/services/infobip_messaging_service.dart';
import 'login_screen_redesign.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'kyc_resubmission_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(seconds: 2),
       vsync: this,
    )..forward();
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    // Lancer l'initialisation complète de manière non-bloquante
    // Le addPostFrameCallback garantit que le premier frame est rendu AVANT
    // tout travail async, ce qui empêche l'ANR Android.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndRoute();
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Point d'entrée unique : initialise tout puis route l'utilisateur.
  /// Timeout global de 10 secondes pour éviter un splash infini.
  Future<void> _initializeAndRoute() async {
    try {
      // .timeout() properly cancels its internal timer when the future completes,
      // unlike Future.any + Future.delayed which leaks an orphan timer.
      await _doInitAndRoute()
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Timeout global — aller au dashboard si token existe, sinon login
      if (!mounted) return;
      if (kDebugMode) debugPrint('⏱️ [Splash] Timeout global 10s — navigation forcée');
      final token = await SecureTokenService.instance.getToken()
          .timeout(const Duration(seconds: 1), onTimeout: () => null);
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        _navigateTo(const DashboardScreen());
      } else {
        _navigateTo(const LoginScreenRedesign());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Splash] Erreur fatale: $e');
      if (mounted) _navigateTo(const LoginScreenRedesign());
    }
  }

  /// Logique principale d'initialisation + routage
  Future<void> _doInitAndRoute() async {
    // ── Phase 1 : Inits critiques en parallèle (avec timeouts individuels) ──
    // Firebase + SharedPreferences + date formatting en même temps
    final results = await Future.wait([
      // Firebase init avec timeout de 4 secondes
      _initFirebase(),
      // SharedPreferences (réutilisé par CacheService et OfflineService)
      _initSharedPreferences(),
      // Date formatting (rapide en général)
      _initDateFormatting(),
    ]);

    if (!mounted) return;

    final SharedPreferences? prefs = results[1] as SharedPreferences?;

    // ── Phase 2 : Services secondaires en parallèle (non-bloquants) ──
    // Lancés en fire-and-forget, ils termineront pendant que l'user navigue
    _initSecondaryServices(prefs);

    // ── Phase 3 : Initialiser connectivité (après que l'UI est visible) ──
    _initConnectivityDeferred();

    // ── Phase 4 : Routage basé sur la session ──
    await _routeUser(prefs);
  }

  /// Initialise Firebase avec un timeout strict
  Future<bool> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 4));
      if (kDebugMode) debugPrint('✅ Firebase initialized');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firebase init failed/timeout: $e');
      return false;
    }
  }

  /// Pré-charge SharedPreferences une seule fois
  Future<SharedPreferences?> _initSharedPreferences() async {
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SharedPreferences init failed: $e');
      return null;
    }
  }

  /// Date formatting (rapide, mais protégé)
  Future<void> _initDateFormatting() async {
    try {
      await initializeDateFormatting('fr_FR', null)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Services secondaires lancés en fire-and-forget
  void _initSecondaryServices(SharedPreferences? prefs) {
    // Injecter les SharedPreferences déjà chargées dans les services
    Future(() async {
      try {
        if (prefs != null) {
          // Injecter directement au lieu de re-charger SharedPreferences
          await CacheService.instance.init();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ CacheService init: $e');
      }
    });

    Future(() async {
      try {
        await OfflineService.instance.init();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ OfflineService init: $e');
      }
    });

    Future(() async {
      try {
        await BackgroundLocationService.initialize();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ BackgroundLocation init: $e');
      }
    });

    Future(() async {
      try {
        await JekoPaymentService.initDeepLinks();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ DeepLinks init: $e');
      }
    });

    // Initialize Infobip Mobile Messaging (non-bloquant)
    Future(() async {
      try {
        await InfobipMessagingService().initialize();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Infobip init: $e');
      }
    });
  }

  /// Initialise la connectivité de manière différée
  void _initConnectivityDeferred() {
    _connectivityTimer = Timer(const Duration(seconds: 2), () {
      try {
        ref.read(connectivityProvider.notifier).checkConnectivity();
        ref.read(syncManagerProvider);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Connectivity init: $e');
      }
    });
  }

  /// Route l'utilisateur basé sur l'état de sa session
  Future<void> _routeUser(SharedPreferences? prefs) async {
    // Petit délai pour que l'animation logo soit visible (minimum 800ms)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // ── Check onboarding ──
    try {
      final onboardingCompleted = prefs?.getBool('courier_onboarding_completed') ?? false;
      if (!onboardingCompleted) {
        _navigateTo(const OnboardingScreen());
        return;
      }
    } catch (_) {}

    // ── Check token ──
    String? token;
    try {
      token = await SecureTokenService.instance.getToken()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // SecureStorage timeout — traiter comme pas de token
    }

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _navigateTo(const LoginScreenRedesign());
      return;
    }

    // ── Token existe → valider le profil avec timeout court ──
    try {
      await ref.read(authRepositoryProvider).getProfile()
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      _navigateTo(const DashboardScreen());
    } on TimeoutException {
      // API lente — aller au dashboard quand même (profil se chargera après)
      if (!mounted) return;
      _navigateTo(const DashboardScreen());
    } catch (e) {
      if (!mounted) return;
      _handleProfileError(e);
    }
  }

  /// Gère les erreurs de profil (pending, suspended, rejected, KYC)
  void _handleProfileError(Object e) {
    final errorMessage = e.toString();
    
    if (errorMessage.contains('PENDING_APPROVAL:')) {
      final message = errorMessage.split('PENDING_APPROVAL:').last.replaceAll('Exception:', '').trim();
      _navigateTo(PendingApprovalScreen(
        status: 'pending_approval',
        message: message.isNotEmpty ? message : 'Votre compte est en attente d\'approbation.',
      ));
      return;
    }
    
    if (errorMessage.contains('INCOMPLETE_KYC:')) {
      final reason = errorMessage.split('INCOMPLETE_KYC:').last.replaceAll('Exception:', '').trim();
      _navigateTo(KycResubmissionScreen(
        rejectionReason: reason.isNotEmpty ? reason : null,
      ));
      return;
    }
    
    if (errorMessage.contains('SUSPENDED:')) {
      final message = errorMessage.split('SUSPENDED:').last.replaceAll('Exception:', '').trim();
      _navigateTo(PendingApprovalScreen(
        status: 'suspended',
        message: message.isNotEmpty ? message : 'Votre compte a été suspendu.',
      ));
      return;
    }
    
    if (errorMessage.contains('REJECTED:')) {
      final message = errorMessage.split('REJECTED:').last.replaceAll('Exception:', '').trim();
      _navigateTo(PendingApprovalScreen(
        status: 'rejected',
        message: message.isNotEmpty ? message : 'Votre demande a été refusée.',
      ));
      return;
    }
    
    // Token invalide ou expiré → nettoyer et aller au login
    SecureTokenService.instance.removeToken().catchError((_) {});
    _navigateTo(const LoginScreenRedesign());
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : Colors.white;
    final r = Responsive.of(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Container(
                    padding: EdgeInsets.all(r.dp(16)),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/logo.png', width: r.dp(80), height: r.dp(80), fit: BoxFit.contain),
                 ),
                 SizedBox(height: r.dp(24)),
                 Text(
                   'DR-PHARMA',
                   style: TextStyle(
                     fontSize: r.sp(32),
                     fontWeight: FontWeight.bold,
                     color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                     letterSpacing: 2.0,
                   ),
                 ),
                 SizedBox(height: r.dp(8)),
                 Text(
                   'LIVREUR',
                   style: TextStyle(
                     fontSize: r.sp(16),
                     letterSpacing: 5.0,
                     color: Colors.blue.shade400,
                   ),
                 ),
                 SizedBox(height: r.dp(48)),
                 SizedBox(
                   width: r.dp(28),
                   height: r.dp(28),
                   child: CircularProgressIndicator(
                     strokeWidth: 2.5,
                     valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                   ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
