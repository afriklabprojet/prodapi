/// Pure phone number normalizer — zero dependencies, fully testable.
abstract final class PhoneNormalizer {
  /// Default country code (Côte d'Ivoire).
  static const defaultCountryCode = '+225';

  /// Strips all non-digit / non-plus characters and prepends country code
  /// when missing. Returns empty string for invalid input.
  static String normalize(
    String phoneNumber, {
    String countryCode = defaultCountryCode,
  }) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('+')) return cleaned;

    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('0')) {
      return '$countryCode${cleaned.substring(1)}';
    }
    return '$countryCode$cleaned';
  }

  /// Returns the digits-only version (no +) for URL schemes.
  static String digitsOnly(String normalized) =>
      normalized.replaceAll(RegExp(r'[^\d]'), '');
}
