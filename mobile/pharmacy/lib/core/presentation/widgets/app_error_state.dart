import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// Widget réutilisable pour afficher un état d'erreur avec action de retry.
/// 
/// Utilisé quand une opération échoue et que l'utilisateur peut réessayer.
/// Fournit un message clair, optionnellement un code d'erreur, et un bouton retry.
class AppErrorState extends StatelessWidget {
  /// Message d'erreur à afficher
  final String message;
  
  /// Callback pour réessayer l'opération
  final VoidCallback onRetry;
  
  /// Code d'erreur optionnel (pour le support)
  final String? errorCode;
  
  /// Icône à afficher (défaut: error_outline)
  final IconData? icon;
  
  /// Label du bouton retry (défaut: "Réessayer")
  final String? retryLabel;

  const AppErrorState({
    required this.message,
    required this.onRetry,
    this.errorCode,
    this.icon,
    this.retryLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur avec cercle de fond
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            
            // Message d'erreur
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Code d'erreur optionnel
            if (errorCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Code: $errorCode',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Bouton Réessayer
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retryLabel ?? 'Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Lien contact support
            TextButton(
              onPressed: () => _showSupportInfo(context),
              child: Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.support_agent,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Contacter le support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si le problème persiste, contactez notre équipe support.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Mentionnez le code: $errorCode',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                label: Text(AppLocalizations.of(ctx).close),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Factory constructors pour les cas courants
  
  /// Erreur réseau générique
  factory AppErrorState.network({required VoidCallback onRetry}) {
    return AppErrorState(
      message: 'Impossible de se connecter.\nVérifiez votre connexion internet.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      errorCode: 'NET_ERR',
    );
  }

  /// Erreur serveur
  factory AppErrorState.server({required VoidCallback onRetry, String? code}) {
    return AppErrorState(
      message: 'Le serveur est temporairement indisponible.\nRéessayez dans quelques instants.',
      onRetry: onRetry,
      icon: Icons.cloud_off,
      errorCode: code ?? 'SRV_ERR',
    );
  }

  /// Erreur de chargement de données
  factory AppErrorState.loadFailed({
    required VoidCallback onRetry, 
    String? what,
  }) {
    return AppErrorState(
      message: what != null 
          ? 'Impossible de charger $what.\nTirez pour actualiser ou appuyez sur Réessayer.'
          : 'Impossible de charger les données.\nTirez pour actualiser.',
      onRetry: onRetry,
      icon: Icons.sync_problem,
    );
  }

  /// Session expirée
  factory AppErrorState.sessionExpired({required VoidCallback onRetry}) {
    return AppErrorState(
      message: 'Votre session a expiré.\nVeuillez vous reconnecter.',
      onRetry: onRetry,
      icon: Icons.lock_clock,
      retryLabel: 'Se reconnecter',
      errorCode: 'AUTH_EXP',
    );
  }

  /// Erreur inconnue
  factory AppErrorState.unknown({required VoidCallback onRetry, String? code}) {
    return AppErrorState(
      message: 'Une erreur inattendue s\'est produite.',
      onRetry: onRetry,
      errorCode: code,
    );
  }
}
