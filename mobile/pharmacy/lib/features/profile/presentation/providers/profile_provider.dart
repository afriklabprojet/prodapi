import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/core_providers.dart';

/// Notifier pour la gestion du profil pharmacie.
///
/// Utilise [ProfileRepository] pour les opérations réseau
/// et rafraîchit l'état d'auth après chaque mise à jour.
class ProfileNotifier extends Notifier<AsyncValue<void>> {
  late final ProfileRepository _repository;

  @override
  AsyncValue<void> build() {
    final apiClient = ref.watch(apiClientProvider);
    _repository = ProfileRepositoryImpl(apiClient: apiClient);
    return const AsyncData<void>(null);
  }

  /// Met à jour les informations d'une pharmacie.
  Future<void> updatePharmacy(int pharmacyId, Map<String, dynamic> data) async {
    state = const AsyncLoading();

    final result = await _repository.updatePharmacy(pharmacyId, data);

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
      (_) {
        state = const AsyncData<void>(null);
        // Refresh auth state to pick up new pharmacy data
        ref.read(authProvider.notifier).checkAuthStatus();
      },
    );
  }

  /// Met à jour les informations du profil utilisateur.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    final result = await _repository.updateProfile(data);

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        // State is already set to error, no need to throw
      },
      (_) {
        state = const AsyncData<void>(null);
        // Refresh auth state to pick up new profile data
        ref.read(authProvider.notifier).checkAuthStatus();
      },
    );
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<void>>(
  ProfileNotifier.new,
);
