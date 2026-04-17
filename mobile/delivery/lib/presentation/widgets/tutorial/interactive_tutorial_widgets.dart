import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/interactive_tutorial_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';

/// Overlay principal pour les tutoriels interactifs avec effet spotlight
class InteractiveTutorialOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const InteractiveTutorialOverlay({super.key, required this.child});

  @override
  ConsumerState<InteractiveTutorialOverlay> createState() =>
      _InteractiveTutorialOverlayState();
}

class _InteractiveTutorialOverlayState
    extends ConsumerState<InteractiveTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(interactiveTutorialProvider);

    if (!tutorialState.isActive) {
      return widget.child;
    }

    final currentStep = tutorialState.currentStep;
    if (currentStep == null) {
      return widget.child;
    }

    // Récupérer la position du widget cible
    Rect? targetRect;
    if (currentStep.targetWidgetKey != null) {
      final targetKey = tutorialTargetKeys[currentStep.targetWidgetKey];
      if (targetKey?.currentContext != null) {
        final renderBox =
            targetKey!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          targetRect = Rect.fromLTWH(
            position.dx - currentStep.spotlightPadding,
            position.dy - currentStep.spotlightPadding,
            renderBox.size.width + currentStep.spotlightPadding * 2,
            renderBox.size.height + currentStep.spotlightPadding * 2,
          );
        }
      }
    }

    return Stack(
      children: [
        widget.child,
        // Overlay avec découpe spotlight
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                shape: currentStep.spotlightShape,
                pulseScale: targetRect != null ? _pulseAnimation.value : 1.0,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Bloquer les interactions sauf sur le widget cible
        if (!currentStep.allowInteraction)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.translucent,
            ),
          ),
        // Permettre interaction sur le widget cible si autorisé
        if (currentStep.allowInteraction && targetRect != null)
          Positioned(
            left: targetRect.left,
            top: targetRect.top,
            width: targetRect.width,
            height: targetRect.height,
            child: GestureDetector(
              onTap: () {
                // L'interaction est permise, avancer automatiquement
                ref.read(interactiveTutorialProvider.notifier).nextStep();
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
        // Tooltip
        _TutorialTooltip(
          step: currentStep,
          tutorialState: tutorialState,
          targetRect: targetRect,
          onNext: () =>
              ref.read(interactiveTutorialProvider.notifier).nextStep(),
          onPrevious: () =>
              ref.read(interactiveTutorialProvider.notifier).previousStep(),
          onSkip: () =>
              ref.read(interactiveTutorialProvider.notifier).cancelTutorial(),
        ),
      ],
    );
  }
}

/// Painter pour l'effet spotlight
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final SpotlightShape shape;
  final double pulseScale;

  _SpotlightPainter({
    this.targetRect,
    this.shape = SpotlightShape.roundedRectangle,
    this.pulseScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRect(fullRect);

    if (targetRect != null) {
      // Appliquer le scale de pulsation
      final scaledRect = Rect.fromCenter(
        center: targetRect!.center,
        width: targetRect!.width * pulseScale,
        height: targetRect!.height * pulseScale,
      );

      // Créer le trou selon la forme
      Path holePath;
      switch (shape) {
        case SpotlightShape.circle:
          final radius = math.max(scaledRect.width, scaledRect.height) / 2;
          holePath = Path()
            ..addOval(Rect.fromCircle(center: scaledRect.center, radius: radius));
          break;
        case SpotlightShape.rectangle:
          holePath = Path()..addRect(scaledRect);
          break;
        case SpotlightShape.roundedRectangle:
          holePath = Path()
            ..addRRect(RRect.fromRectAndRadius(
              scaledRect,
              const Radius.circular(12),
            ));
          break;
      }

      path.addPath(holePath, Offset.zero);
      path.fillType = PathFillType.evenOdd;

      // Bordure lumineuse autour du spotlight
      final borderPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawPath(holePath, borderPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        pulseScale != oldDelegate.pulseScale;
  }
}

/// Tooltip du tutoriel
class _TutorialTooltip extends StatelessWidget {
  final InteractiveTutorialStep step;
  final InteractiveTutorialState tutorialState;
  final Rect? targetRect;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const _TutorialTooltip({
    required this.step,
    required this.tutorialState,
    this.targetRect,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final screenSize = MediaQuery.of(context).size;
    final tutorial = tutorialState.activeTutorial!;
    final stepIndex = tutorialState.currentStepIndex;
    final isFirst = stepIndex == 0;
    final isLast = tutorialState.isLastStep;

    // Calculer la position du tooltip
    double? top;
    double? bottom;
    
    if (targetRect != null) {
      // Positionner au-dessus ou en-dessous du target
      final targetCenterY = targetRect!.center.dy;
      if (targetCenterY > screenSize.height / 2) {
        // Target en bas, tooltip en haut
        top = 100;
      } else {
        // Target en haut, tooltip en bas
        bottom = 100;
      }
    } else {
      // Centrer verticalement
      top = screenSize.height * 0.25;
    }

    return Positioned(
      left: 20,
      right: 20,
      top: top,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: context.r.dp(400)),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tutorial.color,
                      tutorial.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(step.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutorial.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            step.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton fermer
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: onSkip,
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),
              // Indicateur de progression
              LinearProgressIndicator(
                value: tutorialState.progress,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(tutorial.color),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    // Tips
                    if (step.tips != null && step.tips!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tutorial.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: step.tips!
                              .map((tip) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          size: 16,
                                          color: tutorial.color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Précédent
                    if (!isFirst)
                      TextButton.icon(
                        onPressed: onPrevious,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Précédent'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white54 : Colors.grey,
                        ),
                      )
                    else
                      const SizedBox(width: 100),
                    const Spacer(),
                    // Indicateur de step
                    Text(
                      '${stepIndex + 1}/${tutorial.steps.length}',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Suivant / Terminer
                    ElevatedButton.icon(
                      onPressed: onNext,
                      icon: Icon(
                        isLast ? Icons.check : Icons.arrow_forward,
                        size: 18,
                      ),
                      label: Text(
                        step.actionLabel ?? (isLast ? 'Terminer' : 'Suivant'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tutorial.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour marquer un élément comme cible de tutoriel
class TutorialTarget extends StatelessWidget {
  final String targetKey;
  final Widget child;

  const TutorialTarget({
    super.key,
    required this.targetKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final key = registerTutorialTarget(targetKey);
    return KeyedSubtree(
      key: key,
      child: child,
    );
  }
}

/// Bouton pour démarrer un tutoriel
class StartTutorialButton extends ConsumerWidget {
  final String tutorialId;
  final bool showLabel;

  const StartTutorialButton({
    super.key,
    required this.tutorialId,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorial = InteractiveTutorials.getById(tutorialId);
    if (tutorial == null) return const SizedBox.shrink();

    final isCompleted = ref.watch(isTutorialCompletedProvider(tutorialId));

    if (showLabel) {
      return OutlinedButton.icon(
        onPressed: () {
          ref.read(interactiveTutorialProvider.notifier).startTutorial(tutorialId);
        },
        icon: Icon(isCompleted ? Icons.refresh : Icons.play_arrow),
        label: Text(isCompleted ? 'Revoir' : 'Commencer'),
        style: OutlinedButton.styleFrom(
          foregroundColor: tutorial.color,
          side: BorderSide(color: tutorial.color),
        ),
      );
    }

    return IconButton(
      onPressed: () {
        ref.read(interactiveTutorialProvider.notifier).startTutorial(tutorialId);
      },
      icon: Icon(Icons.help_outline, color: tutorial.color),
      tooltip: tutorial.name,
    );
  }
}

/// Badge de progression des tutoriels
class TutorialProgressBadge extends ConsumerWidget {
  const TutorialProgressBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tutorialProgressProvider);
    final completedCount = ref.watch(interactiveTutorialProvider).completedTutorials.length;
    final totalCount = InteractiveTutorials.all.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: progress == 1.0
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            progress == 1.0 ? Icons.check_circle : Icons.school,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$completedCount/$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
