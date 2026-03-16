import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/core_providers.dart';

/// Gère la session utilisateur (token, données cache, etc.)
class SessionManager {
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _onboardingKey = 'has_seen_onboarding';

  SessionManager(this._prefs);

  /// Vérifie si l'utilisateur est connecté
  bool get isLoggedIn => _prefs.containsKey(_tokenKey);

  /// Récupère le token d'authentification
  String? get token => _prefs.getString(_tokenKey);

  /// Sauvegarde le token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Sauvegarde les données utilisateur JSON
  Future<void> saveUserData(String userData) async {
    await _prefs.setString(_userKey, userData);
  }

  /// Récupère les données utilisateur JSON
  String? get userData => _prefs.getString(_userKey);

  /// Vérifie si l'onboarding a déjà été vu
  bool get hasSeenOnboarding => _prefs.getBool(_onboardingKey) ?? false;

  /// Marque l'onboarding comme vu
  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Supprime toutes les données de session
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  /// Déconnexion complète
  Future<void> logout() async {
    await clearSession();
  }
}

/// Provider pour le SessionManager
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SessionManager(prefs);
});
