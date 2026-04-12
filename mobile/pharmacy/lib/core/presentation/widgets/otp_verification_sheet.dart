import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';
import '../../../features/auth/presentation/providers/otp_provider.dart';

/// Shows an OTP verification bottom sheet.
///
/// Returns `true` if the user successfully verifies the OTP, `null` if dismissed.
///
/// Usage:
/// ```dart
/// final verified = await showOtpVerificationSheet(
///   context: context,
///   ref: ref,
///   phoneNumber: user.phone,
///   reason: 'modifier votre numéro de téléphone',
/// );
/// if (verified == true) { /* proceed */ }
/// ```
Future<bool?> showOtpVerificationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String phoneNumber,
  String reason = 'effectuer cette action',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _OtpVerificationSheet(phoneNumber: phoneNumber, reason: reason),
  );
}

class _OtpVerificationSheet extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String reason;

  const _OtpVerificationSheet({
    required this.phoneNumber,
    required this.reason,
  });

  @override
  ConsumerState<_OtpVerificationSheet> createState() =>
      _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends ConsumerState<_OtpVerificationSheet> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;
  String? _channelMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP on open
    _sendOtp();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    final result = await ref
        .read(otpServiceProvider)
        .requestOtp(widget.phoneNumber);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSending = false;
          _error = failure.message;
        });
      },
      (channel) {
        setState(() {
          _isSending = false;
          _channelMessage = _channelLabel(channel);
          _resendCooldown = 60;
        });
        _startCooldown();
      },
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != 6) {
      setState(() => _error = 'Saisissez les 6 chiffres du code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final result = await ref
        .read(otpServiceProvider)
        .verifyOtp(identifier: widget.phoneNumber, otp: code);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isVerifying = false;
          _error = failure.message;
        });
        // Clear the code fields on failure
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
      },
      (_) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      },
    );
  }

  String _channelLabel(String channel) {
    return switch (channel) {
      'sms' => 'Code envoyé par SMS',
      'whatsapp' => 'Code envoyé par WhatsApp',
      'email' => 'Code envoyé par email',
      _ => 'Code envoyé',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maskedPhone = PhoneMasker.maskForDisplay(widget.phoneNumber);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Lock icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Vérification requise',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle with masked phone
              Text(
                'Pour ${widget.reason}, saisissez le code envoyé au $maskedPhone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),

              // Channel message
              if (_channelMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _channelMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // OTP input fields
              if (_isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _buildOtpField(i)),
                ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isVerifying || _isSending) ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend link
              TextButton(
                onPressed: (_resendCooldown > 0 || _isSending)
                    ? null
                    : _sendOtp,
                child: Text(
                  _resendCooldown > 0
                      ? 'Renvoyer le code (${_resendCooldown}s)'
                      : 'Renvoyer le code',
                  style: TextStyle(
                    color: _resendCooldown > 0
                        ? Colors.grey
                        : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          // Auto-verify when all 6 digits entered
          if (_otpCode.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }
}
