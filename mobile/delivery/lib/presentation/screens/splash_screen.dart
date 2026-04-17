import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/app_startup_service.dart';
import '../../core/services/secure_token_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_manager.dart';
import '../../data/services/jeko_payment_service.dart';
import '../../core/router/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Rendre le premier frame AVANT tout travail async → anti-ANR.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Orchestration ───────────────────────────────────

  /// Point d'entrée unique.
  ///
  /// Timeout global de 8s. Aucune lecture Keystore Android ici.
  /// Le startup fait uniquement : Firebase + SharedPrefs + DateFormat (~2s).
  /// Le routage est basé sur SharedPreferences (instantané).
  Future<void> _run() async {
    try {
      await _initAndRoute().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      if (kDebugMode) debugPrint('[Splash] Timeout global — fallback');
      _fallbackRoute();
    } catch (e) {
      if (kDebugMode) debugPrint('[Splash] Erreur fatale: $e');
      if (mounted) _navigateTo(AppRoutes.login);
    }
  }

  Future<void> _initAndRoute() async {
    // ── Étape 1 : Services critiques (~2s, SANS Keystore) ──
    final startup = ref.read(appStartupProvider);
    final result = await startup.initialize();

    if (!mounted) return;

    // ── Étape 2 : Warm-up Keystore en arrière-plan ──
    // Token + CacheService se chargent pendant que le Dashboard charge.
    // L'AuthInterceptor attendra le token via le Completer.
    startup.warmUpSecureServices();

    // ── Étape 3 : Services secondaires (fire-and-forget, différés) ──
    _launchSecondaryServices();

    // ── Étape 4 : Afficher le logo un minimum ──
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // ── Étape 5 : Routage (basé sur SharedPreferences, instantané) ──
    switch (result) {
      case StartupResult.onboarding:
        _navigateTo(AppRoutes.onboarding);

      case StartupResult.unauthenticated:
        _navigateTo(AppRoutes.login);

      case StartupResult.authenticated:
        // Pas de validation API ici ! Le Dashboard gère le chargement
        // du profil et les erreurs (401, PENDING_APPROVAL, etc.).
        _navigateTo(AppRoutes.dashboard);
    }
  }

  // ── Services secondaires (non-bloquants, différés) ──

  void _launchSecondaryServices() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      try {
        ref.read(connectivityProvider.notifier).checkConnectivity();
        ref.read(syncManagerProvider);
        JekoPaymentService.initDeepLinks();
      } catch (_) {}
    });
  }

  // ── Fallback si timeout global ──────────────────────

  void _fallbackRoute() {
    if (!mounted) return;
    // SharedPreferences peut être disponible même si Firebase a timeout.
    final startup = ref.read(appStartupProvider);
    final prefs = startup.prefs;

    if (prefs != null && SecureTokenService.hasTokenSync(prefs)) {
      _navigateTo(AppRoutes.dashboard);
    } else {
      _navigateTo(AppRoutes.login);
    }
  }

  // ── Navigation ──────────────────────────────────────

  void _navigateTo(String route) {
    if (!mounted) return;
    context.go(route);
  }

  // ── UI ──────────────────────────────────────────────

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
                    border: Border.all(
                      color: const Color(0xFF54AB70).withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF54AB70).withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: r.dp(80),
                    height: r.dp(80),
                    cacheWidth: 160,
                    cacheHeight: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: r.dp(24)),
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
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                SizedBox(height: r.dp(8)),
                Text(
                  'LIVREUR',
                  style: TextStyle(
                    fontSize: r.sp(16),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5.0,
                    color: const Color(0xFF54AB70),
                  ),
                ),
                SizedBox(height: r.dp(48)),
                SizedBox(
                  width: r.dp(28),
                  height: r.dp(28),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF54AB70),
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
}
