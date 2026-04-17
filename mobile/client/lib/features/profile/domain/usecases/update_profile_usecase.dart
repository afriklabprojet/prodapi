import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../entities/update_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;
  UpdateProfileUseCase({required this.repository});

  Future<Either<Failure, ProfileEntity>> call(
    UpdateProfileEntity updateProfile,
  ) async {
    // --- Validation côté client ---

    // Nom : non-null + non-vide uniquement si fourni
    if (updateProfile.name != null && updateProfile.name!.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Le nom est requis',
          errors: {
            'name': ['Le nom ne peut pas être vide'],
          },
        ),
      );
    }

    // Email : format basique
    if (updateProfile.email != null && updateProfile.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(updateProfile.email!)) {
        return const Left(
          ValidationFailure(
            message: 'Email invalide',
            errors: {
              'email': ['Veuillez entrer un email valide'],
            },
          ),
        );
      }
    }

    // Téléphone : au moins 8 chiffres si non-null et non-vide
    if (updateProfile.phone != null && updateProfile.phone!.isNotEmpty) {
      final digits = updateProfile.phone!.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) {
        return const Left(
          ValidationFailure(
            message: 'Téléphone invalide',
            errors: {
              'phone': ['Le numéro doit contenir au moins 8 chiffres'],
            },
          ),
        );
      }
    }

    // Changement de mot de passe
    if (updateProfile.newPassword != null &&
        updateProfile.newPassword!.isNotEmpty) {
      if (updateProfile.currentPassword == null ||
          updateProfile.currentPassword!.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Mot de passe actuel requis',
            errors: {
              'current_password': ['Le mot de passe actuel est requis'],
            },
          ),
        );
      }
      if (updateProfile.newPassword!.length < 8) {
        return const Left(
          ValidationFailure(
            message: 'Mot de passe trop court',
            errors: {
              'password': [
                'Le mot de passe doit contenir au moins 8 caractères',
              ],
            },
          ),
        );
      }
      if (updateProfile.newPassword != updateProfile.newPasswordConfirmation) {
        return const Left(
          ValidationFailure(
            message: 'Les mots de passe ne correspondent pas',
            errors: {
              'password_confirmation': [
                'Les mots de passe ne correspondent pas',
              ],
            },
          ),
        );
      }
    }

    return await repository.updateProfile(updateProfile);
  }
}
