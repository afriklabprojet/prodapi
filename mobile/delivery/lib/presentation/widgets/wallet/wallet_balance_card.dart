import 'package:flutter/material.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/wallet_data.dart';

/// Carte affichant le solde du portefeuille et les statistiques.
class WalletBalanceCard extends StatelessWidget {
  final WalletData wallet;
  final VoidCallback onTopUp;
  final VoidCallback? onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.onTopUp,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final canWithdraw = wallet.balance > 500;

    return Container(
      width: double.infinity,
      margin: r.pad(16),
      padding: r.pad(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde Disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildBalance(r),
          if (wallet.pendingPayouts != null && wallet.pendingPayouts! > 0)
            _buildPendingPayouts(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildActionButtons(canWithdraw),
        ],
      ),
    );
  }

  Widget _buildBalance(Responsive r) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        wallet.balance.formatCurrency(symbol: wallet.currency),
        style: TextStyle(
          color: Colors.white,
          fontSize: r.sp(32),
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildPendingPayouts() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Retrait en attente: ${wallet.pendingPayouts!.formatCurrencyCompact()} ${wallet.currency}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatItem(
          label: 'Livraisons',
          value: wallet.deliveriesCount.toString(),
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(width: 12),
        _StatItem(
          label: 'Gains',
          value: wallet.totalEarnings.formatCurrencyCompact(),
          icon: Icons.trending_up,
        ),
        const SizedBox(width: 12),
        _StatItem(
          label: 'Commissions',
          value: wallet.totalCommissions.formatCurrencyCompact(),
          icon: Icons.trending_down,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool canWithdraw) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTopUp,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Recharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canWithdraw ? onWithdraw : null,
            icon: const Icon(Icons.arrow_downward),
            label: const Text('Retirer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              disabledForegroundColor: Colors.white54,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget interne pour afficher une statistique.
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
