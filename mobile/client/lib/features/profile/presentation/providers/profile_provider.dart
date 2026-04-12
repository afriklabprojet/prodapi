import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final repository = ref.watch(profileRepositoryProvider);

  return ProfileNotifier(
    getProfileUseCase: GetProfileUseCase(repository: repository),
    updateProfileUseCase: UpdateProfileUseCase(repository: repository),
    uploadAvatarUseCase: UploadAvatarUseCase(repository: repository),
    deleteAvatarUseCase: DeleteAvatarUseCase(repository: repository),
  );
});
