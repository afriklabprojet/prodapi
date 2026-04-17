import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/update_profile_entity.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import 'profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;

  ProfileNotifier({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
  }) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);

    final result = await getProfileUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
      },
      (profile) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
        );
      },
    );
  }

  Future<bool> updateProfile(UpdateProfileEntity updateProfile) async {
    state = state.copyWith(status: ProfileStatus.updating);

    final result = await updateProfileUseCase(updateProfile);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (profile) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
        );
        return true;
      },
    );
  }

  Future<bool> uploadAvatar(Uint8List imageBytes) async {
    if (state.profile == null) return false;

    state = state.copyWith(status: ProfileStatus.uploadingAvatar);

    final result = await uploadAvatarUseCase(imageBytes);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (avatarUrl) {
        // Update profile with new avatar URL
        state = state.copyWith(
          status: ProfileStatus.loaded,
          avatar: avatarUrl,
        );
        return true;
      },
    );
  }

  Future<bool> deleteAvatar() async {
    if (state.profile == null) return false;

    state = state.copyWith(status: ProfileStatus.updating);

    final result = await deleteAvatarUseCase();

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        // Update profile to remove avatar
        state = state.copyWith(
          status: ProfileStatus.loaded,
          clearAvatar: true,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.clearError();
  }
}
