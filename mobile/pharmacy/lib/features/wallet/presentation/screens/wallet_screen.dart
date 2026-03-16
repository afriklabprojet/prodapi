import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../data/models/wallet_data.dart';
import '../../services/pdf_export_service.dart';
import '../../services/statement_preference_service.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Ce mois';
  final List<String> _periods = [
    'Aujourd hui',
    'Cette semaine',
    'Ce mois',
    'Cette annee'
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: walletAsync.when(
          data: (wallet) => _buildContent(context, wallet, primaryColor),
          loading: () => _buildLoadingState(context),
          error: (err, stack) => _buildErrorState(context, err),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WalletData wallet, Color primaryColor) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, primaryColor)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _buildMainBalanceCard(context, wallet, primaryColor),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildQuickActions(context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildStatsSection(context, wallet),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: _buildTransactionsHeader(context),
          ),
        ),
        _buildTransactionsList(context, wallet),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finance & Gains',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Portefeuille',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderAction(
                icon: Icons.notifications_outlined,
                onTap: () => context.push('/notifications'),
                showBadge: true,
              ),
              const SizedBox(width: 8),
              _buildHeaderAction(
                icon: Icons.refresh_rounded,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // ignore: unused_result
      ref.refresh(walletProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: showBadge
              ? Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                    return Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      backgroundColor: Colors.red,
                      smallSize: 8,
                      child: Icon(icon, size: 22, color: Colors.white),
                    );
                  },
                )
              : Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, WalletData wallet, Color primaryColor) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF2D5A87)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
              blurRadius: 20,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Solde disponible',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Actif',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              currencyFormat.format(wallet.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceAction(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Retrait',
                    onTap: () => _showWithdrawSheet(context),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceAction(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    onTap: () => _showHistorySheet(context),
                    filled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? const Color(0xFF1E3A5F) : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? const Color(0xFF1E3A5F) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.download_rounded,
                label: 'Exporter',
                subtitle: 'Releve PDF',
                color: const Color(0xFF6C63FF),
                onTap: () => _showExportSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics_outlined,
                label: 'Statistiques',
                subtitle: 'Analyses',
                color: const Color(0xFF00BFA5),
                onTap: () => walletAsync.whenData((wallet) => _showStatisticsSheet(context, wallet)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.settings_outlined,
                label: 'Parametres',
                subtitle: 'Compte',
                color: const Color(0xFFFF6B6B),
                onTap: () => _showSettingsSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    
    return Material(
      color: AppColors.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, WalletData wallet) {
    final isDark = AppColors.isDark(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Apercu financier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 20),
                  isDense: true,
                  dropdownColor: AppColors.cardColor(context),
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500),
                  items: _periods.map((period) => DropdownMenuItem(value: period, child: Text(period))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPeriod = value);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total gains',
                value: wallet.totalEarnings,
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Solde',
                value: wallet.balance,
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(value),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions recentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
        ),
        TextButton.icon(
          onPressed: () => _showHistorySheet(context),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Voir tout'),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context, WalletData wallet) {
    final transactions = wallet.transactions;

    if (transactions.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyTransactions());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _buildTransactionCard(tx),
          );
        },
        childCount: transactions.length > 5 ? 5 : transactions.length,
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx) {
    final isCredit = tx.type == 'credit';
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final sign = isCredit ? '+' : '-';
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit 
                  ? (isDark ? const Color(0xFF2E7D32).withValues(alpha: 0.2) : const Color(0xFFE8F5E9))
                  : (isDark ? const Color(0xFFC62828).withValues(alpha: 0.2) : const Color(0xFFFFEBEE)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(tx.date ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormat.format(tx.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    final isDark = AppColors.isDark(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune transaction',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 8),
          Text('Vos transactions apparaitront ici', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          Text('Chargement...', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    final isDark = AppColors.isDark(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'Une erreur est survenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E3A5F)),
            ),
            const SizedBox(height: 8),
            Text(err.toString(), style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(walletProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedMethod = 'wave'; // Par défaut Wave
    bool isLoading = false;
    String? errorMessage;
    final wallet = ref.read(walletProvider).value;

    showModalBottomSheet(
      context: context,
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                
                // Message d'erreur visible
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setModalState(() => errorMessage = null),
                          child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Demande de retrait',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 8),
                if (wallet != null)
                  Text(
                    'Solde disponible: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(wallet.balance)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 24),
                
                // Montant
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant (FCFA)',
                    prefixIcon: Icon(Icons.payments_outlined, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(ctx).primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Montants rapides
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [10000, 25000, 50000, 100000].map((amount) {
                    return TextButton(
                      onPressed: () {
                        amountController.text = amount.toString();
                        setModalState(() {});
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('${amount ~/ 1000}K', style: TextStyle(color: Colors.grey.shade700)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                
                // Choix de l'opérateur
                const Text('Choisir l\'opérateur', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                
                // Première ligne: Wave, MTN, Orange
                Row(
                  children: [
                    Expanded(
                      child: _buildOperatorCard(
                        imagePath: 'assets/images/wave.png',
                        label: 'Wave',
                        color: const Color(0xFF1BA8F0),
                        isSelected: selectedMethod == 'wave',
                        onTap: () => setModalState(() => selectedMethod = 'wave'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOperatorCard(
                        imagePath: 'assets/images/mtn.png',
                        label: 'MTN',
                        color: const Color(0xFFFFCC00),
                        isSelected: selectedMethod == 'mtn',
                        onTap: () => setModalState(() => selectedMethod = 'mtn'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOperatorCard(
                        imagePath: 'assets/images/orange.png',
                        label: 'Orange',
                        color: const Color(0xFFFF6600),
                        isSelected: selectedMethod == 'orange',
                        onTap: () => setModalState(() => selectedMethod = 'orange'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Deuxième ligne: Moov, Djamo, Virement
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
                        onTap: () => setModalState(() => selectedMethod = 'djamo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        icon: Icons.account_balance,
                        label: 'Virement',
                        isSelected: selectedMethod == 'bank',
                        onTap: () => setModalState(() => selectedMethod = 'bank'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        setModalState(() => errorMessage = 'Veuillez entrer un montant valide');
                        return;
                      }
                      
                      if (wallet != null && amount > wallet.balance) {
                        setModalState(() => errorMessage = 'Solde insuffisant pour ce retrait (${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(wallet.balance)} disponible)');
                        return;
                      }
                      
                      setModalState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      try {
                        final response = await ref.read(walletActionsProvider.notifier).requestWithdrawal(
                          amount: amount,
                          paymentMethod: selectedMethod,
                        );
                        
                        if (!mounted || !ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text((response['message'] as String?)?.isNotEmpty == true ? response['message'] as String : 'Demande de retrait envoyee')),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } catch (e) {
                        setModalState(() {
                          isLoading = false;
                          errorMessage = 'Erreur: $e';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmer le retrait', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
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
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
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

  void _showHistorySheet(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    
    showModalBottomSheet(
      context: context,
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
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Historique complet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: walletAsync.when(
                  data: (wallet) {
                    if (wallet.transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucune transaction', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: wallet.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = wallet.transactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTransactionCard(tx),
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

  void _showExportSheet(BuildContext context) {
    String selectedFormat = 'PDF';
    String selectedPeriod = 'Ce mois';
    
    showModalBottomSheet(
      context: context,
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.download_rounded, color: Color(0xFF6C63FF), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exporter le releve', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                          SizedBox(height: 4),
                          Text('Telecharger vos transactions', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Format', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFormatOption('PDF', selectedFormat, Icons.picture_as_pdf_rounded, Colors.red, (val) => setModalState(() => selectedFormat = val)),
                    const SizedBox(width: 12),
                    _buildFormatOption('Excel', selectedFormat, Icons.table_chart_rounded, Colors.green, (val) => setModalState(() => selectedFormat = val)),
                    const SizedBox(width: 12),
                    _buildFormatOption('CSV', selectedFormat, Icons.description_rounded, Colors.blue, (val) => setModalState(() => selectedFormat = val)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Periode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Cette semaine', 'Ce mois', 'Ce trimestre', 'Cette annee', 'Tout'].map((period) {
                    final isSelected = selectedPeriod == period;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _performExport(selectedFormat, selectedPeriod);
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: Text('Exporter en $selectedFormat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildFormatOption(String format, String selected, IconData icon, Color color, Function(String) onSelect) {
    final isSelected = format == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 28),
              const SizedBox(height: 8),
              Text(format, style: TextStyle(color: isSelected ? color : Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  /// Effectue l'export dans le format sélectionné
  Future<void> _performExport(String format, String period) async {
    final walletAsync = ref.read(walletProvider);
    
    walletAsync.whenData((wallet) async {
      try {
        // Afficher le loading
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text('Génération du $format en cours...'),
              ],
            ),
            backgroundColor: const Color(0xFF6C63FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (format == 'PDF') {
          final pdfData = await PdfExportService.generateStatement(
            wallet: wallet,
            pharmacyName: ref.read(authProvider).user?.pharmacies.isNotEmpty == true
                ? (ref.read(authProvider).user!.pharmacies.firstOrNull?.name ?? 'Ma Pharmacie')
                : 'Ma Pharmacie',
            period: period,
          );
          
          // Partager le PDF
          await PdfExportService.sharePdf(pdfData, 'releve_drpharma_${DateTime.now().millisecondsSinceEpoch}.pdf');
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('PDF généré avec succès!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          // Pour Excel et CSV, afficher un message "à venir"
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Export $format bientôt disponible'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Erreur: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  void _showStatisticsSheet(BuildContext context, WalletData wallet) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    
    // Utiliser les totaux de l'API (calculés sur TOUTES les transactions)
    final totalCredits = wallet.totalEarnings;
    final totalDebits = wallet.totalCommissionPaid;
    final nbTransactions = wallet.transactions.length;
    final avgTransaction = nbTransactions > 0 ? (totalCredits + totalDebits) / nbTransactions : 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Color(0xFF00BFA5), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Statistiques detaillees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Revenus vs Depenses
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        title: 'Total Revenus',
                        value: currencyFormat.format(totalCredits),
                        icon: Icons.arrow_downward_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        title: 'Total Depenses',
                        value: currencyFormat.format(totalDebits),
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        title: 'Transactions',
                        value: nbTransactions.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        title: 'Moyenne',
                        value: currencyFormat.format(avgTransaction),
                        icon: Icons.trending_flat_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Graphique simple
                const Text('Repartition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildProgressBar('Revenus', totalCredits, totalCredits + totalDebits, Colors.green),
                      const SizedBox(height: 16),
                      _buildProgressBar('Depenses', totalDebits, totalCredits + totalDebits, Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Resume
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1E3A5F), const Color(0xFF2D5A87)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solde Net', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 4),
                        ],
                      ),
                      Text(
                        currencyFormat.format(totalCredits - totalDebits),
                        style: TextStyle(
                          color: (totalCredits - totalDebits) >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, double total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_rounded, color: Color(0xFFFF6B6B), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Parametres du compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                  ],
                ),
                const SizedBox(height: 32),
                
                _buildSettingItem(
                  icon: Icons.account_balance_rounded,
                  title: 'Informations bancaires',
                  subtitle: 'Modifier vos coordonnees bancaires',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBankInfoSheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.phone_android_rounded,
                  title: 'Mobile Money',
                  subtitle: 'Gerer vos comptes Mobile Money',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMobileMoneySheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  subtitle: 'Gerer les alertes de paiement',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNotificationSettingsSheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.security_rounded,
                  title: 'Securite',
                  subtitle: 'PIN et authentification',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSecuritySettingsSheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Releves automatiques',
                  subtitle: 'Configurer les exports periodiques',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAutoReportSettingsSheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Seuil de retrait',
                  subtitle: 'Configurer le montant minimum',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showWithdrawalThresholdSheet(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Aide et support',
                  subtitle: 'FAQ et contact',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showHelpSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== INFORMATIONS BANCAIRES =====
  void _showBankInfoSheet(BuildContext context) {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ibanController = TextEditingController();
    final holderNameController = TextEditingController();
    bool isLoading = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations bancaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                        Text('Pour recevoir vos paiements', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Nom de la banque
              TextField(
                controller: bankNameController,
                decoration: InputDecoration(
                  labelText: 'Nom de la banque',
                  hintText: 'Ex: Ecobank, SGBCI, BOA...',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Titulaire du compte
              TextField(
                controller: holderNameController,
                decoration: InputDecoration(
                  labelText: 'Titulaire du compte',
                  hintText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Numero de compte
              TextField(
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Numero de compte',
                  hintText: 'XXXX XXXX XXXX XXXX',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              // IBAN / RIB
              TextField(
                controller: ibanController,
                decoration: InputDecoration(
                  labelText: 'IBAN / RIB (optionnel)',
                  hintText: 'CI XX XXXX XXXX XXXX XXXX XXXX XXX',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ces informations sont securisees et utilisees uniquement pour les virements.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: StatefulBuilder(
                  builder: (context, setButtonState) {
                    return ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (bankNameController.text.isEmpty || 
                            holderNameController.text.isEmpty || 
                            accountNumberController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Veuillez remplir tous les champs obligatoires'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        
                        setButtonState(() => isLoading = true);
                        
                        try {
                          await ref.read(walletActionsProvider.notifier).saveBankInfo(
                            bankName: bankNameController.text,
                            holderName: holderNameController.text,
                            accountNumber: accountNumberController.text,
                            iban: ibanController.text.isNotEmpty ? ibanController.text : null,
                          );
                          
                          if (!mounted || !ctx.mounted || !context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Informations bancaires enregistrees'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } catch (e) {
                          setButtonState(() => isLoading = false);
                          if (!mounted || !context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===== MOBILE MONEY =====
  void _showMobileMoneySheet(BuildContext context) {
    String selectedOperator = 'Wave';
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    bool isLoading = false;
    bool isPrimary = true;
    String? errorMessage;
    String? successMessage;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                
                // Message d'erreur
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setModalState(() => errorMessage = null),
                          child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Message de succès
                if (successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            successMessage!,
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_android_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mobile Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                          Text('Recevoir sur votre compte mobile', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Operateurs
                const Text('Choisir l\'operateur', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                // Ligne 1: Wave, Orange, MTN
                Row(
                  children: [
                    _buildOperatorChip('Wave', 'wave', selectedOperator == 'Wave', () {
                      setModalState(() => selectedOperator = 'Wave');
                    }),
                    const SizedBox(width: 8),
                    _buildOperatorChip('Orange Money', 'orange', selectedOperator == 'Orange Money', () {
                      setModalState(() => selectedOperator = 'Orange Money');
                    }),
                    const SizedBox(width: 8),
                    _buildOperatorChip('MTN MoMo', 'mtn', selectedOperator == 'MTN MoMo', () {
                      setModalState(() => selectedOperator = 'MTN MoMo');
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                // Ligne 2: Moov
                Row(
                  children: [
                    _buildOperatorChip('Moov Money', 'moov', selectedOperator == 'Moov Money', () {
                      setModalState(() => selectedOperator = 'Moov Money');
                    }),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Numero de telephone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numero de telephone',
                    hintText: '+225 XX XX XX XX XX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Nom du compte
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom sur le compte',
                    hintText: 'Nom du titulaire',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Compte principal toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Compte principal', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Recevoir les paiements sur ce compte', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isPrimary,
                        onChanged: (val) => setModalState(() => isPrimary = val),
                        activeTrackColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      // Réinitialiser les messages
                      setModalState(() {
                        errorMessage = null;
                        successMessage = null;
                      });
                      
                      if (phoneController.text.isEmpty || nameController.text.isEmpty) {
                        setModalState(() => errorMessage = 'Veuillez remplir tous les champs');
                        return;
                      }
                      
                      // Validation du numéro de téléphone
                      final phone = phoneController.text.trim();
                      if (phone.length < 8) {
                        setModalState(() => errorMessage = 'Numéro de téléphone invalide');
                        return;
                      }
                      
                      setModalState(() => isLoading = true);
                      
                      try {
                        await ref.read(walletActionsProvider.notifier).saveMobileMoneyInfo(
                          operator: selectedOperator,
                          phoneNumber: phone,
                          accountName: nameController.text.trim(),
                          isPrimary: isPrimary,
                        );
                        
                        setModalState(() {
                          isLoading = false;
                          successMessage = 'Compte $selectedOperator enregistré avec succès!';
                        });
                        
                        // Fermer après un délai
                        Future.delayed(const Duration(seconds: 2), () {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        });
                      } catch (e) {
                        setModalState(() {
                          isLoading = false;
                          errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildOperatorChip(String name, String code, bool isSelected, VoidCallback onTap) {
    Color color;
    switch (code) {
      case 'wave':
        color = const Color(0xFF1BA8F0); // Bleu Wave
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'mtn':
        color = Colors.yellow.shade700;
        break;
      case 'moov':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.phone_android, color: isSelected ? color : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(
                name.split(' ').first,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== NOTIFICATIONS =====
  void _showNotificationSettingsSheet(BuildContext context) {
    bool notifyDeposit = true;
    bool notifyWithdraw = true;
    bool notifyWeeklyReport = false;
    bool notifyMonthlyReport = true;
    bool notifyThreshold = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.purple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                          Text('Gerer vos alertes financieres', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Section Transactions
                const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: Colors.green,
                  title: 'Depot recu',
                  subtitle: 'Notification a chaque paiement recu',
                  value: notifyDeposit,
                  onChanged: (val) => setModalState(() => notifyDeposit = val),
                ),
                _buildNotificationToggle(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Colors.red,
                  title: 'Retrait effectue',
                  subtitle: 'Confirmation des retraits',
                  value: notifyWithdraw,
                  onChanged: (val) => setModalState(() => notifyWithdraw = val),
                ),
                
                const SizedBox(height: 20),
                const Text('Rapports', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  icon: Icons.calendar_view_week_rounded,
                  iconColor: Colors.blue,
                  title: 'Resume hebdomadaire',
                  subtitle: 'Chaque lundi matin',
                  value: notifyWeeklyReport,
                  onChanged: (val) => setModalState(() => notifyWeeklyReport = val),
                ),
                _buildNotificationToggle(
                  icon: Icons.calendar_month_rounded,
                  iconColor: Colors.indigo,
                  title: 'Resume mensuel',
                  subtitle: 'Le 1er de chaque mois',
                  value: notifyMonthlyReport,
                  onChanged: (val) => setModalState(() => notifyMonthlyReport = val),
                ),
                
                const SizedBox(height: 20),
                const Text('Alertes', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.orange,
                  title: 'Seuil de solde atteint',
                  subtitle: 'Quand votre solde depasse un montant',
                  value: notifyThreshold,
                  onChanged: (val) => setModalState(() => notifyThreshold = val),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Preferences de notifications enregistrees'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildNotificationToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  // ===== SECURITE =====
  void _showSecuritySettingsSheet(BuildContext context) {
    bool usePinCode = true;
    bool useBiometric = false;
    bool confirmWithdrawal = true;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Securite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                          Text('Protegez votre compte', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Authentification
                const Text('Authentification', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildSecurityOption(
                  icon: Icons.pin_rounded,
                  iconColor: Colors.blue,
                  title: 'Code PIN',
                  subtitle: 'Proteger l\'acces avec un code a 4 chiffres',
                  value: usePinCode,
                  onChanged: (val) => setModalState(() => usePinCode = val),
                  onConfigure: usePinCode ? () {
                    Navigator.pop(ctx);
                    _showChangePinDialog(context);
                  } : null,
                ),
                _buildSecurityOption(
                  icon: Icons.fingerprint_rounded,
                  iconColor: Colors.green,
                  title: 'Empreinte digitale',
                  subtitle: 'Utiliser la biometrie pour valider',
                  value: useBiometric,
                  onChanged: (val) => setModalState(() => useBiometric = val),
                ),
                
                const SizedBox(height: 20),
                const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildSecurityOption(
                  icon: Icons.verified_user_rounded,
                  iconColor: Colors.orange,
                  title: 'Confirmer les retraits',
                  subtitle: 'Demander confirmation pour chaque retrait',
                  value: confirmWithdrawal,
                  onChanged: (val) => setModalState(() => confirmWithdrawal = val),
                ),
                
                const SizedBox(height: 20),
                
                // Actions de securite
                const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 12),
                _buildSecurityAction(
                  icon: Icons.history_rounded,
                  iconColor: Colors.purple,
                  title: 'Historique de connexion',
                  subtitle: 'Voir les dernieres connexions',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLoginHistorySheet(context);
                  },
                ),
                _buildSecurityAction(
                  icon: Icons.devices_rounded,
                  iconColor: Colors.teal,
                  title: 'Appareils connectes',
                  subtitle: 'Gerer les sessions actives',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Aucun autre appareil connecte'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Parametres de securite enregistres'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildSecurityOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onConfigure,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (onConfigure != null && value)
              IconButton(
                onPressed: onConfigure,
                icon: Icon(Icons.edit_rounded, color: Colors.grey.shade400, size: 20),
                tooltip: 'Modifier',
              ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pin_rounded, color: Color(0xFF1E3A5F)),
            SizedBox(width: 12),
            Text('Modifier le code PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Ancien code PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau code PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le code PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Code PIN modifie avec succes'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistorySheet(BuildContext context) {
    final loginHistory = [
      {'date': '27 Jan 2026, 14:32', 'device': 'iPhone 14 Pro', 'location': 'Abidjan, CI', 'current': true},
      {'date': '27 Jan 2026, 09:15', 'device': 'iPhone 14 Pro', 'location': 'Abidjan, CI', 'current': false},
      {'date': '26 Jan 2026, 18:45', 'device': 'Chrome Web', 'location': 'Abidjan, CI', 'current': false},
      {'date': '25 Jan 2026, 11:20', 'device': 'iPhone 14 Pro', 'location': 'Abidjan, CI', 'current': false},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Historique de connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: loginHistory.length,
                itemBuilder: (context, index) {
                  final login = loginHistory[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: login['current'] == true ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: login['current'] == true ? Border.all(color: Colors.green.shade200) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          login['device'].toString().contains('iPhone') ? Icons.phone_iphone : Icons.computer,
                          color: login['current'] == true ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(login['device'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (login['current'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Actuel', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${login['date']} • ${login['location']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== RELEVES AUTOMATIQUES =====
  Future<void> _showAutoReportSettingsSheet(BuildContext context) async {
    // Charger les préférences existantes
    StatementPreference? currentPref;
    bool isLoading = true;
    final statementService = ref.read(statementPreferenceServiceProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Charger les préférences au premier build
          if (isLoading && currentPref == null) {
            statementService.getPreferences().then((pref) {
              setModalState(() {
                currentPref = pref;
                isLoading = false;
              });
            });
          }
          
          // Valeurs par défaut ou préférences existantes
          String frequency = currentPref != null 
              ? StatementPreferenceService.frequencyToUi(currentPref!.frequency)
              : 'Mensuel';
          String format = currentPref != null 
              ? currentPref!.format.toUpperCase()
              : 'PDF';
          bool autoSend = currentPref?.autoSend ?? true;
          String? nextSendLabel = currentPref?.nextSendLabel;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: isLoading 
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _AutoReportSettingsContent(
                    initialFrequency: frequency,
                    initialFormat: format,
                    initialAutoSend: autoSend,
                    nextSendLabel: nextSendLabel,
                    onSave: (freq, fmt, auto) async {
                      
                      final result = await statementService.savePreferences(
                        frequency: StatementPreferenceService.frequencyToApi(freq),
                        format: fmt.toLowerCase(),
                        autoSend: auto,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  result.success ? Icons.check_circle : Icons.error,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(result.message)),
                              ],
                            ),
                            backgroundColor: result.success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
          );
        },
      ),
    );
  }

  // ===== SEUIL DE RETRAIT =====
  void _showWithdrawalThresholdSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WithdrawalThresholdContent(
        ref: ref,
        parentContext: this.context,
      ),
    );
  }

  // ===== AIDE ET SUPPORT =====
  void _showHelpSheet(BuildContext context) {
    final faqItems = [
      {'q': 'Comment demander un retrait ?', 'a': 'Appuyez sur le bouton "Retrait" sur la carte de solde, entrez le montant souhaite et confirmez. Le virement sera effectue sous 24-48h.'},
      {'q': 'Quels sont les frais de retrait ?', 'a': 'Les retraits sont gratuits pour les montants superieurs a 50,000 FCFA. En dessous, des frais de 500 FCFA s\'appliquent.'},
      {'q': 'Comment modifier mes informations bancaires ?', 'a': 'Allez dans Parametres > Informations bancaires et modifiez vos coordonnees. Les changements seront verifies sous 24h.'},
      {'q': 'Pourquoi mon retrait est en attente ?', 'a': 'Les retraits sont traites les jours ouvrables. Si votre retrait est en attente depuis plus de 48h, contactez le support.'},
      {'q': 'Comment contacter le support ?', 'a': 'Vous pouvez nous joindre par email a support@drlpharma.com ou par telephone au +225 27 22 XX XX XX.'},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Colors.cyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aide et support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                              Text('Questions frequentes', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // FAQ
                    ...faqItems.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Contact
                    const Text('Nous contacter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                    const SizedBox(height: 16),
                    
                    _buildContactOption(
                      icon: Icons.email_outlined,
                      color: Colors.blue,
                      title: 'Email',
                      subtitle: 'support@drlpharma.com',
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@drlpharma.com?subject=Support%20Wallet%20Pharmacie');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    _buildContactOption(
                      icon: Icons.phone_outlined,
                      color: Colors.green,
                      title: 'Telephone',
                      subtitle: '+225 27 22 XX XX XX',
                      onTap: () async {
                        final uri = Uri.parse('tel:+22527220000');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    _buildContactOption(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.purple,
                      title: 'Chat en direct',
                      subtitle: 'Disponible 8h - 18h',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Chat en cours de mise en place'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E3A5F))),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.grey.shade600, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget séparé pour le seuil de retrait avec chargement des données
class _WithdrawalThresholdContent extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final BuildContext parentContext;

  const _WithdrawalThresholdContent({
    required this.ref,
    required this.parentContext,
  });

  @override
  ConsumerState<_WithdrawalThresholdContent> createState() => _WithdrawalThresholdContentState();
}

class _WithdrawalThresholdContentState extends ConsumerState<_WithdrawalThresholdContent> {
  double _threshold = 50000;
  bool _autoWithdraw = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  bool _hasPin = false;
  bool _hasMobileMoney = false;
  // Config dynamique depuis Filament
  WithdrawalConfig _config = WithdrawalConfig.defaults();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await widget.ref.read(walletActionsProvider.notifier).getWithdrawalSettings();
      if (mounted) {
        setState(() {
          _threshold = (settings['threshold'] as num?)?.toDouble() ?? 0.0;
          _autoWithdraw = settings['auto_withdraw'] as bool? ?? false;
          _hasPin = settings['has_pin'] as bool? ?? false;
          _hasMobileMoney = settings['has_mobile_money'] as bool? ?? false;
          _config = WithdrawalConfig.fromJson(settings['config'] as Map<String, dynamic>? ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les paramètres';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.ref.read(walletActionsProvider.notifier).setWithdrawalThreshold(
        threshold: _threshold,
        autoWithdraw: _autoWithdraw,
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _successMessage = 'Seuil de ${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA enregistré';
        });
        
        // Fermer après 1.5 secondes
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  // Calcule les divisions du slider selon le step de Filament
  int get _sliderDivisions {
    return ((_config.maxThreshold - _config.minThreshold) / _config.step).round();
  }

  // Génère les valeurs rapides basées sur les config min/max
  List<double> get _quickValues {
    final values = <double>[];
    values.add(_config.minThreshold);
    final quarter = _config.minThreshold + (_config.maxThreshold - _config.minThreshold) * 0.25;
    final half = _config.minThreshold + (_config.maxThreshold - _config.minThreshold) * 0.5;
    final threeQuarter = _config.minThreshold + (_config.maxThreshold - _config.minThreshold) * 0.75;
    values.add((quarter / _config.step).round() * _config.step);
    values.add((half / _config.step).round() * _config.step);
    values.add((threeQuarter / _config.step).round() * _config.step);
    return values;
  }

  String _formatQuickValue(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toInt()}K';
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Message d'erreur
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                    ),
                  ],
                ),
              ),
            ],
            
            // Message de succès
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade700)),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seuil de retrait', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                      Text('Montant minimum pour retrait automatique', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator(color: Colors.teal)),
              const SizedBox(height: 60),
            ] else ...[
              const SizedBox(height: 32),
              
              // Affichage du seuil
              Center(
                child: Column(
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                    ),
                    const SizedBox(height: 4),
                    Text('Montant minimum de retrait', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Slider - utilise les configs de Filament
              Slider(
                value: _threshold.clamp(_config.minThreshold, _config.maxThreshold),
                min: _config.minThreshold,
                max: _config.maxThreshold,
                divisions: _sliderDivisions,
                label: '${NumberFormat('#,###', 'fr_FR').format(_threshold)} FCFA',
                onChanged: (val) => setState(() => _threshold = val),
                activeColor: Colors.teal,
              ),
              
              // Info sur les limites
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NumberFormat('#,###', 'fr_FR').format(_config.minThreshold),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(_config.maxThreshold)} FCFA',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Valeurs rapides - dynamiques selon les configs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickValues.map((val) {
                  final isSelected = (_threshold - val).abs() < _config.step;
                  return TextButton(
                    onPressed: () => setState(() => _threshold = val),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _formatQuickValue(val),
                      style: TextStyle(
                        color: isSelected ? Colors.teal : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Auto withdraw toggle - vérifie si autorisé globalement
              if (!_config.autoWithdrawAllowed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Retrait automatique', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                            Text(
                              'Désactivé par l\'administrateur',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _autoWithdraw ? Colors.teal.withValues(alpha: 0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoWithdraw ? Colors.teal : Colors.grey.shade200,
                      width: _autoWithdraw ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.autorenew_rounded, color: _autoWithdraw ? Colors.teal : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Retrait automatique', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              'Retirer automatiquement quand le solde dépasse le seuil',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoWithdraw,
                        onChanged: (val) => setState(() => _autoWithdraw = val),
                        activeTrackColor: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ],
              
              // Warning si PIN requis mais pas configuré
              if (_autoWithdraw && _config.requirePin && !_hasPin) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configurez d\'abord un code PIN de retrait',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Warning si Mobile Money requis mais pas configuré
              if (_autoWithdraw && _config.requireMobileMoney && !_hasMobileMoney) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configurez d\'abord un compte Mobile Money pour le retrait automatique',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Widget contenu pour les paramètres de relevés automatiques
class _AutoReportSettingsContent extends StatefulWidget {
  final String initialFrequency;
  final String initialFormat;
  final bool initialAutoSend;
  final String? nextSendLabel;
  final Future<void> Function(String frequency, String format, bool autoSend) onSave;

  const _AutoReportSettingsContent({
    required this.initialFrequency,
    required this.initialFormat,
    required this.initialAutoSend,
    this.nextSendLabel,
    required this.onSave,
  });

  @override
  State<_AutoReportSettingsContent> createState() => _AutoReportSettingsContentState();
}

class _AutoReportSettingsContentState extends State<_AutoReportSettingsContent> {
  late String _frequency;
  late String _format;
  late bool _autoSend;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _format = widget.initialFormat;
    _autoSend = widget.initialAutoSend;
  }

  String _calculateNextSendLabel() {
    if (!_autoSend) return 'Désactivé';
    if (widget.nextSendLabel != null && _frequency == widget.initialFrequency) {
      return widget.nextSendLabel!;
    }
    
    final now = DateTime.now();
    return switch (_frequency) {
      'Hebdomadaire' => 'Lundi prochain',
      'Mensuel' => '1er ${_getMonthName(now.month == 12 ? 1 : now.month + 1)} ${now.month == 12 ? now.year + 1 : now.year}',
      'Trimestriel' => '1er ${_getQuarterStartMonth(now)} ${_getQuarterYear(now)}',
      _ => '1er du mois prochain',
    };
  }

  String _getMonthName(int month) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month - 1];
  }

  String _getQuarterStartMonth(DateTime now) {
    final currentQuarter = (now.month - 1) ~/ 3;
    final nextQuarter = (currentQuarter + 1) % 4;
    return _getMonthName(nextQuarter * 3 + 1);
  }

  int _getQuarterYear(DateTime now) {
    final currentQuarter = (now.month - 1) ~/ 3;
    return currentQuarter == 3 ? now.year + 1 : now.year;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          const SizedBox(height: 24),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.indigo, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Relevés automatiques', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                    Text('Recevez vos relevés par email', 
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Fréquence
          const Text("Fréquence d'envoi", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Hebdomadaire', 'Mensuel', 'Trimestriel'].map((f) {
              final isSelected = _frequency == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _frequency = f);
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Format
          const Text('Format du document', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['PDF', 'Excel', 'CSV'].map((f) {
              final isSelected = _format == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _format = f);
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Toggle envoi automatique
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Envoi automatique', 
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Recevoir par email automatiquement', 
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Switch(
                  value: _autoSend,
                  onChanged: (val) => setState(() => _autoSend = val),
                  activeTrackColor: Colors.indigo,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Info prochain relevé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _autoSend ? Colors.indigo.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _autoSend ? Icons.info_outline : Icons.block,
                  color: _autoSend ? Colors.indigo.shade700 : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prochain relevé: ${_calculateNextSendLabel()}',
                    style: TextStyle(
                      fontSize: 13, 
                      color: _autoSend ? Colors.indigo.shade700 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bouton enregistrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving 
                  ? null 
                  : () async {
                      setState(() => _isSaving = true);
                      await widget.onSave(_frequency, _format, _autoSend);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enregistrer', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
