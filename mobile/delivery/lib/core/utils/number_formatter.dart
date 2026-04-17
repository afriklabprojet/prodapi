import 'package:intl/intl.dart';

/// Extensions pour le formatage des nombres et montants.
///
/// Usage:
/// ```dart
/// // Formatage monétaire
/// 15000.formatCurrency()           // → '15 000 FCFA'
/// 15000.formatCurrency(symbol: 'F') // → '15 000 F'
/// 15000.formatCurrencyCompact()    // → '15 000'
///
/// // Formatage numérique
/// 15000.formatNumber()             // → '15 000'
/// 0.754.formatPercent()            // → '75.4%'
/// ```
extension NumberFormatting on num {
  static const String _defaultLocale = 'fr_FR';
  static const String _defaultCurrency = 'FCFA';

  /// Formate le nombre en devise avec symbole.
  ///
  /// [symbol] : Symbole de la devise (défaut: 'FCFA')
  /// [locale] : Locale pour le formatage (défaut: 'fr_FR')
  String formatCurrency({
    String symbol = _defaultCurrency,
    String locale = _defaultLocale,
  }) {
    final formatted = NumberFormat('#,##0', locale).format(this);
    return '$formatted $symbol';
  }

  /// Formate le nombre en devise sans symbole (juste les chiffres formatés).
  ///
  /// [locale] : Locale pour le formatage (défaut: 'fr_FR')
  String formatCurrencyCompact({String locale = _defaultLocale}) {
    return NumberFormat('#,##0', locale).format(this);
  }

  /// Formate le nombre avec séparateurs de milliers.
  ///
  /// [locale] : Locale pour le formatage (défaut: 'fr_FR')
  String formatNumber({String locale = _defaultLocale}) {
    return NumberFormat('#,##0', locale).format(this);
  }

  /// Formate le nombre avec décimales.
  ///
  /// [decimals] : Nombre de décimales (défaut: 2)
  /// [locale] : Locale pour le formatage (défaut: 'fr_FR')
  String formatDecimal({int decimals = 2, String locale = _defaultLocale}) {
    final pattern = '#,##0.${'0' * decimals}';
    return NumberFormat(pattern, locale).format(this);
  }

  /// Formate le nombre en pourcentage.
  ///
  /// Multiplie par 100 si la valeur est entre 0 et 1.
  /// [decimals] : Nombre de décimales (défaut: 1)
  String formatPercent({int decimals = 1}) {
    final value = this <= 1 && this >= 0 ? this * 100 : this;
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Formate le nombre de manière compacte (K, M, etc.)
  ///
  /// [locale] : Locale pour le formatage (défaut: 'fr_FR')
  String formatCompact({String locale = _defaultLocale}) {
    return NumberFormat.compact(locale: locale).format(this);
  }
}

/// Extensions pour les types int et double spécifiquement pour les montants.
extension MoneyFormatting on int {
  /// Formate un montant avec signe (+/-) pour les transactions.
  ///
  /// [isCredit] : true = positif (+), false = négatif (-)
  /// [symbol] : Symbole de la devise (défaut: 'FCFA')
  String formatTransaction({
    required bool isCredit,
    String symbol = 'FCFA',
    String locale = 'fr_FR',
  }) {
    final sign = isCredit ? '+' : '-';
    final formatted = NumberFormat('#,##0', locale).format(this);
    return '$sign$formatted $symbol';
  }
}
