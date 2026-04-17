import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Settings sheet for alert configuration
class AlertSettingsSheet extends StatefulWidget {
  const AlertSettingsSheet({super.key});

  @override
  State<AlertSettingsSheet> createState() => _AlertSettingsSheetState();
}

class _AlertSettingsSheetState extends State<AlertSettingsSheet> {
  int _defaultThreshold = 20;
  int _expirationWarningDays = 30;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Paramètres d\'alerte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor(context),
              ),
            ),
          ),
          Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),

          // Default threshold
          ListTile(
            leading: Icon(
              Icons.inventory_2,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Seuil d\'alerte par défaut',
              style: TextStyle(color: AppColors.textColor(context)),
            ),
            subtitle: Text(
              '$_defaultThreshold unités',
              style: TextStyle(
                color: AppColors.textColor(context).withValues(alpha: 0.6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.textColor(context),
                  ),
                  onPressed: () {
                    if (_defaultThreshold > 5) {
                      setState(() => _defaultThreshold -= 5);
                    }
                  },
                  tooltip: 'Diminuer le seuil',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Text(
                  '$_defaultThreshold',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.textColor(context),
                  ),
                  onPressed: () {
                    setState(() => _defaultThreshold += 5);
                  },
                  tooltip: 'Augmenter le seuil',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),

          // Expiration warning
          ListTile(
            leading: Icon(Icons.event, color: Colors.orange),
            title: Text(
              'Alerte d\'expiration',
              style: TextStyle(color: AppColors.textColor(context)),
            ),
            subtitle: Text(
              '$_expirationWarningDays jours avant',
              style: TextStyle(
                color: AppColors.textColor(context).withValues(alpha: 0.6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.textColor(context),
                  ),
                  onPressed: () {
                    if (_expirationWarningDays > 7) {
                      setState(() => _expirationWarningDays -= 7);
                    }
                  },
                  tooltip: 'Diminuer les jours',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Text(
                  '$_expirationWarningDays',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.textColor(context),
                  ),
                  onPressed: () {
                    setState(() => _expirationWarningDays += 7);
                  },
                  tooltip: 'Augmenter les jours',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: AppColors.isDark(context)
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),

          // Push notifications
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            title: Text(
              'Notifications push',
              style: TextStyle(color: AppColors.textColor(context)),
            ),
            subtitle: Text(
              'Recevoir des alertes sur votre téléphone',
              style: TextStyle(
                color: AppColors.textColor(context).withValues(alpha: 0.6),
              ),
            ),
            secondary: Icon(
              Icons.notifications,
              color: AppColors.textColor(context).withValues(alpha: 0.7),
            ),
          ),

          // Email notifications
          SwitchListTile(
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            title: Text(
              'Notifications email',
              style: TextStyle(color: AppColors.textColor(context)),
            ),
            subtitle: Text(
              'Recevoir un résumé quotidien par email',
              style: TextStyle(
                color: AppColors.textColor(context).withValues(alpha: 0.6),
              ),
            ),
            secondary: Icon(
              Icons.email,
              color: AppColors.textColor(context).withValues(alpha: 0.7),
            ),
          ),

          // Sound
          SwitchListTile(
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
            title: Text(
              'Son d\'alerte',
              style: TextStyle(color: AppColors.textColor(context)),
            ),
            subtitle: Text(
              'Jouer un son lors d\'une alerte critique',
              style: TextStyle(
                color: AppColors.textColor(context).withValues(alpha: 0.6),
              ),
            ),
            secondary: Icon(
              Icons.volume_up,
              color: AppColors.textColor(context).withValues(alpha: 0.7),
            ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres sauvegardés'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).save,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
