import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/dashboard_tab_provider.dart';
import 'dashboard_card.dart';
import 'dashboard_skeletons.dart';
import 'revenue_chart_widget.dart';

/// Financial tab content — watches [walletProvider] only.
/// Extracted as a [ConsumerWidget] so that provider subscriptions
/// are scoped to this subtree and don't trigger rebuilds in sibling tabs.
class FinancialTabContent extends ConsumerWidget {
  final GlobalKey walletKey;

  const FinancialTabContent({super.key, required this.walletKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final walletAsync = ref.watch(walletProvider);

    return Column(
      key: const ValueKey('finances'),
      children: [
        Row(
          children: [
            Expanded(
              child: KeyedSubtree(
                key: walletKey,
                child: walletAsync.when(
                  data: (wallet) => DashboardCard(
                    title: l10n.balance,
                    value: CurrencyFormatter.compact(wallet.balance),
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    subtitle: l10n.currency,
                    onTap: () =>
                        ref.read(dashboardTabProvider.notifier).state = 3,
                  ),
                  loading: () => const FinancialCardSkeleton(),
                  error: (_, __) => DashboardCard(
                    title: l10n.balance,
                    value: '--',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.grey,
                    subtitle: l10n.error,
                    onTap: () =>
                        ref.read(dashboardTabProvider.notifier).state = 3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: walletAsync.when(
                data: (wallet) => DashboardCard(
                  title: l10n.totalEarned,
                  value: CurrencyFormatter.compact(wallet.totalEarnings),
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                  subtitle: l10n.currency,
                  onTap: () =>
                      ref.read(dashboardTabProvider.notifier).state = 3,
                ),
                loading: () => const FinancialCardSkeleton(),
                error: (_, __) => DashboardCard(
                  title: l10n.totalEarned,
                  value: '--',
                  icon: Icons.trending_up_rounded,
                  color: Colors.grey,
                  subtitle: l10n.error,
                  onTap: () =>
                      ref.read(dashboardTabProvider.notifier).state = 3,
                ),
              ),
            ),
          ],
        ),
        const RevenueChartWidget(),
      ],
    );
  }
}
