import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class DeleteAvatarUseCase {
  final ProfileRepository repository;
  DeleteAvatarUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return await repository.deleteAvatar();
  }
}
