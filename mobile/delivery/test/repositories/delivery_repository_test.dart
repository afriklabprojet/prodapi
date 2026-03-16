import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/core/services/cache_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late DeliveryRepository repo;

  setUp(() async {
    mockDio = MockDio();
    repo = DeliveryRepository(mockDio);
    await setupTestDependencies();
  });

  // ── Delivery JSON helper ────────────────────────────
  Map<String, dynamic> deliveryJson({int id = 1, String status = 'pending'}) => {
        'id': id,
        'reference': 'DEL-$id',
        'pharmacy_name': 'Pharma $id',
        'pharmacy_address': 'Addr $id',
        'customer_name': 'Client $id',
        'delivery_address': 'Dest $id',
        'total_amount': 5000.0,
        'status': status,
      };

  // ── getDeliveries ───────────────────────────────────
  group('getDeliveries', () {
    test('returns list of Delivery on success', () async {
      when(() => mockDio.get(ApiConstants.deliveries, queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'data': [deliveryJson(id: 1), deliveryJson(id: 2)],
              }));

      final deliveries = await repo.getDeliveries();
      expect(deliveries, hasLength(2));
      expect(deliveries[0].reference, 'DEL-1');
      expect(deliveries[1].reference, 'DEL-2');
    });

    test('passes status query parameter', () async {
      when(() => mockDio.get(ApiConstants.deliveries, queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({'data': []}));

      await repo.getDeliveries(status: 'active');
      verify(() => mockDio.get(ApiConstants.deliveries,
          queryParameters: {'status': 'active'})).called(1);
    });

    test('returns empty list on empty data', () async {
      when(() => mockDio.get(ApiConstants.deliveries, queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({'data': []}));

      final result = await repo.getDeliveries();
      expect(result, isEmpty);
    });

    test('throws on error', () async {
      when(() => mockDio.get(ApiConstants.deliveries, queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.getDeliveries(), throwsA(isA<Exception>()));
    });

    test('throws on timeout', () async {
      when(() => mockDio.get(ApiConstants.deliveries, queryParameters: any(named: 'queryParameters')))
          .thenThrow(timeoutError());

      expect(() => repo.getDeliveries(), throwsA(isA<Exception>()));
    });
  });

  // ── acceptDelivery ──────────────────────────────────
  group('acceptDelivery', () {
    test('calls POST to accept endpoint', () async {
      when(() => mockDio.post(ApiConstants.acceptDelivery(1)))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.acceptDelivery(1);
      verify(() => mockDio.post(ApiConstants.acceptDelivery(1))).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.acceptDelivery(1)))
          .thenThrow(dioError(statusCode: 400, data: {}));

      expect(() => repo.acceptDelivery(1), throwsA(isA<Exception>()));
    });
  });

  // ── pickupDelivery ──────────────────────────────────
  group('pickupDelivery', () {
    test('succeeds on 200', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.pickupDelivery(1);
      verify(() => mockDio.post(ApiConstants.pickupDelivery(1))).called(1);
    });

    test('throws specific message on 400 with server message', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(
        statusCode: 400,
        data: {'message': 'Livraison déjà récupérée'},
      ));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Livraison déjà récupérée'),
        )),
      );
    });

    test('throws default message on 400 without server message', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(statusCode: 400, data: {}));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('ne peut pas être récupérée'),
        )),
      );
    });

    test('throws specific message on 403 with server message', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(
        statusCode: 403,
        data: {'message': 'Non autorisé'},
      ));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Non autorisé'),
        )),
      );
    });

    test('throws default message on 403 without server message', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(statusCode: 403, data: {}));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('autorisé à récupérer'),
        )),
      );
    });

    test('throws specific message on 404', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(statusCode: 404, data: {}));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Livraison introuvable'),
        )),
      );
    });

    test('throws generic message on other error', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('connexion'),
        )),
      );
    });

    test('throws generic message on timeout', () async {
      when(() => mockDio.post(ApiConstants.pickupDelivery(1)))
          .thenThrow(timeoutError());

      expect(
        () => repo.pickupDelivery(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('connexion'),
        )),
      );
    });
  });

  // ── completeDelivery ────────────────────────────────
  group('completeDelivery', () {
    test('succeeds and invalidates cache', () async {
      when(() => mockDio.post(ApiConstants.completeDelivery(1), data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.completeDelivery(1, 'ABC123');
      verify(() => mockDio.post(ApiConstants.completeDelivery(1),
          data: {'confirmation_code': 'ABC123'})).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.completeDelivery(1), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {}));

      expect(() => repo.completeDelivery(1, 'BAD'), throwsA(isA<Exception>()));
    });
  });

  // ── toggleAvailability ──────────────────────────────
  group('toggleAvailability', () {
    test('returns true when available', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'status': 'available'},
              }));

      final result = await repo.toggleAvailability(desiredStatus: 'available');
      expect(result, isTrue);
    });

    test('returns false when offline', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'status': 'offline'},
              }));

      final result = await repo.toggleAvailability(desiredStatus: 'offline');
      expect(result, isFalse);
    });

    test('sends null data when no desiredStatus', () async {
      when(() => mockDio.post(ApiConstants.availability, data: null))
          .thenAnswer((_) async => successResponse({
                'data': {'status': 'available'},
              }));

      final result = await repo.toggleAvailability();
      expect(result, isTrue);
    });

    test('throws on 403 COURIER_PROFILE_NOT_FOUND', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 403,
        data: {
          'error_code': 'COURIER_PROFILE_NOT_FOUND',
          'message': 'Profil non trouvé',
        },
      ));

      expect(
        () => repo.toggleAvailability(desiredStatus: 'available'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('compte coursier'),
        )),
      );
    });

    test('throws on 403 with server message', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenThrow(dioError(
        statusCode: 403,
        data: {'message': 'Accès interdit'},
      ));

      expect(
        () => repo.toggleAvailability(desiredStatus: 'available'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Accès interdit'),
        )),
      );
    });

    test('throws default on 403 without message', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 403, data: {}));

      expect(
        () => repo.toggleAvailability(desiredStatus: 'available'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Accès refusé'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.toggleAvailability(desiredStatus: 'available'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Session expirée'),
        )),
      );
    });

    test('throws generic on other error', () async {
      when(() => mockDio.post(ApiConstants.availability, data: any(named: 'data')))
          .thenThrow(timeoutError());

      expect(
        () => repo.toggleAvailability(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Impossible de changer'),
        )),
      );
    });
  });

  // ── updateLocation ──────────────────────────────────
  group('updateLocation', () {
    test('sends POST with coordinates', () async {
      when(() => mockDio.post(ApiConstants.location, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.updateLocation(5.3484, -3.9485);
      verify(() => mockDio.post(ApiConstants.location,
          data: {'latitude': 5.3484, 'longitude': -3.9485})).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.location, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.updateLocation(5.3, -3.9),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on timeout', () async {
      when(() => mockDio.post(ApiConstants.location, data: any(named: 'data')))
          .thenThrow(timeoutError());

      expect(() => repo.updateLocation(5.3, -3.9), throwsA(isA<Exception>()));
    });
  });

  // ── getProfile (CourierProfile) ─────────────────────
  group('getProfile', () {
    test('returns CourierProfile on success', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Ali',
                  'email': 'ali@test.com',
                  'status': 'active',
                  'vehicle_type': 'moto',
                  'plate_number': 'AB-123',
                  'rating': 4.5,
                  'completed_deliveries': 50,
                  'earnings': 100000.0,
                }
              }));

      final profile = await repo.getProfile();
      expect(profile.name, 'Ali');
      expect(profile.vehicleType, 'moto');
    });

    test('serves from cache when available', () async {
      await CacheService.instance.cacheCourierProfile({
        'id': 99,
        'name': 'Cache',
        'email': 'c@t.com',
        'status': 'active',
        'vehicle_type': 'vélo',
        'plate_number': '',
        'rating': 5.0,
        'completed_deliveries': 100,
        'earnings': 200000.0,
      });

      final profile = await repo.getProfile();
      expect(profile.name, 'Cache');
      verifyNever(() => mockDio.get(any()));
    });

    test('caches after successful fetch', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 1,
                  'name': 'Fresh',
                  'email': 'f@t.com',
                  'status': 'active',
                  'vehicle_type': 'moto',
                  'plate_number': 'XY-1',
                  'rating': 4.0,
                  'completed_deliveries': 10,
                  'earnings': 50000.0,
                }
              }));

      await repo.getProfile();
      final profile2 = await repo.getProfile();
      expect(profile2.name, 'Fresh');
      verify(() => mockDio.get(ApiConstants.profile)).called(1);
    });

    test('throws on 403 COURIER_PROFILE_NOT_FOUND', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenThrow(dioError(
        statusCode: 403,
        data: {
          'error_code': 'COURIER_PROFILE_NOT_FOUND',
          'message': 'Non trouvé',
        },
      ));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Profil coursier non trouvé'),
        )),
      );
    });

    test('throws on 403 with server message', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenThrow(dioError(statusCode: 403, data: {'message': 'Interdit'}));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Interdit'),
        )),
      );
    });

    test('throws default on 403 without message', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenThrow(dioError(statusCode: 403, data: {}));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Accès refusé'),
        )),
      );
    });

    test('throws on 401', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenThrow(dioError(statusCode: 401));

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('Session expirée'),
        )),
      );
    });

    test('throws generic on other error', () async {
      when(() => mockDio.get(ApiConstants.profile))
          .thenThrow(timeoutError());

      expect(
        () => repo.getProfile(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'msg', contains('charger le profil'),
        )),
      );
    });
  });

  // ── getMessages / sendMessage ───────────────────────
  group('messages', () {
    test('getMessages returns list', () async {
      when(() => mockDio.get(ApiConstants.messages(1), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => successResponse({
                'data': [
                  {
                    'id': 1,
                    'content': 'Hello',
                    'is_me': true,
                    'created_at': '2026-02-13T10:00:00Z',
                  }
                ]
              }));

      final messages = await repo.getMessages(1, 'customer');
      expect(messages, hasLength(1));
      expect(messages[0].content, 'Hello');
    });

    test('getMessages throws on error', () async {
      when(() => mockDio.get(ApiConstants.messages(1), queryParameters: any(named: 'queryParameters')))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.getMessages(1, 'customer'), throwsA(isA<Exception>()));
    });

    test('sendMessage returns ChatMessage', () async {
      when(() => mockDio.post(ApiConstants.messages(1), data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'id': 2,
                  'content': 'Sent',
                  'is_me': true,
                  'created_at': '2026-02-13T10:01:00Z',
                }
              }));

      final msg = await repo.sendMessage(1, 'Sent', 'customer');
      expect(msg.content, 'Sent');
    });

    test('sendMessage throws on error', () async {
      when(() => mockDio.post(ApiConstants.messages(1), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.sendMessage(1, 'Hi', 'customer'), throwsA(isA<Exception>()));
    });
  });

  // ── rejectDelivery ──────────────────────────────────
  group('rejectDelivery', () {
    test('calls POST', () async {
      when(() => mockDio.post(ApiConstants.rejectDelivery(7)))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.rejectDelivery(7);
      verify(() => mockDio.post(ApiConstants.rejectDelivery(7))).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.rejectDelivery(7)))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.rejectDelivery(7), throwsA(isA<Exception>()));
    });
  });

  // ── batchAcceptDeliveries ───────────────────────────
  group('batchAcceptDeliveries', () {
    test('returns data on success', () async {
      when(() => mockDio.post(ApiConstants.batchAcceptDeliveries, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'accepted': 3, 'failed': 0}
              }));

      final result = await repo.batchAcceptDeliveries([1, 2, 3]);
      expect(result['accepted'], 3);
    });

    test('sends correct delivery_ids', () async {
      when(() => mockDio.post(ApiConstants.batchAcceptDeliveries, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'data': {'accepted': 2, 'failed': 1}
              }));

      await repo.batchAcceptDeliveries([10, 20]);
      verify(() => mockDio.post(ApiConstants.batchAcceptDeliveries,
          data: {'delivery_ids': [10, 20]})).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.batchAcceptDeliveries, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(() => repo.batchAcceptDeliveries([1]), throwsA(isA<Exception>()));
    });
  });

  // ── getOptimizedRoute ───────────────────────────────
  group('getOptimizedRoute', () {
    test('returns route data on success', () async {
      when(() => mockDio.get(ApiConstants.deliveriesRoute))
          .thenAnswer((_) async => successResponse({
                'data': {
                  'waypoints': [
                    {'lat': 5.3, 'lng': -3.9},
                    {'lat': 5.4, 'lng': -3.8},
                  ],
                  'total_distance': 12.5,
                }
              }));

      final route = await repo.getOptimizedRoute();
      expect(route['total_distance'], 12.5);
      expect((route['waypoints'] as List), hasLength(2));
    });

    test('throws on error', () async {
      when(() => mockDio.get(ApiConstants.deliveriesRoute))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.getOptimizedRoute(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on timeout', () async {
      when(() => mockDio.get(ApiConstants.deliveriesRoute))
          .thenThrow(timeoutError());

      expect(() => repo.getOptimizedRoute(), throwsA(isA<Exception>()));
    });
  });

  // ── rateCustomer ────────────────────────────────────
  group('rateCustomer', () {
    test('calls POST with rating and comment', () async {
      when(() => mockDio.post(ApiConstants.rateCustomer(5), data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.rateCustomer(deliveryId: 5, rating: 4, comment: 'Bien');
      verify(() => mockDio.post(ApiConstants.rateCustomer(5), data: any(named: 'data'))).called(1);
    });

    test('calls POST with rating only (no comment)', () async {
      when(() => mockDio.post(ApiConstants.rateCustomer(3), data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.rateCustomer(deliveryId: 3, rating: 5);
      verify(() => mockDio.post(ApiConstants.rateCustomer(3), data: {'rating': 5})).called(1);
    });

    test('includes tags when provided', () async {
      when(() => mockDio.post(ApiConstants.rateCustomer(2), data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({'success': true}));

      await repo.rateCustomer(
        deliveryId: 2,
        rating: 3,
        comment: 'OK',
        tags: ['rapide', 'aimable'],
      );
      verify(() => mockDio.post(ApiConstants.rateCustomer(2), data: {
            'rating': 3,
            'comment': 'OK',
            'tags': ['rapide', 'aimable'],
          })).called(1);
    });

    test('throws on error', () async {
      when(() => mockDio.post(ApiConstants.rateCustomer(5), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 500));

      expect(
        () => repo.rateCustomer(deliveryId: 5, rating: 4),
        throwsA(isA<Exception>()),
      );
    });
  });
}
