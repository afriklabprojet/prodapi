import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

/// Dialogue de sélection du moyen de paiement mobile money
/// Retourne un Map avec {provider: 'jeko', payment_method: 'wave'|'orange'|...}
/// ou {provider: 'wallet', payment_method: 'wallet'} si paiement par portefeuille.
class PaymentProviderDialog extends StatelessWidget {
  /// Solde disponible dans le portefeuille (null = ne pas afficher l'option wallet)
  final double? walletBalance;
  /// Montant de la commande à payer (pour vérifier la suffisance du solde)
  final double? orderAmount;

  const PaymentProviderDialog({super.key, this.walletBalance, this.orderAmount});

  static Future<Map<String, String>?> show(
    BuildContext context, {
    double? walletBalance,
    double? orderAmount,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PaymentProviderDialog(
        walletBalance: walletBalance,
        orderAmount: orderAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWallet = walletBalance != null;
    final canPayWithWallet =
        hasWallet && (orderAmount == null || walletBalance! >= orderAmount!);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return SimpleDialog(
      title: const Text(
        'Choisir le moyen de paiement',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        // Option Portefeuille (wallet) — toujours en premier
        if (hasWallet)
          _buildWalletOption(
            context: context,
            balance: walletBalance!,
            enabled: canPayWithWallet,
            currencyFormat: currencyFormat,
          ),
        if (hasWallet) const Divider(height: 8, indent: 8, endIndent: 8),
        _buildPaymentMethod(
          context: context,
          method: 'wave',
          name: 'Wave',
          color: AppColors.operatorWave,
          icon: Icons.waves,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'orange',
          name: 'Orange Money',
          color: AppColors.operatorOrange,
          icon: Icons.phone_android,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'mtn',
          name: 'MTN MoMo',
          color: AppColors.operatorMtn,
          icon: Icons.account_balance_wallet,
          textColor: Colors.black87,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'moov',
          name: 'Moov Money',
          color: AppColors.operatorMoov,
          icon: Icons.mobile_friendly,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'djamo',
          name: 'Djamo',
          color: AppColors.operatorDjamo,
          icon: Icons.credit_card,
        ),
      ],
    );
  }

  Widget _buildWalletOption({
    required BuildContext context,
    required double balance,
    required bool enabled,
    required NumberFormat currencyFormat,
  }) {
    const color = AppColors.walletGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled
                ? () => Navigator.pop(context, {
                      'provider': 'wallet',
                      'payment_method': 'wallet',
                    })
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: enabled ? color.withValues(alpha: 0.06) : null,
                border: Border.all(color: color.withValues(alpha: enabled ? 0.6 : 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Portefeuille',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          enabled
                              ? 'Solde : ${currencyFormat.format(balance)}'
                              : 'Solde insuffisant (${currencyFormat.format(balance)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: enabled ? color : Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required BuildContext context,
    required String method,
    required String name,
    required Color color,
    required IconData icon,
    Color textColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context, {
            'provider': 'jeko',
            'payment_method': method,
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: textColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialogue de chargement pour le paiement
class PaymentLoadingDialog extends StatelessWidget {
  const PaymentLoadingDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentLoadingDialog(),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation du paiement...'),
            ],
          ),
        ),
      ),
    );
  }
}
