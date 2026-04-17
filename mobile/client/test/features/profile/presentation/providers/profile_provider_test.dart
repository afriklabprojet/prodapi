import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/profile/presentation/providers/profile_provider.dart';
import 'package:drpharma_client/features/profile/presentation/providers/profile_state.dart';

void main() {
  group('ProfileProvider Tests', () {
    test('profileProvider should be defined', () {
      expect(profileProvider, isNotNull);
    });

    test('profileProvider should be a StateNotifierProvider', () {
      expect(profileProvider, isA<StateNotifierProvider>());
    });

    test('ProfileState should have initial state', () {
      const state = ProfileState();
      expect(state.isLoading, false);
      expect(state.profile, isNull);
      expect(state.errorMessage, isNull);
    });

    test('ProfileState should support loading state', () {
      const state = ProfileState(status: ProfileStatus.loading);
      expect(state.isLoading, true);
    });

    test('ProfileState should support error state', () {
      const state = ProfileState(
        status: ProfileStatus.error,
        errorMessage: 'Test error',
      );
      expect(state.errorMessage, 'Test error');
    });
  });
}
