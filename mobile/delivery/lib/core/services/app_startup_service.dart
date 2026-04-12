import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import 'secure_token_service.dart';
import 'cache_service.dart';

/// Route initiale déterminée à l'issue du démarrage.
enum StartupResult {
  /// Premier lancement — afficher l'onboarding.
  onboarding,

  /// Aucune session active — afficher l'écran de connexion.
  unauthenticated,

  /// Session valide — afficher le tableau de bord.
  authenticated,
}

/// Orchestre l'initialisation de l'application au démarrage.
///
/// Principe fondamental : **ZÉRO accès Keystore Android sur le chemin critique**.
///
/// Le Keystore Android (EncryptedSharedPreferences) bloque le thread natif
/// pendant 2-5s sur un cold start (MasterKey init). Deux lectures séquentielles
/// = 4-10s d'écran splash figé = ANR.
///
/// Solution : le routage se fait uniquement via SharedPreferences (instantané).
/// Les lectures Keystore (token + clé Hive) sont lancées en arrière-plan
/// APRÈS la navigation, et se terminent pendant que le Dashboard charge.
///
/// Phase 1 – Critique (parallèle, ~2s) :
///   Firebase, SharedPreferences, formatage de dates.
///
/// Phase 2 – Routage (instantané) :
///   Décision basée sur SharedPreferences uniquement.
///
/// Phase 3 – Warm-up (fire-and-forget, APRÈS navigation) :
///   Token Keystore → cache mémoire, puis CacheService/Hive.
class AppStartupService {
  AppStartupService._();

  SharedPreferences? _prefs;
  bool _firebaseReady = false;
  bool _initialized = false;
  Completer<void>? _initCompleter;

  /// SharedPreferences chargées lors de l'init.
  SharedPreferences? get prefs => _prefs;

  /// `true` si Firebase a été initialisé avec succès.
  bool get isFirebaseReady => _firebaseReady;

  /// `true` une fois l'initialisation critique terminée.
  bool get isInitialized => _initialized;

  /// Initialise les services critiques et résout la route.
  ///
  /// RAPIDE (~2s) : aucune lecture Keystore. Le routage est basé
  /// uniquement sur SharedPreferences (flag `has_auth_token`).
  ///
  /// Thread-safe via [Completer].
  Future<StartupResult> initialize() async {
    if (_initialized) return _resolveRoute();

    if (_initCompleter != null) {
      await _initCompleter!.future;
      return _resolveRoute();
    }

    _initCompleter = Completer<void>();
    try {
      await _runCriticalInit();
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }

    return _resolveRoute();
  }

  /// Lance le warm-up des services Keystore en arrière-plan.
  ///
  /// Appelé APRÈS la navigation (depuis le splash), pour que les
  /// lectures Keystore se fassent pendant que le Dashboard charge.
  /// Le token sera prêt quand l'AuthInterceptor en aura besoin.
  void warmUpSecureServices() {
    // Token Keystore → cache mémoire (lu 1 seule fois).
    // L'AuthInterceptor attend ce résultat via le Completer.
    SecureTokenService.instance.getToken().then((_) {
      // Après le token, initialiser CacheService (2e lecture Keystore).
      // Séquentiel → pas de concurrence Keystore.
      CacheService.instance.init().catchError((e) {
        if (kDebugMode) debugPrint('[Startup] Cache warm-up failed: $e');
      });
    }).catchError((e) {
      if (kDebugMode) debugPrint('[Startup] Token warm-up failed: $e');
      // Même si le token échoue, tenter le cache (peut fonctionner).
      CacheService.instance.init().catchError((_) {});
    });
  }

  // ── Phase 1 : Init critique (sans Keystore) ──────────

  Future<void> _runCriticalInit() async {
    final results = await Future.wait([
      _initFirebase(),
      _initSharedPreferences(),
      _initDateFormatting(),
    ]);
    _firebaseReady = results[0] as bool;
    _prefs = results[1] as SharedPreferences?;
  }

  // ── Résolution de la route ────────────────────────

  StartupResult _resolveRoute() {
    // Pas de SharedPreferences → impossible de vérifier l'onboarding.
    // Sécurité : on montre l'onboarding plutôt que de perdre l'utilisateur.
    if (_prefs == null) return StartupResult.onboarding;

    final onboarded = _prefs!.getBool('courier_onboarding_completed') ?? false;
    if (!onboarded) return StartupResult.onboarding;

    // Vérification INSTANTANÉE via SharedPreferences (pas de Keystore).
    // Ce flag est synchronisé par SecureTokenService.setToken()/removeToken().
    if (SecureTokenService.hasTokenSync(_prefs!)) {
      return StartupResult.authenticated;
    }

    return StartupResult.unauthenticated;
  }

  // ── Helpers Phase 1 ───────────────────────────────

  Future<bool> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Startup] Firebase init failed: $e');
      return false;
    }
  }

  Future<SharedPreferences?> _initSharedPreferences() async {
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (kDebugMode) debugPrint('[Startup] SharedPreferences failed: $e');
      return null;
    }
  }

  Future<void> _initDateFormatting() async {
    try {
      await initializeDateFormatting('fr_FR', null)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Non critique — les dates s'afficheront en format par défaut.
    }
  }
}

/// Singleton applicatif exposé via Riverpod.
final appStartupProvider = Provider<AppStartupService>((ref) {
  return AppStartupService._();
});
