import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/usecases/get_profile_usecase.dart';

/// AsyncNotifier pour charger le profil utilisateur de façon réactive
class ProfileAsyncNotifier extends AsyncNotifier<ProfileEntity?> {
  @override
  Future<ProfileEntity?> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    final result = await GetProfileUseCase(repository: repository).call();
    return result.fold((_) => null, (profile) => profile);
  }
}

final profileAsyncProvider =
    AsyncNotifierProvider<ProfileAsyncNotifier, ProfileEntity?>(
      ProfileAsyncNotifier.new,
    );
