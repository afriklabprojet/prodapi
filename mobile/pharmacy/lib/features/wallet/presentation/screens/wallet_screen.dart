import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../data/models/wallet_data.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../providers/wallet_provider.dart';
import '../providers/wallet_stats_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import 'wallet_sheets.dart';
import 'wallet_settings_sheets.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Ce mois';
  final List<String> _periods = [
    "Aujourd'hui",
    'Cette semaine',
    'Ce mois',
    'Cette année',
    'Tout',
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
        child: AsyncValueWidget<WalletData>(
          value: walletAsync,
          data: (wallet) => _buildContent(context, wallet, primaryColor),
          loading: () => _buildLoadingState(context),
          error: (err, stack) => _buildErrorState(context, err),
          onRetry: () => ref.refresh(walletProvider),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WalletData wallet,
    Color primaryColor,
  ) {
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
                    final unreadCount = ref.watch(
                      unreadNotificationCountProvider,
                    );
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

  Widget _buildMainBalanceCard(
    BuildContext context,
    WalletData wallet,
    Color primaryColor,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.textPrimary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.4),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
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
                    onTap: () => showWalletWithdrawSheet(context, ref),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceAction(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    onTap: () => showWalletHistorySheet(context, ref),
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
    return Semantics(
      button: true,
      enabled: true,
      label: '$label. Appuyez pour $label.',
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      excludeSemantics: true,
      child: Material(
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: filled ? AppColors.textPrimary : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? AppColors.textPrimary : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.download_rounded,
                label: 'Exporter',
                subtitle: 'Releve PDF',
                color: AppColors.secondary,
                onTap: () => showWalletExportSheet(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics_outlined,
                label: 'Statistiques',
                subtitle: 'Analyses',
                color: AppColors.accent,
                onTap: () => showWalletStatisticsSheet(
                  context,
                  ref.read(walletRemoteDataSourceProvider),
                  _selectedPeriod,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.settings_outlined,
                label: 'Parametres',
                subtitle: 'Compte',
                color: AppColors.error,
                onTap: () => showWalletSettingsSheet(context, ref),
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

    return Semantics(
      button: true,
      enabled: true,
      label: '$label: $subtitle. Appuyez pour $label.',
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      excludeSemantics: true,
      child: Material(
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
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
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 20,
                  ),
                  isDense: true,
                  dropdownColor: AppColors.cardColor(context),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _periods
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPeriod = value);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Stat cards — fetched from server for accurate period totals
        Consumer(
          builder: (context, ref, _) {
            final statsAsync = ref.watch(walletStatsProvider(_selectedPeriod));
            return statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gains',
                      value: stats.totalCredits,
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Dépenses',
                      value: stats.totalDebits,
                      icon: Icons.trending_down_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gains',
                      value: 0,
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Dépenses',
                      value: 0,
                      icon: Icons.trending_down_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gains',
                      value: 0,
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Dépenses',
                      value: 0,
                      icon: Icons.trending_down_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            );
          },
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
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        TextButton.icon(
          onPressed: () => showWalletHistorySheet(context, ref),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Voir tout'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context, WalletData wallet) {
    final transactions = filterWalletTransactionsByPeriod(
      wallet.transactions,
      _selectedPeriod,
    );

    if (transactions.isEmpty) {
      // Vérifier si des transactions existent hors période
      if (wallet.transactions.isNotEmpty) {
        return SliverToBoxAdapter(
          child: _buildNoTransactionsForPeriod(wallet.transactions.length),
        );
      }
      return SliverToBoxAdapter(child: _buildEmptyTransactions());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tx = transactions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: buildWalletTransactionCard(context, tx),
        );
      }, childCount: transactions.length > 5 ? 5 : transactions.length),
    );
  }

  Widget _buildNoTransactionsForPeriod(int totalCount) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.shade800.withValues(alpha: 0.5)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 48,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction $_selectedPeriod',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$totalCount transaction${totalCount > 1 ? 's' : ''} au total',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _selectedPeriod = 'Tout');
              },
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('Voir tout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppEmptyState.transactions(),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 140,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Balance card skeleton
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            // Quick actions skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Transactions header skeleton
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            // Transactions list skeleton
            ...List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: TransactionCardSkeleton(),
              ),
            ),
          ],
        ),
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
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.shade900.withValues(alpha: 0.3)
                    : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(walletProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
