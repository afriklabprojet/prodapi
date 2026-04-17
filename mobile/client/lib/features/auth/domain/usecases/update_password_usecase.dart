import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_translator.dart';

/// Use case pour changer le mot de passe
class UpdatePasswordUseCase {
  final ApiClient _apiClient;

  UpdatePasswordUseCase(this._apiClient);

  Future<Either<Failure, void>> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.updatePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: ErrorTranslator.toUserFriendly(e.message), statusCode: e.statusCode));
    } on ValidationException catch (e) {
      final translated = ErrorTranslator.translateErrors(e.errors);
      final msg = translated.values.expand((v) => v).join('\n');
      return Left(ValidationFailure(message: msg, errors: translated));
    } catch (e) {
      return Left(ServerFailure(message: 'Une erreur inattendue est survenue.'));
    }
  }
}
