import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/wallet_data.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/jeko_payment_repository.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/wallet/earnings_export_sheet.dart';
import 'payment_status_screen.dart';
import 'earnings_history_screen.dart';

// --- Provider pour les données du wallet ---
final walletDataProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.getWalletData();
});

// --- Main Wallet Screen ---
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {

  void _showTopUpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TopUpSheet(
        onSuccess: () => ref.invalidate(walletDataProvider),
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
        onSuccess: () => ref.invalidate(walletDataProvider),
      ),
    );
  }
  
  void _openEarningsHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EarningsHistoryScreen()),
    );
  }

  void _openExportSheet() {
    // Récupérer le nom du livreur depuis le profil
    final profile = ref.read(profileProvider);
    final courierName = profile.value?.name ?? 'Livreur';
    EarningsExportSheet.show(context, courierName: courierName);
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletDataProvider);
    // Écouter les changements de thème
    ref.watch(themeProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Mon Portefeuille', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exporter revenus',
            onPressed: () => _openExportSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(walletDataProvider),
          )
        ],
      ),
      body: walletAsync.when(
        data: (wallet) {
          final r = context.r;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Warning Banner if can't deliver
                if (!wallet.canDeliver)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Solde insuffisant pour livrer. Rechargez au moins ${wallet.commissionAmount} FCFA.',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Balance Card
                Container(
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
                      Text(
                        '${NumberFormat("#,##0", "fr_FR").format(wallet.balance)} ${wallet.currency}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (wallet.pendingPayouts != null && wallet.pendingPayouts! > 0) ...[
                        const SizedBox(height: 12),
                        Container(
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
                                'Retrait en attente: ${NumberFormat("#,##0").format(wallet.pendingPayouts)} ${wallet.currency}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Stats Row
                      Row(
                        children: [
                          _buildStatItem('Livraisons', wallet.deliveriesCount.toString(), Icons.local_shipping_outlined),
                          const SizedBox(width: 12),
                          _buildStatItem('Gains', NumberFormat("#,##0").format(wallet.totalEarnings), Icons.trending_up),
                          const SizedBox(width: 12),
                          _buildStatItem('Commissions', NumberFormat("#,##0").format(wallet.totalCommissions), Icons.trending_down),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showTopUpDialog,
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
                              onPressed: wallet.balance > 500 ? () => _showWithdrawDialog(wallet.availableBalance ?? wallet.balance) : null,
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
                      ),
                    ],
                  ),
                ),

                // Operator Shortcuts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOperatorIcon('Orange Money', Colors.orange, 'orange_money'),
                      _buildOperatorIcon('MTN MoMo', Colors.yellow.shade700, 'mtn_momo'),
                      _buildOperatorIcon('Wave', Colors.blue, 'wave'),
                      _buildOperatorIcon('Carte', Colors.indigo, 'card'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Transactions List
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historique',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _openEarningsHistory,
                            icon: const Icon(Icons.trending_up, size: 16),
                            label: const Text('Voir les gains'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (wallet.transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune transaction',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wallet.transactions.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = wallet.transactions[index];
                            return _buildTransactionTile(tx);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (err, stack) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(walletDataProvider),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorIcon(String label, Color color, String method) {
    return GestureDetector(
      onTap: () => _showTopUpDialogWithMethod(method),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showTopUpDialogWithMethod(String method) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TopUpSheet(
        preselectedMethod: method,
        onSuccess: () => ref.invalidate(walletDataProvider),
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    final isCredit = tx.isCredit;
    final amount = tx.amount;

    IconData icon;
    Color bgColor;
    String title = tx.description ?? 'Transaction';

    if (tx.isCommission) {
      icon = Icons.percent;
      bgColor = Colors.purple;
      title = 'Commission Dr Pharma';
    } else if (tx.isTopUp) {
      icon = Icons.add_circle_outline;
      bgColor = Colors.green;
      title = 'Rechargement';
    } else if (tx.isWithdrawal) {
      icon = Icons.arrow_downward;
      bgColor = Colors.orange;
      title = 'Retrait Mobile Money';
    } else {
      icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
      bgColor = isCredit ? Colors.green : Colors.red;
    }

    // Use createdAt directly (already DateTime)
    final date = tx.createdAt;

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
            DateFormat('dd MMM yyyy, HH:mm').format(date),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          if (tx.status == 'pending')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('En attente', style: TextStyle(color: Colors.orange.shade800, fontSize: 10)),
            ),
        ],
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}${NumberFormat("#,##0", "fr_FR").format(amount)} FCFA',
        style: TextStyle(
          color: isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// --- Top Up Sheet with JEKO Integration ---
class TopUpSheet extends ConsumerStatefulWidget {
  final String? preselectedMethod;
  final VoidCallback? onSuccess;

  const TopUpSheet({super.key, this.preselectedMethod, this.onSuccess});

  @override
  ConsumerState<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<TopUpSheet> {
  final List<int> _amounts = [500, 1000, 2000, 5000, 10000];
  int? _selectedAmount;
  JekoPaymentMethod _selectedMethod = JekoPaymentMethod.wave;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMethod != null) {
      _selectedMethod = _methodFromString(widget.preselectedMethod!);
    }
  }

  JekoPaymentMethod _methodFromString(String value) {
    return JekoPaymentMethod.values.firstWhere(
      (m) => m.value == value || value.contains(m.value),
      orElse: () => JekoPaymentMethod.wave,
    );
  }

  void _openPaymentScreen() {
    if (_selectedAmount == null) return;
    
    Navigator.pop(context); // Fermer le bottom sheet
    
    // Ouvrir l'écran de paiement dédié
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStatusScreen(
          amount: _selectedAmount!.toDouble(),
          method: _selectedMethod,
          onSuccess: widget.onSuccess,
          onCancel: () {}, // Rien à faire
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle_outline, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Recharger mon compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paiement sécurisé via JEKO',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          // Payment Method Selection
          const Text('Moyen de paiement', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JekoPaymentMethod.values.map((method) {
              return _buildMethodChip(method);
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          const Text('Montant', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _amounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return ChoiceChip(
                label: Text('${NumberFormat("#,##0").format(amount)} FCFA'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedAmount = selected ? amount : null);
                },
                selectedColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green.shade800 : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vous serez redirigé vers ${_selectedMethod.label} pour finaliser le paiement.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAmount == null ? null : _openPaymentScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('Payer ${_selectedAmount != null ? NumberFormat("#,##0").format(_selectedAmount) : ''} FCFA'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(JekoPaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final color = _getMethodColor(method);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMethodIcon(method),
              color: isSelected ? color : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              method.label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(JekoPaymentMethod method) {
    return switch (method) {
      JekoPaymentMethod.wave => Colors.blue,
      JekoPaymentMethod.orange => Colors.orange,
      JekoPaymentMethod.mtn => Colors.amber.shade700,
      JekoPaymentMethod.moov => Colors.green,
      JekoPaymentMethod.djamo => Colors.purple,
    };
  }

  IconData _getMethodIcon(JekoPaymentMethod method) {
    return switch (method) {
      JekoPaymentMethod.wave => Icons.waves,
      JekoPaymentMethod.orange => Icons.phone_android,
      JekoPaymentMethod.mtn => Icons.phone_android,
      JekoPaymentMethod.moov => Icons.phone_android,
      JekoPaymentMethod.djamo => Icons.credit_card,
    };
  }
}

// --- Payment Status Dialog ---
class PaymentStatusDialog extends ConsumerStatefulWidget {
  final String reference;
  final double amount;
  final Function(bool success)? onComplete;

  const PaymentStatusDialog({
    super.key,
    required this.reference,
    required this.amount,
    this.onComplete,
  });

  @override
  ConsumerState<PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends ConsumerState<PaymentStatusDialog> {
  PaymentStatusResponse? _status;
  bool _isChecking = false;
  int _checkCount = 0;
  static const int _maxChecks = 60; // 5 minutes max (5 sec interval)

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    while (mounted && _checkCount < _maxChecks) {
      await _checkStatus();
      
      if (_status?.isFinal == true) {
        break;
      }
      
      await Future.delayed(const Duration(seconds: 5));
      _checkCount++;
    }
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    
    if (!mounted) return;
    setState(() => _isChecking = true);
    
    try {
      final jekoRepo = ref.read(jekoPaymentRepositoryProvider);
      final status = await jekoRepo.checkPaymentStatus(widget.reference);
      
      if (!mounted) return;
      setState(() => _status = status);
      
      if (status.isFinal) {
        widget.onComplete?.call(status.isSuccess);
      }
    } catch (e) {
      // Ignore errors, continue polling
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == null || _status!.isPending) ...[
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Paiement en cours...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat("#,##0").format(widget.amount)} FCFA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              'Veuillez terminer le paiement dans votre application mobile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isChecking ? null : _checkStatus,
              child: const Text('Vérifier le statut'),
            ),
          ] else if (_status!.isSuccess) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paiement réussi !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '+${NumberFormat("#,##0").format(widget.amount)} FCFA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuer'),
              ),
            ),
          ] else if (_status!.isFailed) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paiement échoué',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _status!.errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Withdraw Sheet ---
class WithdrawSheet extends ConsumerStatefulWidget {
  final double maxAmount;
  final VoidCallback? onSuccess;

  const WithdrawSheet({super.key, required this.maxAmount, this.onSuccess});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMethod = 'orange_money';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _doWithdraw() async {
    final amount = int.tryParse(_amountController.text);
    final phone = _phoneController.text.trim();

    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant minimum: 500 FCFA')),
      );
      return;
    }

    if (amount > widget.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solde insuffisant')),
      );
      return;
    }

    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone invalide')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.requestPayout(
        amount: amount.toDouble(),
        paymentMethod: _selectedMethod,
        phoneNumber: phone,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de retrait enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Retrait de fonds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Solde disponible: ${NumberFormat("#,##0").format(widget.maxAmount)} FCFA',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Payment Method Selection
          const Text('Vers', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              _buildMethodChip('Orange Money', 'orange_money', Colors.orange),
              _buildMethodChip('MTN MoMo', 'mtn_momo', Colors.yellow.shade700),
              _buildMethodChip('Wave', 'wave', Colors.blue),
            ],
          ),

          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Numéro de téléphone',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Montant à retirer (min. 500 FCFA)',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.money),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmer le retrait'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String label, String value, Color color) {
    final isSelected = _selectedMethod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedMethod = value);
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
