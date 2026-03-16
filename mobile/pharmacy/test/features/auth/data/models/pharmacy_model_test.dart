import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/pharmacy_model.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/pharmacy_entity.dart';

void main() {
  group('PharmacyModel', () {
    const tPharmacyModel = PharmacyModel(
      id: 1,
      name: 'Pharmacie Test',
      address: '123 Rue Test',
      city: 'Abidjan',
      phone: '+225 0123456789',
      email: 'pharmacy@test.com',
      status: 'active',
      licenseNumber: 'LIC123456',
      licenseDocument: 'documents/license.pdf',
      idCardDocument: 'documents/id_card.pdf',
      dutyZoneId: 5,
    );

    const tPharmacyModelMinimal = PharmacyModel(
      id: 2,
      name: 'Pharmacie Minimal',
      status: 'pending',
    );

    group('fromJson', () {
      test('should return a valid model from complete JSON', () {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': 1,
          'name': 'Pharmacie Test',
          'address': '123 Rue Test',
          'city': 'Abidjan',
          'phone': '+225 0123456789',
          'email': 'pharmacy@test.com',
          'status': 'active',
          'license_number': 'LIC123456',
          'license_document': 'documents/license.pdf',
          'id_card_document': 'documents/id_card.pdf',
          'duty_zone_id': 5,
        };

        // act
        final result = PharmacyModel.fromJson(jsonMap);

        // assert
        expect(result.id, equals(tPharmacyModel.id));
        expect(result.name, equals(tPharmacyModel.name));
        expect(result.address, equals(tPharmacyModel.address));
        expect(result.city, equals(tPharmacyModel.city));
        expect(result.phone, equals(tPharmacyModel.phone));
        expect(result.email, equals(tPharmacyModel.email));
        expect(result.status, equals(tPharmacyModel.status));
        expect(result.licenseNumber, equals(tPharmacyModel.licenseNumber));
        expect(result.licenseDocument, equals(tPharmacyModel.licenseDocument));
        expect(result.idCardDocument, equals(tPharmacyModel.idCardDocument));
        expect(result.dutyZoneId, equals(tPharmacyModel.dutyZoneId));
      });

      test('should return a valid model from minimal JSON', () {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': 2,
          'name': 'Pharmacie Minimal',
          'status': 'pending',
        };

        // act
        final result = PharmacyModel.fromJson(jsonMap);

        // assert
        expect(result.id, equals(2));
        expect(result.name, equals('Pharmacie Minimal'));
        expect(result.status, equals('pending'));
        expect(result.address, isNull);
        expect(result.city, isNull);
        expect(result.phone, isNull);
        expect(result.email, isNull);
        expect(result.licenseNumber, isNull);
        expect(result.licenseDocument, isNull);
        expect(result.idCardDocument, isNull);
        expect(result.dutyZoneId, isNull);
      });

      test('should handle null optional fields in JSON', () {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': 3,
          'name': 'Pharmacie Null',
          'status': 'inactive',
          'address': null,
          'city': null,
          'phone': null,
          'email': null,
          'license_number': null,
          'license_document': null,
          'id_card_document': null,
          'duty_zone_id': null,
        };

        // act
        final result = PharmacyModel.fromJson(jsonMap);

        // assert
        expect(result.id, equals(3));
        expect(result.name, equals('Pharmacie Null'));
        expect(result.status, equals('inactive'));
        expect(result.address, isNull);
        expect(result.city, isNull);
        expect(result.phone, isNull);
        expect(result.email, isNull);
        expect(result.licenseNumber, isNull);
        expect(result.licenseDocument, isNull);
        expect(result.idCardDocument, isNull);
        expect(result.dutyZoneId, isNull);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tPharmacyModel.toJson();

        // assert
        expect(result['id'], equals(1));
        expect(result['name'], equals('Pharmacie Test'));
        expect(result['address'], equals('123 Rue Test'));
        expect(result['city'], equals('Abidjan'));
        expect(result['phone'], equals('+225 0123456789'));
        expect(result['email'], equals('pharmacy@test.com'));
        expect(result['status'], equals('active'));
        expect(result['license_number'], equals('LIC123456'));
        expect(result['license_document'], equals('documents/license.pdf'));
        expect(result['id_card_document'], equals('documents/id_card.pdf'));
        expect(result['duty_zone_id'], equals(5));
      });

      test('should return a JSON map with null optional fields', () {
        // act
        final result = tPharmacyModelMinimal.toJson();

        // assert
        expect(result['id'], equals(2));
        expect(result['name'], equals('Pharmacie Minimal'));
        expect(result['status'], equals('pending'));
        expect(result['address'], isNull);
        expect(result['city'], isNull);
        expect(result['phone'], isNull);
        expect(result['email'], isNull);
        expect(result['license_number'], isNull);
        expect(result['license_document'], isNull);
        expect(result['id_card_document'], isNull);
        expect(result['duty_zone_id'], isNull);
      });
    });

    group('toEntity', () {
      test('should return a PharmacyEntity with same values', () {
        // act
        final result = tPharmacyModel.toEntity();

        // assert
        expect(result, isA<PharmacyEntity>());
        expect(result.id, equals(tPharmacyModel.id));
        expect(result.name, equals(tPharmacyModel.name));
        expect(result.address, equals(tPharmacyModel.address));
        expect(result.city, equals(tPharmacyModel.city));
        expect(result.phone, equals(tPharmacyModel.phone));
        expect(result.email, equals(tPharmacyModel.email));
        expect(result.status, equals(tPharmacyModel.status));
        expect(result.licenseNumber, equals(tPharmacyModel.licenseNumber));
        expect(result.licenseDocument, equals(tPharmacyModel.licenseDocument));
        expect(result.idCardDocument, equals(tPharmacyModel.idCardDocument));
        expect(result.dutyZoneId, equals(tPharmacyModel.dutyZoneId));
      });

      test('should return a PharmacyEntity with null optional values', () {
        // act
        final result = tPharmacyModelMinimal.toEntity();

        // assert
        expect(result, isA<PharmacyEntity>());
        expect(result.id, equals(2));
        expect(result.name, equals('Pharmacie Minimal'));
        expect(result.status, equals('pending'));
        expect(result.address, isNull);
        expect(result.city, isNull);
        expect(result.phone, isNull);
        expect(result.email, isNull);
        expect(result.licenseNumber, isNull);
        expect(result.licenseDocument, isNull);
        expect(result.idCardDocument, isNull);
        expect(result.dutyZoneId, isNull);
      });
    });

    group('Different status values', () {
      test('should handle active status', () {
        final model = PharmacyModel(id: 1, name: 'Test', status: 'active');
        expect(model.status, equals('active'));
      });

      test('should handle pending status', () {
        final model = PharmacyModel(id: 1, name: 'Test', status: 'pending');
        expect(model.status, equals('pending'));
      });

      test('should handle inactive status', () {
        final model = PharmacyModel(id: 1, name: 'Test', status: 'inactive');
        expect(model.status, equals('inactive'));
      });

      test('should handle suspended status', () {
        final model = PharmacyModel(id: 1, name: 'Test', status: 'suspended');
        expect(model.status, equals('suspended'));
      });
    });
  });
}
