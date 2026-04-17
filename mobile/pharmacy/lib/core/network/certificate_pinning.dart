import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning pour protéger les communications API
/// contre les attaques MITM (Man-In-The-Middle).
///
/// Vérifie l'empreinte SHA-256 du certificat serveur.
/// En mode debug, le pinning est désactivé pour le développement local.
class CertificatePinning {
  CertificatePinning._();

  /// Empreintes SHA-256 des certificats serveur de confiance.
  /// Mettre à jour lors du renouvellement des certificats.
  ///
  /// Pour obtenir l'empreinte d'un certificat :
  /// ```bash
  /// openssl s_client -connect drlpharma.pro:443 -servername drlpharma.pro < /dev/null 2>/dev/null \
  ///   | openssl x509 -outform DER \
  ///   | openssl dgst -sha256 -hex
  /// ```
  static const List<String> _trustedFingerprints = [
    // Certificat leaf drlpharma.pro (à renouveler avec le certificat)
    'fc45963526155f53c5b33320da6a823cab863233c327cd7aa1274f28c0c9b23a',
    // Certificat intermédiaire CA (backup)
    '131fce7784016899a5a00203a9efc80f18ebbd75580717edc1553580930836ec',
  ];

  /// Applique le certificate pinning sur l'instance Dio.
  /// Désactivé en mode debug pour faciliter le développement.
  static void apply(Dio dio) {
    // Skip en debug (développement local, proxy Charles/Fiddler, etc.)
    if (kDebugMode) return;

    // Skip si aucune empreinte configurée (évite de bloquer en prod avant config)
    if (_trustedFingerprints.isEmpty) {
      debugPrint(
        '⚠️ [CertPinning] Aucune empreinte configurée — pinning inactif',
      );
      return;
    }

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // Intercepter la vérification SSL
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            return _verifyCertificate(cert, host);
          };
      return client;
    };
  }

  /// Vérifie l'empreinte SHA-256 du certificat contre les empreintes de confiance.
  static bool _verifyCertificate(X509Certificate cert, String host) {
    try {
      final fingerprint = sha256.convert(cert.der).toString();
      final trusted = _trustedFingerprints.contains(fingerprint);
      if (!trusted) {
        debugPrint('🔒 [CertPinning] Certificat rejeté pour $host');
        debugPrint('   Empreinte reçue: $fingerprint');
      }
      return trusted;
    } catch (e) {
      debugPrint('🔒 [CertPinning] Erreur de vérification: $e');
      return false;
    }
  }
}
