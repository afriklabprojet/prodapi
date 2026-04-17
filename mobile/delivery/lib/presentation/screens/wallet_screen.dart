import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/route_names.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/utils/app_exceptions.dart';
import '../../data/models/wallet_data.dart';
import '../../data/repositories/jeko_payment_repository.dart';
import '../providers/profile_provider.dart';
import '../providers/wallet_provider.dart' show walletProvider;
import '../widgets/common/common_widgets.dart';
import '../widgets/wallet/wallet_widgets.dart';
import 'payment_status_screen.dart';

class _WalletColors {
  static const navyDark = Color(0xFF0F1C3F);
  static const navyMedium = Color(0xFF1A2B52);
  static const accentGold = Color(0xFFE5C76B);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF60A5FA);
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const softBackground = Color(0xFFF8FAFC);
}

/// Écran principal du portefeuille redesigné.
///
/// Affiche le solde, les transactions et permet les rechargements/retraits.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    _checkPendingPayment();
  }

  /// Vérifie si un paiement JEKO était en cours lors d'un précédent lancement.
  Future<void> _checkPendingPayment() async {
    final pending = await PaymentStatusScreen.getPendingPayment();
    if (pending == null || !mounted) return;

    final reference = pending['reference'] as String?;
    if (reference == null) return;

    try {
      final repo = ref.read(jekoPaymentRepositoryProvider);
      final status = await repo.checkPaymentStatus(reference);
      if (status.isSuccess) {
        ref.invalidate(walletProvider);
        await PaymentStatusScreen.clearPendingPayment();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement précédent confirmé ! Solde mis à jour.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (status.isFailed) {
        await PaymentStatusScreen.clearPendingPayment();
      }
    } catch (_) {
      // Silencieux — le polling serveur se chargera de confirmer.
    }
  }

  Future<void> _refreshWallet() async {
    ref.invalidate(walletProvider);
    try {
      await ref.read(walletProvider.future);
    } catch (_) {
      // L'UI d'erreur existante prendra le relais si nécessaire.
    }
  }

  void _showTopUpDialog({String? preselectedMethod}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TopUpSheet(
        preselectedMethod: preselectedMethod,
        onSuccess: () => ref.invalidate(walletProvider),
      ),
    );
  }

  void _showWithdrawDialog(double maxAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WithdrawSheet(
        maxAmount: maxAmount,
        onSuccess: () => ref.invalidate(walletProvider),
      ),
    );
  }

  void _openEarningsHistory() {
    context.push(AppRoutes.historyExport);
  }

  void _openExportSheet() {
    final profile = ref.read(profileProvider);
    final courierName = profile.value?.name ?? 'Livreur';
    EarningsExportSheet.show(context, courierName: courierName);
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: _WalletColors.softBackground,
      body: walletAsync.when(
        data: (wallet) => RefreshIndicator(
          onRefresh: _refreshWallet,
          color: _WalletColors.navyDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, wallet),
                if (!wallet.canDeliver)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildActivationBanner(wallet),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatsGrid(wallet),
                      const SizedBox(height: 16),
                      _buildOperatorsSection(),
                      const SizedBox(height: 16),
                      _buildTransactionsSection(wallet.transactions),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const AppLoadingWidget(),
        error: (err, stack) => err is IncompleteKycException
            ? AppErrorWidget(
                message:
                    'Complétez votre vérification d\'identité pour accéder au portefeuille.',
                icon: Icons.verified_user_outlined,
                iconColor: Colors.orange,
                title: 'Vérification requise',
              )
            : AppErrorWidget(
                message: err is AppException
                    ? err.userMessage
                    : err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(walletProvider),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WalletData wallet) {
    final availableBalance = wallet.availableBalance ?? wallet.balance;
    final canWithdraw = availableBalance > 500;
    final currency = wallet.currency == 'XOF' ? 'FCFA' : wallet.currency;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_WalletColors.navyDark, _WalletColors.navyMedium],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon Portefeuille',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Gérez vos gains et retraits',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.download_rounded,
                    tooltip: 'Exporter revenus',
                    onTap: _openExportSheet,
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Actualiser',
                    onTap: () => ref.invalidate(walletProvider),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Solde disponible',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  wallet.balance.formatCurrency(symbol: currency),
                  style: GoogleFonts.sora(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.verified_rounded,
                    label: wallet.canDeliver
                        ? 'Compte actif'
                        : 'Activation requise',
                    color: wallet.canDeliver
                        ? _WalletColors.successGreen
                        : _WalletColors.warningOrange,
                  ),
                  _InfoChip(
                    icon: Icons.savings_rounded,
                    label:
                        'Disponible ${availableBalance.formatCurrency(symbol: currency)}',
                    color: _WalletColors.accentTeal,
                  ),
                  if ((wallet.pendingPayouts ?? 0) > 0)
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label:
                          'En attente ${wallet.pendingPayouts!.formatCurrency(symbol: currency)}',
                      color: _WalletColors.accentGold,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Recharger',
                      filled: true,
                      onTap: _showTopUpDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Retirer',
                      onTap: canWithdraw
                          ? () => _showWithdrawDialog(availableBalance)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivationBanner(WalletData wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _WalletColors.warningOrange.withValues(alpha: 0.14),
            _WalletColors.accentGold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _WalletColors.warningOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _WalletColors.warningOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: _WalletColors.warningOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activez vos livraisons',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _WalletColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez au moins ${wallet.commissionAmount.formatCurrency()} pour recevoir des commandes.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _showTopUpDialog,
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WalletData wallet) {
    final availableBalance = wallet.availableBalance ?? wallet.balance;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _WalletMetricCard(
          title: 'Disponible',
          value: availableBalance.formatCurrency(),
          icon: Icons.account_balance_wallet_outlined,
          color: _WalletColors.accentBlue,
        ),
        _WalletMetricCard(
          title: 'Aujourd’hui',
          value: wallet.todayEarnings.formatCurrency(),
          icon: Icons.bolt_rounded,
          color: _WalletColors.successGreen,
        ),
        _WalletMetricCard(
          title: 'Total gains',
          value: wallet.totalEarnings.formatCurrency(),
          icon: Icons.trending_up_rounded,
          color: _WalletColors.accentTeal,
        ),
        _WalletMetricCard(
          title: 'Livraisons',
          value: wallet.deliveriesCount.toString(),
          icon: Icons.local_shipping_outlined,
          color: _WalletColors.accentGold,
        ),
      ],
    );
  }

  Widget _buildOperatorsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rechargement rapide',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _WalletColors.navyDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisissez votre opérateur mobile money.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          OperatorShortcuts(
            onOperatorSelected: (method) =>
                _showTopUpDialog(preselectedMethod: method),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<WalletTransaction> transactions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique récent',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _WalletColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vos derniers mouvements financiers.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _openEarningsHistory,
                icon: const Icon(Icons.show_chart_rounded, size: 16),
                label: const Text('Voir plus'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            _WalletEmptyState(onTopUp: _showTopUpDialog)
          else
            Column(
              children: [
                for (final tx in transactions.take(6)) ...[
                  _WalletTransactionTile(transaction: tx),
                  if (tx != transactions.take(6).last)
                    Divider(color: Colors.grey.shade100, height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.12);
    final foreground = filled ? _WalletColors.navyDark : Colors.white;

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
        disabledForegroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.sora(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WalletMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _WalletColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletEmptyState extends StatelessWidget {
  final VoidCallback onTopUp;

  const _WalletEmptyState({required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune transaction pour le moment',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _WalletColors.navyDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Vos rechargements et retraits apparaîtront ici.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onTopUp,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Recharger maintenant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _WalletColors.navyDark,
              side: BorderSide(
                color: _WalletColors.navyDark.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _WalletTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final dateLabel = DateFormat(
      'dd MMM • HH:mm',
      'fr_FR',
    ).format(transaction.createdAt);
    final (icon, color, title) = _resolveStyle(transaction);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _WalletColors.navyDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.amount.toInt().formatTransaction(isCredit: isCredit),
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCredit
                    ? _WalletColors.successGreen
                    : Colors.red.shade400,
              ),
            ),
            if (transaction.status == 'pending')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _WalletColors.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'En attente',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _WalletColors.warningOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  (IconData, Color, String) _resolveStyle(WalletTransaction tx) {
    if (tx.isCommission) {
      return (
        Icons.percent_rounded,
        Colors.purple.shade400,
        'Commission Dr Pharma',
      );
    }
    if (tx.isTopUp) {
      return (
        Icons.add_card_rounded,
        _WalletColors.successGreen,
        'Rechargement',
      );
    }
    if (tx.isWithdrawal) {
      return (
        Icons.outbox_rounded,
        _WalletColors.warningOrange,
        'Retrait Mobile Money',
      );
    }
    return (
      tx.isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
      tx.isCredit ? _WalletColors.successGreen : Colors.red.shade400,
      tx.description?.trim().isNotEmpty == true
          ? tx.description!.trim()
          : (tx.isCredit ? 'Crédit' : 'Débit'),
    );
  }
}
