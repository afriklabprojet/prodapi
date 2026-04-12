import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/profile/domain/entities/profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/entities/update_profile_entity.dart';
import 'package:drpharma_client/features/profile/domain/repositories/profile_repository.dart';
import 'package:drpharma_client/features/profile/domain/usecases/delete_avatar_usecase.dart';
import 'package:drpharma_client/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:drpharma_client/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:drpharma_client/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:drpharma_client/features/profile/presentation/providers/profile_notifier.dart';
import 'package:drpharma_client/features/profile/presentation/providers/profile_state.dart';

// ─────────────────────────────────────────────────────────
// Fake repository
// ─────────────────────────────────────────────────────────

class _FakeProfileRepository implements ProfileRepository {
  Either<Failure, ProfileEntity>? profileResult;
  Either<Failure, ProfileEntity>? updateResult;
  Either<Failure, String>? uploadResult;
  Either<Failure, void>? deleteResult;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async => profileResult!;

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile(
    UpdateProfileEntity data,
  ) async => updateResult!;

  @override
  Future<Either<Failure, String>> uploadAvatar(Uint8List bytes) async =>
      uploadResult!;

  @override
  Future<Either<Failure, void>> deleteAvatar() async => deleteResult!;
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

final _testProfile = ProfileEntity(
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  createdAt: DateTime(2024, 1, 1),
);

ProfileNotifier _makeNotifier(_FakeProfileRepository repo) {
  return ProfileNotifier(
    getProfileUseCase: GetProfileUseCase(repository: repo),
    updateProfileUseCase: UpdateProfileUseCase(repository: repo),
    uploadAvatarUseCase: UploadAvatarUseCase(repository: repo),
    deleteAvatarUseCase: DeleteAvatarUseCase(repository: repo),
  );
}

void main() {
  group('ProfileNotifier', () {
    // ── initial state ──────────────────────────────────
    group('initial state', () {
      test('is initial with no profile', () {
        final repo = _FakeProfileRepository();
        final notifier = _makeNotifier(repo);
        expect(notifier.state.status, ProfileStatus.initial);
        expect(notifier.state.profile, isNull);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    // ── loadProfile ────────────────────────────────────
    group('loadProfile', () {
      test('emits loading then loaded on success', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile);
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();

        expect(notifier.state.status, ProfileStatus.loaded);
        expect(notifier.state.profile, _testProfile);
        expect(notifier.state.errorMessage, isNull);
      });

      test('emits loading then error on failure', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = const Left(ServerFailure(message: 'Server error'));
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();

        expect(notifier.state.status, ProfileStatus.error);
        expect(notifier.state.errorMessage, 'Server error');
        expect(notifier.state.profile, isNull);
      });

      test('isLoading transitions correctly', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile);
        final notifier = _makeNotifier(repo);

        final states = <ProfileStatus>[];
        notifier.addListener((s) => states.add(s.status));

        await notifier.loadProfile();

        expect(states, contains(ProfileStatus.loading));
        expect(states.last, ProfileStatus.loaded);
      });
    });

    // ── updateProfile ──────────────────────────────────
    group('updateProfile', () {
      final updateData = const UpdateProfileEntity(name: 'New Name');
      final updatedProfile = ProfileEntity(
        id: 1,
        name: 'New Name',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
      );

      test('returns true and sets loaded on success', () async {
        final repo = _FakeProfileRepository()
          ..updateResult = Right(updatedProfile);
        final notifier = _makeNotifier(repo);

        final result = await notifier.updateProfile(updateData);

        expect(result, isTrue);
        expect(notifier.state.status, ProfileStatus.loaded);
        expect(notifier.state.profile?.name, 'New Name');
      });

      test('returns false and sets error on failure', () async {
        final repo = _FakeProfileRepository()
          ..updateResult = const Left(
            ValidationFailure(message: 'Nom invalide'),
          );
        final notifier = _makeNotifier(repo);

        final result = await notifier.updateProfile(updateData);

        expect(result, isFalse);
        expect(notifier.state.status, ProfileStatus.error);
        expect(notifier.state.errorMessage, 'Nom invalide');
      });

      test('transitions through updating state', () async {
        final repo = _FakeProfileRepository()
          ..updateResult = Right(updatedProfile);
        final notifier = _makeNotifier(repo);

        final statuses = <ProfileStatus>[];
        notifier.addListener((s) => statuses.add(s.status));

        await notifier.updateProfile(updateData);

        expect(statuses, contains(ProfileStatus.updating));
        expect(statuses.last, ProfileStatus.loaded);
      });
    });

    // ── uploadAvatar ───────────────────────────────────
    group('uploadAvatar', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      test('returns false immediately when profile is null', () async {
        final repo = _FakeProfileRepository();
        final notifier = _makeNotifier(repo);

        final result = await notifier.uploadAvatar(bytes);

        expect(result, isFalse);
        expect(notifier.state.status, ProfileStatus.initial);
      });

      test('returns true and updates avatar on success', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile)
          ..uploadResult = const Right('https://cdn.example.com/avatar.jpg');
        final notifier = _makeNotifier(repo);

        // First load the profile so it's not null
        await notifier.loadProfile();

        final result = await notifier.uploadAvatar(bytes);

        expect(result, isTrue);
        expect(notifier.state.status, ProfileStatus.loaded);
        expect(
          notifier.state.profile?.avatar,
          'https://cdn.example.com/avatar.jpg',
        );
      });

      test('returns false and sets error on failure', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile)
          ..uploadResult = const Left(ServerFailure(message: 'Upload failed'));
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();
        final result = await notifier.uploadAvatar(bytes);

        expect(result, isFalse);
        expect(notifier.state.status, ProfileStatus.error);
      });

      test('transitions through uploadingAvatar state', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile)
          ..uploadResult = const Right('https://cdn.example.com/avatar.jpg');
        final notifier = _makeNotifier(repo);
        await notifier.loadProfile();

        final statuses = <ProfileStatus>[];
        notifier.addListener((s) => statuses.add(s.status));

        await notifier.uploadAvatar(bytes);

        expect(statuses, contains(ProfileStatus.uploadingAvatar));
        expect(statuses.last, ProfileStatus.loaded);
      });
    });

    // ── deleteAvatar ───────────────────────────────────
    group('deleteAvatar', () {
      test('returns false immediately when profile is null', () async {
        final repo = _FakeProfileRepository();
        final notifier = _makeNotifier(repo);

        final result = await notifier.deleteAvatar();
        expect(result, isFalse);
      });

      test('returns true and clears avatar on success', () async {
        final profileWithAvatar = ProfileEntity(
          id: 1,
          name: 'Test',
          email: 'test@test.com',
          avatar: 'https://cdn.example.com/avatar.jpg',
          createdAt: DateTime(2024),
        );
        final repo = _FakeProfileRepository()
          ..profileResult = Right(profileWithAvatar)
          ..deleteResult = const Right(null);
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();
        final result = await notifier.deleteAvatar();

        expect(result, isTrue);
        expect(notifier.state.status, ProfileStatus.loaded);
        expect(notifier.state.profile?.avatar, isNull);
      });

      test('returns false and sets error on failure', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile)
          ..deleteResult = const Left(ServerFailure(message: 'Delete error'));
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();
        final result = await notifier.deleteAvatar();

        expect(result, isFalse);
        expect(notifier.state.status, ProfileStatus.error);
      });
    });

    // ── clearError ──────────────────────────────────────
    group('clearError', () {
      test('resets status to initial when no profile', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = const Left(ServerFailure(message: 'Err'));
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();
        expect(notifier.state.status, ProfileStatus.error);

        notifier.clearError();

        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.status, ProfileStatus.initial);
      });

      test('resets status to loaded when profile exists', () async {
        final repo = _FakeProfileRepository()
          ..profileResult = Right(_testProfile)
          ..updateResult = const Left(ValidationFailure(message: 'Err'));
        final notifier = _makeNotifier(repo);

        await notifier.loadProfile();
        await notifier.updateProfile(const UpdateProfileEntity(name: 'X'));
        expect(notifier.state.status, ProfileStatus.error);

        notifier.clearError();

        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.status, ProfileStatus.loaded);
      });
    });
  });
}
