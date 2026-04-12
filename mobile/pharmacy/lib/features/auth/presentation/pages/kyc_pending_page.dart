import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Page affichée quand le KYC de la pharmacie est en attente de validation.
/// L'utilisateur ne peut pas accéder aux fonctionnalités tant que son KYC
/// n'est pas approuvé.
class KycPendingPage extends ConsumerWidget {
  const KycPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final pharmacy = authState.user?.pharmacy;
    final status = pharmacy?.status ?? 'pending_review';

    // Déterminer le message selon le statut
    final (icon, color, title, message) = switch (status) {
      'rejected' => (
        Icons.cancel_outlined,
        Colors.red,
        'Vérification refusée',
        'Votre demande de vérification a été refusée. Veuillez vérifier vos documents et soumettre une nouvelle demande.',
      ),
      'suspended' => (
        Icons.pause_circle_outline,
        Colors.orange,
        'Compte suspendu',
        'Votre compte a été temporairement suspendu. Contactez le support pour plus d\'informations.',
      ),
      _ => (
        Icons.hourglass_top_rounded,
        Colors.amber,
        'Vérification en cours',
        'Votre pharmacie est en cours de vérification. Nous examinerons vos documents dans les plus brefs délais.',
      ),
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Nom de la pharmacie
              if (pharmacy != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_pharmacy_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (pharmacy.city != null)
                              Text(
                                pharmacy.city!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Boutons d'action
              if (status == 'rejected') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/edit-pharmacy', extra: pharmacy);
                    },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Resoumettre les documents'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bouton de déconnexion
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact support
              TextButton.icon(
                onPressed: () {
                  context.push('/help-support');
                },
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text('Contacter le support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
