import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/wallet_data.dart';

/// Liste des transactions du portefeuille.
class TransactionList extends StatelessWidget {
  final List<WalletTransaction> transactions;
  final VoidCallback onViewEarnings;
  final VoidCallback onTopUp;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onViewEarnings,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            _buildEmptyState()
          else
            _buildTransactionsList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Historique',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: onViewEarnings,
          icon: const Icon(Icons.trending_up, size: 16),
          label: const Text('Voir les gains'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos rechargements et retraits\napparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Recharger votre wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _TransactionTile(transaction: tx);
      },
    );
  }
}

/// Tuile individuelle pour une transaction.
class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amount = transaction.amount;

    final (icon, bgColor, title) = _getTransactionStyle();
    final date = transaction.createdAt;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: bgColor.withValues(alpha: 0.1),
        child: Icon(icon, color: bgColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(date),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          if (transaction.status == 'pending')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'En attente',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 10),
              ),
            ),
        ],
      ),
      trailing: Text(
        amount.toInt().formatTransaction(isCredit: isCredit),
        style: TextStyle(
          color: isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (IconData, Color, String) _getTransactionStyle() {
    final isCredit = transaction.isCredit;
    String title = transaction.description ?? 'Transaction';

    if (transaction.isCommission) {
      return (Icons.percent, Colors.purple, 'Commission Dr Pharma');
    } else if (transaction.isTopUp) {
      return (Icons.add_circle_outline, Colors.green, 'Rechargement');
    } else if (transaction.isWithdrawal) {
      return (Icons.arrow_downward, Colors.orange, 'Retrait Mobile Money');
    } else {
      return (
        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
        isCredit ? Colors.green : Colors.red,
        title,
      );
    }
  }
}
