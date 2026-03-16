import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/interactive_tutorial_service.dart';
import '../../core/theme/theme_provider.dart';
import '../widgets/tutorial/interactive_tutorial_widgets.dart';

/// Écran des tutoriels interactifs
class InteractiveTutorialScreen extends ConsumerWidget {
  const InteractiveTutorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final progress = ref.watch(tutorialProgressProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Tutoriels',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          if (tutorialState.completedTutorials.isNotEmpty)
            TextButton(
              onPressed: () => _showResetDialog(context, ref),
              child: const Text('Réinitialiser'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progression globale
            _ProgressCard(progress: progress, tutorialState: tutorialState),
            const SizedBox(height: 24),
            
            // Liste des tutoriels
            Text(
              'Tutoriels disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            ...InteractiveTutorials.all.map((tutorial) => _TutorialCard(
              tutorial: tutorial,
              isCompleted: tutorialState.completedTutorials.contains(tutorial.id),
            )),
            
            const SizedBox(height: 32),
            
            // Section d'aide
            _HelpSection(),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les tutoriels'),
        content: const Text(
          'Tous les tutoriels seront marqués comme non complétés. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(interactiveTutorialProvider.notifier).resetAllTutorials();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutoriels réinitialisés'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

/// Carte de progression globale
class _ProgressCard extends StatelessWidget {
  final double progress;
  final InteractiveTutorialState tutorialState;

  const _ProgressCard({
    required this.progress,
    required this.tutorialState,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = tutorialState.completedTutorials.length;
    final totalCount = InteractiveTutorials.all.length;
    final isComplete = progress == 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.blue.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? Colors.green : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isComplete ? Icons.emoji_events : Icons.school,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Félicitations ! 🎉' : 'Votre progression',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? 'Tous les tutoriels complétés'
                          : '$completedCount sur $totalCount tutoriels complétés',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% complété',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un tutoriel
class _TutorialCard extends ConsumerWidget {
  final InteractiveTutorial tutorial;
  final bool isCompleted;

  const _TutorialCard({
    required this.tutorial,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ref.read(interactiveTutorialProvider.notifier).startTutorial(tutorial.id);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tutorial.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tutorial.icon,
                  color: tutorial.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tutorial.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Complété',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tutorial.description,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${tutorial.estimatedMinutes} min',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.format_list_numbered,
                          size: 14,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial.steps.length} étapes',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Bouton
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tutorial.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.replay : Icons.play_arrow,
                  color: tutorial.color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section d'aide
class _HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Conseils',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip(
            context,
            Icons.touch_app,
            'Interactions',
            'Certaines étapes permettent d\'interagir directement avec l\'élément.',
          ),
          const SizedBox(height: 12),
          _buildTip(
            context,
            Icons.skip_next,
            'Passer',
            'Vous pouvez toujours passer un tutoriel et le revoir plus tard.',
          ),
          const SizedBox(height: 12),
          _buildTip(
            context,
            Icons.help_outline,
            'Aide contextuelle',
            'Cherchez l\'icône ? sur chaque écran pour accéder au tutoriel associé.',
          ),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, IconData icon, String title, String desc) {
    final isDark = context.isDark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget liste des tutoriels pour le bottom sheet
class TutorialListWidget extends ConsumerWidget {
  const TutorialListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final tutorialState = ref.watch(interactiveTutorialProvider);
    final progress = ref.watch(tutorialProgressProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Tutoriels interactifs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              TutorialProgressBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Apprenez à utiliser l\'app avec des guides pas à pas',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          
          // Mini progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Liste compacte
          ...InteractiveTutorials.all.map((tutorial) {
            final isCompleted = tutorialState.completedTutorials.contains(tutorial.id);
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tutorial.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tutorial.icon, color: tutorial.color, size: 20),
              ),
              title: Text(
                tutorial.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                '~${tutorial.estimatedMinutes} min • ${tutorial.steps.length} étapes',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : Icon(Icons.play_circle_outline, color: tutorial.color, size: 24),
              onTap: () {
                ref.read(interactiveTutorialProvider.notifier).startTutorial(tutorial.id);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
