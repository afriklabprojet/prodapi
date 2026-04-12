import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/utils/error_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/router/route_names.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import 'otp_verification_screen.dart';

// ---------------------------------------------------------------------------
// Login Screen
// ---------------------------------------------------------------------------
class LoginScreenRedesign extends ConsumerStatefulWidget {
  const LoginScreenRedesign({super.key});

  @override
  ConsumerState<LoginScreenRedesign> createState() =>
      _LoginScreenRedesignState();
}

class _LoginScreenRedesignState extends ConsumerState<LoginScreenRedesign> {
  // --- Controllers ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  // --- State ---
  String _appVersion = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _mode = 'email'; // 'email' | 'otp'
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  bool get _isOtpMode => _mode == 'otp';

  // ======================================================================
  // Lifecycle
  // ======================================================================

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkBiometric();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // ======================================================================
  // Init helpers
  // ======================================================================

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _checkBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final canCheck = await biometricService.canCheckBiometrics();
    final isEnabled = ref.read(biometricSettingsProvider);
    if (mounted) {
      setState(() {
        _biometricAvailable = canCheck;
        _biometricEnabled = isEnabled;
      });
      if (canCheck && isEnabled) {
        Future.delayed(const Duration(milliseconds: 700), _loginWithBiometric);
      }
    }
  }

  // ======================================================================
  // Auth actions
  // ======================================================================

  Future<void> _login() async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    _clearErrors();

    if (_isOtpMode) return _loginWithOtp();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .login(_emailController.text.trim(), _passwordController.text);
      HapticFeedback.mediumImpact();
      if (mounted) context.go(AppRoutes.dashboard);
    } catch (e, stackTrace) {
      ErrorHandler.logError('LOGIN', e, stackTrace);
      HapticFeedback.heavyImpact();
      _handleLoginError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _emailError = l10n.pleaseEnterPhoneNumber);
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone, purpose: 'login');
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.push(
          AppRoutes.otpVerification,
          extra: {'identifier': phone, 'purpose': OtpPurpose.login},
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('LOGIN_OTP', e, stackTrace);
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _generalError = e
              .toString()
              .replaceAll(RegExp(r'Exception:?\s*'), '')
              .trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    final biometricService = ref.read(biometricServiceProvider);
    try {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();
      final authenticated = await biometricService.authenticate(
        reason: l10n.biometricAuthReason,
      );
      if (!authenticated) return;
      final authRepo = ref.read(authRepositoryProvider);
      if (await authRepo.hasStoredCredentials()) {
        await authRepo.loginWithStoredCredentials();
        if (mounted) context.go(AppRoutes.dashboard);
      } else {
        _showSnackBar(l10n.loginWithCredentialsFirst, isWarning: true);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('BIOMETRIC', e, stackTrace);
      _showSnackBar(l10n.biometricError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ======================================================================
  // Error handling
  // ======================================================================

  void _handleLoginError(dynamic e) {
    final l10n = AppLocalizations.of(context)!;
    final msg = e.toString().replaceAll(RegExp(r'Exception:?\s*'), '').trim();
    final lower = msg.toLowerCase();

    if (_isNetworkError(lower)) {
      setState(() => _generalError = l10n.connectionFailed);
    } else if (_isCredentialsError(lower)) {
      setState(() {
        _emailError = l10n.incorrectCredentials;
        _passwordError = l10n.checkEmailAndPassword;
      });
    } else if (_isAccountStatusError(lower)) {
      setState(() => _generalError = msg);
    } else {
      setState(
        () => _generalError = msg.length > 200 ? l10n.errorOccurredRetry : msg,
      );
    }
  }

  bool _isNetworkError(String e) =>
      e.contains('xmlhttprequest') ||
      e.contains('connection') ||
      e.contains('dioexception') ||
      e.contains('socketexception') ||
      e.contains('network') ||
      e.contains('timeout');

  bool _isCredentialsError(String e) =>
      e.contains('password') ||
      e.contains('credentials') ||
      e.contains('invalid') ||
      e.contains('unauthorized') ||
      e.contains('401');

  bool _isAccountStatusError(String e) =>
      e.contains('attente') ||
      e.contains('pending') ||
      e.contains('suspendu') ||
      e.contains('suspended') ||
      e.contains('kyc');

  void _clearErrors() => setState(() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
  });

  void _clearError(String field) => setState(() {
    if (field == 'email') _emailError = null;
    if (field == 'password') _passwordError = null;
  });

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.error
            : isWarning
            ? AppColors.warning
            : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ======================================================================
  // Forgot-password sheet (unchanged business logic)
  // ======================================================================

  void _showForgotPasswordSheet() {
    final l10n = AppLocalizations.of(context)!;
    final resetController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;
    bool usePhone = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 28,
                    color: DesignTokens.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.resetPassword,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  usePhone
                      ? l10n.resetPasswordPhoneDesc
                      : l10n.resetPasswordEmailDesc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                // Method toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildResetChip(
                      l10n.phone,
                      Icons.phone_outlined,
                      usePhone,
                      () => setSheet(() {
                        usePhone = true;
                        resetController.clear();
                      }),
                    ),
                    const SizedBox(width: 12),
                    _buildResetChip(
                      l10n.email,
                      Icons.email_outlined,
                      !usePhone,
                      () => setSheet(() {
                        usePhone = false;
                        resetController.clear();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  key: resetFormKey,
                  child: _buildField(
                    controller: resetController,
                    label: usePhone ? l10n.phoneNumber : l10n.emailAddress,
                    hint: usePhone ? l10n.phoneHint : l10n.pleaseEnterEmail,
                    icon: usePhone
                        ? Icons.phone_outlined
                        : Icons.email_outlined,
                    keyboardType: usePhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return usePhone
                            ? l10n.pleaseEnterPhoneNumber
                            : l10n.pleaseEnterEmail;
                      }
                      if (!usePhone && (!v.contains('@') || !v.contains('.'))) {
                        return l10n.invalidEmail;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSending
                        ? null
                        : () async {
                            if (!resetFormKey.currentState!.validate()) return;
                            HapticFeedback.lightImpact();
                            setSheet(() => isSending = true);
                            try {
                              final id = resetController.text.trim();
                              final authRepo = ref.read(authRepositoryProvider);
                              if (usePhone) {
                                await authRepo.forgotPasswordByPhone(id);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                                if (mounted) {
                                  context.push(
                                    AppRoutes.otpVerification,
                                    extra: {
                                      'identifier': id,
                                      'purpose': OtpPurpose.passwordReset,
                                    },
                                  );
                                }
                              } else {
                                await authRepo.forgotPassword(id);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                                if (mounted) {
                                  _showSnackBar(l10n.resetLinkSent);
                                }
                              }
                            } catch (e) {
                              HapticFeedback.heavyImpact();
                              setSheet(() => isSending = false);
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceAll(
                                            RegExp(r'Exception:?\s*'),
                                            '',
                                          )
                                          .trim(),
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSending
                        ? const SizedBox.shrink()
                        : Icon(
                            usePhone ? Icons.sms_outlined : Icons.send_rounded,
                            size: 18,
                          ),
                    label: isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            usePhone ? l10n.sendOtpCode : l10n.sendLink,
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: DesignTokens.primary.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetChip(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? DesignTokens.primary
                : DesignTokens.fieldBorderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? DesignTokens.primary : DesignTokens.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? DesignTokens.primary : DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // BUILD
  // ======================================================================

  // Couleurs du nouveau design
  static const Color _headerNavy = Color(0xFF0F1C3F);
  static const Color _accentYellow = Color(0xFFE5C76B);
  static const Color _accentTeal = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildDecorativeHeader(context),
              _buildFormSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================================
  // DECORATIVE HEADER - Navy avec formes géométriques
  // ======================================================================

  Widget _buildDecorativeHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 340,
      decoration: const BoxDecoration(
        color: _headerNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Formes décoratives - Cercle jaune semi-transparent
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentYellow.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          // Cercle jaune plein petit
          Positioned(
            top: 60,
            right: 40,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _accentYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Forme abstraite en bas à gauche
          Positioned(
            bottom: 80,
            left: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _accentTeal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Lignes décoratives
          Positioned(
            top: 120,
            left: 30,
            child: SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(painter: _DecorativeLinesPainter()),
            ),
          ),
          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Logo DR-PHARMA
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_pharmacy_rounded,
                            color: DesignTokens.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DR-PHARMA',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.textDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Indicateur de progression avec checkmark
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: DesignTokens.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Welcome message
                  Text(
                    'Bon retour 👋',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte livreur',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // FORM SECTION - Formulaire blanc
  // ======================================================================

  Widget _buildFormSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented control stylisé
            _buildModernSegmentedControl(),
            const SizedBox(height: 24),

            // Error banner
            if (_generalError != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 16),
            ],

            // Form panes
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _isOtpMode
                  ? _buildOtpPane(l10n)
                  : _buildModernEmailPane(l10n),
            ),
            const SizedBox(height: 28),

            // CTA button
            _buildModernCTAButton(l10n),

            // Biometric
            if (_biometricAvailable &&
                _biometricEnabled &&
                !_isOtpMode &&
                !_isLoading)
              _buildBiometricRow(l10n),

            const SizedBox(height: 28),

            // Register link
            Center(
              child: Text.rich(
                TextSpan(
                  text: "Vous n'avez pas de compte ? ",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: Text(
                          'Créer un compte',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Version
            if (_appVersion.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  l10n.versionLabel(_appVersion),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // Modern Segmented Control
  // ======================================================================

  Widget _buildModernSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildModernSegmentTab(
            label: 'Email',
            icon: Icons.email_outlined,
            isActive: !_isOtpMode,
            onTap: () {
              if (_isOtpMode) {
                HapticFeedback.lightImpact();
                setState(() {
                  _mode = 'email';
                  _clearErrors();
                });
              }
            },
          ),
          _buildModernSegmentTab(
            label: 'OTP',
            icon: Icons.sms_outlined,
            isActive: _isOtpMode,
            onTap: () {
              if (!_isOtpMode) {
                HapticFeedback.lightImpact();
                setState(() {
                  _mode = 'otp';
                  _clearErrors();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernSegmentTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? DesignTokens.primary : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? DesignTokens.primary : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================================
  // Modern Email Pane
  // ======================================================================

  Widget _buildModernEmailPane(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('modern_email_pane'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email field avec fond vert clair
        _buildModernField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'Email ou téléphone',
          hint: 'exemple@email.com',
          icon: Icons.person_outline_rounded,
          error: _emailError,
          fillColor: DesignTokens.primary.withValues(alpha: 0.08),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _clearError('email'),
        ),
        const SizedBox(height: 18),
        // Password field
        _buildModernField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          error: _passwordError,
          isPassword: true,
          onChanged: (_) => _clearError('password'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: Text(
              'Mot de passe oublié ?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    Color? fillColor,
    TextInputType? keyboardType,
    bool isPassword = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _headerNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: fillColor ?? Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: error != null
                  ? BorderSide(color: AppColors.error.withValues(alpha: 0.5))
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: DesignTokens.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  // ======================================================================
  // Modern CTA Button
  // ======================================================================

  Widget _buildModernCTAButton(AppLocalizations l10n) {
    final label = _isOtpMode ? l10n.sendCode : 'Se connecter';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DesignTokens.primary.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: DesignTokens.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ======================================================================
  // OTP Pane
  // ======================================================================

  Widget _buildOtpPane(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('otp_pane'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          label: l10n.phoneNumber.toUpperCase(),
          hint: l10n.phoneHint,
          icon: Icons.phone_outlined,
          error: _emailError,
          keyboardType: TextInputType.phone,
          onChanged: (_) => _clearError('email'),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 16,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code OTP à 6 chiffres',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entrez votre numéro puis appuyez sur « ${l10n.sendCode} ». La vérification du code se fera sur l’écran suivant.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ======================================================================
  // Biometric row
  // ======================================================================

  Widget _buildBiometricRow(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: DesignTokens.fieldBorderLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.or,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: DesignTokens.fieldBorderLight)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _loginWithBiometric,
            icon: const Icon(Icons.fingerprint_rounded, size: 22),
            label: Text(
              l10n.biometricLogin,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.primary,
              side: BorderSide(
                color: DesignTokens.primary.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================================
  // Error banner
  // ======================================================================

  Widget _buildErrorBanner() {
    final isConnection = _generalError!.toLowerCase().contains('connexion');
    final color = isConnection ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isConnection ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generalError!,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // Shared field builder
  // ======================================================================

  Widget _buildField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    bool isPassword = false,
    bool autofocus = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: DesignTokens.fontSizeCaption,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: hasError ? AppColors.error : context.tokenLabelColor,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          obscureText: isPassword && _obscurePassword,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: FontWeight.w500,
            color: context.tokenTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: DesignTokens.fontSizeBody,
              color: context.tokenIconColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                icon,
                size: DesignTokens.fieldIconSize,
                color: hasError ? AppColors.error : context.tokenIconColor,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: DesignTokens.fieldIconSize,
                      color: context.tokenIconColor,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: hasError
                ? AppColors.error.withValues(alpha: 0.04)
                : context.tokenFieldBg,
            contentPadding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spaceMd,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(color: context.tokenFieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withValues(alpha: 0.5)
                    : context.tokenFieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : DesignTokens.primary,
                width: 1.5,
              ),
            ),
          ),
          validator:
              validator ??
              (v) {
                if (v == null || v.isEmpty) {
                  return AppLocalizations.of(context)!.fieldRequired;
                }
                return null;
              },
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: DesignTokens.spaceMd),
            child: Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// Custom Painter for decorative lines
// ============================================================================

class _DecorativeLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5C76B).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ligne horizontale
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );

    // Ligne verticale
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      paint,
    );

    // Petit cercle au centre
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      4,
      Paint()..color = const Color(0xFFE5C76B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
