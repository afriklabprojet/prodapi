import 'package:flutter/services.dart';

/// Centralized haptic feedback utility for consistent tactile responses.
///
/// Provides semantic methods for different user interactions:
/// - [light] - Subtle feedback (tab switches, scroll snaps)
/// - [medium] - Standard feedback (button presses, selection)
/// - [heavy] - Strong feedback (destructive actions, errors)
/// - [selection] - Selection changes (toggles, radio buttons)
/// - [success] - Positive outcomes (form submission, payment success)
/// - [error] - Negative outcomes (validation errors, failures)
/// - [warning] - Caution signals (delete confirmation)
///
/// Usage:
/// ```dart
/// Haptics.success(); // After order confirmed
/// Haptics.error();   // After validation failed
/// Haptics.selection(); // On tab change
/// ```
class Haptics {
  Haptics._();

  /// Light impact - tab switches, scroll snaps, subtle interactions
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact - standard button presses, confirmations
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy impact - destructive actions, critical errors
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection click - toggles, radio buttons, checkboxes, list items
  static void selection() => HapticFeedback.selectionClick();

  /// Success feedback - positive outcomes (submissions, payments, confirmations)
  static void success() => HapticFeedback.mediumImpact();

  /// Error feedback - validation failures, network errors, rejections
  static void error() => HapticFeedback.heavyImpact();

  /// Warning feedback - caution signals, delete confirmations
  static void warning() => HapticFeedback.mediumImpact();

  /// Vibrate pattern - custom vibration (Android only, requires permission)
  static void vibrate() => HapticFeedback.vibrate();
}
