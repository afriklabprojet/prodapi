import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/user.dart';

void main() {
  group('User', () {
    test('fromJson with full data', () {
      final json = {
        'id': 1,
        'name': 'Ali',
        'email': 'ali@test.com',
        'phone': '+221770000000',
        'role': 'courier',
        'avatar': 'https://example.com/avatar.png',
        'courier': {
          'id': 10,
          'status': 'active',
          'vehicle_type': 'moto',
          'vehicle_number': 'DK-1234',
          'rating': 4.8,
          'completed_deliveries': 120,
        },
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Ali');
      expect(user.email, 'ali@test.com');
      expect(user.phone, '+221770000000');
      expect(user.role, 'courier');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.courier, isNotNull);
      expect(user.courier!.id, 10);
      expect(user.courier!.status, 'active');
      expect(user.courier!.vehicleType, 'moto');
      expect(user.courier!.vehicleNumber, 'DK-1234');
      expect(user.courier!.rating, 4.8);
      expect(user.courier!.completedDeliveries, 120);
    });

    test('fromJson with minimal data', () {
      final json = {'id': 2, 'name': 'Fatou', 'email': 'fatou@test.com'};
      final user = User.fromJson(json);
      expect(user.id, 2);
      expect(user.name, 'Fatou');
      expect(user.phone, isNull);
      expect(user.courier, isNull);
    });

    test('fromJson handles string id', () {
      final json = {'id': '42', 'name': 'Test', 'email': 'test@test.com'};
      final user = User.fromJson(json);
      expect(user.id, 42);
    });

    test('fromJson handles null id (_forceInt fallback)', () {
      final json = {'id': null, 'name': 'Test', 'email': 'test@test.com'};
      final user = User.fromJson(json);
      expect(user.id, 0);
    });

    test('fromJson handles non-parseable string id', () {
      final json = {'id': 'abc', 'name': 'Test', 'email': 'test@test.com'};
      final user = User.fromJson(json);
      expect(user.id, 0);
    });

    test('fromJson handles bool id (_forceInt default)', () {
      final json = {'id': true, 'name': 'Test', 'email': 'test@test.com'};
      final user = User.fromJson(json);
      expect(user.id, 0);
    });

    test('toJson round-trip', () {
      final user = const User(id: 1, name: 'Ali', email: 'ali@test.com');
      final json = user.toJson();
      final restored = User.fromJson(json);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
    });

    test('copyWith creates modified copy', () {
      const user = User(id: 1, name: 'Ali', email: 'ali@test.com');
      final modified = user.copyWith(name: 'Moussa');
      expect(modified.name, 'Moussa');
      expect(modified.email, 'ali@test.com');
    });

    test('equality works', () {
      const a = User(id: 1, name: 'Ali', email: 'ali@test.com');
      const b = User(id: 1, name: 'Ali', email: 'ali@test.com');
      expect(a, equals(b));
    });
  });

  group('CourierInfo', () {
    test('fromJson with full data', () {
      final json = {
        'id': 10,
        'status': 'active',
        'vehicle_type': 'moto',
        'vehicle_number': 'DK-1234',
        'rating': '4.5',
        'completed_deliveries': '50',
      };
      final info = CourierInfo.fromJson(json);
      expect(info.id, 10);
      expect(info.status, 'active');
      expect(info.vehicleType, 'moto');
      expect(info.vehicleNumber, 'DK-1234');
      expect(info.rating, 4.5);
      expect(info.completedDeliveries, 50);
    });

    test('fromJson handles numeric rating and deliveries', () {
      final json = {
        'id': 10,
        'status': 'active',
        'rating': 4.8,
        'completed_deliveries': 100,
      };
      final info = CourierInfo.fromJson(json);
      expect(info.rating, 4.8);
      expect(info.completedDeliveries, 100);
    });

    test('fromJson handles null optionals', () {
      final json = {'id': 10, 'status': 'pending'};
      final info = CourierInfo.fromJson(json);
      expect(info.vehicleType, isNull);
      expect(info.rating, isNull);
      expect(info.completedDeliveries, isNull);
    });

    test('fromJson handles string id', () {
      final json = {'id': '99', 'status': 'active'};
      final info = CourierInfo.fromJson(json);
      expect(info.id, 99);
    });

    test('fromJson handles non-parseable string rating', () {
      final json = {'id': 10, 'status': 'active', 'rating': 'not-a-number'};
      final info = CourierInfo.fromJson(json);
      expect(info.rating, isNull);
    });

    test('fromJson handles non-parseable string deliveries', () {
      final json = {'id': 10, 'status': 'active', 'completed_deliveries': 'abc'};
      final info = CourierInfo.fromJson(json);
      expect(info.completedDeliveries, isNull);
    });

    test('fromJson handles bool rating (_stringToDouble fallback)', () {
      final json = {'id': 10, 'status': 'active', 'rating': true};
      final info = CourierInfo.fromJson(json);
      expect(info.rating, isNull);
    });

    test('fromJson handles bool deliveries (_stringToInt fallback)', () {
      final json = {'id': 10, 'status': 'active', 'completed_deliveries': true};
      final info = CourierInfo.fromJson(json);
      expect(info.completedDeliveries, isNull);
    });

    test('toJson round-trip', () {
      const info = CourierInfo(id: 1, status: 'active', rating: 4.5, completedDeliveries: 10);
      final json = info.toJson();
      expect(json['id'], 1);
      expect(json['status'], 'active');
      expect(json['rating'], 4.5);
      expect(json['completed_deliveries'], 10);
    });

    test('copyWith works', () {
      const info = CourierInfo(id: 1, status: 'active');
      final modified = info.copyWith(status: 'suspended');
      expect(modified.status, 'suspended');
      expect(modified.id, 1);
    });

    test('equality works', () {
      const a = CourierInfo(id: 1, status: 'active');
      const b = CourierInfo(id: 1, status: 'active');
      expect(a, equals(b));
    });
  });
}
