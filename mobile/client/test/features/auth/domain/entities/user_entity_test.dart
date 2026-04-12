import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity — isPhoneVerified', () {
    test('true when phoneVerifiedAt is set', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        phoneVerifiedAt: DateTime(2024, 3, 1),
        createdAt: DateTime(2024),
      );
      expect(u.isPhoneVerified, isTrue);
    });

    test('false when phoneVerifiedAt is null', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      expect(u.isPhoneVerified, isFalse);
    });
  });

  group('UserEntity — isEmailVerified', () {
    test('true when emailVerifiedAt is set', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        emailVerifiedAt: DateTime(2024, 3, 1),
        createdAt: DateTime(2024),
      );
      expect(u.isEmailVerified, isTrue);
    });

    test('false when emailVerifiedAt is null', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      expect(u.isEmailVerified, isFalse);
    });
  });

  group('UserEntity — hasAvatar', () {
    test('true when profilePicture is non-empty', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        profilePicture: 'https://example.com/avatar.jpg',
        createdAt: DateTime(2024),
      );
      expect(u.hasAvatar, isTrue);
    });

    test('false when profilePicture is null', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      expect(u.hasAvatar, isFalse);
    });

    test('false when profilePicture is empty string', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        profilePicture: '',
        createdAt: DateTime(2024),
      );
      expect(u.hasAvatar, isFalse);
    });
  });

  group('UserEntity — hasAddress & hasDefaultAddress', () {
    test('true when address is non-empty', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        address: '12 Rue des Fleurs',
        createdAt: DateTime(2024),
      );
      expect(u.hasAddress, isTrue);
      expect(u.hasDefaultAddress, isTrue);
    });

    test('false when address is null', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      expect(u.hasAddress, isFalse);
    });

    test('false when address is empty string', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        address: '',
        createdAt: DateTime(2024),
      );
      expect(u.hasAddress, isFalse);
    });
  });

  group('UserEntity — hasPhone', () {
    test('true when phone is non-empty', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      expect(u.hasPhone, isTrue);
    });

    test('false when phone is empty string', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.hasPhone, isFalse);
    });
  });

  group('UserEntity — initials', () {
    test('two-word name → first letters of first two words', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi Mensah',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.initials, 'KM');
    });

    test('three-word name → first letters of first two words only', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi Asante Mensah',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.initials, 'KA');
    });

    test('single-word name → first letter', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.initials, 'K');
    });

    test('empty name → ?', () {
      final u = UserEntity(
        id: 1,
        name: '',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.initials, '?');
    });

    test('initials are uppercase', () {
      final u = UserEntity(
        id: 1,
        name: 'kofi mensah',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.initials, 'KM');
    });
  });

  group('UserEntity — avatar & defaultAddress aliases', () {
    test('avatar returns profilePicture', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        profilePicture: 'url',
        createdAt: DateTime(2024),
      );
      expect(u.avatar, 'url');
    });

    test('defaultAddress returns address', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        address: 'Rue 1',
        createdAt: DateTime(2024),
      );
      expect(u.defaultAddress, 'Rue 1');
    });
  });

  group('UserEntity — stats', () {
    test('totalOrders, completedOrders, totalSpent default to 0', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        createdAt: DateTime(2024),
      );
      expect(u.totalOrders, 0);
      expect(u.completedOrders, 0);
      expect(u.totalSpent, 0.0);
    });

    test('stat values can be set', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        totalOrders: 10,
        completedOrders: 8,
        totalSpent: 125000.0,
        createdAt: DateTime(2024),
      );
      expect(u.totalOrders, 10);
      expect(u.completedOrders, 8);
      expect(u.totalSpent, 125000.0);
    });
  });

  group('UserEntity — copyWith', () {
    test('updates name only, preserves other fields', () {
      final u = UserEntity(
        id: 1,
        name: 'Kofi',
        email: 'k@k.com',
        phone: '+22507',
        createdAt: DateTime(2024),
      );
      final copy = u.copyWith(name: 'Kwame');
      expect(copy.name, 'Kwame');
      expect(copy.email, 'k@k.com');
      expect(copy.id, 1);
    });

    test('clearAddress sets address to null', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        address: 'Rue 1',
        createdAt: DateTime(2024),
      );
      final copy = u.copyWith(clearAddress: true);
      expect(copy.address, isNull);
    });

    test('clearProfilePicture sets profilePicture to null', () {
      final u = UserEntity(
        id: 1,
        name: 'K',
        email: 'k@k.com',
        phone: '',
        profilePicture: 'url',
        createdAt: DateTime(2024),
      );
      final copy = u.copyWith(clearProfilePicture: true);
      expect(copy.profilePicture, isNull);
    });
  });
}
