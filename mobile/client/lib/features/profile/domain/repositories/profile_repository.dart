import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../entities/update_profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, ProfileEntity>> updateProfile(
    UpdateProfileEntity updateProfile,
  );
  Future<Either<Failure, String>> uploadAvatar(Uint8List imageBytes);
  Future<Either<Failure, void>> deleteAvatar();
}
