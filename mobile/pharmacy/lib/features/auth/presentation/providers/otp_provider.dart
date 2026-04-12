import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/services/otp_service.dart';

/// OTP service provider — uses the shared ApiClient.
final otpServiceProvider = Provider<OtpService>((ref) {
  return OtpService(ref.watch(apiClientProvider));
});
