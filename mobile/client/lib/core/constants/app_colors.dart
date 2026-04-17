import 'package:flutter/material.dart';

/// Couleurs de l'application DR Pharma
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // ── Accent / Secondary ──
  static const Color accent = Color(0xFF00897B);
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF00796B);

  // ── Text ──
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // ── Background ──
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color scaffoldDark = Color(0xFF121212);

  // ── Status ──
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ── Order Status Colors ──
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusConfirmed = Color(0xFF42A5F5);
  static const Color statusReady = Color(0xFF66BB6A);
  static const Color statusDelivering = Color(0xFF26C6DA);
  static const Color statusDelivered = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFEF5350);

  // ── Misc ──
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color rating = Color(0xFFFFC107);
  static const Color shadow = Color(0x1A000000);

  // ── Opérateurs de paiement ──
  static const Color operatorWave = Color(0xFF1DC3F0);
  static const Color operatorOrange = Color(0xFFFF6600);
  static const Color operatorMtn = Color(0xFFFFCC00);
  static const Color operatorMoov = Color(0xFF0066B3);
  static const Color operatorDjamo = Color(0xFF6C63FF);
  static const Color walletGreen = Color(0xFF00B67A);
  static const Color whatsApp = Color(0xFF25D366);

  // ── Statuts pharmacie ──
  static const Color onDuty = Color(0xFFFF5722);
  static const Color pharmacyOpen = Color(0xFF4CAF50);
  static const Color pharmacyOpenDark = Color(0xFF2E7D32);
  static const Color pharmacyClosed = Color(0xFFEF5350);
  static const Color pharmacyClosedDark = Color(0xFFC62828);

  // ── Palette dark mode ──
  static const Color darkElevated = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF3C3C3C);
  static const Color darkBackgroundDeep = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color errorRed = Color(0xFFE53935); // alias AppColors.error
}
