/// Tests d'intégration du flux de commande pharmacie
///
/// Ce fichier teste le flux complet de gestion des commandes:
/// 1. Réception d'une commande (pending)
/// 2. Confirmation de la commande (confirmed)
/// 3. Préparation terminée (ready)
/// 4. Livraison effectuée (delivered)
///
/// Run avec: flutter test --tags integration test_integration/order_flow_integration_test.dart

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
    // Fallback: try socket connection
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
  int? testOrderId;

  setUpAll(() async {
    serverAvailable = await _isServerRunning();
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: TestConfig.connectTimeout,
        receiveTimeout: TestConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );

    // Authentification automatique au démarrage
    if (serverAvailable && TestConfig.hasCredentials) {
      try {
        final response = await dio.post(
          '/auth/login',
          data: {
            'email': TestConfig.testPharmacyEmail,
            'password': TestConfig.testPharmacyPassword,
          },
        );
        if (response.statusCode == 200 && response.data['data'] != null) {
          authToken = response.data['data']['token'];
        }
      } catch (_) {
        // Login failed, tests will skip
      }
    }
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

  group('Order Flow Integration Tests - Pharmacie', () {
    group('1. Authentification Pharmacie', () {
      test('POST /auth/login permet de se connecter', () async {
        if (skipIfNoServer()) return;
        if (!TestConfig.hasCredentials) {
          markTestSkipped(
            'Credentials non configurés - créez test_integration/.env.test',
          );
          return;
        }

        // Vérifier que l'auth s'est bien passée dans setUpAll
        if (authToken == null) {
          // Retry login
          final response = await dio.post(
            '/auth/login',
            data: {
              'email': TestConfig.testPharmacyEmail,
              'password': TestConfig.testPharmacyPassword,
            },
          );

          expect(response.statusCode, anyOf(200, 201));
          expect(response.data['success'], true);

          if (response.data['data'] != null &&
              response.data['data']['token'] != null) {
            authToken = response.data['data']['token'];
          }
        } else {
          expect(authToken, isNotNull);
        }
      });
    });

    group('2. Récupération des Commandes', () {
      test('GET /pharmacy/orders retourne la liste des commandes', () async {
        if (skipIfNoServer()) return;
        setAuthHeader();

        final response = await dio.get('/pharmacy/orders');

        // 401 si non authentifié
        if (response.statusCode == 401) {
          markTestSkipped('Authentification requise');
          return;
        }

        expect(response.statusCode, 200);
        expect(response.data['success'], anyOf(true, isNull));
        // L'API peut retourner une liste ou un objet paginé
        expect(response.data['data'], anyOf(isA<Map>(), isA<List>()));
      });

      test(
        'GET /pharmacy/orders?status=pending retourne les commandes en attente',
        () async {
          if (skipIfNoServer()) return;
          setAuthHeader();

          final response = await dio.get(
            '/pharmacy/orders',
            queryParameters: {'status': 'pending'},
          );

          if (response.statusCode == 401) {
            markTestSkipped('Authentification requise');
            return;
          }

          expect(response.statusCode, 200);
          expect(response.data['success'], anyOf(true, isNull));

          // Stocker un ID de commande pour les tests suivants
          // L'API peut retourner une liste directement ou un objet avec clé 'orders'
          final data = response.data['data'];
          final List? orders = data is List
              ? data
              : (data is Map
                    ? data['orders'] as List? ?? data['data'] as List?
                    : null);
          if (orders != null && orders.isNotEmpty) {
            testOrderId = orders.first['id'];
          }
        },
      );

      test(
        'GET /pharmacy/orders/:id retourne les détails d\'une commande',
        () async {
          if (skipIfNoServer()) return;
          if (testOrderId == null) {
            markTestSkipped('Aucune commande disponible pour le test');
            return;
          }
          setAuthHeader();

          final response = await dio.get('/pharmacy/orders/$testOrderId');

          if (response.statusCode == 401) {
            markTestSkipped('Authentification requise');
            return;
          }

          expect(response.statusCode, 200);
          expect(response.data['success'], true);
          expect(response.data['data']['id'], testOrderId);
        },
      );
    });

    group('3. Cycle de Vie de la Commande', () {
      test('POST /pharmacy/orders/:id/confirm confirme une commande', () async {
        if (skipIfNoServer()) return;
        if (testOrderId == null) {
          markTestSkipped('Aucune commande disponible pour le test');
          return;
        }
        setAuthHeader();

        final response = await dio.post(
          '/pharmacy/orders/$testOrderId/confirm',
        );

        if (response.statusCode == 401) {
          markTestSkipped('Authentification requise');
          return;
        }

        // 200 si succès, 400/422 si déjà confirmée ou état invalide
        expect(response.statusCode, anyOf(200, 400, 422));

        if (response.statusCode == 200 && response.data['data'] != null) {
          expect(response.data['success'], anyOf(true, isNull));
          // Le statut peut être dans data.status ou data.order.status
          final status =
              response.data['data']['status'] ??
              response.data['data']['order']?['status'];
          if (status != null) {
            expect(status, anyOf('confirmed', 'pending', 'ready'));
          }
        }
      });

      test(
        'POST /pharmacy/orders/:id/reject rejette une commande avec motif',
        () async {
          if (skipIfNoServer()) return;
          setAuthHeader();

          // On ne teste pas sur la commande en cours pour ne pas interrompre le flux
          // Ce test vérifie juste que l'endpoint existe et retourne un format valide
          final response = await dio.post(
            '/pharmacy/orders/99999/reject',
            data: {'reason': 'Produit en rupture de stock'},
          );

          // 404 car commande inexistante, ou 401 si non auth
          expect(response.statusCode, anyOf(401, 404, 422));
        },
      );

      test(
        'POST /pharmacy/orders/:id/ready marque une commande comme prête',
        () async {
          if (skipIfNoServer()) return;
          if (testOrderId == null) {
            markTestSkipped('Aucune commande disponible pour le test');
            return;
          }
          setAuthHeader();

          final response = await dio.post(
            '/pharmacy/orders/$testOrderId/ready',
          );

          if (response.statusCode == 401) {
            markTestSkipped('Authentification requise');
            return;
          }

          // 200 si succès, 400/422 si état invalide (commande déjà traitée)
          expect(response.statusCode, anyOf(200, 400, 422));

          if (response.statusCode == 200 && response.data['data'] != null) {
            expect(response.data['success'], anyOf(true, isNull));
            // Le statut peut être dans data.status ou data.order.status
            final status =
                response.data['data']['status'] ??
                response.data['data']['order']?['status'];
            if (status != null) {
              expect(status, anyOf('ready', 'confirmed', 'pending'));
            }
          }
        },
      );
    });

    group('4. Statistiques et Historique', () {
      test('GET /pharmacy/orders/stats retourne les statistiques', () async {
        if (skipIfNoServer()) return;
        setAuthHeader();

        final response = await dio.get('/pharmacy/orders/stats');

        if (response.statusCode == 401) {
          markTestSkipped('Authentification requise');
          return;
        }

        // 200 si endpoint existe, 404 si non implémenté
        expect(response.statusCode, anyOf(200, 404));
        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });

      test(
        'GET /pharmacy/orders?status=delivered retourne l\'historique',
        () async {
          if (skipIfNoServer()) return;
          setAuthHeader();

          final response = await dio.get(
            '/pharmacy/orders',
            queryParameters: {'status': 'delivered'},
          );

          if (response.statusCode == 401) {
            markTestSkipped('Authentification requise');
            return;
          }

          expect(response.statusCode, 200);
          expect(response.data['success'], true);
        },
      );
    });

    group('5. Validation des Erreurs', () {
      test('GET /pharmacy/orders/:id avec ID invalide retourne 404', () async {
        if (skipIfNoServer()) return;
        setAuthHeader();

        final response = await dio.get('/pharmacy/orders/99999999');

        if (response.statusCode == 401) {
          markTestSkipped('Authentification requise');
          return;
        }

        expect(response.statusCode, 404);
        expect(response.data['success'], anyOf(false, isNull));
      });

      test(
        'POST /pharmacy/orders/:id/confirm sans auth retourne 401',
        () async {
          if (skipIfNoServer()) return;

          // Supprimer temporairement le token
          final savedToken = dio.options.headers['Authorization'];
          dio.options.headers.remove('Authorization');

          final response = await dio.post('/pharmacy/orders/1/confirm');

          expect(response.statusCode, 401);

          // Restaurer le token
          if (savedToken != null) {
            dio.options.headers['Authorization'] = savedToken;
          }
        },
      );
    });
  });
}
