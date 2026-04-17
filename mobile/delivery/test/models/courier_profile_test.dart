import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/courier_profile.dart';

void main() {
  group('CourierProfile', () {
    test('fromJson with full data', () {
      final json = {
        'id': 10,
        'name': 'Ali Diallo',
        'email': 'ali@test.com',
        'avatar': 'https://example.com/avatar.png',
        'status': 'active',
        'vehicle_type': 'moto',
        'plate_number': 'DK-1234',
        'rating': 4.8,
        'completed_deliveries': 120,
        'earnings': 250000.0,
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.id, 10);
      expect(profile.name, 'Ali Diallo');
      expect(profile.email, 'ali@test.com');
      expect(profile.avatar, 'https://example.com/avatar.png');
      expect(profile.status, 'active');
      expect(profile.vehicleType, 'moto');
      expect(profile.plateNumber, 'DK-1234');
      expect(profile.rating, 4.8);
      expect(profile.completedDeliveries, 120);
      expect(profile.earnings, 250000.0);
    });

    test('fromJson with default plate_number', () {
      final json = {
        'id': 10,
        'name': 'Fatou',
        'email': 'fatou@test.com',
        'status': 'active',
        'vehicle_type': 'vélo',
        'rating': 4.0,
        'completed_deliveries': 10,
        'earnings': 30000.0,
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.plateNumber, '');
    });

    test('toJson round-trip', () {
      final profile = const CourierProfile(
        id: 1,
        name: 'Test',
        email: 'test@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'AB-123',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      final json = profile.toJson();
      final restored = CourierProfile.fromJson(json);
      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.vehicleType, profile.vehicleType);
    });

    test('copyWith creates modified copy', () {
      const profile = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK-1234',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      final updated = profile.copyWith(status: 'suspended', rating: 3.0);
      expect(updated.status, 'suspended');
      expect(updated.rating, 3.0);
      expect(updated.name, 'Ali');
    });

    test('equality works', () {
      const a = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      const b = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      expect(a, equals(b));
    });
  });

  group('CourierProfile - additional', () {
    test('fromJson with null avatar', () {
      final json = {
        'id': 5,
        'name': 'Moussa',
        'email': 'moussa@test.com',
        'status': 'active',
        'vehicle_type': 'voiture',
        'plate_number': 'AB-100',
        'rating': 3.9,
        'completed_deliveries': 5,
        'earnings': 10000.0,
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.avatar, isNull);
      expect(profile.kycStatus, 'unknown');
    });

    test('fromJson defaults kycStatus to unknown', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'email': 'test@test.com',
        'status': 'active',
        'vehicle_type': 'moto',
        'rating': 4.0,
        'completed_deliveries': 0,
        'earnings': 0.0,
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.kycStatus, 'unknown');
    });

    test('fromJson handles string id from PHP API', () {
      final json = {
        'id': '25',
        'name': 'Awa',
        'email': 'awa@test.com',
        'status': 'active',
        'vehicle_type': 'scooter',
        'plate_number': 'SC-001',
        'rating': '4.5',
        'completed_deliveries': '30',
        'earnings': '75000',
        'kyc_status': 'verified',
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.id, 25);
      expect(profile.rating, 4.5);
      expect(profile.completedDeliveries, 30);
      expect(profile.earnings, 75000.0);
    });

    test('fromJson handles int-typed rating', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'email': 'test@test.com',
        'status': 'pending',
        'vehicle_type': 'vélo',
        'rating': 5,
        'completed_deliveries': 100,
        'earnings': 200000,
      };
      final profile = CourierProfile.fromJson(json);
      expect(profile.rating, 5.0);
      expect(profile.earnings, 200000.0);
    });

    test('copyWith preserves all fields when none changed', () {
      const original = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        avatar: 'http://img.png',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK-1234',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
      expect(copy.avatar, 'http://img.png');
      expect(copy.kycStatus, 'verified');
    });

    test('inequality when different id', () {
      const a = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      const b = CourierProfile(
        id: 2,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode differs for different profiles', () {
      const a = CourierProfile(
        id: 1,
        name: 'Ali',
        email: 'ali@test.com',
        status: 'active',
        vehicleType: 'moto',
        plateNumber: 'DK',
        rating: 4.5,
        completedDeliveries: 50,
        earnings: 100000.0,
        kycStatus: 'verified',
      );
      const b = CourierProfile(
        id: 2,
        name: 'Fatou',
        email: 'fatou@test.com',
        status: 'pending',
        vehicleType: 'vélo',
        plateNumber: '',
        rating: 3.0,
        completedDeliveries: 10,
        earnings: 20000.0,
        kycStatus: 'pending',
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('fromJson with all kyc statuses', () {
      for (final status in ['verified', 'pending', 'rejected', 'unknown']) {
        final json = {
          'id': 1,
          'name': 'T',
          'email': 'e@t.com',
          'status': 'active',
          'vehicle_type': 'moto',
          'rating': 4.0,
          'completed_deliveries': 0,
          'earnings': 0.0,
          'kyc_status': status,
        };
        final profile = CourierProfile.fromJson(json);
        expect(profile.kycStatus, status);
      }
    });
  });
}
