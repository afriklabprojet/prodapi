import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../prescriptions/presentation/providers/prescription_provider.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_recent_cards.dart';
import 'dashboard_skeletons.dart';

/// Prescriptions tab content — watches [prescriptionListProvider] only.
/// Scoped subscription avoids wallet/order rebuilds.
class PrescriptionsTabContent extends ConsumerWidget {
  const PrescriptionsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionState = ref.watch(prescriptionListProvider);

    if (prescriptionState.status == PrescriptionStatus.loading) {
      return Column(
        key: const ValueKey('prescriptions_loading'),
        children: [
          SkeletonList(itemBuilder: () => const PrescriptionRowSkeleton()),
        ],
      );
    }

    final recentPrescriptions = prescriptionState.prescriptions
        .take(3)
        .toList();

    if (recentPrescriptions.isEmpty) {
      return DashboardEmptyState(
        key: const ValueKey('prescriptions_empty'),
        icon: Icons.medical_services_outlined,
        message: AppLocalizations.of(context).noRecentPrescriptions,
      );
    }

    return Column(
      key: const ValueKey('prescriptions'),
      children: [
        for (final prescription in recentPrescriptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecentPrescriptionCard(
              prescription: prescription,
              onTap: () =>
                  context.push('/prescription-details', extra: prescription),
            ),
          ),
      ],
    );
  }
}
