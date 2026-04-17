import 'dart:math' as math;
import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// DR-PHARMA — Responsive Utility System
// ──────────────────────────────────────────────────────────────────────────────
// Usage:
//   final r = Responsive.of(context);
//   Container(width: r.w(90), height: r.h(30))       // % of screen
//   Text('Hello', style: TextStyle(fontSize: r.sp(16))) // scaled font
//   Padding(padding: r.pad(16))                         // scaled padding
//   if (r.isTablet) ...                                 // device detection
//
// Or use the BuildContext extension:
//   context.r.w(90)
//   context.r.sp(16)
// ──────────────────────────────────────────────────────────────────────────────

/// Device type breakpoints (logical pixels width)
enum DeviceType {
  /// < 360 lp (very small phones like iPhone SE 1st gen)
  smallPhone,

  /// 360–599 lp (standard phones)
  phone,

  /// 600–839 lp (large phones, foldables inner screen)
  largePhone,

  /// 840–1199 lp (tablets portrait, foldables unfolded)
  tablet,

  /// ≥ 1200 lp (tablets landscape, desktops)
  desktop,
}

/// Core responsive helper – lightweight, zero-dependency.
/// Design reference: 375 × 812 (iPhone 13 mini) as base.
class Responsive {
  Responsive._(this._mq);

  final MediaQueryData _mq;

  /// Factory from BuildContext
  factory Responsive.of(BuildContext context) {
    return Responsive._(MediaQuery.of(context));
  }

  // ── Screen dimensions ────────────────────────────────────────────────────

  /// Full screen width in logical pixels
  double get screenWidth => _mq.size.width;

  /// Full screen height in logical pixels
  double get screenHeight => _mq.size.height;

  /// Screen aspect ratio
  double get aspectRatio => screenWidth / screenHeight;

  // ── Design base (iPhone 13 mini: 375×812) ────────────────────────────────

  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  /// Horizontal scale factor relative to base design
  double get scaleX => screenWidth / _baseWidth;

  /// Vertical scale factor relative to base design
  double get scaleY => screenHeight / _baseHeight;

  /// Balanced scale factor (geometric mean, capped to avoid extremes)
  double get scale {
    final raw = math.sqrt(scaleX * scaleY);
    // Cap between 0.8 and 1.6 to prevent absurd sizes on very small/large screens
    return raw.clamp(0.8, 1.6);
  }

  // ── Percentage-based sizing ──────────────────────────────────────────────

  /// [percent]% of screen width (e.g., w(90) = 90% of screen width)
  double w(double percent) => screenWidth * percent / 100;

  /// [percent]% of screen height
  double h(double percent) => screenHeight * percent / 100;

  // ── Scaled pixel values ──────────────────────────────────────────────────

  /// Scale a pixel value horizontally (width-proportionate)
  double wp(double px) => px * scaleX;

  /// Scale a pixel value vertically (height-proportionate)
  double hp(double px) => px * scaleY;

  /// Scale a pixel value using the balanced scale factor.
  /// Use for sizes that should scale in both directions (icons, circles).
  double dp(double px) => px * scale;

  /// Scale font size. Uses width-based scaling (clamped) so text stays readable.
  /// textScaleFactor from system settings is NOT applied here — Flutter handles
  /// that separately via MediaQuery.textScaler.
  double sp(double fontSize) {
    final scaled = fontSize * scaleX;
    // Clamp: never shrink below 80% or grow above 140% of design size
    final min = fontSize * 0.8;
    final max = fontSize * 1.4;
    return scaled.clamp(min, max);
  }

  // ── Responsive padding ──────────────────────────────────────────────────

  /// Scaled symmetric padding
  EdgeInsets pad(double value) {
    final v = dp(value);
    return EdgeInsets.all(v);
  }

  /// Scaled horizontal-only padding
  EdgeInsets padH(double value) {
    final v = dp(value);
    return EdgeInsets.symmetric(horizontal: v);
  }

  /// Scaled vertical-only padding
  EdgeInsets padV(double value) {
    final v = dp(value);
    return EdgeInsets.symmetric(vertical: v);
  }

  /// Scaled asymmetric padding
  EdgeInsets padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: dp(left),
      top: dp(top),
      right: dp(right),
      bottom: dp(bottom),
    );
  }

  // ── Device type detection ────────────────────────────────────────────────

  DeviceType get deviceType {
    if (screenWidth < 360) return DeviceType.smallPhone;
    if (screenWidth < 600) return DeviceType.phone;
    if (screenWidth < 840) return DeviceType.largePhone;
    if (screenWidth < 1200) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  bool get isSmallPhone => deviceType == DeviceType.smallPhone;
  bool get isPhone => deviceType == DeviceType.phone || isSmallPhone;
  bool get isLargePhone => deviceType == DeviceType.largePhone;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isTabletOrLarger => isTablet || isDesktop;
  bool get isLandscape => screenWidth > screenHeight;
  bool get isPortrait => !isLandscape;

  /// Safe area insets
  EdgeInsets get safeArea => _mq.padding;

  /// Bottom inset (keyboard height if visible)
  double get keyboardHeight => _mq.viewInsets.bottom;

  /// Whether the keyboard is currently visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  // ── Adaptive value helpers ──────────────────────────────────────────────

  /// Return different values based on device type.
  /// Only [phone] is required; others default to [phone] if not provided.
  T adaptive<T>({
    required T phone,
    T? smallPhone,
    T? largePhone,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return smallPhone ?? phone;
      case DeviceType.phone:
        return phone;
      case DeviceType.largePhone:
        return largePhone ?? phone;
      case DeviceType.tablet:
        return tablet ?? largePhone ?? phone;
      case DeviceType.desktop:
        return desktop ?? tablet ?? largePhone ?? phone;
    }
  }

  /// Number of grid columns based on screen width
  int get gridColumns => adaptive(
    phone: 2,
    largePhone: 3,
    tablet: 4,
    desktop: 6,
  );

  /// Max content width for centered layouts (e.g., forms on tablets)
  double get maxContentWidth => adaptive<double>(
    phone: screenWidth,
    tablet: 600,
    desktop: 800,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// BuildContext extension for quick access
// ──────────────────────────────────────────────────────────────────────────────

extension ResponsiveExtension on BuildContext {
  /// Quick access to [Responsive] from any BuildContext
  Responsive get r => Responsive.of(this);
}

// ──────────────────────────────────────────────────────────────────────────────
// Adaptive Layout Builder Widget
// ──────────────────────────────────────────────────────────────────────────────

/// A layout builder that provides [Responsive] helpers to its child builder.
/// Automatically adapts when the screen size changes (rotation, foldable, etc.)
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.builder,
  });

  /// Builder receives the [Responsive] helper for the current constraints.
  final Widget Function(BuildContext context, Responsive r) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.of(context);
        return builder(context, r);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Responsive Scaffold — centers content on tablets, adds SafeArea everywhere
// ──────────────────────────────────────────────────────────────────────────────

/// A scaffold wrapper that automatically:
/// - Adds SafeArea
/// - Centers content within maxContentWidth on tablets
/// - Provides responsive helpers via builder
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.useSafeArea = true,
    this.centerOnTablet = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool useSafeArea;
  final bool centerOnTablet;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    Widget content = body;

    // Center on tablets/desktop
    if (centerOnTablet && r.isTabletOrLarger) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.maxContentWidth),
          child: content,
        ),
      );
    }

    // Wrap in SafeArea
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Responsive Grid — auto-adapts column count
// ──────────────────────────────────────────────────────────────────────────────

/// A GridView that automatically adjusts its crossAxisCount based on screen width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.minColumns,
    this.maxColumns,
  });

  final List<Widget> children;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int? minColumns;
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    int columns = r.gridColumns;

    if (minColumns != null) columns = math.max(columns, minColumns!);
    if (maxColumns != null) columns = math.min(columns, maxColumns!);

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: r.dp(mainAxisSpacing),
      crossAxisSpacing: r.dp(crossAxisSpacing),
      padding: padding ?? r.pad(16),
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Responsive Text — auto-scales font size
// ──────────────────────────────────────────────────────────────────────────────

/// A Text widget that automatically scales its fontSize based on screen size.
class RText extends StatelessWidget {
  const RText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final scaledSize = r.sp(baseStyle.fontSize ?? 14);

    return Text(
      data,
      style: baseStyle.copyWith(fontSize: scaledSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
