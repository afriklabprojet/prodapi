import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  });

  /// Register new customer
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
  });

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get stored token
  Future<String?> getToken();

  /// Update password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Verify OTP code for phone verification
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required String identifier,
    required String otp,
  });

  /// Verify phone via Firebase Authentication
  Future<Either<Failure, AuthResponseEntity>> verifyFirebaseOtp({
    required String phone,
    required String firebaseUid,
  });

  /// Resend OTP code
  /// Returns a map with 'message' and 'channel' keys
  Future<Either<Failure, Map<String, dynamic>>> resendOtp({
    required String identifier,
  });

  /// Request password reset email
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  /// Verify reset OTP code
  Future<Either<Failure, void>> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Reset password with OTP
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  });
}
