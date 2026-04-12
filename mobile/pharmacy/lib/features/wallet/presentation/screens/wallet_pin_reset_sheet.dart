import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/wallet_provider.dart';

/// Sheet pour réinitialiser le code PIN oublié via OTP
class WalletPinResetSheet extends ConsumerStatefulWidget {
  /// Callback appelé après réinitialisation réussie
  final VoidCallback? onPinReset;

  const WalletPinResetSheet({super.key, this.onPinReset});

  @override
  ConsumerState<WalletPinResetSheet> createState() =>
      _WalletPinResetSheetState();
}

class _WalletPinResetSheetState extends ConsumerState<WalletPinResetSheet> {
  // Étapes: 0 = demander OTP, 1 = entrer OTP + nouveau PIN
  int _step = 0;

  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _pinFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  String? _maskedPhone;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  // Timer pour le renvoi d'OTP
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _otpFocusNode.dispose();
    _pinFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(walletActionsProvider.notifier)
          .requestPinReset();
      HapticService.onSuccess();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 1;
          _maskedPhone = result['masked_phone'] as String?;
        });
        _startResendTimer();

        // Auto-focus sur le champ OTP
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNode.requestFocus();
        });
      }
    } catch (e) {
      HapticService.onError();
      setState(() {
        _isLoading = false;
        _errorMessage = _parseError(e.toString());
      });
    }
  }

  Future<void> _confirmReset() async {
    final otp = _otpController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    // Validation
    if (otp.length != 6) {
      setState(
        () =>
            _errorMessage = 'Le code de vérification doit contenir 6 chiffres',
      );
      return;
    }

    if (pin.length != 4) {
      setState(() => _errorMessage = 'Le code PIN doit contenir 4 chiffres');
      return;
    }

    if (pin != confirmPin) {
      setState(() => _errorMessage = 'Les codes PIN ne correspondent pas');
      HapticService.onError();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(walletActionsProvider.notifier)
          .confirmPinReset(otp: otp, newPin: pin);
      HapticService.onSuccess();

      if (mounted) {
        Navigator.pop(context);
        widget.onPinReset?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Code PIN réinitialisé avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      HapticService.onError();
      setState(() {
        _isLoading = false;
        _errorMessage = _parseError(e.toString());
      });
    }
  }

  String _parseError(String error) {
    final errorLower = error.toLowerCase();

    // Erreurs OTP
    if (errorLower.contains('otp_invalid') ||
        errorLower.contains('code incorrect') ||
        errorLower.contains('invalid otp') ||
        errorLower.contains('otp invalide')) {
      return 'Le code de vérification est incorrect. Vérifiez le SMS reçu.';
    }
    if (errorLower.contains('otp_expired') ||
        errorLower.contains('expiré') ||
        errorLower.contains('expired')) {
      return 'Le code de vérification a expiré. Demandez un nouveau code.';
    }

    // Erreurs téléphone
    if (errorLower.contains('no_phone') ||
        errorLower.contains('phone_not_found') ||
        errorLower.contains('aucun numéro')) {
      return 'Aucun numéro de téléphone n\'est associé à votre compte. Contactez le support.';
    }

    // Erreurs PIN
    if (errorLower.contains('pin_not_set') ||
        errorLower.contains('pin non configuré')) {
      return 'Vous n\'avez pas encore de code PIN configuré.';
    }
    if (errorLower.contains('pin_already_set') ||
        errorLower.contains('déjà configuré')) {
      return 'Un code PIN est déjà configuré sur votre compte.';
    }

    // Erreurs SMS
    if (errorLower.contains('sms_failed') || errorLower.contains('sms error')) {
      return 'Impossible d\'envoyer le SMS. Réessayez dans quelques instants.';
    }

    // Erreurs réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket') ||
        errorLower.contains('internet')) {
      return 'Problème de connexion internet. Vérifiez votre réseau et réessayez.';
    }

    // Erreurs serveur
    if (errorLower.contains('500') ||
        errorLower.contains('server error') ||
        errorLower.contains('internal')) {
      return 'Le serveur rencontre un problème. Réessayez plus tard.';
    }
    if (errorLower.contains('503') || errorLower.contains('unavailable')) {
      return 'Service temporairement indisponible. Réessayez dans quelques minutes.';
    }
    if (errorLower.contains('401') || errorLower.contains('unauthenticated')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (errorLower.contains('403') || errorLower.contains('forbidden')) {
      return 'Vous n\'êtes pas autorisé à effectuer cette action.';
    }

    // Erreurs de validation
    if (errorLower.contains('422') || errorLower.contains('validation')) {
      return 'Les informations saisies sont incorrectes. Vérifiez et réessayez.';
    }

    return 'Une erreur est survenue. Veuillez réessayer ou contacter le support.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 0 ? 'PIN oublié ?' : 'Nouveau code PIN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _step == 0
                            ? 'Nous allons vérifier votre identité'
                            : 'Entrez le code reçu par SMS',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_step == 0) _buildStep0(isDark) else _buildStep1(isDark),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.sms_outlined, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Un code de vérification sera envoyé par SMS au numéro associé à votre compte.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.orange.withValues(alpha: 0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Envoyer le code de vérification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info avec numéro masqué
        if (_maskedPhone != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Code envoyé au $_maskedPhone',
                    style: TextStyle(
                      color: isDark
                          ? Colors.green.shade200
                          : Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // OTP field
        Text(
          'Code de vérification (6 chiffres)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => _errorMessage = null),
          decoration: InputDecoration(
            hintText: '• • • • • •',
            counterText: '',
            prefixIcon: Icon(Icons.sms_outlined, color: Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),

        // Resend button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resendSeconds > 0 ? null : _requestOtp,
            child: Text(
              _resendSeconds > 0
                  ? 'Renvoyer dans ${_resendSeconds}s'
                  : 'Renvoyer le code',
              style: TextStyle(
                color: _resendSeconds > 0 ? Colors.grey : Colors.orange,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // New PIN field
        Text(
          'Nouveau code PIN (4 chiffres)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pinController,
          focusNode: _pinFocusNode,
          keyboardType: TextInputType.number,
          obscureText: _obscurePin,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => _errorMessage = null),
          decoration: InputDecoration(
            hintText: '• • • •',
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
              ),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Confirm PIN field
        Text(
          'Confirmer le code PIN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPinController,
          keyboardType: TextInputType.number,
          obscureText: _obscureConfirm,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => _errorMessage = null),
          onSubmitted: (_) => _confirmReset(),
          decoration: InputDecoration(
            hintText: '• • • •',
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.orange.withValues(alpha: 0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Réinitialiser mon code PIN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Affiche le sheet de réinitialisation du PIN
void showPinResetSheet(BuildContext context, {VoidCallback? onPinReset}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WalletPinResetSheet(onPinReset: onPinReset),
  );
}
