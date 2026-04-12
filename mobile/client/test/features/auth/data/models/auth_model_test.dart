import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/auth/data/models/auth_response_model.dart';
import 'package:drpharma_client/features/auth/data/models/user_model.dart';
import 'package:drpharma_client/features/auth/domain/entities/auth_response_entity.dart';
import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// Helper JSON
// ────────────────────────────────────────────────────────────────────────────
Map<String, dynamic> _userJson({
  int id = 1,
  String name = 'Jean Dupont',
  String email = 'jean@example.com',
  String phone = '+2250700000001',
  String? address,
  String? avatar,
  String? emailVerifiedAt = '2024-01-01T10:00:00.000Z',
  String? phoneVerifiedAt,
  String createdAt = '2024-01-01T08:00:00.000Z',
  int totalOrders = 5,
  int completedOrders = 3,
  dynamic totalSpent = 12500.0,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'email': email,
  'phone': phone,
  if (address != null) 'address': address,
  if (avatar != null) 'avatar': avatar,
  'email_verified_at': emailVerifiedAt,
  'phone_verified_at': phoneVerifiedAt,
  'created_at': createdAt,
  'total_orders': totalOrders,
  'completed_orders': completedOrders,
  'total_spent': totalSpent,
};

Map<String, dynamic> _authResponseJson({String? firebaseToken}) =>
    <String, dynamic>{
      'user': _userJson(),
      'token': 'tok_abc123',
      if (firebaseToken != null) 'firebase_token': firebaseToken,
    };

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // UserModel
  // ────────────────────────────────────────────────────────────────────────────
  group('UserModel', () {
    group('fromJson', () {
      test('parses all required fields', () {
        final model = UserModel.fromJson(_userJson());

        expect(model.id, 1);
        expect(model.name, 'Jean Dupont');
        expect(model.email, 'jean@example.com');
        expect(model.phone, '+2250700000001');
        expect(model.totalOrders, 5);
        expect(model.completedOrders, 3);
        expect(model.totalSpent, 12500.0);
      });

      test('uses default empty string when name/email/phone missing', () {
        final model = UserModel.fromJson(<String, dynamic>{'id': 1});

        expect(model.name, '');
        expect(model.email, '');
        expect(model.phone, '');
      });

      test('uses default 0 for totalOrders/completedOrders when missing', () {
        final model = UserModel.fromJson(<String, dynamic>{'id': 1});

        expect(model.totalOrders, 0);
        expect(model.completedOrders, 0);
      });

      test('uses default 0.0 for totalSpent when missing', () {
        final model = UserModel.fromJson(<String, dynamic>{'id': 1});

        expect(model.totalSpent, 0.0);
      });

      test('parses optional address', () {
        final model = UserModel.fromJson(
          _userJson(address: '12 rue de la Paix'),
        );
        expect(model.address, '12 rue de la Paix');
      });

      test('parses optional avatar', () {
        final model = UserModel.fromJson(_userJson(avatar: 'avatars/pic.jpg'));
        expect(model.avatar, 'avatars/pic.jpg');
      });

      test('parses emailVerifiedAt', () {
        final model = UserModel.fromJson(
          _userJson(emailVerifiedAt: '2024-01-01T10:00:00.000Z'),
        );
        expect(model.emailVerifiedAt, '2024-01-01T10:00:00.000Z');
      });

      test('parses null phoneVerifiedAt', () {
        final model = UserModel.fromJson(_userJson(phoneVerifiedAt: null));
        expect(model.phoneVerifiedAt, isNull);
      });

      test('parses totalSpent as int (API sometimes sends int)', () {
        final model = UserModel.fromJson(_userJson(totalSpent: 5000));
        expect(model.totalSpent, 5000);
      });

      test('parses totalSpent as string', () {
        final model = UserModel.fromJson(_userJson(totalSpent: '7500.50'));
        // Stored as dynamic, toEntity parses the value
        final entity = model.toEntity();
        expect(entity.totalSpent, 7500.50);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final model = UserModel.fromJson(_userJson());
        final json = model.toJson();

        expect(json['id'], 1);
        expect(json['name'], 'Jean Dupont');
        expect(json['email'], 'jean@example.com');
        expect(json['phone'], '+2250700000001');
      });
    });

    group('toEntity', () {
      test('converts to UserEntity with all fields', () {
        final entity = UserModel.fromJson(_userJson()).toEntity();

        expect(entity, isA<UserEntity>());
        expect(entity.id, 1);
        expect(entity.name, 'Jean Dupont');
        expect(entity.email, 'jean@example.com');
        expect(entity.totalOrders, 5);
        expect(entity.completedOrders, 3);
        expect(entity.totalSpent, 12500.0);
      });

      test('parses email verified date', () {
        final entity = UserModel.fromJson(
          _userJson(emailVerifiedAt: '2024-06-15T12:00:00.000Z'),
        ).toEntity();

        expect(entity.emailVerifiedAt, isNotNull);
        expect(entity.isEmailVerified, isTrue);
      });

      test('returns isEmailVerified = false when emailVerifiedAt is null', () {
        final entity = UserModel.fromJson(
          _userJson(emailVerifiedAt: null),
        ).toEntity();

        expect(entity.isEmailVerified, isFalse);
      });

      test('parses phone verified date', () {
        final entity = UserModel.fromJson(
          _userJson(phoneVerifiedAt: '2024-06-20T10:00:00.000Z'),
        ).toEntity();

        expect(entity.isPhoneVerified, isTrue);
      });

      test('returns isPhoneVerified = false when phoneVerifiedAt is null', () {
        final entity = UserModel.fromJson(
          _userJson(phoneVerifiedAt: null),
        ).toEntity();

        expect(entity.isPhoneVerified, isFalse);
      });

      test('builds avatar URL for relative path', () {
        final entity = UserModel.fromJson(
          _userJson(avatar: 'avatars/profile.jpg'),
        ).toEntity();

        expect(entity.profilePicture, contains('avatars/profile.jpg'));
        expect(entity.hasAvatar, isTrue);
      });

      test('returns avatar as-is for absolute URL', () {
        final entity = UserModel.fromJson(
          _userJson(avatar: 'https://cdn.example.com/avatar.jpg'),
        ).toEntity();

        expect(entity.profilePicture, 'https://cdn.example.com/avatar.jpg');
      });

      test('returns null profilePicture when avatar is null', () {
        final entity = UserModel.fromJson(_userJson()).toEntity();
        // avatar is null in default _userJson
        expect(entity.hasAvatar, isFalse);
      });

      test('address maps correctly', () {
        final entity = UserModel.fromJson(
          _userJson(address: 'Cocody'),
        ).toEntity();

        expect(entity.address, 'Cocody');
        expect(entity.hasAddress, isTrue);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // UserEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('UserEntity computed properties', () {
    final user = UserEntity(
      id: 10,
      name: 'Marie',
      email: 'marie@example.com',
      phone: '+2250700000002',
      createdAt: DateTime(2024, 1, 1),
    );

    test('initials with multi-word name', () {
      final u = user.copyWith(name: 'Marie Dupont');
      expect(u.initials, 'MD');
    });

    test('initials with single name', () {
      final u = user.copyWith(name: 'Alice');
      expect(u.initials, 'A');
    });

    test('initials is ? for empty name', () {
      final u = user.copyWith(name: '');
      expect(u.initials, '?');
    });

    test('hasPhone is true when phone non-empty', () {
      expect(user.hasPhone, isTrue);
    });

    test('hasAddress is false when address null', () {
      expect(user.hasAddress, isFalse);
    });

    test('hasAddress is true when address set', () {
      final u = user.copyWith(address: 'Plateau');
      expect(u.hasAddress, isTrue);
    });

    test('copyWith creates new entity with changed fields', () {
      final copy = user.copyWith(name: 'Alice', email: 'alice@example.com');
      expect(copy.name, 'Alice');
      expect(copy.email, 'alice@example.com');
      expect(copy.id, user.id);
    });

    test('clearAddress clears address in copyWith', () {
      final u = user.copyWith(address: 'Some Address');
      final cleared = u.copyWith(clearAddress: true);
      expect(cleared.address, isNull);
    });

    test('Equatable props work', () {
      final same = UserEntity(
        id: 10,
        name: 'Marie',
        email: 'marie@example.com',
        phone: '+2250700000002',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(user, same);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AuthResponseModel
  // ────────────────────────────────────────────────────────────────────────────
  group('AuthResponseModel', () {
    group('fromJson', () {
      test('parses token and user', () {
        final model = AuthResponseModel.fromJson(_authResponseJson());
        expect(model.token, 'tok_abc123');
        expect(model.user.email, 'jean@example.com');
        expect(model.firebaseToken, isNull);
      });

      test('parses optional firebase_token', () {
        final model = AuthResponseModel.fromJson(
          _authResponseJson(firebaseToken: 'firebase_xyz'),
        );
        expect(model.firebaseToken, 'firebase_xyz');
      });
    });

    group('toJson', () {
      test('serializes token', () {
        final json = AuthResponseModel.fromJson(_authResponseJson()).toJson();
        expect(json['token'], 'tok_abc123');
        expect(json.containsKey('user'), isTrue);
      });
    });

    group('toEntity', () {
      test('converts to AuthResponseEntity', () {
        final entity = AuthResponseModel.fromJson(
          _authResponseJson(),
        ).toEntity();

        expect(entity, isA<AuthResponseEntity>());
        expect(entity.token, 'tok_abc123');
        expect(entity.user.email, 'jean@example.com');
        expect(entity.firebaseToken, isNull);
      });

      test('includes firebaseToken in entity', () {
        final entity = AuthResponseModel.fromJson(
          _authResponseJson(firebaseToken: 'fb_tok'),
        ).toEntity();

        expect(entity.firebaseToken, 'fb_tok');
      });
    });
  });
}
