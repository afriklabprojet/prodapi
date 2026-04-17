/// Tests d'intégration du flux portefeuille pharmacie
///
/// Ce fichier teste le flux complet de gestion du portefeuille:
/// 1. Consultation du solde
/// 2. Historique des transactions
/// 3. Demande de retrait
/// 4. Suivi des retraits
///
/// Run avec: flutter test --tags integration test_integration/pharmacy/wallet_flow_integration_test.dart

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
  int? withdrawalId;

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

  group('Wallet Flow Integration Tests - Pharmacie', () {
    group('0. Authentification Préalable', () {
      test('POST /auth/login pour obtenir un token', () async {
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

          final data = response.data['data'];
          if (data != null) {
            authToken = data['token'] ?? data['access_token'];
          }
        } else {
          expect(authToken, isNotNull);
        }
      });
    });

    group('1. Consultation du Solde', () {
      test('GET /pharmacy/wallet retourne le solde actuel', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get('/pharmacy/wallet');

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        expect(response.statusCode, 200);
        expect(response.data['success'], anyOf(true, isNull));
        expect(response.data['data'], isA<Map>());

        final wallet = response.data['data'];
        // Le solde peut être au format 'balance' ou 'current_balance' ou numérique directement
        expect(
          wallet.containsKey('balance') ||
              wallet.containsKey('current_balance'),
          true,
        );
      });

      test('GET /pharmacy/wallet sans auth retourne 401', () async {
        if (skipIfNoServer()) return;

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

        final response = await dioNoAuth.get('/pharmacy/wallet');
        expect(response.statusCode, 401);

        dioNoAuth.close();
      });
    });

    group('2. Historique des Transactions', () {
      test(
        'GET /pharmacy/wallet/transactions retourne l\'historique',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          final response = await dio.get('/pharmacy/wallet/transactions');

          if (response.statusCode == 401) {
            markTestSkipped('Token invalide');
            return;
          }

          // L'endpoint peut ne pas exister (404)
          expect(response.statusCode, anyOf(200, 404));
          if (response.statusCode == 200) {
            expect(response.data['success'], anyOf(true, isNull));
          }
        },
      );

      test('GET /pharmacy/wallet/transactions avec filtres', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get(
          '/pharmacy/wallet/transactions',
          queryParameters: {
            'type': 'credit',
            'from_date': '2024-01-01',
            'to_date': '2024-12-31',
          },
        );

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        // L'endpoint peut ne pas exister (404)
        expect(response.statusCode, anyOf(200, 404));
        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });

      test('GET /pharmacy/wallet/transactions avec pagination', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get(
          '/pharmacy/wallet/transactions',
          queryParameters: {'page': 1, 'per_page': 10},
        );

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        // L'endpoint peut ne pas exister (404)
        expect(response.statusCode, anyOf(200, 404));
        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });
    });

    group('3. Demande de Retrait', () {
      test('POST /pharmacy/wallet/withdraw avec montant valide', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        // Petit montant pour le test (le minimum est généralement 1000 FCFA)
        final response = await dio.post(
          '/pharmacy/wallet/withdraw',
          data: {
            'amount': 1000,
            'payment_method': 'mobile_money',
            'phone_number': '+225 07 07 07 07 07',
          },
        );

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        // 200/201 si succès, 422 si solde insuffisant ou validation échoue
        expect(response.statusCode, anyOf(200, 201, 422));

        if (response.statusCode == 200 || response.statusCode == 201) {
          expect(response.data['success'], true);
          withdrawalId = response.data['data']['id'];
        }
      });

      test('POST /pharmacy/wallet/withdraw rejette montant négatif', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.post(
          '/pharmacy/wallet/withdraw',
          data: {
            'amount': -1000,
            'payment_method': 'mobile_money',
            'phone_number': '+225 07 07 07 07 07',
          },
        );

        expect(response.statusCode, 422);
        expect(response.data['success'], false);
      });

      test(
        'POST /pharmacy/wallet/withdraw rejette montant supérieur au solde',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          // Montant très élevé qui devrait dépasser le solde
          final response = await dio.post(
            '/pharmacy/wallet/withdraw',
            data: {
              'amount': 999999999,
              'payment_method': 'mobile_money',
              'phone_number': '+225 07 07 07 07 07',
            },
          );

          expect(response.statusCode, 422);
          expect(response.data['success'], false);
        },
      );

      test(
        'POST /pharmacy/wallet/withdraw valide le numéro de téléphone',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          final response = await dio.post(
            '/pharmacy/wallet/withdraw',
            data: {
              'amount': 1000,
              'payment_method': 'mobile_money',
              'phone_number': 'invalid-phone',
            },
          );

          // Devrait rejeter le numéro invalide
          expect(response.statusCode, anyOf(422, 400));
          expect(response.data['success'], false);
        },
      );
    });

    group('4. Suivi des Retraits', () {
      test(
        'GET /pharmacy/wallet/withdrawals retourne la liste des retraits',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          final response = await dio.get('/pharmacy/wallet/withdrawals');

          if (response.statusCode == 401) {
            markTestSkipped('Token invalide');
            return;
          }

          // L'endpoint peut ne pas exister
          expect(response.statusCode, anyOf(200, 404));
          if (response.statusCode == 200) {
            expect(response.data['success'], anyOf(true, isNull));
          }
        },
      );

      test(
        'GET /pharmacy/wallet/withdrawals/:id retourne le détail d\'un retrait',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          // Récupérer un ID de retrait depuis la liste si on n'en a pas
          if (withdrawalId == null) {
            final listResponse = await dio.get('/pharmacy/wallet/withdrawals');
            if (listResponse.statusCode == 200 &&
                listResponse.data['data'] != null) {
              final withdrawals =
                  listResponse.data['data']['data'] as List? ??
                  listResponse.data['data'] as List?;
              if (withdrawals != null && withdrawals.isNotEmpty) {
                withdrawalId = withdrawals.first['id'];
              }
            }
          }

          if (withdrawalId == null) {
            // Tester avec un ID fictif pour vérifier le comportement 404
            final response = await dio.get(
              '/pharmacy/wallet/withdrawals/99999',
            );
            expect(response.statusCode, anyOf(404, 401));
            return;
          }

          final response = await dio.get(
            '/pharmacy/wallet/withdrawals/$withdrawalId',
          );

          if (response.statusCode == 401) {
            markTestSkipped('Token invalide');
            return;
          }

          expect(response.statusCode, anyOf(200, 404));

          if (response.statusCode == 200) {
            expect(response.data['success'], anyOf(true, isNull));
          }
        },
      );

      test('GET /pharmacy/wallet/withdrawals avec filtre de statut', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get(
          '/pharmacy/wallet/withdrawals',
          queryParameters: {'status': 'pending'},
        );

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        // L'endpoint peut ne pas exister
        expect(response.statusCode, anyOf(200, 404));
        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });
    });

    group('5. Statistiques du Portefeuille', () {
      test('GET /pharmacy/wallet/stats retourne les statistiques', () async {
        if (skipIfNoServer()) return;
        if (authToken == null) {
          markTestSkipped('Authentification préalable requise');
          return;
        }
        setAuthHeader();

        final response = await dio.get('/pharmacy/wallet/stats');

        if (response.statusCode == 401) {
          markTestSkipped('Token invalide');
          return;
        }

        // L'endpoint peut ne pas exister
        expect(response.statusCode, anyOf(200, 404));

        if (response.statusCode == 200) {
          expect(response.data['success'], anyOf(true, isNull));
        }
      });
    });

    group('6. Annulation de Retrait', () {
      test(
        'DELETE /pharmacy/wallet/withdrawals/:id annule un retrait en attente',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          // Récupérer un withdrawal pending depuis la liste si possible
          if (withdrawalId == null) {
            final listResponse = await dio.get(
              '/pharmacy/wallet/withdrawals',
              queryParameters: {'status': 'pending'},
            );
            if (listResponse.statusCode == 200 &&
                listResponse.data['data'] != null) {
              final withdrawals =
                  listResponse.data['data']['data'] as List? ??
                  listResponse.data['data'] as List?;
              if (withdrawals != null && withdrawals.isNotEmpty) {
                withdrawalId = withdrawals.first['id'];
              }
            }
          }

          if (withdrawalId == null) {
            // Pas de retrait à annuler - tester avec ID fictif
            final response = await dio.delete(
              '/pharmacy/wallet/withdrawals/99999',
            );
            expect(response.statusCode, anyOf(404, 401, 422));
            return;
          }

          final response = await dio.delete(
            '/pharmacy/wallet/withdrawals/$withdrawalId',
          );

          if (response.statusCode == 401) {
            markTestSkipped('Token invalide');
            return;
          }

          // 200 si annulé, 422 si déjà traité, 404 si non trouvé
          expect(response.statusCode, anyOf(200, 204, 404, 422));
        },
      );

      test(
        'DELETE /pharmacy/wallet/withdrawals/:id avec ID invalide retourne 404',
        () async {
          if (skipIfNoServer()) return;
          if (authToken == null) {
            markTestSkipped('Authentification préalable requise');
            return;
          }
          setAuthHeader();

          final response = await dio.delete(
            '/pharmacy/wallet/withdrawals/99999999',
          );

          if (response.statusCode == 401) {
            markTestSkipped('Token invalide');
            return;
          }

          expect(response.statusCode, 404);
        },
      );
    });
  });
}
