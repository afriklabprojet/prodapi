/// Scalable message template system for WhatsApp / SMS pre-filled messages.
///
/// Each template is a pure function — no side effects, fully testable.
/// Add new templates here as the business grows (delivery updates,
/// prescription reminders, etc.).
abstract final class MessageTemplates {
  // ───────────────────────── Support ─────────────────────────

  static String support({String? customMessage}) =>
      customMessage ??
      'Bonjour, j\'ai besoin d\'aide avec mon compte DR-PHARMA.';

  // ───────────────────────── Courier ─────────────────────────

  static String courier({String? courierName, String? orderReference}) {
    final buffer = StringBuffer('Bonjour');
    if (courierName != null && courierName.isNotEmpty) {
      buffer.write(' $courierName');
    }
    buffer.write(', je vous contacte concernant ma livraison');
    if (orderReference != null && orderReference.isNotEmpty) {
      buffer.write(' (commande $orderReference)');
    }
    buffer.write('.');
    return buffer.toString();
  }

  // ───────────────────────── Pharmacy ────────────────────────

  static String pharmacy({String? pharmacyName, String? orderReference}) {
    final buffer = StringBuffer('Bonjour');
    if (pharmacyName != null && pharmacyName.isNotEmpty) {
      buffer.write(' $pharmacyName');
    }
    buffer.write(', je vous contacte concernant ma commande');
    if (orderReference != null && orderReference.isNotEmpty) {
      buffer.write(' $orderReference');
    }
    buffer.write('.');
    return buffer.toString();
  }
}
