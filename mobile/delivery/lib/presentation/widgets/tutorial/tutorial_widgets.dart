import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import '../../../core/services/tutorial_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';

/// Provider pour l'état du tutorial en cours
final activeTutorialProvider = StateProvider<TutorialType?>((ref) => null);
final tutorialStepProvider = StateProvider<int>((ref) => 0);

/// Overlay pour afficher le tutoriel interactif
class TutorialOverlay extends ConsumerWidget {
  final Widget child;
  
  const TutorialOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTutorial = ref.watch(activeTutorialProvider);
    final currentStep = ref.watch(tutorialStepProvider);
    
    if (activeTutorial == null) {
      return child;
    }
    
    final steps = Tutorials.getSteps(activeTutorial);
    if (currentStep >= steps.length) {
      return child;
    }
    
    return Stack(
      children: [
        child,
        // Overlay semi-transparent
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Bloque les taps
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Carte du tutoriel
        Center(
          child: TutorialCard(
            tutorial: activeTutorial,
            step: steps[currentStep],
            stepIndex: currentStep,
            totalSteps: steps.length,
            onNext: () {
              if (currentStep < steps.length - 1) {
                ref.read(tutorialStepProvider.notifier).state = currentStep + 1;
              } else {
                // Tutorial terminé
                ref.read(tutorialServiceProvider).markCompleted(activeTutorial);
                ref.read(activeTutorialProvider.notifier).state = null;
                ref.read(tutorialStepProvider.notifier).state = 0;
              }
            },
            onSkip: () {
              ref.read(tutorialServiceProvider).markCompleted(activeTutorial);
              ref.read(activeTutorialProvider.notifier).state = null;
              ref.read(tutorialStepProvider.notifier).state = 0;
            },
          ),
        ),
      ],
    );
  }
}

/// Carte affichant un step de tutoriel
class TutorialCard extends StatelessWidget {
  final TutorialType tutorial;
  final TutorialStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  
  const TutorialCard({
    super.key,
    required this.tutorial,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isLastStep = stepIndex == totalSteps - 1;
    
    return Container(
      margin: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxWidth: context.r.dp(340)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec indicateur de progression
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Indicateur de progression
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == stepIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index <= stepIndex 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                // Skip
                if (stepIndex < totalSteps - 1)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                const Spacer(),
                // Step indicator
                Text(
                  '${stepIndex + 1}/$totalSteps',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Next / Finish
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    step.actionLabel ?? (isLastStep ? 'Terminer' : 'Suivant'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension pour démarrer facilement un tutoriel
extension TutorialExtension on WidgetRef {
  /// Démarrer un tutoriel si non complété
  Future<bool> startTutorialIfNeeded(TutorialType type) async {
    final service = read(tutorialServiceProvider);
    final completed = await service.isCompleted(type);
    
    if (!completed) {
      read(tutorialStepProvider.notifier).state = 0;
      read(activeTutorialProvider.notifier).state = type;
      return true;
    }
    return false;
  }
  
  /// Forcer le démarrage d'un tutoriel
  void startTutorial(TutorialType type) {
    read(tutorialStepProvider.notifier).state = 0;
    read(activeTutorialProvider.notifier).state = type;
  }
}

/// Widget pour afficher le bouton d'aide contextuelle
class TutorialHelpButton extends ConsumerWidget {
  final TutorialType tutorial;
  final Color? color;
  
  const TutorialHelpButton({
    super.key,
    required this.tutorial,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: color ?? Colors.grey),
      tooltip: 'Aide',
      onPressed: () => ref.startTutorial(tutorial),
    );
  }
}

/// Dialog pour proposer un tutoriel
class TutorialPromptDialog extends StatelessWidget {
  final TutorialType tutorial;
  final String title;
  final String message;
  
  const TutorialPromptDialog({
    super.key,
    required this.tutorial,
    required this.title,
    required this.message,
  });
  
  static Future<bool?> show(
    BuildContext context, {
    required TutorialType tutorial,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => TutorialPromptDialog(
        tutorial: tutorial,
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Non merci',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Voir le guide'),
        ),
      ],
    );
  }
}

/// Liste des tutoriels disponibles dans les paramètres
class TutorialListWidget extends ConsumerWidget {
  const TutorialListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    
    final tutorials = [
      (TutorialType.welcome, 'Bienvenue', 'Découvrez les bases de l\'application'),
      (TutorialType.acceptDelivery, 'Accepter une commande', 'Comment recevoir et accepter des livraisons'),
      (TutorialType.navigation, 'Navigation', 'Utilisez la carte et le GPS'),
      (TutorialType.completeDelivery, 'Compléter une livraison', 'Photos, signatures et confirmation'),
      (TutorialType.wallet, 'Portefeuille', 'Gérez vos gains et retraits'),
      (TutorialType.challenges, 'Défis & Bonus', 'Gagnez plus avec la gamification'),
      (TutorialType.offlineMode, 'Mode hors-ligne', 'Fonctionnement sans réseau'),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tutoriels',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        ...tutorials.map((t) => _TutorialListTile(
          type: t.$1,
          title: t.$2,
          subtitle: t.$3,
        )),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(tutorialServiceProvider).resetAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tous les tutoriels ont été réinitialisés')),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser tous les tutoriels'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorialListTile extends ConsumerWidget {
  final TutorialType type;
  final String title;
  final String subtitle;
  
  const _TutorialListTile({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(tutorialCompletedProvider(type));
    final isDark = context.isDark;
    
    return ListTile(
      leading: completedAsync.when(
        data: (completed) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: completed 
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed ? Icons.check_circle : Icons.play_circle_outline,
            color: completed ? Colors.green : Colors.blue,
            size: 24,
          ),
        ),
        loading: () => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => const Icon(Icons.error_outline, color: Colors.red),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isDark ? Colors.white38 : Colors.grey,
      ),
      onTap: () => ref.startTutorial(type),
    );
  }
}
