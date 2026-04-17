import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/addresses/data/models/address_model.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _addressJson({
  int id = 1,
  String label = 'Domicile',
  String address = '12 Rue des Jardins',
  String? city = 'Abidjan',
  String? district = 'Cocody',
  String? phone,
  String? instructions,
  dynamic latitude = '5.3599317',
  dynamic longitude = '-4.0082563',
  bool isDefault = true,
  String fullAddress = '12 Rue des Jardins, Cocody, Abidjan',
  bool hasCoordinates = true,
  String createdAt = '2024-03-10T09:00:00.000Z',
  String updatedAt = '2024-03-10T09:00:00.000Z',
}) => <String, dynamic>{
  'id': id,
  'label': label,
  'address': address,
  'city': ?city,
  'district': ?district,
  'phone': ?phone,
  'instructions': ?instructions,
  'latitude': latitude,
  'longitude': longitude,
  'is_default': isDefault,
  'full_address': fullAddress,
  'has_coordinates': hasCoordinates,
  'created_at': createdAt,
  'updated_at': updatedAt,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // AddressModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('AddressModel', () {
    group('fromJson — basic fields', () {
      test('parses id, label, address', () {
        final model = AddressModel.fromJson(_addressJson());
        expect(model.id, 1);
        expect(model.label, 'Domicile');
        expect(model.address, '12 Rue des Jardins');
      });

      test('parses city and district', () {
        final model = AddressModel.fromJson(_addressJson());
        expect(model.city, 'Abidjan');
        expect(model.district, 'Cocody');
      });

      test('parses nullable phone', () {
        final model = AddressModel.fromJson(
          _addressJson(phone: '+22507000000'),
        );
        expect(model.phone, '+22507000000');
      });

      test('parses nullable instructions', () {
        final model = AddressModel.fromJson(
          _addressJson(instructions: 'Sonner au portail bleu'),
        );
        expect(model.instructions, 'Sonner au portail bleu');
      });

      test('parses isDefault', () {
        final def = AddressModel.fromJson(_addressJson(isDefault: true));
        final notDef = AddressModel.fromJson(_addressJson(isDefault: false));
        expect(def.isDefault, isTrue);
        expect(notDef.isDefault, isFalse);
      });

      test('parses fullAddress', () {
        final model = AddressModel.fromJson(_addressJson());
        expect(model.fullAddress, '12 Rue des Jardins, Cocody, Abidjan');
      });

      test('parses hasCoordinates', () {
        final model = AddressModel.fromJson(
          _addressJson(hasCoordinates: false),
        );
        expect(model.hasCoordinates, isFalse);
      });
    });

    group('fromJson — StringToDoubleConverter (lat/lng)', () {
      test('latitude/longitude as String', () {
        final model = AddressModel.fromJson(
          _addressJson(latitude: '5.3599317', longitude: '-4.0082563'),
        );
        expect(model.latitude, closeTo(5.3599317, 1e-7));
        expect(model.longitude, closeTo(-4.0082563, 1e-7));
      });

      test('latitude/longitude as double', () {
        final model = AddressModel.fromJson(
          _addressJson(latitude: 5.3599, longitude: -4.0082),
        );
        expect(model.latitude, closeTo(5.3599, 1e-4));
        expect(model.longitude, closeTo(-4.0082, 1e-4));
      });

      test('latitude/longitude as int', () {
        final model = AddressModel.fromJson(
          _addressJson(latitude: 5, longitude: -4),
        );
        expect(model.latitude, 5.0);
        expect(model.longitude, -4.0);
      });

      test('latitude/longitude as null', () {
        final model = AddressModel.fromJson(
          _addressJson(latitude: null, longitude: null),
        );
        expect(model.latitude, isNull);
        expect(model.longitude, isNull);
      });
    });

    group('toJson', () {
      test('round-trip preserves key fields', () {
        final json = AddressModel.fromJson(_addressJson()).toJson();
        expect(json['id'], 1);
        expect(json['label'], 'Domicile');
        expect(json['is_default'], isTrue);
        expect(json['full_address'], '12 Rue des Jardins, Cocody, Abidjan');
        expect(json['has_coordinates'], isTrue);
      });

      test('lat/lng serialized as double or null', () {
        final json = AddressModel.fromJson(
          _addressJson(latitude: '5.36'),
        ).toJson();
        expect(json['latitude'], closeTo(5.36, 1e-4));
        final jsonNull = AddressModel.fromJson(
          _addressJson(latitude: null),
        ).toJson();
        expect(jsonNull['latitude'], isNull);
      });
    });

    // ──────────────────────────────────────────────────────────────────────────
    // toEntity
    // ──────────────────────────────────────────────────────────────────────────
    group('toEntity', () {
      test('returns AddressEntity', () {
        expect(
          AddressModel.fromJson(_addressJson()).toEntity(),
          isA<AddressEntity>(),
        );
      });

      test('parses createdAt and updatedAt dates', () {
        final entity = AddressModel.fromJson(_addressJson()).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-03-10T09:00:00.000Z'));
        expect(entity.updatedAt, DateTime.parse('2024-03-10T09:00:00.000Z'));
      });

      test('entity fields match model fields', () {
        final entity = AddressModel.fromJson(_addressJson()).toEntity();
        expect(entity.id, 1);
        expect(entity.label, 'Domicile');
        expect(entity.address, '12 Rue des Jardins');
        expect(entity.city, 'Abidjan');
        expect(entity.district, 'Cocody');
        expect(entity.isDefault, isTrue);
        expect(entity.hasCoordinates, isTrue);
        expect(entity.latitude, closeTo(5.3599317, 1e-7));
      });

      test('null lat/lng passed through', () {
        final entity = AddressModel.fromJson(
          _addressJson(latitude: null, longitude: null),
        ).toEntity();
        expect(entity.latitude, isNull);
        expect(entity.longitude, isNull);
      });
    });

    // ──────────────────────────────────────────────────────────────────────────
    // fromEntity
    // ──────────────────────────────────────────────────────────────────────────
    group('fromEntity', () {
      test('round-trip entity → model → entity preserves fields', () {
        final originalEntity = AddressEntity(
          id: 10,
          label: 'Bureau',
          address: '5 Avenue Centrale',
          city: 'Abidjan',
          district: 'Plateau',
          phone: '+22507111',
          isDefault: false,
          fullAddress: '5 Avenue Centrale, Plateau, Abidjan',
          hasCoordinates: true,
          latitude: 5.320,
          longitude: -4.015,
          createdAt: DateTime(2024, 5, 1),
          updatedAt: DateTime(2024, 5, 2),
        );
        final model = AddressModel.fromEntity(originalEntity);
        expect(model.id, 10);
        expect(model.label, 'Bureau');
        expect(model.latitude, 5.320);
        expect(model.isDefault, isFalse);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AddressEntity copyWith
  // ────────────────────────────────────────────────────────────────────────────
  group('AddressEntity', () {
    final base = AddressEntity(
      id: 1,
      label: 'Domicile',
      address: '12 Rue',
      isDefault: true,
      fullAddress: '12 Rue, Abidjan',
      hasCoordinates: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('copyWith updates label', () {
      expect(base.copyWith(label: 'Travail').label, 'Travail');
    });

    test('copyWith preserves unchanged fields', () {
      final updated = base.copyWith(id: 99);
      expect(updated.address, '12 Rue');
      expect(updated.isDefault, isTrue);
    });

    test('copyWith updates latitude/longitude', () {
      final updated = base.copyWith(
        latitude: 5.36,
        longitude: -4.01,
        hasCoordinates: true,
      );
      expect(updated.latitude, 5.36);
      expect(updated.hasCoordinates, isTrue);
    });

    test('two identical entities are equal', () {
      final e1 = base.copyWith();
      expect(e1, equals(base));
    });
  });
}
