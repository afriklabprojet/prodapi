/// Formats currency amounts for compact display (e.g. 1.2M, 15K, 500).
/// Centralised to ensure consistent formatting across all dashboard surfaces.
abstract final class CurrencyFormatter {
  /// Compact format: 1.2M / 15K / 500
  static String compact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
