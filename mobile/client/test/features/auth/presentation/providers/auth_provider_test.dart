import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:drpharma_client/features/auth/presentation/providers/auth_state.dart';

void main() {
  group('AuthProvider Tests', () {
    test('authProvider should be defined', () {
      expect(authProvider, isNotNull);
    });

    test('authProvider should be a StateNotifierProvider', () {
      expect(authProvider, isA<StateNotifierProvider>());
    });

    test('AuthState should have initial state', () {
      const state = AuthState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('AuthState should have loading state', () {
      const state = AuthState.loading();
      expect(state.status, AuthStatus.loading);
    });

    test('AuthState should have error state', () {
      const state = AuthState.error(message: 'Test error');
      expect(state.errorMessage, 'Test error');
    });
  });
}
