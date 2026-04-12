/// Service de Certificate Pinning pour sécuriser les connexions HTTPS
/// Protège contre les attaques MITM (Man-in-the-Middle)
library;

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../services/app_logger.dart';
import '../config/env_config.dart';

/// Configuration du Certificate Pinning
///
/// Pour générer les hashes des certificats:
/// 1. Obtenir le certificat: `openssl s_client -servername api.drlpharma.pro -connect api.drlpharma.pro:443 < /dev/null 2>/dev/null | openssl x509 -outform DER > cert.der`
/// 2. Générer le hash: `openssl dgst -sha256 -binary cert.der | openssl base64`
///
/// Ou utiliser: https://www.ssllabs.com/ssltest/
class CertificatePinningConfig {
  /// SHA-256 hashes des certificats autorisés (format base64)
  /// Inclure le certificat actuel ET le backup pour permettre la rotation
  ///
  /// IMPORTANT: Mettre à jour ces hashes 30 jours AVANT l'expiration du certificat
  /// Date d'expiration à documenter dans le README
  static List<String> get pinnedCertificateHashes {
    final env = EnvConfig.environment;

    switch (env) {
      case 'production':
        return const [
          // ========================================
          // CERTIFICATS PRODUCTION DR-PHARMA API
          // ========================================
          //
          // Pour régénérer ces hashes, exécuter depuis le terminal:
          //   ./scripts/fetch_cert_hashes.sh drlpharma.pro
          //
          // Certificat leaf — CN=drlpharma.pro (Let's Encrypt R12)
          // Expiration: 20 mai 2026
          // ⚠️ Régénérer 30 jours AVANT l'expiration (avant le 20 avril 2026)
          'sha256/OBpQ2b6UyKU5qAq+3lMQ2YCx0Neq6CalGQ5i7IQgoNE=',

          // Certificat intermédiaire — CN=R12 (Let's Encrypt)
          // Issuer: ISRG Root X1 — reste stable entre renouvellements leaf
          'sha256/kZwN96eHtZftBWrOZUsd6cA4es80n3NzSk/XtYz2EqQ=',

          // ISRG Root X1 (root CA) — très stable, change rarement
          'sha256/C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=',
        ];

      case 'staging':
        return const [
          // Certificats staging (peut être self-signed)
          'sha256/STAGING_CERT_HASH_HERE=====================',
        ];

      default:
        // Development: pas de pinning, certificats locaux acceptés
        return const [];
    }
  }

  /// Domaines autorisés pour le pinning
  static List<String> get pinnedDomains {
    final env = EnvConfig.environment;

    switch (env) {
      case 'production':
        return const ['drlpharma.pro', 'www.drlpharma.pro'];

      case 'staging':
        return const ['staging-api.drlpharma.pro', 'staging.drlpharma.pro'];

      default:
        return const []; // Pas de pinning en dev
    }
  }

  /// Active/désactive le pinning selon l'environnement
  static bool get isEnabled {
    final env = EnvConfig.environment;

    // Pinning est activé en production et staging si des hashes sont configurés
    if (env == 'production' || env == 'staging') {
      final hasRealHashes =
          pinnedCertificateHashes.isNotEmpty &&
          !pinnedCertificateHashes.any((h) => h.contains('PLACEHOLDER'));

      if (!hasRealHashes) {
        AppLogger.warning(
          '[CertPinning] Disabled in $env - configure real certificate hashes!',
        );
        return false;
      }
      return true;
    }

    // Disabled in development
    return false;
  }

  /// Retourne les informations de configuration pour le debugging
  static Map<String, dynamic> get debugInfo => {
    'enabled': isEnabled,
    'environment': EnvConfig.environment,
    'pinnedDomains': pinnedDomains,
    'hashCount': pinnedCertificateHashes.length,
  };
}

/// Service de Certificate Pinning
class CertificatePinningService {
  CertificatePinningService._();

  /// Configure le certificate pinning sur un client Dio
  static void configureDio(Dio dio) {
    if (!CertificatePinningConfig.isEnabled) {
      AppLogger.info('[CertPinning] Skipping certificate pinning (debug mode)');
      return;
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        // Configurer la validation du certificat
        client
            .badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Vérifier si le domaine est dans la liste des domaines pinnés
          final isPinnedDomain = CertificatePinningConfig.pinnedDomains.any(
            (domain) => host.endsWith(domain),
          );

          if (!isPinnedDomain) {
            // Domaine non pinné, accepter le certificat standard
            AppLogger.debug('[CertPinning] Non-pinned domain: $host');
            return false; // Laisser la validation standard
          }

          // Vérifier le hash du certificat (avec préfixe sha256/ pour correspondre à la config)
          final certHash = _computeCertificateHash(cert);
          final isValid = CertificatePinningConfig.pinnedCertificateHashes
              .contains('sha256/$certHash');

          if (!isValid) {
            AppLogger.error(
              '[CertPinning] Certificate validation FAILED for $host',
              error:
                  'Hash mismatch. Expected one of: ${CertificatePinningConfig.pinnedCertificateHashes}, got: sha256/$certHash',
            );
          } else {
            AppLogger.debug('[CertPinning] Certificate validated for $host');
          }

          // badCertificateCallback: true = accepter, false = rejeter
          // On accepte si le hash est valide (isValid), on rejette sinon
          return isValid;
        };

        return client;
      },
    );

    AppLogger.info('[CertPinning] Certificate pinning configured');
  }

  /// Calcule le hash SHA-256 du certificat en base64
  static String _computeCertificateHash(X509Certificate certificate) {
    final derBytes = certificate.der;
    final hash = sha256.convert(derBytes);
    return base64.encode(hash.bytes);
  }

  /// Vérifie manuellement un certificat
  static bool verifyCertificate(X509Certificate certificate) {
    final hash = _computeCertificateHash(certificate);
    return CertificatePinningConfig.pinnedCertificateHashes.contains(hash);
  }

  /// Génère le hash d'un certificat pour l'ajouter à la configuration
  /// Utile pour obtenir le hash lors de la configuration initiale
  static String generateCertificateHash(X509Certificate certificate) {
    return _computeCertificateHash(certificate);
  }
}

/// Extension pour faciliter l'ajout du pinning à Dio
extension DioSecurityExtension on Dio {
  /// Active le certificate pinning sur cette instance Dio
  void enableCertificatePinning() {
    CertificatePinningService.configureDio(this);
  }
}

/// Intercepteur Dio pour logging des erreurs de certificat
class CertificatePinningInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.badCertificate) {
      AppLogger.error('[CertPinning] SSL/TLS Error', error: err.message);
      // Transformer en erreur plus explicite
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.badCertificate,
          error: 'Connexion sécurisée impossible. Vérifiez votre réseau.',
          message: 'Certificate pinning validation failed',
        ),
      );
      return;
    }
    handler.next(err);
  }
}
