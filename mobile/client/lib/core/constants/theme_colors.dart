import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Semantic theme-aware color tokens.
///
/// Use `context.cardBackground`, `context.textPrimary`, etc.
/// instead of hardcoded `Colors.white`, `Colors.grey[600]`.
///
/// These automatically adapt to light/dark theme.
extension ThemeColors on BuildContext {
  ThemeData get _theme => Theme.of(this);
  bool get isDark => _theme.brightness == Brightness.dark;

  // ── Backgrounds ──
  Color get cardBackground =>
      isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get elevatedSurface =>
      isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;

  Color get scaffoldBg => _theme.scaffoldBackgroundColor;

  Color get inputFill =>
      isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;

  Color get disabledBg =>
      isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade200;

  // ── Text ──
  Color get textPrimary =>
      isDark ? Colors.white : AppColors.textPrimary;

  Color get textSecondary =>
      isDark ? Colors.grey.shade400 : AppColors.textSecondary;

  Color get textHint =>
      isDark ? Colors.grey.shade500 : AppColors.textHint;

  // ── Borders & Dividers ──
  Color get subtleBorder =>
      isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade300;

  Color get dividerColor =>
      isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade200;

  // ── Icons ──
  Color get iconDefault =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  Color get iconSubtle =>
      isDark ? Colors.grey.shade500 : Colors.grey.shade400;

  // ── Shadows ──
  Color get subtleShadow =>
      Colors.black.withValues(alpha: isDark ? 0.3 : 0.05);

  Color get cardShadow =>
      Colors.black.withValues(alpha: isDark ? 0.4 : 0.08);

  // ── Specialized ──
  Color get searchBarFill =>
      isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;

  Color get chipUnselectedBg =>
      isDark ? const Color(0xFF2C2C2C) : Colors.white;

  Color get chipSelectedText => Colors.white;

  // ── AppBar on gradient (always white) ──
  Color get onGradient => Colors.white;
}
