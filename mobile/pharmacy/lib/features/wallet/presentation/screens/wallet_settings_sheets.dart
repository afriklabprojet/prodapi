import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'wallet_auto_report_sheet.dart';
import 'wallet_bank_info_sheet.dart';
import 'wallet_help_sheet.dart';
import 'wallet_mobile_money_sheet.dart';
import 'wallet_notification_settings_sheet.dart';
import 'wallet_security_settings_sheet.dart';
import 'wallet_threshold_settings.dart';

void showWalletSettingsSheet(BuildContext parentContext, WidgetRef ref) {
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
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Parametres du compte',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 32),
              _buildSettingItem(
                icon: Icons.account_balance_rounded,
                title: 'Informations bancaires',
                subtitle: 'Modifier vos coordonnees bancaires',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletBankInfoSheet(parentContext, ref);
                },
              ),
              _buildSettingItem(
                icon: Icons.phone_android_rounded,
                title: 'Mobile Money',
                subtitle: 'Gerer vos comptes Mobile Money',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletMobileMoneySheet(parentContext, ref);
                },
              ),
              _buildSettingItem(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Gerer les alertes de paiement',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletNotificationSettingsSheet(parentContext);
                },
              ),
              _buildSettingItem(
                icon: Icons.security_rounded,
                title: 'Securite',
                subtitle: 'PIN et authentification',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletSecuritySettingsSheet(parentContext);
                },
              ),
              _buildSettingItem(
                icon: Icons.receipt_long_rounded,
                title: 'Releves automatiques',
                subtitle: 'Configurer les exports periodiques',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletAutoReportSettingsSheet(parentContext, ref);
                },
              ),
              _buildSettingItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Seuil de retrait',
                subtitle: 'Configurer le montant minimum',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletWithdrawalThresholdSheet(parentContext);
                },
              ),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: 'Aide et support',
                subtitle: 'FAQ et contact',
                onTap: () {
                  Navigator.pop(ctx);
                  showWalletHelpSheet(parentContext);
                },
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
              child:
                  Icon(icon, color: Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400),
          ],
        ),
      ),
    ),
  );
}
