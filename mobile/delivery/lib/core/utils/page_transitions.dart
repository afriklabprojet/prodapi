import 'package:flutter/material.dart';

/// Helper class for animated page transitions
class PageTransitions {
  /// Slide transition from right to left
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide transition from bottom to top
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Fade and scale transition
  static Route<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );
        
        var scaleAnimation = animation.drive(
          Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Shared axis transition (Material Design)
  static Route<T> sharedAxis<T>(Widget page, {bool horizontal = true}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        
        // Forward animation
        final slideBegin = horizontal ? const Offset(0.3, 0.0) : const Offset(0.0, 0.3);
        var slideAnimation = animation.drive(
          Tween(begin: slideBegin, end: Offset.zero).chain(CurveTween(curve: curve)),
        );
        
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );

        // Reverse animation for current page
        final slideOutEnd = horizontal ? const Offset(-0.3, 0.0) : const Offset(0.0, -0.3);
        var slideOutAnimation = secondaryAnimation.drive(
          Tween(begin: Offset.zero, end: slideOutEnd).chain(CurveTween(curve: curve)),
        );
        
        var fadeOutAnimation = secondaryAnimation.drive(
          Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: curve)),
        );

        return SlideTransition(
          position: slideOutAnimation,
          child: FadeTransition(
            opacity: fadeOutAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Hero-compatible fade transition (use with Hero widgets)
  static Route<T> heroFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Animated navigation extension
extension AnimatedNavigation on BuildContext {
  /// Navigate with slide from right animation
  Future<T?> pushSlide<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.slideFromRight(page));
  }

  /// Navigate with fade and scale animation
  Future<T?> pushFadeScale<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.fadeScale(page));
  }

  /// Navigate with shared axis animation
  Future<T?> pushSharedAxis<T>(Widget page, {bool horizontal = true}) {
    return Navigator.push<T>(this, PageTransitions.sharedAxis(page, horizontal: horizontal));
  }

  /// Navigate with hero-compatible fade
  Future<T?> pushHeroFade<T>(Widget page) {
    return Navigator.push<T>(this, PageTransitions.heroFade(page));
  }

  /// Replace with slide animation
  Future<T?> pushReplacementSlide<T extends Object?, TO extends Object?>(Widget page) {
    return Navigator.pushReplacement<T, TO>(this, PageTransitions.slideFromRight(page));
  }
}

/// Hero tag generator for deliveries
class DeliveryHeroTags {
  static String card(int deliveryId) => 'delivery_card_$deliveryId';
  static String icon(int deliveryId) => 'delivery_icon_$deliveryId';
  static String id(int deliveryId) => 'delivery_id_$deliveryId';
  static String pharmacy(int deliveryId) => 'delivery_pharmacy_$deliveryId';
  static String status(int deliveryId) => 'delivery_status_$deliveryId';
}
