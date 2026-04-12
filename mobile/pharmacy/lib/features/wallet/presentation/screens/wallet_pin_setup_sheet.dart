import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/wallet_provider.dart';

/// Sheet pour configurer le code PIN de retrait pour la première fois
class WalletPinSetupSheet extends ConsumerStatefulWidget {
  /// Callback appelé après configuration réussie du PIN
  final VoidCallback? onPinConfigured;

  const WalletPinSetupSheet({super.key, this.onPinConfigured});

  @override
  ConsumerState<WalletPinSetupSheet> createState() =>
      _WalletPinSetupSheetState();
}

class _WalletPinSetupSheetState extends ConsumerState<WalletPinSetupSheet> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    // Validation
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
      await ref.read(walletActionsProvider.notifier).setWithdrawalPin(pin);
      HapticService.onSuccess();

      if (mounted) {
        Navigator.pop(context);
        widget.onPinConfigured?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Code PIN configuré avec succès !'),
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

    // PIN déjà configuré
    if (errorLower.contains('already') ||
        errorLower.contains('déjà') ||
        errorLower.contains('pin_exists')) {
      return 'Un code PIN est déjà configuré sur votre compte.';
    }

    // Erreurs de validation
    if (errorLower.contains('422') ||
        errorLower.contains('validation') ||
        errorLower.contains('invalid')) {
      return 'Le code PIN saisi est invalide. Utilisez 4 chiffres.';
    }

    // Erreurs réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('internet')) {
      return 'Problème de connexion internet. Vérifiez votre réseau et réessayez.';
    }

    // Erreurs serveur
    if (errorLower.contains('500') || errorLower.contains('server')) {
      return 'Le serveur rencontre un problème. Réessayez plus tard.';
    }
    if (errorLower.contains('401') || errorLower.contains('unauthenticated')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    return 'Impossible de configurer le code PIN. Veuillez réessayer.';
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

            // Header avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pin_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurer votre code PIN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ce code sécurise vos retraits',
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

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ce code PIN sera demandé à chaque retrait pour sécuriser vos fonds.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
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
            ],

            const SizedBox(height: 24),

            // PIN field
            Text(
              'Code PIN (4 chiffres)',
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
              onSubmitted: (_) => _confirmFocusNode.requestFocus(),
              decoration: InputDecoration(
                hintText: '• • • •',
                counterText: '',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                ),
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
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
              focusNode: _confirmFocusNode,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirm,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _errorMessage = null),
              onSubmitted: (_) => _setupPin(),
              decoration: InputDecoration(
                hintText: '• • • •',
                counterText: '',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                ),
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _setupPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: Colors.blue.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Configurer mon code PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Affiche le sheet de configuration du PIN
void showPinSetupSheet(BuildContext context, {VoidCallback? onPinConfigured}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WalletPinSetupSheet(onPinConfigured: onPinConfigured),
  );
}
