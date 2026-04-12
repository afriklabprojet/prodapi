import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/profile/data/models/profile_model.dart';
import 'package:drpharma_client/features/profile/domain/entities/profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/entities/update_profile_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _profileJson({
  int id = 1,
  String name = 'Alice Koné',
  String email = 'alice@example.com',
  String? phone,
  String? avatar,
  String? defaultAddress,
  String createdAt = '2024-01-15T08:00:00.000Z',
  int totalOrders = 5,
  int completedOrders = 3,
  dynamic totalSpent = 12500.0,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'email': email,
  if (phone != null) 'phone': phone,
  if (avatar != null) 'avatar': avatar,
  if (defaultAddress != null) 'default_address': defaultAddress,
  'created_at': createdAt,
  'total_orders': totalOrders,
  'completed_orders': completedOrders,
  'total_spent': totalSpent,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // ProfileModel.fromJson
  // ────────────────────────────────────────────────────────────────────────────
  group('ProfileModel', () {
    group('fromJson', () {
      test('parses required fields', () {
        final model = ProfileModel.fromJson(_profileJson());
        expect(model.id, 1);
        expect(model.name, 'Alice Koné');
        expect(model.email, 'alice@example.com');
        expect(model.createdAt, '2024-01-15T08:00:00.000Z');
        expect(model.totalOrders, 5);
        expect(model.completedOrders, 3);
      });

      test('parses phone', () {
        final model = ProfileModel.fromJson(
          _profileJson(phone: '+22507000000'),
        );
        expect(model.phone, '+22507000000');
      });

      test('parses avatar url', () {
        final model = ProfileModel.fromJson(
          _profileJson(avatar: 'https://cdn.example.com/avatar.jpg'),
        );
        expect(model.avatar, 'https://cdn.example.com/avatar.jpg');
      });

      test('parses default_address', () {
        final model = ProfileModel.fromJson(
          _profileJson(defaultAddress: 'Abidjan Plateau'),
        );
        expect(model.defaultAddress, 'Abidjan Plateau');
      });

      test('total_spent as double', () {
        final model = ProfileModel.fromJson(_profileJson(totalSpent: 9800.50));
        expect(model.totalSpent, 9800.50);
      });

      test('total_spent as String', () {
        final model = ProfileModel.fromJson(
          _profileJson(totalSpent: '4500.75'),
        );
        expect(model.totalSpent, '4500.75');
      });

      test('nullable fields are null by default', () {
        final model = ProfileModel.fromJson(_profileJson());
        expect(model.phone, isNull);
        expect(model.avatar, isNull);
        expect(model.defaultAddress, isNull);
      });
    });

    group('toJson round-trip', () {
      test('serializes all fields', () {
        final json = ProfileModel.fromJson(
          _profileJson(
            phone: '+2250709',
            avatar: 'https://img.png',
            defaultAddress: 'Abidjan',
          ),
        ).toJson();

        expect(json['id'], 1);
        expect(json['name'], 'Alice Koné');
        expect(json['email'], 'alice@example.com');
        expect(json['phone'], '+2250709');
        expect(json['avatar'], 'https://img.png');
        expect(json['default_address'], 'Abidjan');
        expect(json['total_orders'], 5);
        expect(json['completed_orders'], 3);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // toEntity
    // ────────────────────────────────────────────────────────────────────────
    group('toEntity', () {
      test('returns ProfileEntity', () {
        expect(
          ProfileModel.fromJson(_profileJson()).toEntity(),
          isA<ProfileEntity>(),
        );
      });

      test('parses createdAt date', () {
        final entity = ProfileModel.fromJson(_profileJson()).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-01-15T08:00:00.000Z'));
      });

      test('totalSpent as double', () {
        final entity = ProfileModel.fromJson(
          _profileJson(totalSpent: 7000.0),
        ).toEntity();
        expect(entity.totalSpent, 7000.0);
      });

      test('totalSpent as String converts to double', () {
        final entity = ProfileModel.fromJson(
          _profileJson(totalSpent: '3250.50'),
        ).toEntity();
        expect(entity.totalSpent, 3250.50);
      });

      test('totalSpent as null becomes 0.0', () {
        final json = _profileJson();
        json['total_spent'] = null;
        final entity = ProfileModel.fromJson(json).toEntity();
        expect(entity.totalSpent, 0.0);
      });

      test('totalOrders defaults to 0 when absent', () {
        final json = _profileJson();
        json.remove('total_orders');
        final entity = ProfileModel.fromJson(json).toEntity();
        expect(entity.totalOrders, 0);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // fromEntity
    // ────────────────────────────────────────────────────────────────────────
    group('fromEntity', () {
      test('round-trip: entity → model → entity preserves fields', () {
        final entity = ProfileEntity(
          id: 7,
          name: 'Bob Traoré',
          email: 'bob@example.com',
          phone: '+22501000000',
          avatar: 'https://cdn.example.com/bob.jpg',
          defaultAddress: 'Cocody',
          createdAt: DateTime(2024, 3, 10),
          totalOrders: 10,
          completedOrders: 8,
          totalSpent: 25000.0,
        );
        final model = ProfileModel.fromEntity(entity);
        expect(model.id, 7);
        expect(model.name, 'Bob Traoré');
        expect(model.email, 'bob@example.com');
        expect(model.phone, '+22501000000');
        expect(model.totalSpent, 25000.0);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ProfileEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('ProfileEntity', () {
    ProfileEntity _make({
      String? phone,
      String? avatar,
      String? defaultAddress,
    }) => ProfileEntity(
      id: 1,
      name: 'Alice Koné',
      email: 'alice@example.com',
      phone: phone,
      avatar: avatar,
      defaultAddress: defaultAddress,
      createdAt: DateTime(2024, 1, 1),
    );

    group('hasAvatar', () {
      test(
        'false when avatar is null',
        () => expect(_make().hasAvatar, isFalse),
      );
      test(
        'false when avatar is empty',
        () => expect(_make(avatar: '').hasAvatar, isFalse),
      );
      test(
        'true when avatar set',
        () => expect(_make(avatar: 'https://img.png').hasAvatar, isTrue),
      );
    });

    group('hasPhone', () {
      test('false when phone is null', () => expect(_make().hasPhone, isFalse));
      test(
        'false when phone is empty',
        () => expect(_make(phone: '').hasPhone, isFalse),
      );
      test(
        'true when phone set',
        () => expect(_make(phone: '+2250700').hasPhone, isTrue),
      );
    });

    group('hasDefaultAddress', () {
      test('false when null', () => expect(_make().hasDefaultAddress, isFalse));
      test(
        'false when empty',
        () => expect(_make(defaultAddress: '').hasDefaultAddress, isFalse),
      );
      test(
        'true when set',
        () => expect(_make(defaultAddress: 'Cocody').hasDefaultAddress, isTrue),
      );
    });

    group('initials', () {
      test('two-word name → first letters uppercase', () {
        expect(_make().initials, 'AK');
      });

      test('single-word name → first letter', () {
        final entity = ProfileEntity(
          id: 1,
          name: 'Amadou',
          email: 'a@x.com',
          createdAt: DateTime(2024),
        );
        expect(entity.initials, 'A');
      });

      test('empty name → ?', () {
        final entity = ProfileEntity(
          id: 1,
          name: '',
          email: 'a@x.com',
          createdAt: DateTime(2024),
        );
        expect(entity.initials, '?');
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        expect(_make().copyWith(name: 'Chantal').name, 'Chantal');
      });

      test('clearPhone removes phone', () {
        final e = _make(phone: '+22500').copyWith(clearPhone: true);
        expect(e.phone, isNull);
      });

      test('clearAvatar removes avatar', () {
        final e = _make(avatar: 'url').copyWith(clearAvatar: true);
        expect(e.avatar, isNull);
      });

      test('clearDefaultAddress removes address', () {
        final e = _make(
          defaultAddress: 'Abidjan',
        ).copyWith(clearDefaultAddress: true);
        expect(e.defaultAddress, isNull);
      });

      test('unchanged fields carry over', () {
        final original = _make(
          phone: '+22507',
          avatar: 'url',
          defaultAddress: 'Yop',
        );
        final copied = original.copyWith(id: 99);
        expect(copied.phone, '+22507');
        expect(copied.avatar, 'url');
        expect(copied.defaultAddress, 'Yop');
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // UpdateProfileEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('UpdateProfileEntity', () {
    test('toJson includes only non-null fields', () {
      final entity = UpdateProfileEntity(
        name: 'Alice',
        email: 'alice@example.com',
      );
      final json = entity.toJson();
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json.containsKey('phone'), isFalse);
    });

    test('toJson includes phone when set', () {
      final entity = UpdateProfileEntity(phone: '+22507000000');
      final json = entity.toJson();
      expect(json['phone'], '+22507000000');
    });

    test('toJson includes password fields when set', () {
      final entity = UpdateProfileEntity(
        currentPassword: 'old123',
        newPassword: 'new456',
        newPasswordConfirmation: 'new456',
      );
      final json = entity.toJson();
      expect(json.containsKey('current_password'), isTrue);
      expect(json.containsKey('new_password'), isTrue);
      expect(json.containsKey('new_password_confirmation'), isTrue);
    });

    test('hasPasswordChange true when both passwords are set', () {
      final entity = UpdateProfileEntity(
        currentPassword: 'old',
        newPassword: 'secret',
      );
      expect(entity.hasPasswordChange, isTrue);
    });

    test('hasPasswordChange false when newPassword is null', () {
      final entity = UpdateProfileEntity(name: 'Alice');
      expect(entity.hasPasswordChange, isFalse);
    });

    test('toJson is empty when all fields null', () {
      final entity = UpdateProfileEntity();
      expect(entity.toJson(), isEmpty);
    });

    test('address field is included in json when set', () {
      final entity = UpdateProfileEntity(address: 'Plateau, Abidjan');
      final json = entity.toJson();
      expect(json['address'], 'Plateau, Abidjan');
    });
  });
}
