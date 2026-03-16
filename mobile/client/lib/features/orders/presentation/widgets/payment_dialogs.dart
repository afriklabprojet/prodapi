import 'package:flutter/material.dart';

/// Dialogue de sélection du moyen de paiement mobile money
/// Retourne un Map avec {provider: 'jeko', payment_method: 'wave'|'orange'|...}
class PaymentProviderDialog extends StatelessWidget {
  const PaymentProviderDialog({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PaymentProviderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text(
        'Choisir le moyen de paiement',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        _buildPaymentMethod(
          context: context,
          method: 'wave',
          name: 'Wave',
          color: const Color(0xFF1DC3F0),
          icon: Icons.waves,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'orange',
          name: 'Orange Money',
          color: const Color(0xFFFF6600),
          icon: Icons.phone_android,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'mtn',
          name: 'MTN MoMo',
          color: const Color(0xFFFFCC00),
          icon: Icons.account_balance_wallet,
          textColor: Colors.black87,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'moov',
          name: 'Moov Money',
          color: const Color(0xFF0066B3),
          icon: Icons.mobile_friendly,
        ),
        _buildPaymentMethod(
          context: context,
          method: 'djamo',
          name: 'Djamo',
          color: const Color(0xFF6C63FF),
          icon: Icons.credit_card,
        ),
      ],
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
