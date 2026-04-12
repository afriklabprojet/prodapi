import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  final ProfileRepository repository;
  UploadAvatarUseCase({required this.repository});

  static const int _maxSizeBytes = 5 * 1024 * 1024; // 5 MB

  Future<Either<Failure, String>> call(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Image invalide',
          errors: {
            'avatar': ['Aucune image sélectionnée'],
          },
        ),
      );
    }
    if (imageBytes.length > _maxSizeBytes) {
      return const Left(
        ValidationFailure(
          message: 'Image trop volumineuse',
          errors: {
            'avatar': ['L\'image ne doit pas dépasser 5MB'],
          },
        ),
      );
    }
    return await repository.uploadAvatar(imageBytes);
  }
}
