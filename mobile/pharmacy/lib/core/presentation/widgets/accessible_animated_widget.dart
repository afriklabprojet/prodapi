import 'package:flutter/material.dart';

/// Widget AnimatedContainer accessible qui respecte les préférences reduce_motion.
///
/// Remplace AnimatedContainer standard pour désactiver automatiquement
/// les animations si l'utilisateur a activé "Réduire les animations".
///
/// Usage:
/// ```dart
/// AccessibleAnimatedContainer(
///   duration: Duration(milliseconds: 300),
///   color: isSelected ? Colors.blue : Colors.grey,
///   child: Text('Contenu'),
/// )
/// ```
class AccessibleAnimatedContainer extends StatelessWidget {
  const AccessibleAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
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

  final Widget child;
  final Duration duration;
  final Curve curve;
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
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : duration,
      curve: reduceMotion ? Curves.linear : curve,
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

/// Widget AnimatedOpacity accessible qui respecte les préférences reduce_motion.
class AccessibleAnimatedOpacity extends StatelessWidget {
  const AccessibleAnimatedOpacity({
    super.key,
    required this.child,
    required this.opacity,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onEnd,
    this.alwaysIncludeSemantics = false,
  });

  final Widget child;
  final double opacity;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;
  final bool alwaysIncludeSemantics;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedOpacity(
      opacity: opacity,
      duration: reduceMotion ? Duration.zero : duration,
      curve: reduceMotion ? Curves.linear : curve,
      onEnd: onEnd,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      child: child,
    );
  }
}

/// Widget AnimatedScale accessible qui respecte les préférences reduce_motion.
class AccessibleAnimatedScale extends StatelessWidget {
  const AccessibleAnimatedScale({
    super.key,
    required this.child,
    required this.scale,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.filterQuality,
    this.onEnd,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
  final FilterQuality? filterQuality;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedScale(
      scale: scale,
      duration: reduceMotion ? Duration.zero : duration,
      curve: reduceMotion ? Curves.linear : curve,
      alignment: alignment,
      filterQuality: filterQuality,
      onEnd: onEnd,
      child: child,
    );
  }
}

/// Widget AnimatedSlide accessible qui respecte les préférences reduce_motion.
class AccessibleAnimatedSlide extends StatelessWidget {
  const AccessibleAnimatedSlide({
    super.key,
    required this.child,
    required this.offset,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onEnd,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedSlide(
      offset: offset,
      duration: reduceMotion ? Duration.zero : duration,
      curve: reduceMotion ? Curves.linear : curve,
      onEnd: onEnd,
      child: child,
    );
  }
}

/// Widget AnimatedSwitcher accessible qui respecte les préférences reduce_motion.
class AccessibleAnimatedSwitcher extends StatelessWidget {
  const AccessibleAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  });

  final Widget child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      // Pas d'animation, juste afficher le nouveau widget
      return child;
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

/// Widget AnimatedCrossFade accessible qui respecte les préférences reduce_motion.
class AccessibleAnimatedCrossFade extends StatelessWidget {
  const AccessibleAnimatedCrossFade({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.crossFadeState,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.firstCurve = Curves.linear,
    this.secondCurve = Curves.linear,
    this.sizeCurve = Curves.linear,
    this.alignment = Alignment.topCenter,
    this.layoutBuilder = AnimatedCrossFade.defaultLayoutBuilder,
    this.excludeBottomFocus = true,
  });

  final Widget firstChild;
  final Widget secondChild;
  final CrossFadeState crossFadeState;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve firstCurve;
  final Curve secondCurve;
  final Curve sizeCurve;
  final AlignmentGeometry alignment;
  final AnimatedCrossFadeBuilder layoutBuilder;
  final bool excludeBottomFocus;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      // Pas d'animation, afficher directement le bon widget
      return crossFadeState == CrossFadeState.showFirst
          ? firstChild
          : secondChild;
    }

    return AnimatedCrossFade(
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: crossFadeState,
      duration: duration,
      reverseDuration: reverseDuration,
      firstCurve: firstCurve,
      secondCurve: secondCurve,
      sizeCurve: sizeCurve,
      alignment: alignment,
      layoutBuilder: layoutBuilder,
      excludeBottomFocus: excludeBottomFocus,
    );
  }
}

/// Extension pour créer facilement des animations accessibles.
extension AccessibleAnimationContext on BuildContext {
  /// Retourne Duration.zero si reduce motion est activé.
  Duration accessibleDuration(Duration normalDuration) {
    return MediaQuery.of(this).disableAnimations ? Duration.zero : normalDuration;
  }

  /// Retourne la courbe linéaire si reduce motion est activé.
  Curve accessibleCurve(Curve normalCurve) {
    return MediaQuery.of(this).disableAnimations ? Curves.linear : normalCurve;
  }
}
