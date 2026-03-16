import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';

/// État du profil pharmacie
class ProfileState {
  final bool isLoading;
  final bool hasError;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.hasError = false,
    this.error,
  });

  ProfileState copyWith({bool? isLoading, bool? hasError, String? error}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? false,
      error: error,
    );
  }
}

/// Notifier pour la gestion du profil pharmacie
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(const ProfileState());

  Future<void> updatePharmacy(int pharmacyId, dynamic data) async {
    state = state.copyWith(isLoading: true, hasError: false, error: null);
    try {
      await _apiClient.post('/pharmacy/profile/$pharmacyId', data: data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileNotifier(apiClient);
});
