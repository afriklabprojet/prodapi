import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/ui_state_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_otp_service.dart';
import '../../providers/firebase_otp_provider.dart';
import '../providers/auth_provider.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool sendOtpOnInit;
  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.sendOtpOnInit = true,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage>
    with TickerProviderStateMixin, CodeAutoFill {
  static const _otpLength = 6;
  static const _otpCountdownId = 'otp_resend';

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  // Animations
  late AnimationController _enterAnim;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  late AnimationController _iconPulse;
  late Animation<double> _pulseScale;

  late AnimationController _successAnim;

  Timer? _resendTimer;
  bool _autoVerified = false;
  String? _lastAutoFilledCode;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    // Smooth page enter
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _enterAnim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterAnim, curve: Curves.easeOutCubic));

    // Gentle icon pulse
    _iconPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _iconPulse, curve: Curves.easeInOut),
    );

    // Success checkmark
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _enterAnim.forward();

    // Start SMS auto-fill listener (Android only)
    _startSmsListener();

    // Defer provider modifications to after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startResendCountdown();
      if (widget.sendOtpOnInit) _sendFirebaseOtp();
    });
  }

  @override
  void dispose() {
    cancel(); // Cancel SMS auto-fill listener
    unregisterListener(); // Unregister CodeAutoFill listener
    _enterAnim.dispose();
    _iconPulse.dispose();
    _successAnim.dispose();
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SMS AUTO-FILL
  // ---------------------------------------------------------------------------

  /// Start listening for incoming SMS (Android SMS User Consent API)
  Future<void> _startSmsListener() async {
    if (kIsWeb) return;
    try {
      // Listen for SMS using CodeAutoFill mixin
      listenForCode();
      debugPrint('[OTP] SMS auto-fill listener started');
    } catch (e) {
      debugPrint('[OTP] Failed to start SMS listener: $e');
    }
  }

  /// Called automatically by CodeAutoFill when SMS code is detected
  @override
  void codeUpdated() {
    final detectedCode = code;
    if (detectedCode != null && detectedCode.length >= _otpLength) {
      // Extract only digits
      final digits = detectedCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= _otpLength) {
        final otpCode = digits.substring(0, _otpLength);
        debugPrint('[OTP] SMS auto-detected code: $otpCode');
        _autoFillCode(otpCode);
      }
    }
  }

  /// Auto-fill OTP fields and trigger verification
  void _autoFillCode(String otpCode) {
    if (_lastAutoFilledCode == otpCode) return; // Prevent duplicate fills
    _lastAutoFilledCode = otpCode;

    for (int i = 0; i < _otpLength && i < otpCode.length; i++) {
      _controllers[i].text = otpCode[i];
    }
    setState(() {});

    // Unfocus all fields
    for (final f in _focusNodes) {
      f.unfocus();
    }

    // Small delay for visual feedback before auto-verify
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isOtpComplete) {
        _verifyOtp();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // LOGIC
  // ---------------------------------------------------------------------------

  void _startResendCountdown() {
    _resendTimer?.cancel();
    ref.read(countdownProvider(_otpCountdownId).notifier).setValue(60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = ref.read(countdownProvider(_otpCountdownId));
      if (current > 0) {
        ref.read(countdownProvider(_otpCountdownId).notifier).decrement();
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == _otpLength;

  void _onOtpChanged(int index, String value) {
    setState(() {});
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete) _verifyOtp();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _sendFirebaseOtp() async {
    final notifier = ref.read(firebaseOtpProvider.notifier);
    await notifier.sendOtp(widget.phoneNumber);
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) {
      _showSnackBar('Veuillez entrer le code complet', isError: true);
      return;
    }
    final notifier = ref.read(firebaseOtpProvider.notifier);
    final result = await notifier.verifyOtp(_otpCode);
    if (!mounted) return;
    if (result.success) {
      _successAnim.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) await _linkToBackend(result.firebaseUid!);
    }
  }

  /// Handle Firebase auto-verification (verificationCompleted)
  void _handleAutoVerification(FirebaseOtpStateData otpState) {
    // Auto-fill fields if Firebase provided the SMS code
    final autoCode = otpState.autoRetrievedSmsCode;
    if (autoCode != null && autoCode.length == _otpLength && _lastAutoFilledCode != autoCode) {
      _autoFillCode(autoCode);
    }

    // If Firebase auto-verified (verificationCompleted), go to backend
    if (otpState.state == FirebaseOtpState.verified && !_autoVerified && otpState.firebaseUid != null) {
      _autoVerified = true;
      _successAnim.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _linkToBackend(otpState.firebaseUid!);
      });
    }
  }

  Future<void> _linkToBackend(String firebaseUid) async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.verifyFirebaseOtp(
        phone: widget.phoneNumber,
        firebaseUid: firebaseUid,
      );
      if (!mounted) return;
      result.fold(
        (failure) => _showSnackBar(failure.message, isError: true),
        (success) {
          if (context.mounted) context.go(AppRoutes.home);
        },
      );
    } catch (e) {
      if (mounted) _showSnackBar('Erreur de liaison au compte', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _resendOtp() async {
    final countdown = ref.read(countdownProvider(_otpCountdownId));
    if (countdown > 0) return;
    for (var c in _controllers) {
      c.clear();
    }
    _lastAutoFilledCode = null;
    _autoVerified = false;
    _focusNodes[0].requestFocus();
    setState(() {});
    final notifier = ref.read(firebaseOtpProvider.notifier);
    await notifier.resendOtp();
    _startResendCountdown();
    // Restart SMS listener for the new code
    _startSmsListener();
    if (mounted) {
      _showSnackBar('Nouveau code envoyé avec succès');
    }
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+225') && phone.length >= 13) {
      final n = phone.substring(4);
      return '+225 ${n.substring(0, 2)} ${n.substring(2, 4)} ${n.substring(4, 6)} ${n.substring(6, 8)} ${n.substring(8)}';
    }
    return phone;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(firebaseOtpProvider);
    final countdown = ref.watch(countdownProvider(_otpCountdownId));
    final isLoading = otpState.isLoading;
    final errorMessage = otpState.errorMessage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;

    // Handle Firebase auto-verification
    ref.listen<FirebaseOtpStateData>(firebaseOtpProvider, (previous, next) {
      _handleAutoVerification(next);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1512) : Colors.white,
        body: Stack(
          children: [
            _BackgroundDecor(isDark: isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(isDark),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              SizedBox(height: screenH * 0.02),
                              _buildIcon(isDark),
                              const SizedBox(height: 32),
                              _buildHeader(isDark),
                              const SizedBox(height: 32),
                              _buildOtpInput(isDark),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _buildError(errorMessage, isDark),
                              ],
                              const SizedBox(height: 28),
                              _buildVerifyButton(isLoading, isDark),
                              const SizedBox(height: 28),
                              _buildResend(countdown, isLoading, isDark),
                              const SizedBox(height: 40),
                              _buildSecurityNote(isDark),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildBackButton(isDark),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Connexion sécurisée',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.8),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle back navigation: logout first to break the redirect loop,
  /// then navigate to login page.
  Future<void> _handleBack() async {
    // Reset the Firebase OTP state
    ref.read(firebaseOtpProvider.notifier).reset();
    // Logout to clear authenticated state (phone not verified)
    // This prevents the router redirect from sending us back to OTP
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: _handleBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFF5F7F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: isDark ? Colors.white70 : const Color(0xFF3D5347),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ICON
  // ---------------------------------------------------------------------------

  Widget _buildIcon(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseScale,
      builder: (context, child) => Transform.scale(
        scale: _pulseScale.value,
        child: child,
      ),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00D47B), Color(0xFF00A86B), Color(0xFF008556)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 60,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _successAnim,
          builder: (context, child) {
            if (_successAnim.value > 0.5) {
              return const Icon(Icons.check_rounded, size: 48, color: Colors.white);
            }
            return const Icon(Icons.sms_rounded, size: 42, color: Colors.white);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Vérification SMS',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A2B21),
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Entrez le code à 6 chiffres envoyé au',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : const Color(0xFF7A8A80),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.1)
                : const Color(0xFFEDF8F2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            _formatPhone(widget.phoneNumber),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primary : const Color(0xFF1A6B3F),
              letterSpacing: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OTP INPUT
  // ---------------------------------------------------------------------------

  Widget _buildOtpInput(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate field size based on available width
        // 6 fields + 5 gaps (4px each) + 1 dash (20px) = need to fit in maxWidth
        final dashWidth = 20.0;
        final gapWidth = 4.0;
        final totalGaps = (_otpLength - 1) * gapWidth + dashWidth;
        final fieldSize = ((constraints.maxWidth - totalGaps) / _otpLength).clamp(36.0, 48.0);
        final fieldHeight = (fieldSize * 1.15).clamp(44.0, 56.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (i) {
            final isMiddleGap = i == _otpLength ~/ 2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMiddleGap)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gapWidth),
                    child: Container(
                      width: 8,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFBCC5BF),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                if (!isMiddleGap && i > 0) SizedBox(width: gapWidth),
                _buildOtpField(i, isDark, fieldSize: fieldSize, fieldHeight: fieldHeight),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildOtpField(int index, bool isDark, {double fieldSize = 48, double fieldHeight = 56}) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    Color borderColor;
    Color bgColor;

    if (hasValue) {
      borderColor = AppColors.primary;
      bgColor = isDark
          ? AppColors.primary.withValues(alpha: 0.08)
          : const Color(0xFFF0FAF4);
    } else if (isFocused) {
      borderColor = AppColors.primary;
      bgColor = isDark ? const Color(0xFF141E18) : Colors.white;
    } else {
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : const Color(0xFFD8DDD9);
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : const Color(0xFFF7F8F7);
    }

    return GestureDetector(
      onTap: () => _focusNodes[index].requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: fieldSize,
        height: fieldHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isFocused || hasValue ? 1.8 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _onKeyEvent(index, event),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A2B21),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            cursorColor: AppColors.primary,
            cursorHeight: 24,
            cursorWidth: 1.5,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              filled: false,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onOtpChanged(index, value),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR
  // ---------------------------------------------------------------------------

  Widget _buildError(String message, bool isDark) {
    final isRateLimit = message.toLowerCase().contains('trop de tentatives') ||
        message.toLowerCase().contains('too many requests');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRateLimit
            ? const Color(0xFFFFF8E7)
            : isDark
                ? const Color(0xFF2D1515)
                : const Color(0xFFFDF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRateLimit
              ? const Color(0xFFFFE082)
              : isDark
                  ? Colors.red.shade900
                  : const Color(0xFFF5C6C6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRateLimit ? Icons.schedule_rounded : Icons.info_outline_rounded,
            color: isRateLimit
                ? const Color(0xFFF9A825)
                : const Color(0xFFE53935),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isRateLimit
                    ? const Color(0xFF8D6E00)
                    : isDark
                        ? Colors.red.shade300
                        : const Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VERIFY BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildVerifyButton(bool isLoading, bool isDark) {
    final isComplete = _isOtpComplete;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isComplete
              ? const LinearGradient(
                  colors: [Color(0xFF00D47B), Color(0xFF00A86B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isComplete
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF0F2F1),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading || !isComplete ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor:
                isDark ? Colors.white24 : const Color(0xFFB0BAB3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Vérifier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isComplete
                        ? Colors.white
                        : isDark
                            ? Colors.white24
                            : const Color(0xFFB0BAB3),
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESEND
  // ---------------------------------------------------------------------------

  Widget _buildResend(int countdown, bool isLoading, bool isDark) {
    if (countdown > 0) {
      return Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: countdown / 60,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFEDF0EE),
                    color: AppColors.primary,
                    strokeWidth: 3.0,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${countdown}s',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF3D5347),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Renvoyer le code dans',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF9BA8A0),
            ),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: isLoading ? null : _resendOtp,
      icon: Icon(
        Icons.refresh_rounded,
        size: 18,
        color: AppColors.primary.withValues(alpha: 0.9),
      ),
      label: Text(
        'Renvoyer le code',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECURITY NOTE
  // ---------------------------------------------------------------------------

  Widget _buildSecurityNote(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 14,
          color: isDark ? Colors.white24 : const Color(0xFFB0BAB3),
        ),
        const SizedBox(width: 6),
        Text(
          'Vérification chiffrée de bout en bout',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white24 : const Color(0xFFB0BAB3),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BACKGROUND DECORATION
// =============================================================================

class _BackgroundDecor extends StatelessWidget {
  final bool isDark;
  const _BackgroundDecor({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
