import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/models/wallet_data.dart';
import '../../../core/utils/number_formatter.dart';

class GainsCard extends StatelessWidget {
  final User user;
  final WalletData? walletData;

  const GainsCard({super.key, required this.user, this.walletData});

  @override
  Widget build(BuildContext context) {
    final courier = user.courier;
    final balance = walletData?.balance ?? 0;
    final earnings = walletData?.totalEarnings ?? 0;
    final topups = walletData?.totalTopups ?? 0;
    final commissions = walletData?.totalCommissions ?? 0;
    final deliveries = walletData?.deliveriesCount ?? courier?.completedDeliveries ?? 0;
    final rating = courier?.rating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // === Stats row ===
          Row(
            children: [
              _statTile(
                icon: Icons.local_shipping_outlined,
                value: '$deliveries',
                label: 'Livraisons',
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 10),
              _statTile(
                icon: Icons.star_rounded,
                value: (rating ?? 0) > 0 ? rating!.toStringAsFixed(1) : '--',
                label: 'Note',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _statTile(
                icon: Icons.trending_up_rounded,
                value: earnings.formatCurrencyCompact(),
                label: 'Gains',
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // === Wallet card ===
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF065F46), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF065F46).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Solde disponible',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  balance.formatCurrency(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _walletMini(
                      Icons.arrow_downward_rounded,
                      'Rechargé',
                      '${topups.formatCurrencyCompact()} F',
                    ),
                    _walletDivider(),
                    _walletMini(
                      Icons.receipt_long_outlined,
                      'Commissions',
                      '${commissions.formatCurrencyCompact()} F',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D26),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletMini(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
