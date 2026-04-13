import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/accessibility_service.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// WIDGETS D'ANIMATION ACCESSIBLES (Reduce Motion Aware)
/// ══════════════════════════════════════════════════════════════════════════
/// 
/// Composants drop-in qui respectent automatiquement le paramètre reduce_motion.
/// En mode reduce_motion, les animations sont désactivées ou accélérées.
///
/// Usage:
///   // Au lieu de AnimatedContainer
///   AccessibleAnimatedContainer(...)
///   
///   // Au lieu de AnimatedOpacity
///   AccessibleAnimatedOpacity(...)
/// ══════════════════════════════════════════════════════════════════════════

/// Durée minimale quand reduce_motion est actif.
const _kReducedDuration = Duration(milliseconds: 50);

/// Courbe linéaire pour reduce_motion (pas de rebond/ease).
const _kReducedCurve = Curves.linear;

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED CONTAINER ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedContainer].
/// Respecte automatiquement reduce_motion.
class AccessibleAnimatedContainer extends ConsumerWidget {
  final Duration duration;
  final Curve curve;
  final Widget? child;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;
  final void Function()? onEnd;

  const AccessibleAnimatedContainer({
    super.key,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.child,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    return AnimatedContainer(
      duration: reduceMotion ? _kReducedDuration : duration,
      curve: reduceMotion ? _kReducedCurve : curve,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      onEnd: onEnd,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED OPACITY ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedOpacity].
class AccessibleAnimatedOpacity extends ConsumerWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;
  final double opacity;
  final bool alwaysIncludeSemantics;
  final void Function()? onEnd;

  const AccessibleAnimatedOpacity({
    super.key,
    required this.duration,
    required this.opacity,
    required this.child,
    this.curve = Curves.easeInOut,
    this.alwaysIncludeSemantics = false,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    return AnimatedOpacity(
      duration: reduceMotion ? _kReducedDuration : duration,
      curve: reduceMotion ? _kReducedCurve : curve,
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      onEnd: onEnd,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED SWITCHER ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedSwitcher].
class AccessibleAnimatedSwitcher extends ConsumerWidget {
  final Duration duration;
  final Duration? reverseDuration;
  final Widget? child;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  const AccessibleAnimatedSwitcher({
    super.key,
    required this.duration,
    this.reverseDuration,
    this.child,
    this.switchInCurve = Curves.easeInOut,
    this.switchOutCurve = Curves.easeInOut,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    if (reduceMotion) {
      // Pas de transition, juste afficher le child
      return child ?? const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED SCALE ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedScale].
class AccessibleAnimatedScale extends ConsumerWidget {
  final Duration duration;
  final Curve curve;
  final double scale;
  final Widget? child;
  final Alignment alignment;
  final FilterQuality? filterQuality;
  final void Function()? onEnd;

  const AccessibleAnimatedScale({
    super.key,
    required this.duration,
    required this.scale,
    this.curve = Curves.easeInOut,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    return AnimatedScale(
      duration: reduceMotion ? _kReducedDuration : duration,
      curve: reduceMotion ? _kReducedCurve : curve,
      scale: scale,
      alignment: alignment,
      filterQuality: filterQuality,
      onEnd: onEnd,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED SLIDE ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedSlide].
class AccessibleAnimatedSlide extends ConsumerWidget {
  final Duration duration;
  final Curve curve;
  final Offset offset;
  final Widget? child;
  final void Function()? onEnd;

  const AccessibleAnimatedSlide({
    super.key,
    required this.duration,
    required this.offset,
    this.curve = Curves.easeInOut,
    this.child,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    // Si reduce_motion, pas de décalage
    final effectiveOffset = reduceMotion ? Offset.zero : offset;

    return AnimatedSlide(
      duration: reduceMotion ? _kReducedDuration : duration,
      curve: reduceMotion ? _kReducedCurve : curve,
      offset: effectiveOffset,
      onEnd: onEnd,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED ROTATION ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedRotation].
class AccessibleAnimatedRotation extends ConsumerWidget {
  final Duration duration;
  final Curve curve;
  final double turns;
  final Widget? child;
  final Alignment alignment;
  final FilterQuality? filterQuality;
  final void Function()? onEnd;

  const AccessibleAnimatedRotation({
    super.key,
    required this.duration,
    required this.turns,
    this.curve = Curves.easeInOut,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    return AnimatedRotation(
      duration: reduceMotion ? _kReducedDuration : duration,
      curve: reduceMotion ? _kReducedCurve : curve,
      turns: turns,
      alignment: alignment,
      filterQuality: filterQuality,
      onEnd: onEnd,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED CROSS FADE ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedCrossFade].
class AccessibleAnimatedCrossFade extends ConsumerWidget {
  final Duration duration;
  final Duration? reverseDuration;
  final Widget firstChild;
  final Widget secondChild;
  final CrossFadeState crossFadeState;
  final Curve firstCurve;
  final Curve secondCurve;
  final Curve sizeCurve;
  final AlignmentGeometry alignment;
  final AnimatedCrossFadeBuilder? layoutBuilder;
  final bool excludeBottomFocus;

  const AccessibleAnimatedCrossFade({
    super.key,
    required this.duration,
    required this.firstChild,
    required this.secondChild,
    required this.crossFadeState,
    this.reverseDuration,
    this.firstCurve = Curves.easeInOut,
    this.secondCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.topCenter,
    this.layoutBuilder,
    this.excludeBottomFocus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    if (reduceMotion) {
      // Pas de transition, juste afficher le child actif
      return crossFadeState == CrossFadeState.showFirst
          ? firstChild
          : secondChild;
    }

    return AnimatedCrossFade(
      duration: duration,
      reverseDuration: reverseDuration,
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: crossFadeState,
      firstCurve: firstCurve,
      secondCurve: secondCurve,
      sizeCurve: sizeCurve,
      alignment: alignment,
      layoutBuilder: layoutBuilder ?? AnimatedCrossFade.defaultLayoutBuilder,
      excludeBottomFocus: excludeBottomFocus,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED SIZE ACCESSIBLE
// ══════════════════════════════════════════════════════════════════════════

/// Version accessible de [AnimatedSize].
class AccessibleAnimatedSize extends ConsumerWidget {
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Widget? child;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;

  const AccessibleAnimatedSize({
    super.key,
    required this.duration,
    this.reverseDuration,
    this.curve = Curves.easeInOut,
    this.child,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    return AnimatedSize(
      duration: reduceMotion ? _kReducedDuration : duration,
      reverseDuration: reduceMotion ? _kReducedDuration : reverseDuration,
      curve: reduceMotion ? _kReducedCurve : curve,
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════

/// Extension pour obtenir une durée adaptée à reduce_motion.
extension AccessibleDuration on Duration {
  /// Retourne la durée appropriée selon l'accessibilité.
  Duration accessibleValue(bool reduceMotion) {
    return reduceMotion ? _kReducedDuration : this;
  }
}

/// Mixin pour les widgets avec AnimationController.
/// 
/// Usage:
/// ```dart
/// class MyWidget extends ConsumerStatefulWidget {
///   ...
/// }
/// 
/// class _MyWidgetState extends ConsumerState<MyWidget>
///     with SingleTickerProviderStateMixin, AccessibleAnimationMixin {
///   
///   late AnimationController _controller;
///   
///   @override
///   void initState() {
///     super.initState();
///     _controller = createAccessibleController(
///       duration: const Duration(milliseconds: 500),
///     );
///   }
/// }
/// ```
mixin AccessibleAnimationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, TickerProvider {
  
  /// Crée un AnimationController avec durée adaptée à reduce_motion.
  AnimationController createAccessibleController({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    double? value,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final reduceMotion = ref.read(accessibilityProvider).reduceMotion;
    
    return AnimationController(
      duration: reduceMotion ? _kReducedDuration : duration,
      reverseDuration: reduceMotion 
          ? _kReducedDuration 
          : (reverseDuration ?? duration),
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      value: value,
      animationBehavior: animationBehavior,
      vsync: this,
    );
  }

  /// Met à jour la durée d'un controller selon reduce_motion.
  void updateControllerDuration(
    AnimationController controller,
    Duration normalDuration,
  ) {
    final reduceMotion = ref.read(accessibilityProvider).reduceMotion;
    controller.duration = reduceMotion ? _kReducedDuration : normalDuration;
  }
}

/// Widget qui pulse (animation de respiration) avec support reduce_motion.
/// Utile pour les indicateurs de chargement ou pour attirer l'attention.
class AccessiblePulse extends ConsumerStatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool enabled;

  const AccessiblePulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.enabled = true,
  });

  @override
  ConsumerState<AccessiblePulse> createState() => _AccessiblePulseState();
}

class _AccessiblePulseState extends ConsumerState<AccessiblePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    final reduceMotion = ref.read(accessibilityProvider).reduceMotion;
    
    _controller = AnimationController(
      duration: reduceMotion ? Duration.zero : widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled && !reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AccessiblePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final reduceMotion = ref.read(accessibilityProvider).reduceMotion;
    
    if (widget.enabled && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0.5; // Position neutre
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(
      accessibilityProvider.select((s) => s.reduceMotion),
    );

    if (reduceMotion || !widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
