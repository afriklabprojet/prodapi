import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/pharmacies/data/models/pharmacy_model.dart';
import 'package:drpharma_client/features/pharmacies/domain/entities/pharmacy_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _pharmacyJson({
  dynamic id = 1,
  String name = 'Pharmacie du Centre',
  String address = '12 Rue Principale',
  String? phone,
  String? email,
  dynamic latitude = '5.3599',
  dynamic longitude = '-4.0082',
  String status = 'active',
  dynamic isOpen = true,
  String? imageUrl,
  dynamic isOnDuty,
  dynamic distance,
  String? openingHours,
  String? closingHours,
  String? dutyType,
  String? dutyEndAt,
  String? description,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'address': address,
  if (phone != null) 'phone': phone,
  if (email != null) 'email': email,
  'latitude': latitude,
  'longitude': longitude,
  'status': status,
  'is_open': isOpen,
  if (imageUrl != null) 'image_url': imageUrl,
  if (isOnDuty != null) 'is_on_duty': isOnDuty,
  if (distance != null) 'distance': distance,
  if (openingHours != null) 'opening_hours': openingHours,
  if (closingHours != null) 'closing_hours': closingHours,
  if (dutyType != null) 'duty_type': dutyType,
  if (dutyEndAt != null) 'duty_end_at': dutyEndAt,
  if (description != null) 'description': description,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PharmacyModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('PharmacyModel', () {
    group('fromJson — basic fields', () {
      test('parses id as int', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(id: 42));
        expect(model.id, 42);
      });

      test('parses id as String', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(id: '7'));
        expect(model.id, 7);
      });

      test('id defaults to 0 on parse failure', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(id: 'bad'));
        expect(model.id, 0);
      });

      test('parses name and address', () {
        final model = PharmacyModel.fromJson(_pharmacyJson());
        expect(model.name, 'Pharmacie du Centre');
        expect(model.address, '12 Rue Principale');
      });

      test('parses phone', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(phone: '+2250700000'),
        );
        expect(model.phone, '+2250700000');
      });

      test('parses email', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(email: 'pharm@example.com'),
        );
        expect(model.email, 'pharm@example.com');
      });

      test('parses status', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(status: 'inactive'));
        expect(model.status, 'inactive');
      });

      test('parses description', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(description: 'Grande pharmacie'),
        );
        expect(model.description, 'Grande pharmacie');
      });

      test('parses opening/closing hours', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(openingHours: '08:00', closingHours: '22:00'),
        );
        expect(model.openingHours, '08:00');
        expect(model.closingHours, '22:00');
      });

      test('parses dutyType and dutyEndAt', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(dutyType: 'night', dutyEndAt: '2024-06-02T06:00:00Z'),
        );
        expect(model.dutyType, 'night');
        expect(model.dutyEndAt, '2024-06-02T06:00:00Z');
      });
    });

    group('fromJson — isOpen parsing', () {
      test('isOpen from bool true', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson(isOpen: true)).isOpen,
          isTrue,
        );
      });

      test('isOpen from bool false', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson(isOpen: false)).isOpen,
          isFalse,
        );
      });

      test('isOpen from int 1', () {
        expect(PharmacyModel.fromJson(_pharmacyJson(isOpen: 1)).isOpen, isTrue);
      });

      test('isOpen from int 0', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson(isOpen: 0)).isOpen,
          isFalse,
        );
      });
    });

    group('fromJson — isOnDuty parsing', () {
      test('isOnDuty from bool true', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson(isOnDuty: true)).isOnDuty,
          isTrue,
        );
      });

      test('isOnDuty from int 1', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson(isOnDuty: 1)).isOnDuty,
          isTrue,
        );
      });

      test('isOnDuty null or false when absent', () {
        // is_on_duty absent → json[...] = null → false (not null)
        final model = PharmacyModel.fromJson(_pharmacyJson());
        expect(model.isOnDuty, anyOf(isNull, isFalse));
      });
    });

    group('fromJson — latitude/longitude (_parseDouble)', () {
      test('lat/lng as String', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(latitude: '5.3599', longitude: '-4.0082'),
        );
        expect(model.latitude, closeTo(5.3599, 1e-4));
        expect(model.longitude, closeTo(-4.0082, 1e-4));
      });

      test('lat/lng as double', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(latitude: 5.3599, longitude: -4.0082),
        );
        expect(model.latitude, closeTo(5.3599, 1e-4));
      });

      test('lat/lng as int', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(latitude: 5, longitude: -4),
        );
        expect(model.latitude, 5.0);
      });

      test('lat/lng as null', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(latitude: null, longitude: null),
        );
        expect(model.latitude, isNull);
        expect(model.longitude, isNull);
      });
    });

    group('fromJson — imageUrl', () {
      test('uses image_url key', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(imageUrl: 'https://cdn/img.jpg'),
        );
        expect(model.imageUrl, 'https://cdn/img.jpg');
      });

      test('falls back to logo key when image_url absent', () {
        final json = _pharmacyJson();
        json['logo'] = 'https://cdn/logo.png';
        final model = PharmacyModel.fromJson(json);
        expect(model.imageUrl, 'https://cdn/logo.png');
      });
    });

    group('fromJson — distance', () {
      test('distance as double', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(distance: 3.5));
        expect(model.distance, 3.5);
      });

      test('distance as string', () {
        final model = PharmacyModel.fromJson(_pharmacyJson(distance: '2.8'));
        expect(model.distance, closeTo(2.8, 1e-4));
      });

      test('distance null when absent', () {
        expect(PharmacyModel.fromJson(_pharmacyJson()).distance, isNull);
      });
    });

    group('toJson', () {
      test('always includes id, name, address, status, is_open', () {
        final json = PharmacyModel.fromJson(_pharmacyJson()).toJson();
        expect(json['id'], 1);
        expect(json['name'], 'Pharmacie du Centre');
        expect(json['address'], '12 Rue Principale');
        expect(json['status'], 'active');
        expect(json['is_open'], isTrue);
      });

      test('optional fields absent when null', () {
        final json = PharmacyModel.fromJson(_pharmacyJson()).toJson();
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('image_url'), isFalse);
      });

      test('optional fields present when set', () {
        final json = PharmacyModel.fromJson(
          _pharmacyJson(phone: '+22501', email: 'p@x.com', imageUrl: 'url'),
        ).toJson();
        expect(json['phone'], '+22501');
        expect(json['email'], 'p@x.com');
        expect(json['image_url'], 'url');
      });
    });

    // ──────────────────────────────────────────────────────────────────────────
    // toEntity
    // ──────────────────────────────────────────────────────────────────────────
    group('toEntity', () {
      test('returns PharmacyEntity', () {
        expect(
          PharmacyModel.fromJson(_pharmacyJson()).toEntity(),
          isA<PharmacyEntity>(),
        );
      });

      test('entity.phone defaults to empty string when null', () {
        final entity = PharmacyModel.fromJson(_pharmacyJson()).toEntity();
        expect(entity.phone, '');
      });

      test('entity.phone set when present', () {
        final entity = PharmacyModel.fromJson(
          _pharmacyJson(phone: '+22507'),
        ).toEntity();
        expect(entity.phone, '+22507');
      });

      test('entity fields match model fields', () {
        final model = PharmacyModel.fromJson(
          _pharmacyJson(distance: '1.5', isOnDuty: true, status: 'active'),
        );
        final entity = model.toEntity();
        expect(entity.id, 1);
        expect(entity.name, 'Pharmacie du Centre');
        expect(entity.isOnDuty, isTrue);
        expect(entity.distance, closeTo(1.5, 1e-4));
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PharmacyEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('PharmacyEntity', () {
    PharmacyEntity make({double? lat, double? lng, double? distance}) =>
        PharmacyEntity(
          id: 1,
          name: 'Test Pharmacie',
          address: 'Abidjan',
          phone: '',
          isOpen: true,
          status: 'active',
          latitude: lat,
          longitude: lng,
          distance: distance,
        );

    test('hasCoordinates true when lat and lng set', () {
      expect(make(lat: 5.36, lng: -4.01).hasCoordinates, isTrue);
    });

    test('hasCoordinates false when lat is null', () {
      expect(make(lng: -4.01).hasCoordinates, isFalse);
    });

    test('hasCoordinates false when lng is null', () {
      expect(make(lat: 5.36).hasCoordinates, isFalse);
    });

    test('distanceText formats to 1 decimal when set', () {
      // 3.0.toStringAsFixed(1) = '3.0'
      expect(make(distance: 3.0).distanceText, '3.0 km');
    });

    test('distanceText is empty when null', () {
      expect(make().distanceText, '');
    });

    test('distanceLabel equals distanceText', () {
      final entity = make(distance: 3.0);
      expect(entity.distanceLabel, entity.distanceText);
    });
  });
}
