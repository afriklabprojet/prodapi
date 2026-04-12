import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/responsive_builder.dart';
import '../providers/dashboard_ui_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'financial_tab_content.dart';
import 'orders_tab_content.dart';
import 'prescriptions_tab_content.dart';
import 'segmented_tab_bar.dart';

/// Dashboard info section — lightweight orchestrator that composes:
/// - [SegmentedTabBar] for tab selection
/// - [FinancialTabContent] / [OrdersTabContent] / [PrescriptionsTabContent]
///
/// Each tab content is a separate [ConsumerWidget] that watches only
/// the provider it requires. This eliminates cross-tab rebuilds
/// (e.g. wallet stream ticks don't re-render the orders list).
class DashboardInfoTabs extends ConsumerWidget {
  final GlobalKey walletKey;

  const DashboardInfoTabs({super.key, required this.walletKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedInfoTabProvider);
    final l10n = AppLocalizations.of(context);
    final tabLabels = [l10n.finances, l10n.orders, l10n.prescriptions];

    return ResponsiveBuilder(
      builder: (context, responsive) => Padding(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          20,
          responsive.horizontalPadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedTabBar(
              labels: tabLabels,
              selectedIndex: selectedTab,
              onTabChanged: (index) =>
                  ref.read(selectedInfoTabProvider.notifier).state = index,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTabContent(selectedTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    return switch (tabIndex) {
      0 => FinancialTabContent(walletKey: walletKey),
      1 => const OrdersTabContent(),
      2 => const PrescriptionsTabContent(),
      _ => const SizedBox.shrink(),
    };
  }
}
