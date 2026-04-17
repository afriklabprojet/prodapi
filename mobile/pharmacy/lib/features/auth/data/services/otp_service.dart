import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';

/// Service for requesting and verifying OTP codes.
///
/// Used to protect sensitive operations (phone number change, wallet, etc.).
/// Calls the existing backend `/auth/resend` and `/auth/verify` endpoints.
class OtpService {
  final ApiClient _api;

  OtpService(this._api);

  /// Request an OTP to be sent to [identifier] (phone or email).
  ///
  /// Returns the channel used (sms, whatsapp, email) on success.
  Future<Either<Failure, String>> requestOtp(String identifier) async {
    try {
      final response = await _api.dio.post(
        '/auth/resend',
        data: {'identifier': identifier},
      );

      final channel = response.data['channel'] as String? ?? 'sms';
      return Right(channel);
    } catch (e) {
      if (kDebugMode) debugPrint('[OtpService] requestOtp error: $e');
      return Left(
        ServerFailure(
          'Impossible d\'envoyer le code. Réessayez.',
          originalError: e,
        ),
      );
    }
  }

  /// Verify an OTP code for the given [identifier].
  ///
  /// Returns `true` if the code is valid.
  Future<Either<Failure, bool>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      await _api.dio.post(
        '/auth/verify',
        data: {'identifier': identifier, 'otp': otp},
      );
      return const Right(true);
    } catch (e) {
      if (kDebugMode) debugPrint('[OtpService] verifyOtp error: $e');
      return Left(ServerFailure('Code invalide ou expiré', originalError: e));
    }
  }
}
