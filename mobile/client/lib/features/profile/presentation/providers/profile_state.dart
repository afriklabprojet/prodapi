import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  uploadingAvatar,
  error,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  bool get isLoading => status == ProfileStatus.loading;
  bool get isUpdating => status == ProfileStatus.updating;
  bool get isUploadingAvatar => status == ProfileStatus.uploadingAvatar;
  bool get hasError => status == ProfileStatus.error;
  bool get hasProfile => profile != null;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileEntity? profile,
    bool clearProfile = false,
    String? errorMessage,
    bool clearError = false,
    String? avatar,
    bool clearAvatar = false,
  }) {
    ProfileEntity? newProfile = clearProfile ? null : (profile ?? this.profile);
    // Handle avatar updates
    if (avatar != null && newProfile != null) {
      newProfile = newProfile.copyWith(avatar: avatar);
    } else if (clearAvatar && newProfile != null) {
      newProfile = newProfile.copyWith(clearAvatar: true);
    }
    return ProfileState(
      status: status ?? this.status,
      profile: newProfile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  ProfileState clearError() {
    return copyWith(
      status: hasProfile ? ProfileStatus.loaded : ProfileStatus.initial,
      clearError: true,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
