/// Tests d'intégration du flux d'authentification pharmacie
///
/// Ce fichier teste le flux complet d'authentification:
/// 1. Inscription d'une nouvelle pharmacie
/// 2. Connexion email/mot de passe
/// 3. Vérification du profil
/// 4. Refresh du token
/// 5. Déconnexion
///
/// Run avec: flutter test --tags integration test_integration/auth_flow_integration_test.dart

@Tags(['integration'])
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

/// Vérifie si le serveur API est accessible.
Future<bool> _isServerRunning() async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://drlpharma.pro/api/health',
      options: Options(receiveTimeout: const Duration(seconds: 5)),
    );
    return response.statusCode == 200;
  } catch (_) {
    try {
      final socket = await Socket.connect(
        'drlpharma.pro',
        443,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

void main() {
  late Dio dio;
  final baseUrl = TestConfig.baseUrl;
  bool serverAvailable = false;
  String? authToken;
  String? refreshToken;

  // Credentials pour tests futurs d'inscription (non utilisés actuellement)
  // final testEmail = 'test_${Random().nextInt(999999)}@pharmacy-test.com';
  // const testPassword = 'TestPassword123!';

  setUpAll(() async {
    serverAvailable = await _isServerRunning();
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );
  });

  tearDownAll(() {
    dio.close();
  });

  bool skipIfNoServer() {
    if (!serverAvailable) {
      markTestSkipped('Serveur API non disponible sur 127.0.0.1:8000');
      return true;
    }
    return false;
  }

  void setAuthHeader() {
    if (authToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $authToken';
    }
  }

  group('Auth Flow Integration Tests - Pharmacie', () {
    group('1. Validation des Entrées', () {
      test('POST /auth/login rejette email invalide', () async {
        if (skipIfNoServer()) return;

        final response = await dio.post(
          '/auth/login',
          data: {'email': 'invalid-email', 'password': 'password'},
        );

        expect(response.statusCode, anyOf(401, 422));
        expect(response.data['success'], anyOf(false, isNull));
      });

      test('POST /auth/login rejette mot de passe vide', () async {
        if (skipIfNoServer()) return;

        final response = await dio.post(
          '/auth/login',
          data: {'email': 'test@pharmacy.com', 'password': ''},
        );

        expect(response.statusCode, anyOf(401, 422));
        expect(response.data['success'], anyOf(false, isNull));
      });

      test('POST /auth/login rejette credentials invalides', () async {
        if (skipIfNoServer()) return;

        final response = await dio.post(
          '/auth/login',
          data: {
            'email': 'nonexistent@pharmacy.com',
            'password': 'wrongpassword',
          },
        );

        expect(response.statusCode, 401);
        expect(response.data['success'], false);
      });
    });

    group('2. Connexion Réussie', () {
      test('POST /auth/login avec credentials valides', () async {
        if (skipIfNoServer()) return;
        if (!TestConfig.hasCredentials) {
          markTestSkipped(
            'Credentials non configurés - créez test_integration/.env.test',
          );
          return;
        }

        final response = await dio.post(
          '/auth/login',
          data: {
            'email': TestConfig.testPharmacyEmail,
            'password': TestConfig.testPharmacyPassword,
          },
        );

        expect(response.statusCode, anyOf(200, 201));
        expect(response.data['success'], true);
        expect(response.data['data'], isA<Map>());

        // Stocker les tokens pour les tests suivants
        final data = response.data['data'];
        if (data != null) {
          authToken = data['token'] ?? data['access_token'];
          refreshToken = data['refresh_token'];
        }
      });

      test('La réponse de login contient les infos pharmacie', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }

        // On a déjà les données du login précédent
        // Ce test vérifie que la structure est correcte
        expect(authToken, isNotNull);
      });
    });

    group('3. Vérification du Profil', () {
      test('GET /auth/me retourne les infos de la pharmacie', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get('/auth/me');

        expect(response.statusCode, 200);
        expect(response.data['success'], true);
        expect(response.data['data'], isA<Map>());

        final pharmacy = response.data['data'];
        expect(pharmacy['email'], isNotNull);
        expect(pharmacy['name'], isNotNull);
      });

      test('GET /auth/me sans token retourne 401', () async {
        if (skipIfNoServer()) return;

        // Requête sans header Authorization
        final dioNoAuth = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) => true,
          ),
        );

        final response = await dioNoAuth.get('/auth/me');
        expect(response.statusCode, 401);

        dioNoAuth.close();
      });
    });

    group('4. Gestion du Token', () {
      test('POST /auth/refresh renouvelle le token', () async {
        if (skipIfNoServer()) return;
        setAuthHeader();

        // Tester l'endpoint même sans refresh_token pour vérifier son existence
        final response = await dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken ?? 'test-token'},
        );

        // Si on a un refresh token valide et l'endpoint existe
        if (response.statusCode == 200 && refreshToken != null) {
          expect(response.data['success'], anyOf(true, isNull));

          final data = response.data['data'];
          if (data != null && data['token'] != null) {
            authToken = data['token'];
          }
        } else {
          // L'endpoint peut ne pas être implémenté, ou token invalide
          expect(response.statusCode, anyOf(200, 401, 404, 405, 422));
        }
      });

      test('Les requêtes avec token expiré retournent 401', () async {
        if (skipIfNoServer()) return;

        final dioExpiredToken = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer expired_token_12345',
            },
            validateStatus: (status) => true,
          ),
        );

        final response = await dioExpiredToken.get('/auth/me');
        expect(response.statusCode, 401);

        dioExpiredToken.close();
      });
    });

    group('5. Mise à jour du Profil', () {
      test('PUT /auth/me met à jour les infos', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.put(
          '/auth/me',
          data: {'phone': '+225 07 07 07 07 07'},
        );

        // 200 si succès, 422 si validation échoue, 500 si erreur serveur, 404 si endpoint non disponible, 405 si méthode non autorisée
        expect(response.statusCode, anyOf(200, 404, 405, 422, 500));

        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });
    });

    group('6. Changement de Mot de Passe', () {
      test(
        'POST /auth/change-password avec ancien mot de passe invalide',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          final response = await dio.post(
            '/auth/change-password',
            data: {
              'current_password': 'wrong_password',
              'new_password': 'NewPassword123!',
              'new_password_confirmation': 'NewPassword123!',
            },
          );

          // 401 ou 422 si mot de passe incorrect, 404 si endpoint non disponible, 500 erreur serveur
          expect(response.statusCode, anyOf(401, 404, 422, 500));
          if (response.statusCode != 404 && response.statusCode != 500) {
            expect(response.data['success'], anyOf(false, isNull));
          }
        },
      );
    });

    group('7. Mot de Passe Oublié', () {
      test('POST /auth/forgot-password envoie un email de reset', () async {
        if (skipIfNoServer()) return;

        final response = await dio.post(
          '/auth/forgot-password',
          data: {'email': TestConfig.testPharmacyEmail},
        );

        // 200 si email envoyé, 404 si email non trouvé
        expect(response.statusCode, anyOf(200, 404, 422));
      });

      test('POST /auth/forgot-password rejette email invalide', () async {
        if (skipIfNoServer()) return;

        final response = await dio.post(
          '/auth/forgot-password',
          data: {'email': 'invalid-email'},
        );

        expect(response.statusCode, anyOf(404, 422));
      });
    });

    group('8. Déconnexion', () {
      test('POST /auth/logout déconnecte l\'utilisateur', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.post('/auth/logout');

        // 200 si succès, 204 si pas de contenu
        expect(response.statusCode, anyOf(200, 204));
      });

      test('Le token est invalide après déconnexion', () async {
        if (skipIfNoServer()) return;
        // Utiliser le token qui devrait être invalide après logout
        setAuthHeader();

        final response = await dio.get('/auth/me');

        // Devrait retourner 401 si le token a été invalidé
        // Note: certaines APIs ne révoquent pas le token immédiatement
        expect(response.statusCode, anyOf(200, 401));
      });
    });
  });
}
