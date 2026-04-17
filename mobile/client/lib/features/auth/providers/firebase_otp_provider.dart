import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_otp_service.dart';

/// Provider pour le service Firebase OTP
final firebaseOtpServiceProvider = Provider<FirebaseOtpService>((ref) {
  return FirebaseOtpService();
});

/// Etat de la verification OTP Firebase
class FirebaseOtpStateData {
  final FirebaseOtpState state;
  final String? errorMessage;
  final String? firebaseUid;
  final String? phoneNumber;
  final bool isLoading;
  /// Code SMS auto-détecté (rempli quand verificationCompleted fournit le code)
  final String? autoRetrievedSmsCode;

  const FirebaseOtpStateData({
    this.state = FirebaseOtpState.initial,
    this.errorMessage,
    this.firebaseUid,
    this.phoneNumber,
    this.isLoading = false,
    this.autoRetrievedSmsCode,
  });

  FirebaseOtpStateData copyWith({
    FirebaseOtpState? state,
    String? errorMessage,
    String? firebaseUid,
    String? phoneNumber,
    bool? isLoading,
    String? autoRetrievedSmsCode,
  }) {
    return FirebaseOtpStateData(
      state: state ?? this.state,
      errorMessage: errorMessage,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      autoRetrievedSmsCode: autoRetrievedSmsCode ?? this.autoRetrievedSmsCode,
    );
  }
}

/// Notifier pour gerer l'etat de la verification OTP Firebase
class FirebaseOtpNotifier extends StateNotifier<FirebaseOtpStateData> {
  final FirebaseOtpService _service;

  FirebaseOtpNotifier(this._service) : super(const FirebaseOtpStateData()) {
    _service.onStateChanged = _onStateChanged;
    _service.onCodeAutoRetrieved = _onCodeAutoRetrieved;
    _service.onSmsCodeAutoRetrieved = _onSmsCodeAutoRetrieved;
  }

  void _onSmsCodeAutoRetrieved(String smsCode) {
    state = state.copyWith(autoRetrievedSmsCode: smsCode);
  }

  void _onStateChanged(FirebaseOtpState newState, {String? error}) {
    state = state.copyWith(
      state: newState,
      errorMessage: error,
      isLoading: newState == FirebaseOtpState.verifying,
    );
  }

  void _onCodeAutoRetrieved() {
    state = state.copyWith(isLoading: true);
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      phoneNumber: phoneNumber,
    );
    await _service.sendOtp(phoneNumber: phoneNumber);
  }

  Future<FirebaseOtpResult> verifyOtp(String smsCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.verifyOtp(smsCode);
    if (result.success) {
      state = state.copyWith(
        state: FirebaseOtpState.verified,
        firebaseUid: result.firebaseUid,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        state: FirebaseOtpState.error,
        errorMessage: result.errorMessage,
        isLoading: false,
      );
    }
    return result;
  }

  Future<void> resendOtp() async {
    if (state.phoneNumber == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _service.resendOtp(phoneNumber: state.phoneNumber!);
  }

  void reset() {
    _service.reset();
    state = const FirebaseOtpStateData();
  }

  @override
  void dispose() {
    _service.onStateChanged = null;
    _service.onCodeAutoRetrieved = null;
    _service.onSmsCodeAutoRetrieved = null;
    super.dispose();
  }
}

/// Provider pour le notifier Firebase OTP
final firebaseOtpProvider = StateNotifierProvider.autoDispose<FirebaseOtpNotifier, FirebaseOtpStateData>((ref) {
  final service = ref.watch(firebaseOtpServiceProvider);
  return FirebaseOtpNotifier(service);
});
