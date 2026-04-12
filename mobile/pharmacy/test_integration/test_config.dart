/// Configuration pour les tests d'intégration
///
/// Ces credentials peuvent être définis via:
/// 1. Variables d'environnement
/// 2. Fichier .env.test (copier depuis .env.test.example)
/// 3. Valeurs par défaut du seeder (dev uniquement)
///
/// Variables d'environnement supportées:
/// - TEST_PHARMACY_EMAIL: email du compte test
/// - TEST_PHARMACY_PASSWORD: mot de passe du compte test
/// - TEST_API_URL: URL de l'API (défaut: https://drlpharma.pro/api)

import 'dart:io';

class TestConfig {
  static Map<String, String>? _envVars;

  /// Charge les variables depuis .env.test si présent
  static void _loadEnvFile() {
    if (_envVars != null) return;
    _envVars = {};

    try {
      final envFile = File('test_integration/.env.test');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty || line.startsWith('#')) continue;
          final parts = line.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            _envVars![key] = value;
          }
        }
      }
    } catch (_) {
      // .env.test not found or unreadable
    }
  }

  static String _getEnv(String key, String defaultValue) {
    _loadEnvFile();
    return Platform.environment[key] ?? _envVars?[key] ?? defaultValue;
  }

  /// URL de base de l'API
  static String get baseUrl =>
      _getEnv('TEST_API_URL', 'https://drlpharma.pro/api');

  /// Credentials de test pour la pharmacie
  static String get testPharmacyEmail => _getEnv('TEST_PHARMACY_EMAIL', '');

  static String get testPharmacyPassword =>
      _getEnv('TEST_PHARMACY_PASSWORD', '');

  /// Vérifie si les credentials de test sont configurés
  static bool get hasCredentials =>
      testPharmacyEmail.isNotEmpty && testPharmacyPassword.isNotEmpty;

  /// Alternative pharmacies pour tests parallèles (si configurées)
  static String get testPharmacy2Email => _getEnv('TEST_PHARMACY2_EMAIL', '');
  static String get testPharmacy3Email => _getEnv('TEST_PHARMACY3_EMAIL', '');

  /// Timeout pour les requêtes
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
