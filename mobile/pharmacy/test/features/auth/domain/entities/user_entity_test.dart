import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/pharmacy_entity.dart';

import '../../../../test_helpers.dart';

void main() {
  group('UserEntity', () {
    test('should create UserEntity with required fields', () {
      const user = UserEntity(
        id: 1,
        name: 'Test Pharmacist',
        email: 'test@pharmacy.com',
        phone: '+225 01 02 03 04 05',
      );

      expect(user.id, 1);
      expect(user.name, 'Test Pharmacist');
      expect(user.email, 'test@pharmacy.com');
      expect(user.phone, '+225 01 02 03 04 05');
      expect(user.role, isNull);
      expect(user.avatar, isNull);
      expect(user.pharmacies, isEmpty);
    });

    test('should create UserEntity with all fields', () {
      final pharmacy = TestDataFactory.createPharmacy();
      final user = UserEntity(
        id: 1,
        name: 'Test Pharmacist',
        email: 'test@pharmacy.com',
        phone: '+225 01 02 03 04 05',
        role: 'pharmacist',
        avatar: 'https://example.com/avatar.jpg',
        pharmacies: [pharmacy],
      );

      expect(user.role, 'pharmacist');
      expect(user.avatar, 'https://example.com/avatar.jpg');
      expect(user.pharmacies.length, 1);
      expect(user.pharmacies.first.name, pharmacy.name);
    });

    test('should create UserEntity using factory', () {
      final user = TestDataFactory.createUser(
        id: 5,
        name: 'Dr. Konan',
        email: 'konan@pharmacy.com',
      );

      expect(user.id, 5);
      expect(user.name, 'Dr. Konan');
      expect(user.email, 'konan@pharmacy.com');
      expect(user.pharmacies, isNotEmpty);
    });
  });

  group('PharmacyEntity', () {
    test('should create PharmacyEntity with required fields', () {
      const pharmacy = PharmacyEntity(
        id: 1,
        name: 'Pharmacie Centrale',
        status: 'active',
      );

      expect(pharmacy.id, 1);
      expect(pharmacy.name, 'Pharmacie Centrale');
      expect(pharmacy.status, 'active');
      expect(pharmacy.address, isNull);
      expect(pharmacy.phone, isNull);
    });

    test('should create PharmacyEntity with all fields', () {
      const pharmacy = PharmacyEntity(
        id: 1,
        name: 'Pharmacie Centrale',
        address: '123 Rue du Commerce',
        city: 'Abidjan',
        phone: '+225 27 22 00 00 00',
        email: 'contact@pharmacie.ci',
        status: 'active',
        licenseNumber: 'LIC-12345',
        dutyZoneId: 2,
      );

      expect(pharmacy.address, '123 Rue du Commerce');
      expect(pharmacy.city, 'Abidjan');
      expect(pharmacy.phone, '+225 27 22 00 00 00');
      expect(pharmacy.email, 'contact@pharmacie.ci');
      expect(pharmacy.licenseNumber, 'LIC-12345');
      expect(pharmacy.dutyZoneId, 2);
    });

    test('should create PharmacyEntity using factory', () {
      final pharmacy = TestDataFactory.createPharmacy(
        id: 10,
        name: 'Pharmacie du Plateau',
        status: 'pending',
      );

      expect(pharmacy.id, 10);
      expect(pharmacy.name, 'Pharmacie du Plateau');
      expect(pharmacy.status, 'pending');
    });
  });
}
