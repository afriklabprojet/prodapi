import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/wallet_provider.dart';
import '../widgets/error_banner_with_support.dart';
import 'wallet_pin_reset_sheet.dart';
import 'wallet_pin_setup_sheet.dart';

/// Affiche le sheet de retrait. Vérifie d'abord si le PIN est configuré.
Future<void> showWalletWithdrawSheet(
  BuildContext parentContext,
  WidgetRef ref,
) async {
  // Vérifier si le PIN est configuré
  try {
    final settings = await ref.read(withdrawalSettingsProvider.future);
    final hasPin = settings['has_pin'] == true;

    if (!hasPin && parentContext.mounted) {
      // PIN pas configuré - afficher d'abord le sheet de configuration
      showPinSetupSheet(
        parentContext,
        onPinConfigured: () {
          // Après configuration, ouvrir le sheet de retrait
          if (parentContext.mounted) {
            _showWithdrawSheetInternal(parentContext, ref);
          }
        },
      );
      return;
    }
  } catch (e) {
    // En cas d'erreur, on tente quand même d'afficher le sheet
    // L'erreur sera gérée lors de la tentative de retrait
  }

  if (parentContext.mounted) {
    _showWithdrawSheetInternal(parentContext, ref);
  }
}

void _showWithdrawSheetInternal(BuildContext parentContext, WidgetRef ref) {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  String selectedMethod = 'wave';
  bool isLoading = false;
  String? errorMessage;
  final wallet = ref.read(walletProvider).value;

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorBannerWithSupport(
                  message: errorMessage!,
                  onDismiss: () => setModalState(() => errorMessage = null),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Demande de retrait',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (wallet != null)
                Text(
                  'Solde disponible: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(wallet.balance)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(ctx).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [10000, 25000, 50000, 100000].map((amount) {
                  return TextButton(
                    onPressed: () {
                      amountController.text = amount.toString();
                      setModalState(() {});
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${amount ~/ 1000}K',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choisir l\'opérateur',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildOperatorCard(
                      imagePath: 'assets/images/wave.png',
                      label: 'Wave',
                      color: AppColors.info,
                      isSelected: selectedMethod == 'wave',
                      onTap: () => setModalState(() => selectedMethod = 'wave'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperatorCard(
                      imagePath: 'assets/images/mtn.png',
                      label: 'MTN',
                      color: AppColors.warning,
                      isSelected: selectedMethod == 'mtn',
                      onTap: () => setModalState(() => selectedMethod = 'mtn'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperatorCard(
                      imagePath: 'assets/images/orange.png',
                      label: 'Orange',
                      color: AppColors.warning,
                      isSelected: selectedMethod == 'orange',
                      onTap: () =>
                          setModalState(() => selectedMethod = 'orange'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildOperatorCard(
                      imagePath: 'assets/images/moov.png',
                      label: 'Moov',
                      color: const Color(0xFF0066B3),
                      isSelected: selectedMethod == 'moov',
                      onTap: () => setModalState(() => selectedMethod = 'moov'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperatorCard(
                      imagePath: 'assets/images/djamo.png',
                      label: 'Djamo',
                      color: const Color(0xFF6B4EFF),
                      isSelected: selectedMethod == 'djamo',
                      onTap: () =>
                          setModalState(() => selectedMethod = 'djamo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodCard(
                      context: context,
                      icon: Icons.account_balance,
                      label: 'Virement',
                      isSelected: selectedMethod == 'bank',
                      onTap: () => setModalState(() => selectedMethod = 'bank'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (selectedMethod != 'bank') ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '07 XX XX XX XX',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(ctx).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Code PIN (4 chiffres)',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(ctx).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (parentContext.mounted) {
                      showPinResetSheet(
                        parentContext,
                        onPinReset: () {
                          if (parentContext.mounted) {
                            _showWithdrawSheetInternal(parentContext, ref);
                          }
                        },
                      );
                    }
                  },
                  child: const Text(
                    'PIN oublié ?',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            setModalState(
                              () => errorMessage =
                                  'Veuillez entrer un montant valide',
                            );
                            return;
                          }
                          if (amount < 1000) {
                            setModalState(
                              () => errorMessage =
                                  'Le montant minimum de retrait est de 1 000 FCFA',
                            );
                            return;
                          }
                          if (wallet != null && amount > wallet.balance) {
                            setModalState(
                              () => errorMessage =
                                  'Solde insuffisant pour ce retrait (${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(wallet.balance)} disponible)',
                            );
                            return;
                          }
                          if (selectedMethod != 'bank' &&
                              phoneController.text.trim().isEmpty) {
                            setModalState(
                              () => errorMessage =
                                  'Veuillez entrer votre numéro de téléphone',
                            );
                            return;
                          }

                          final securityService = ref.read(
                            securityServiceProvider,
                          );
                          bool biometricPassed = false;

                          if (securityService.isBiometricEnabled()) {
                            final biometricResult = await securityService
                                .authenticateWithBiometric(
                                  reason:
                                      'Confirmez votre retrait de ${NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0).format(amount)} FCFA',
                                );
                            if (biometricResult.success) {
                              biometricPassed = true;
                            } else if (biometricResult.errorCode ==
                                'permanent_lockout') {
                              setModalState(
                                () => errorMessage =
                                    'Biométrie bloquée. Veuillez utiliser votre code PIN.',
                              );
                            }
                          }

                          if (!biometricPassed &&
                              pinController.text.trim().length != 4) {
                            setModalState(
                              () => errorMessage =
                                  'Le code PIN doit contenir 4 chiffres',
                            );
                            return;
                          }

                          setModalState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          HapticService.onTransaction(); // Feedback transaction

                          try {
                            final response = await ref
                                .read(walletActionsProvider.notifier)
                                .requestWithdrawal(
                                  amount: amount,
                                  paymentMethod: selectedMethod,
                                  phone: selectedMethod != 'bank'
                                      ? phoneController.text.trim()
                                      : null,
                                  pin: biometricPassed
                                      ? null
                                      : pinController.text.trim(),
                                );

                            if (!parentContext.mounted || !ctx.mounted) {
                              return;
                            }
                            HapticService.onSuccess(); // Feedback succès
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        (response['message'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? response['message'] as String
                                            : 'Demande de retrait envoyee',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            HapticService.onError(); // Feedback erreur

                            final errorStr = e.toString();

                            // Détecter l'erreur "PIN non configuré"
                            if (errorStr.contains('PIN_NOT_CONFIGURED') ||
                                errorStr.contains('configurer un code PIN')) {
                              // Fermer le sheet de retrait
                              Navigator.pop(ctx);
                              // Afficher le sheet de configuration du PIN
                              if (parentContext.mounted) {
                                showPinSetupSheet(
                                  parentContext,
                                  onPinConfigured: () {
                                    // Réouvrir le sheet de retrait après configuration
                                    if (parentContext.mounted) {
                                      _showWithdrawSheetInternal(
                                        parentContext,
                                        ref,
                                      );
                                    }
                                  },
                                );
                              }
                              return;
                            }

                            setModalState(() {
                              isLoading = false;
                              errorMessage = _parseWithdrawError(errorStr);
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmer le retrait',
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
      ),
    ),
  );
}

Widget _buildPaymentMethodCard({
  required BuildContext context,
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildOperatorCard({
  required String imagePath,
  required String label,
  required Color color,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Parse les erreurs de retrait en messages user-friendly
/// Délègue au parseWalletError centralisé pour éviter la duplication
String _parseWithdrawError(String error) => parseWalletError(error).message;
