import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/router/route_names.dart';
import '../../data/repositories/auth_repository.dart';

/// But de l'écran OTP
enum OtpPurpose {
  /// Vérification de téléphone après inscription
  verification,

  /// OTP pour connexion sans mot de passe
  login,

  /// OTP pour réinitialisation de mot de passe
  passwordReset,
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier; // téléphone ou email
  final OtpPurpose purpose;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.purpose = OtpPurpose.verification,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  // Countdown pour le renvoi
  int _resendCooldown = 60;
  Timer? _resendTimer;

  static const int _otpLength = 6;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _fullOtp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _fullOtp;
    if (otp.length != _otpLength) {
      setState(
        () =>
            _errorMessage = 'Veuillez saisir les $_otpLength chiffres du code.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Vérifier via l'API backend (source unique de vérité)
      if (widget.purpose == OtpPurpose.passwordReset) {
        final resetToken = await authRepo.verifyResetOtp(
          widget.identifier,
          otp,
        );
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.changePassword,
          extra: {'resetToken': resetToken},
        );
      } else {
        final user = await authRepo.verifyOtp(widget.identifier, otp);
        if (!mounted) return;

        // Vérifier le statut du coursier avant de naviguer
        final courierStatus = user.courier?.status;
        if (courierStatus == 'suspended' || courierStatus == 'rejected') {
          context.go(
            AppRoutes.pendingApproval,
            extra: {
              'status': courierStatus,
              'message': courierStatus == 'suspended'
                  ? 'Votre compte a été suspendu.'
                  : 'Votre demande a été refusée.',
            },
          );
        } else {
          // pending_approval et incomplete_kyc → dashboard avec KycBanner
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _clearOtpFields();
      }
    }
  }

  void _clearOtpFields() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final purpose = switch (widget.purpose) {
        OtpPurpose.passwordReset => 'password_reset',
        OtpPurpose.login => 'login',
        OtpPurpose.verification => 'verification',
      };

      // Renvoyer via API backend (source unique)
      await authRepo.sendOtp(
        widget.identifier,
        purpose: purpose,
        forceFallback: true,
      );

      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code renvoyé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final r = Responsive.of(context);
    final isReset = widget.purpose == OtpPurpose.passwordReset;
    final isLogin = widget.purpose == OtpPurpose.login;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.login);
          }
        },
        child: Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              // ── Header gradient ──
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark, r, isReset, isLogin),
              ),

              // ── Contenu ──
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.dp(24)),
                  child: Column(
                    children: [
                      SizedBox(height: r.dp(32)),

                      // Champs OTP
                      _buildOtpFields(isDark, r),

                      SizedBox(height: r.dp(16)),

                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(r.dp(12)),
                          margin: EdgeInsets.only(bottom: r.dp(8)),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.shade900.withValues(alpha: 0.3)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade700
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700,
                              ),
                              SizedBox(width: r.dp(8)),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: isDark
                                        ? Colors.red.shade300
                                        : Colors.red.shade700,
                                    fontSize: r.sp(13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: r.dp(8)),

                      // Bouton Vérifier
                      _buildVerifyButton(isDark, r, isReset, isLogin),

                      SizedBox(height: r.dp(24)),

                      // Renvoyer le code
                      _buildResendSection(isDark, r),

                      const Spacer(),

                      // Info canal
                      _buildInfoBanner(isDark, r),

                      SizedBox(height: r.dp(16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Responsive r,
    bool isReset,
    bool isLogin,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2940), const Color(0xFF0D1B2A)]
              : [DesignTokens.primary, DesignTokens.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.dp(20), r.dp(8), r.dp(20), r.dp(32)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(r.dp(8)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: r.dp(18),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Logo compact
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.dp(12),
                      vertical: r.dp(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_pharmacy_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: r.dp(16),
                        ),
                        SizedBox(width: r.dp(6)),
                        Text(
                          'DR PHARMA',
                          style: GoogleFonts.inter(
                            fontSize: r.sp(11),
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: r.dp(28)),

              // Icône
              Container(
                padding: EdgeInsets.all(r.dp(16)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isReset ? Icons.lock_reset_rounded : Icons.message_rounded,
                  size: r.dp(32),
                  color: Colors.white,
                ),
              ),

              SizedBox(height: r.dp(20)),

              // Titre
              Text(
                isReset
                    ? 'Réinitialisation'
                    : isLogin
                    ? 'Connexion par code'
                    : 'Vérification OTP',
                style: GoogleFonts.inter(
                  fontSize: r.sp(24),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: r.dp(8)),

              Text(
                isLogin
                    ? 'Entrez le code à 6 chiffres envoyé au'
                    : 'Entrez le code envoyé au',
                style: GoogleFonts.inter(
                  fontSize: r.sp(14),
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: r.dp(8)),

              // Numéro masqué dans un chip glassmorphism
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.dp(16),
                      vertical: r.dp(8),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          size: r.dp(16),
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        SizedBox(width: r.dp(8)),
                        Text(
                          _maskIdentifier(widget.identifier),
                          style: GoogleFonts.inter(
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(
    bool isDark,
    Responsive r,
    bool isReset,
    bool isLogin,
  ) {
    final isComplete = _fullOtp.length == _otpLength;

    return SizedBox(
      width: double.infinity,
      height: r.dp(54),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isComplete && !_isVerifying
              ? const LinearGradient(
                  colors: [DesignTokens.primary, DesignTokens.primaryDark],
                )
              : null,
          color: isComplete && !_isVerifying
              ? null
              : (isDark ? const Color(0xFF2D3E4E) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isComplete && !_isVerifying
              ? [
                  BoxShadow(
                    color: DesignTokens.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isVerifying ? null : _verifyOtp,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isVerifying
                  ? SizedBox(
                      width: r.dp(22),
                      height: r.dp(22),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isReset
                              ? Icons.lock_open_rounded
                              : isLogin
                              ? Icons.login_rounded
                              : Icons.verified_rounded,
                          color: Colors.white,
                          size: r.dp(20),
                        ),
                        SizedBox(width: r.dp(10)),
                        Text(
                          isReset
                              ? 'Vérifier'
                              : isLogin
                              ? 'Se connecter'
                              : 'Confirmer le code',
                          style: GoogleFonts.inter(
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(bool isDark, Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.dp(16), vertical: r.dp(12)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2030) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3E4E) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh_rounded,
            size: r.dp(18),
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
          SizedBox(width: r.dp(8)),
          Text(
            'Pas reçu ? ',
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: r.sp(13),
            ),
          ),
          if (_resendCooldown > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.dp(10),
                vertical: r.dp(4),
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withValues(alpha: 0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_resendCooldown}s',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _isResending ? null : _resendOtp,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.dp(12),
                  vertical: r.dp(4),
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.primary.withValues(alpha: 0.15)
                      : DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isResending ? 'Envoi...' : 'Renvoyer',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? DesignTokens.primaryLight
                        : DesignTokens.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: r.sp(13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark, Responsive r) {
    return Container(
      padding: EdgeInsets.all(r.dp(14)),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.info.withValues(alpha: 0.1)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? DesignTokens.info.withValues(alpha: 0.3)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.dp(6)),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.info.withValues(alpha: 0.2)
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sms_rounded,
              size: r.dp(16),
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
          ),
          SizedBox(width: r.dp(10)),
          Expanded(
            child: Text(
              'Le code est envoyé par WhatsApp ou SMS. Vérifiez aussi vos messages.',
              style: GoogleFonts.inter(
                fontSize: r.sp(12),
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields(bool isDark, Responsive r) {
    return Column(
      children: [
        // Label
        Text(
          'Code de vérification',
          style: GoogleFonts.inter(
            fontSize: r.sp(13),
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        SizedBox(height: r.dp(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final hasValue = _controllers[index].text.isNotEmpty;
            final isFocused = _focusNodes[index].hasFocus;

            // Séparateur visuel après le 3e digit
            final widgets = <Widget>[];
            if (index == 3) {
              widgets.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.dp(6)),
                  child: Container(
                    width: r.dp(12),
                    height: 2,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              );
            }

            widgets.add(
              Container(
                width: r.dp(46),
                height: r.dp(58),
                margin: EdgeInsets.symmetric(horizontal: r.dp(3)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: hasValue
                        ? (isDark
                              ? DesignTokens.primary.withValues(alpha: 0.12)
                              : DesignTokens.primary.withValues(alpha: 0.06))
                        : (isDark ? const Color(0xFF1A2030) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasValue
                          ? DesignTokens.primary
                          : isFocused
                          ? DesignTokens.primaryLight
                          : (isDark
                                ? const Color(0xFF2D3E4E)
                                : const Color(0xFFE2E8F0)),
                      width: hasValue || isFocused ? 2 : 1.5,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: DesignTokens.primary.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : hasValue
                        ? [
                            BoxShadow(
                              color: DesignTokens.primary.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.inter(
                      fontSize: r.sp(24),
                      fontWeight: FontWeight.w700,
                      color: hasValue
                          ? (isDark
                                ? DesignTokens.primaryLight
                                : DesignTokens.primary)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_fullOtp.length == 6) {
                        _verifyOtp();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            );

            return Row(mainAxisSize: MainAxisSize.min, children: widgets);
          }),
        ),
      ],
    );
  }

  /// Masquer partiellement l'identifiant pour la confidentialité
  String _maskIdentifier(String identifier) {
    if (identifier.contains('@')) {
      // Email: a***@gmail.com
      final parts = identifier.split('@');
      if (parts[0].length <= 2) return identifier;
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
    // Téléphone: +225 07 ** ** 00
    if (identifier.length > 6) {
      return '${identifier.substring(0, 6)} ** ** ${identifier.substring(identifier.length - 2)}';
    }
    return identifier;
  }
}
