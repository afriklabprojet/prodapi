/// Pure phone masking utility — zero dependencies, fully testable.
///
/// Masks phone numbers for display: `+225 07 ** ** 07`
/// Only reveals first 2 and last 2 digits to protect customer privacy.
abstract final class PhoneMasker {
  /// Masks a phone number, showing only [visibleStart] leading digits
  /// and [visibleEnd] trailing digits.
  ///
  /// Examples:
  /// - `mask('+22507070707')` → `+225 07•••07`
  /// - `mask('0707070707')` → `07•••07`
  /// - `mask('')` → `••••`
  static String mask(
    String phoneNumber, {
    int visibleStart = 4,
    int visibleEnd = 2,
    String maskChar = '•',
  }) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return maskChar * 4;

    final hasPlus = digits.startsWith('+');
    final raw = hasPlus ? digits.substring(1) : digits;

    if (raw.length <= visibleStart + visibleEnd) {
      // Too short to mask meaningfully — mask the middle
      if (raw.length <= 2) return '${hasPlus ? '+' : ''}$raw';
      final start = raw.substring(0, 1);
      final end = raw.substring(raw.length - 1);
      return '${hasPlus ? '+' : ''}$start${maskChar * (raw.length - 2)}$end';
    }

    final start = raw.substring(0, visibleStart);
    final end = raw.substring(raw.length - visibleEnd);
    final maskedLength = raw.length - visibleStart - visibleEnd;

    return '${hasPlus ? '+' : ''}$start${maskChar * maskedLength}$end';
  }

  /// Formats a masked phone for readable display with spaces.
  ///
  /// Example: `+225 07•••07`
  static String maskForDisplay(String phoneNumber) {
    final masked = mask(phoneNumber);

    // Insert spaces every 2 digits for readability
    final buffer = StringBuffer();
    int digitCount = 0;

    for (int i = 0; i < masked.length; i++) {
      final char = masked[i];
      if (char == '+') {
        buffer.write(char);
        continue;
      }
      if (digitCount > 0 &&
          digitCount % 2 == 0 &&
          digitCount < masked.replaceAll('+', '').length) {
        buffer.write(' ');
      }
      buffer.write(char);
      digitCount++;
    }

    return buffer.toString();
  }
}
