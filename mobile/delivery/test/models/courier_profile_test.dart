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
      );
      final updated = profile.copyWith(status: 'suspended', rating: 3.0);
      expect(updated.status, 'suspended');
      expect(updated.rating, 3.0);
      expect(updated.name, 'Ali');
    });

    test('equality works', () {
      const a = CourierProfile(
        id: 1, name: 'Ali', email: 'ali@test.com', status: 'active',
        vehicleType: 'moto', plateNumber: 'DK', rating: 4.5,
        completedDeliveries: 50, earnings: 100000.0,
      );
      const b = CourierProfile(
        id: 1, name: 'Ali', email: 'ali@test.com', status: 'active',
        vehicleType: 'moto', plateNumber: 'DK', rating: 4.5,
        completedDeliveries: 50, earnings: 100000.0,
      );
      expect(a, equals(b));
    });
  });
}
