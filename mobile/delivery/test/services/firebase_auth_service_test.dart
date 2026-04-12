import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:courier/core/services/firebase_auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FirebaseAuthService service;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    service = FirebaseAuthService(auth: mockAuth);
  });

  tearDown(() {
    service.dispose();
  });

  group('FirebaseAuthService', () {
    test('currentUser returns null when not signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(service.currentUser, isNull);
    });

    test('isAuthenticated returns false when not signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(service.isAuthenticated, false);
    });

    test('isAuthenticated returns true when signed in', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(service.isAuthenticated, true);
    });

    test('signInWithCustomToken returns true on success', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockAuth.signInWithCustomToken('token-123'),
      ).thenAnswer((_) async => mockCredential);
      when(() => mockAuth.currentUser).thenReturn(MockUser());

      final result = await service.signInWithCustomToken('token-123');
      expect(result, true);
      verify(() => mockAuth.signInWithCustomToken('token-123')).called(1);
    });

    test('signInWithCustomToken returns false on failure', () async {
      when(() => mockAuth.signInWithCustomToken('bad-token')).thenThrow(
        FirebaseAuthException(code: 'invalid-custom-token', message: 'Invalid'),
      );

      final result = await service.signInWithCustomToken('bad-token');
      expect(result, false);
    });

    test('signOut calls Firebase signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await service.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });

    test('getIdToken returns null when no user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final token = await service.getIdToken();
      expect(token, isNull);
    });

    test('getIdToken returns token from user', () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockUser.getIdToken(false),
      ).thenAnswer((_) async => 'id-token-123');

      final token = await service.getIdToken();
      expect(token, 'id-token-123');
    });

    test('getIdToken with forceRefresh', () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockUser.getIdToken(true),
      ).thenAnswer((_) async => 'fresh-token');

      final token = await service.getIdToken(forceRefresh: true);
      expect(token, 'fresh-token');
    });

    test('refreshTokenIfNeeded is no-op when no user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      await service.refreshTokenIfNeeded();
      // Should not throw
    });

    test('authStateChanges returns stream', () {
      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));
      expect(service.authStateChanges, isA<Stream<User?>>());
    });
  });
}
