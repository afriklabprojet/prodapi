import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A reusable full-screen loading overlay widget (standalone version).
///
/// Use this when you need to show a loading state that blocks user interaction
/// while an async operation is in progress.
///
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     YourContent(),
///     if (isLoading)
///       LoadingOverlay(message: 'Chargement en cours...'),
///   ],
/// )
/// ```
///
/// Or use the static methods for programmatic control:
/// ```dart
/// FullScreenLoadingOverlay.show(context, message: 'Saving...');
/// await saveData();
/// FullScreenLoadingOverlay.hide(context);
/// ```
class FullScreenLoadingOverlay extends StatelessWidget {
  /// Optional message to display below the spinner.
  final String? message;

  /// Primary color for the progress indicator.
  final Color? primaryColor;

  /// Whether to show a white background card around the indicator.
  final bool showCard;

  /// Background overlay opacity (0.0 to 1.0).
  final double overlayOpacity;

  /// Size of the progress indicator.
  final double indicatorSize;

  /// Stroke width of the progress indicator.
  final double strokeWidth;

  const FullScreenLoadingOverlay({
    super.key,
    this.message,
    this.primaryColor,
    this.showCard = true,
    this.overlayOpacity = 0.4,
    this.indicatorSize = 50,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? AppColors.primary;

    final indicator = SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          const SizedBox(height: 20),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    return Container(
      color: Colors.black.withValues(alpha: overlayOpacity),
      child: Center(
        child: showCard
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: content,
              )
            : content,
      ),
    );
  }

  /// Shows a loading overlay using a dialog.
  ///
  /// Returns a function to close the dialog.
  /// Alternatively, call [hide] with the same context.
  static void show(
    BuildContext context, {
    String? message,
    Color? primaryColor,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: FullScreenLoadingOverlay(
          message: message,
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  /// Hides the loading overlay shown with [show].
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// A simple inline loading indicator (without overlay).
  ///
  /// Use this in places where you just need a centered spinner.
  static Widget inline({
    Color? color,
    double size = 24,
    double strokeWidth = 2,
  }) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: color != null
              ? AlwaysStoppedAnimation<Color>(color)
              : null,
        ),
      ),
    );
  }

  /// A button-friendly loading indicator (for use inside buttons).
  ///
  /// Matches typical button content size.
  static Widget button({Color color = Colors.white, double size = 18}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
