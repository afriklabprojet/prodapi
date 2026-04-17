import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

void showWalletNotificationSettingsSheet(BuildContext parentContext) {
  bool notifyDeposit = true;
  bool notifyWithdraw = true;
  bool notifyWeeklyReport = false;
  bool notifyMonthlyReport = true;
  bool notifyThreshold = false;

  showModalBottomSheet(
    context: parentContext,
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
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
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
                    child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.purple,
                        size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('Gerer vos alertes financieres',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Transactions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildNotificationToggle(
                icon: Icons.arrow_downward_rounded,
                iconColor: Colors.green,
                title: 'Depot recu',
                subtitle: 'Notification a chaque paiement recu',
                value: notifyDeposit,
                onChanged: (val) =>
                    setModalState(() => notifyDeposit = val),
              ),
              _buildNotificationToggle(
                icon: Icons.arrow_upward_rounded,
                iconColor: Colors.red,
                title: 'Retrait effectue',
                subtitle: 'Confirmation des retraits',
                value: notifyWithdraw,
                onChanged: (val) =>
                    setModalState(() => notifyWithdraw = val),
              ),
              const SizedBox(height: 20),
              const Text('Rapports',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildNotificationToggle(
                icon: Icons.calendar_view_week_rounded,
                iconColor: Colors.blue,
                title: 'Resume hebdomadaire',
                subtitle: 'Chaque lundi matin',
                value: notifyWeeklyReport,
                onChanged: (val) =>
                    setModalState(() => notifyWeeklyReport = val),
              ),
              _buildNotificationToggle(
                icon: Icons.calendar_month_rounded,
                iconColor: Colors.indigo,
                title: 'Resume mensuel',
                subtitle: 'Le 1er de chaque mois',
                value: notifyMonthlyReport,
                onChanged: (val) =>
                    setModalState(() => notifyMonthlyReport = val),
              ),
              const SizedBox(height: 20),
              const Text('Alertes',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildNotificationToggle(
                icon: Icons.trending_up_rounded,
                iconColor: Colors.orange,
                title: 'Seuil de solde atteint',
                subtitle:
                    'Quand votre solde depasse un montant',
                value: notifyThreshold,
                onChanged: (val) =>
                    setModalState(() => notifyThreshold = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                                'Preferences de notifications enregistrees'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppLocalizations.of(context).save,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
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
