import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service d'authentification Firebase pour le livreur.
///
/// Utilise un custom token généré par le backend Laravel
/// pour authentifier le livreur auprès de Firebase.
/// Cela permet l'accès à Firestore (tracking temps réel).
///
/// Inclut un mécanisme de rafraîchissement automatique
/// des tokens Firebase (expiration toutes les heures).
class FirebaseAuthService {
  final FirebaseAuth _auth;

  /// Timer pour le rafraîchissement périodique du token
  Timer? _refreshTimer;

  /// Durée avant expiration du custom token Firebase (1h)
  /// On rafraîchit 5 minutes avant pour éviter les coupures.
  static const Duration _refreshInterval = Duration(minutes: 55);

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// L'utilisateur Firebase actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Est-ce que l'utilisateur est authentifié auprès de Firebase ?
  bool get isAuthenticated => _auth.currentUser != null;

  /// Se connecter avec un custom token généré par le backend.
  ///
  /// Appelé après le login API réussi.
  /// Le [customToken] est fourni dans la réponse du endpoint /api/auth/login.
  Future<bool> signInWithCustomToken(String customToken) async {
    try {
      final credential = await _auth.signInWithCustomToken(customToken);
      if (kDebugMode) {
        debugPrint('🔥 [Firebase Auth] Connecté: uid=${credential.user?.uid}');
      }
      // Démarrer le rafraîchissement automatique
      _startTokenRefreshTimer();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Firebase Auth] Erreur signInWithCustomToken: $e');
      }
      return false;
    }
  }

  /// Se déconnecter de Firebase.
  ///
  /// Appelé lors du logout de l'app.
  Future<void> signOut() async {
    _stopTokenRefreshTimer();
    try {
      await _auth.signOut();
      if (kDebugMode) debugPrint('🔥 [Firebase Auth] Déconnecté');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Firebase Auth] Erreur signOut: $e');
    }
  }

  /// Rafraîchir le token Firebase si nécessaire.
  ///
  /// Les ID tokens Firebase expirent après 1h.
  /// Cette méthode force le rafraîchissement du token.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Firebase Auth] Erreur getIdToken: $e');
      return null;
    }
  }

  /// Rafraîchir le token proactivement.
  ///
  /// Appelé par le timer périodique pour éviter l'expiration.
  Future<void> refreshTokenIfNeeded() async {
    if (_auth.currentUser == null) {
      _stopTokenRefreshTimer();
      return;
    }

    try {
      // Force refresh pour obtenir un nouveau token
      final newToken = await _auth.currentUser?.getIdToken(true);
      if (newToken != null) {
        if (kDebugMode) debugPrint('🔥 [Firebase Auth] Token rafraîchi avec succès');
      } else {
        if (kDebugMode) debugPrint('⚠️ [Firebase Auth] Token null après rafraîchissement');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Firebase Auth] Erreur rafraîchissement token: $e');
      // Si le refresh échoue, c'est probablement que le custom token a expiré
      // L'app devra re-demander un custom token au backend
    }
  }

  /// Démarrer le timer de rafraîchissement automatique
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      refreshTokenIfNeeded();
    });
    if (kDebugMode) {
      debugPrint('🔥 [Firebase Auth] Timer de rafraîchissement démarré (toutes les ${_refreshInterval.inMinutes}min)');
    }
  }

  /// Arrêter le timer de rafraîchissement
  void _stopTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Écouter les changements d'état d'authentification.
  /// Utile pour détecter la déconnexion automatique par Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Nettoyage des ressources
  void dispose() {
    _stopTokenRefreshTimer();
  }
}

/// Provider Riverpod pour le service Firebase Auth
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
