import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/wallet_data.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/utils/responsive.dart';

class EarningsHistoryScreen extends ConsumerWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletDataProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Historique des Revenus'),
        backgroundColor: context.cardBackground,
        foregroundColor: context.primaryText,
        elevation: 0,
      ),
      body: AsyncValueWidget<WalletData>(
        value: walletAsync,
        data: (wallet) => _EarningsContent(wallet: wallet),
        onRetry: () => ref.invalidate(walletDataProvider),
      ),
    );
  }
}

// Provider pour les données du wallet
final walletDataProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.getWalletData();
});

class _EarningsContent extends StatelessWidget {
  final WalletData wallet;

  const _EarningsContent({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    
    // Calculer les statistiques depuis les transactions
    final earnings = wallet.transactions
        .where((t) => t.type == 'credit' && t.category == 'delivery_earning')
        .toList();
    
    final commissions = wallet.transactions
        .where((t) => t.type == 'debit' && t.category == 'commission')
        .toList();
    
    final totalEarnings = earnings.fold<double>(
      0, (sum, t) => sum + t.amount,
    );
    
    final totalCommissions = commissions.fold<double>(
      0, (sum, t) => sum + t.amount.abs(),
    );
    
    final netEarnings = totalEarnings - totalCommissions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé des gains
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gains Nets',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${currencyFormat.format(netEarnings)} ${wallet.currency}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.r.sp(32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Total Gains',
                        value: '${currencyFormat.format(totalEarnings)} ${wallet.currency}',
                        icon: Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Commissions',
                        value: '-${currencyFormat.format(totalCommissions)} ${wallet.currency}',
                        icon: Icons.arrow_downward,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistiques par période
          Row(
            children: [
              Expanded(
                child: _PeriodCard(
                  title: "Aujourd'hui",
                  amount: _calculatePeriodEarnings(wallet.transactions, 0),
                  currency: wallet.currency,
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PeriodCard(
                  title: 'Cette semaine',
                  amount: _calculatePeriodEarnings(wallet.transactions, 7),
                  currency: wallet.currency,
                  icon: Icons.date_range,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _PeriodCard(
                  title: 'Ce mois',
                  amount: _calculatePeriodEarnings(wallet.transactions, 30),
                  currency: wallet.currency,
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PeriodCard(
                  title: 'Livraisons',
                  amount: earnings.length.toDouble(),
                  currency: '',
                  isCount: true,
                  icon: Icons.local_shipping,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Détail des commissions amélioré
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.percent, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commission Plateforme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Par livraison effectuée',
                        style: TextStyle(color: context.secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Text(
                    '${wallet.commissionAmount} ${wallet.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des transactions de gains
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique des Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.filter_list, color: context.iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          
          if (wallet.transactions.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 30),
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_outlined, size: 40, color: Colors.blue.shade200),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(
                      color: context.primaryText, 
                      fontSize: 18,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "L'historique de vos revenus et commissions apparaîtra ici une fois que vous effectuerez des livraisons.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.secondaryText,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallet.transactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = wallet.transactions[index];
                return _TransactionItem(transaction: tx, currency: wallet.currency);
              },
            ),
        ],
      ),
    );
  }

  double _calculatePeriodEarnings(List<WalletTransaction> transactions, int days) {
    final now = DateTime.now();
    final startDate = days == 0 
        ? DateTime(now.year, now.month, now.day) 
        : now.subtract(Duration(days: days));
    
    return transactions
        .where((t) => 
            t.type == 'credit' && 
            t.category == 'delivery_earning' &&
            t.createdAt.isAfter(startDate))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final IconData icon;
  final Color color;
  final bool isCount;

  const _PeriodCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: context.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            isCount 
                ? '${amount.toInt()}' 
                : '${currencyFormat.format(amount)} $currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final WalletTransaction transaction;
  final String currency;

  const _TransactionItem({
    required this.transaction,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'credit';
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');
    
    IconData icon;
    Color color;
    String title;
    
    switch (transaction.category) {
      case 'delivery_earning':
        icon = Icons.local_shipping;
        color = Colors.green;
        title = 'Gain livraison';
        break;
      case 'commission':
        icon = Icons.percent;
        color = Colors.red;
        title = 'Commission plateforme';
        break;
      case 'topup':
        icon = Icons.add_circle;
        color = Colors.blue;
        title = 'Rechargement';
        break;
      case 'withdrawal':
        icon = Icons.remove_circle;
        color = Colors.orange;
        title = 'Retrait';
        break;
      case 'bonus':
        icon = Icons.star;
        color = Colors.amber;
        title = 'Bonus';
        break;
      default:
        icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
        color = isCredit ? Colors.green : Colors.red;
        title = transaction.description ?? 'Transaction';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.primaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(transaction.createdAt),
                  style: TextStyle(color: context.secondaryText, fontSize: 12),
                ),
                if (transaction.reference != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Réf: ${transaction.reference}',
                    style: TextStyle(color: context.tertiaryText, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount.abs())} $currency',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
