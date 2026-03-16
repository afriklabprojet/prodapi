import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

// ──────────────────────────────────────────────────────────────────────────────
// DR-PHARMA — Reusable Adaptive Widgets
// ──────────────────────────────────────────────────────────────────────────────

/// Adaptive button that scales padding, font size, and min height.
/// On tablets, buttons are wider and taller for better touch targets.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return SizedBox(
      height: r.dp(52),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: (style ?? ElevatedButton.styleFrom()).copyWith(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: r.dp(24), vertical: r.dp(14)),
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w600),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: r.dp(22),
                height: r.dp(22),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : child,
      ),
    );
  }
}

/// Adaptive icon container — scales size based on screen.
/// Great for onboarding circles, profile avatars, etc.
class AdaptiveIconCircle extends StatelessWidget {
  const AdaptiveIconCircle({
    super.key,
    required this.icon,
    this.size = 80,
    this.iconSize,
    this.gradient,
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.shadow = true,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final Color iconColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final scaledSize = r.dp(size);
    final scaledIconSize = r.dp(iconSize ?? size * 0.5);

    return Container(
      width: scaledSize,
      height: scaledSize,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient!,
              )
            : null,
        color: gradient == null ? (backgroundColor ?? Colors.blue) : null,
        shape: BoxShape.circle,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: (gradient?.first ?? backgroundColor ?? Colors.blue)
                      .withValues(alpha: 0.3),
                  blurRadius: r.dp(20),
                  offset: Offset(0, r.dp(8)),
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: scaledIconSize, color: iconColor),
    );
  }
}

/// Adaptive card with responsive padding and border radius.
class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius = 16,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Container(
      margin: margin ?? r.padH(16),
      padding: padding ?? r.pad(16),
      decoration: BoxDecoration(
        color: color ?? context.cardBg,
        borderRadius: BorderRadius.circular(r.dp(borderRadius)),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08 * elevation),
                  blurRadius: r.dp(8 * elevation),
                  offset: Offset(0, r.dp(2 * elevation)),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Adaptive SizedBox — scales its width/height
class RGap extends StatelessWidget {
  const RGap(this.size, {super.key});
  const RGap.h(this.size, {super.key});
  
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SizedBox(height: r.dp(size));
  }
}

/// Horizontal gap
class RGapW extends StatelessWidget {
  const RGapW(this.size, {super.key});
  
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SizedBox(width: r.dp(size));
  }
}

/// Responsive image that scales width and preserves aspect ratio.
/// On tablets, limits max width to avoid overly large images.
class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    super.key,
    required this.image,
    this.widthPercent = 100,
    this.maxWidth = 400,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
  });

  final ImageProvider image;
  final double widthPercent;
  final double maxWidth;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final width = r.w(widthPercent).clamp(0.0, r.dp(maxWidth));

    Widget img = Image(
      image: image,
      width: width,
      fit: fit,
    );

    if (borderRadius > 0) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(r.dp(borderRadius)),
        child: img,
      );
    }

    return img;
  }
}

/// Wrapper that constrains content width on tablets and centers it
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (!r.isTabletOrLarger) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? r.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Quick context extension for card background (avoids importing theme_provider)
// ──────────────────────────────────────────────────────────────────────────────

extension _AdaptiveTheme on BuildContext {
  Color get cardBg {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }
}
