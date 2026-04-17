import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../data/models/wallet_data.dart';
import '../providers/wallet_provider.dart';

export 'wallet_withdraw_sheet.dart' show showWalletWithdrawSheet;
export 'wallet_export_sheet.dart' show showWalletExportSheet;
export 'wallet_statistics_sheet.dart'
    show showWalletStatisticsSheet, filterWalletTransactionsByPeriod;

Widget buildWalletTransactionCard(BuildContext context, WalletTransaction tx) {
  final isCredit = tx.type == 'credit';
  final currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final sign = isCredit ? '+' : '-';
  final isDark = AppColors.isDark(context);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCredit
                ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.successBg)
                : (isDark
                      ? AppColors.urgent.withValues(alpha: 0.2)
                      : AppColors.errorBg),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isCredit ? AppColors.primary : AppColors.urgent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.description ?? 'Transaction',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tx.date ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$sign${currencyFormat.format(tx.amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isCredit ? AppColors.primary : AppColors.urgent,
          ),
        ),
      ],
    ),
  );
}

void showWalletHistorySheet(BuildContext parentContext, WidgetRef ref) {
  final walletAsync = ref.watch(walletProvider);

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historique complet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueWidget<WalletData>(
                value: walletAsync,
                isEmpty: (wallet) => wallet.transactions.isEmpty,
                emptyTitle: 'Aucune transaction',
                emptyMessage: 'Aucune transaction effectuée pour le moment.',
                onRetry: () => ref.refresh(walletProvider),
                data: (wallet) {
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = wallet.transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildWalletTransactionCard(context, tx),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
