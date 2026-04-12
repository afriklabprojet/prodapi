import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';

void main() {
  final testUser = UserEntity(
    id: 1,
    name: 'Kofi Mensah',
    email: 'kofi@example.com',
    phone: '+2250700000001',
    createdAt: DateTime(2024, 1, 1),
  );

  group('AuthState — named constructors', () {
    test('initial() sets AuthStatus.initial with null user/error', () {
      const s = AuthState.initial();
      expect(s.status, AuthStatus.initial);
      expect(s.user, isNull);
      expect(s.errorMessage, isNull);
      expect(s.validationErrors, isNull);
    });

    test('loading() sets AuthStatus.loading', () {
      const s = AuthState.loading();
      expect(s.status, AuthStatus.loading);
      expect(s.user, isNull);
      expect(s.errorMessage, isNull);
    });

    test('authenticated(user) sets user and AuthStatus.authenticated', () {
      final s = AuthState.authenticated(testUser);
      expect(s.status, AuthStatus.authenticated);
      expect(s.user, testUser);
      expect(s.errorMessage, isNull);
    });

    test('unauthenticated() sets AuthStatus.unauthenticated', () {
      const s = AuthState.unauthenticated();
      expect(s.status, AuthStatus.unauthenticated);
      expect(s.user, isNull);
    });

    test('error(message) sets AuthStatus.error with message', () {
      const s = AuthState.error(message: 'Identifiants invalides');
      expect(s.status, AuthStatus.error);
      expect(s.errorMessage, 'Identifiants invalides');
      expect(s.user, isNull);
    });

    test('error with validation errors stores them', () {
      const s = AuthState.error(
        message: 'Validation failed',
        errors: {
          'email': ['Email invalide'],
          'password': ['Trop court'],
        },
      );
      expect(s.validationErrors, isNotNull);
      expect(s.validationErrors!['email'], contains('Email invalide'));
    });
  });

  group('AuthState — copyWith', () {
    test('copyWith updates status only', () {
      final s = AuthState.authenticated(testUser);
      final copy = s.copyWith(status: AuthStatus.loading);
      expect(copy.status, AuthStatus.loading);
      expect(copy.user, testUser); // preserved
    });

    test('clearUser removes user', () {
      final s = AuthState.authenticated(testUser);
      final copy = s.copyWith(clearUser: true);
      expect(copy.user, isNull);
    });

    test('clearError removes errorMessage', () {
      const s = AuthState.error(message: 'err');
      final copy = s.copyWith(clearError: true);
      expect(copy.errorMessage, isNull);
    });

    test('clearValidationErrors removes errors', () {
      const s = AuthState.error(
        message: 'err',
        errors: {
          'email': ['bad'],
        },
      );
      final copy = s.copyWith(clearValidationErrors: true);
      expect(copy.validationErrors, isNull);
    });
  });

  group('AuthState — props', () {
    test('two identical states are equal', () {
      final a = AuthState.authenticated(testUser);
      final b = AuthState.authenticated(testUser);
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = AuthState.initial();
      const b = AuthState.unauthenticated();
      expect(a, isNot(equals(b)));
    });
  });
}
