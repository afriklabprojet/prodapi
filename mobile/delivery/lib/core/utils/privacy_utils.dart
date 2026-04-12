/// Utilitaires de protection des données personnelles
/// SÉCURITÉ: Masquer les données sensibles (téléphone, email) dans l'UI
/// pour empêcher la collecte de données par capture d'écran ou visuel
library;

/// Masque un numéro de téléphone pour l'affichage
/// Ex: "+2250707070707" → "+225****0707"
/// Le numéro brut est conservé uniquement pour les intents (tel:, whatsapp:)
String maskPhoneNumber(String? phone) {
  if (phone == null || phone.isEmpty) return '****';

  final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');

  if (cleaned.length <= 4) return '****';

  // Garder les 3-4 premiers caractères (indicatif) et les 2 derniers
  final prefixLength = cleaned.startsWith('+') ? 4 : 3;
  final prefix = cleaned.substring(0, prefixLength.clamp(0, cleaned.length));
  final suffix = cleaned.substring(
    (cleaned.length - 2).clamp(0, cleaned.length),
  );

  return '$prefix****$suffix';
}

/// Masque le nom complet (prénom + initial du nom)
/// Ex: "Jean Dupont" → "Jean D."
String maskFullName(String? name) {
  if (name == null || name.isEmpty) return '***';

  final parts = name.trim().split(' ');
  if (parts.length <= 1) return name;

  return '${parts.first} ${parts.last[0]}.';
}
