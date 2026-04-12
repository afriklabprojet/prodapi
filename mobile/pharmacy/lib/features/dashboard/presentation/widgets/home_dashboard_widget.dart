import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/presentation/widgets/sync_status_banner.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../prescriptions/presentation/providers/prescription_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import 'dashboard_header.dart';
import 'dashboard_quick_actions.dart';
import 'dashboard_kpi_section.dart';
import 'dashboard_insights.dart';
import 'dashboard_info_tabs.dart';
import 'dashboard_expiry_alerts.dart';
import 'daily_performance_widget.dart';
import 'welcome_onboarding_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget de tableau de bord principal avec KPIs
class HomeDashboardWidget extends ConsumerStatefulWidget {
  const HomeDashboardWidget({super.key});

  @override
  ConsumerState<HomeDashboardWidget> createState() =>
      _HomeDashboardWidgetState();
}

class _HomeDashboardWidgetState extends ConsumerState<HomeDashboardWidget> {
  final _ordersKey = GlobalKey();
  final _statsKey = GlobalKey();
  final _walletKey = GlobalKey();
  final _scanKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingFlow();
    });
  }

  /// Clé pour le premier onboarding complet (welcome + tutorial)
  static const _onboardingCompleteKey = 'onboarding_complete_v1';

  /// Flow d'onboarding: welcome sheet puis coach marks
  Future<void> _showOnboardingFlow() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool(_onboardingCompleteKey) ?? false;

    if (!hasCompletedOnboarding && mounted) {
      // Afficher le welcome sheet en premier
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => WelcomeOnboardingSheet(
          onGetStarted: () {
            // Callback appelé après fermeture du sheet
          },
        ),
      );

      // Marquer l'onboarding comme complété
      await prefs.setBool(_onboardingCompleteKey, true);

      // Puis lancer les coach marks
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _showDashboardTutorial();
      }
    } else {
      // Utilisateur existant: vérifier si le tutorial dashboard a été vu
      await _showDashboardTutorial();
    }
  }

  Future<void> _showDashboardTutorial() async {
    if (!mounted) return;

    final tutorialService = ref.read(tutorialServiceProvider);
    final targets = TutorialService.buildDashboardTargets(
      ordersKey: _ordersKey,
      statsKey: _statsKey,
      walletKey: _walletKey,
      scanKey: _scanKey,
    );

    await tutorialService.showTutorialIfNeeded(
      context: context,
      tutorialKey: TutorialKeys.dashboard,
      targets: targets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final pharmacyName = (authState.user?.pharmacies.isNotEmpty == true)
        ? (authState.user!.pharmacies.firstOrNull?.name ?? l10n.myPharmacy)
        : l10n.myPharmacy;
    final userName = authState.user?.name ?? l10n.pharmacist;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orderListProvider);
          ref.invalidate(walletProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(prescriptionListProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SyncStatusBanner()),
            SliverToBoxAdapter(
              child: DashboardHeader(
                userName: userName,
                pharmacyName: pharmacyName,
              ),
            ),
            const SliverToBoxAdapter(child: DailyPerformanceWidget()),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _ordersKey,
                child: const DashboardKpiSection(),
              ),
            ),
            const SliverToBoxAdapter(child: DashboardInsightsBanner()),
            const SliverToBoxAdapter(child: DashboardExpiryAlerts()),
            SliverToBoxAdapter(
              child: DashboardQuickActions(scannerKey: _scanKey),
            ),
            SliverToBoxAdapter(child: DashboardInfoTabs(walletKey: _walletKey)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
