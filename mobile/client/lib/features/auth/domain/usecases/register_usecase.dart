import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case pour l'inscription
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, dynamic>> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? address,
  }) async {
    return await repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      address: address,
    );
  }
}
