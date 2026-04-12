/// Extensions utilitaires pour l'application DR Pharma

/// Extension pour formater les numéros de téléphone au format international E.164
extension PhoneFormatExtension on String {
  /// Convertit un numéro au format international E.164
  /// En Côte d'Ivoire, les numéros ont 10 chiffres (incluant le 0 initial)
  /// Ex: "0574535472" → "+2250574535472"
  /// Ex: "+2250574535472" → "+2250574535472" (déjà correct)
  /// Ex: "225 05 74 53 54 72" → "+2250574535472"
  String get toInternationalPhone {
    // Nettoyer le numéro: garder uniquement les chiffres et le +
    String cleaned = replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    
    // Déjà au format international
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1);
      if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
        throw FormatException('Numéro de téléphone invalide: $this');
      }
      return cleaned;
    }
    
    // Retirer le 00 initial (format international alternatif)
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
      return '+$cleaned';
    }
    
    // Format local CI: 10 chiffres commençant par 0 (le 0 fait partie du numéro)
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+225$cleaned';
    }
    
    // Déjà avec indicatif pays sans +
    if (cleaned.startsWith('225') && cleaned.length >= 12) {
      return '+$cleaned';
    }
    
    // Numéro CI sans indicatif pays (10 chiffres)
    if (RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return '+225$cleaned';
    }
    
    // Fallback: ajouter le + si pas présent
    if (RegExp(r'^\d+$').hasMatch(cleaned) && cleaned.length >= 10) {
      return '+$cleaned';
    }
    
    throw FormatException('Format de numéro non reconnu: $this');
  }
}

/// Extension pour le formatage des prix
extension PriceFormatExtension on num {
  /// Formate un prix en FCFA
  /// Ex: 2500 → "2 500 FCFA"
  String get formatPrice {
    final formatted = toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    return '$formatted FCFA';
  }

  /// Formate en nombre avec séparateur de milliers
  String get formatNumber {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }
}

/// Extension pour les dates
extension DateExtension on DateTime {
  /// Formate en date lisible français
  /// Ex: "14 mars 2025"
  String get formatDateFr {
    const months = [
      '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '$day ${months[month]} $year';
  }

  /// Formate en date + heure
  String get formatDateTimeFr {
    return '${formatDateFr} à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Temps relatif (il y a X minutes/heures/jours)
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return formatDateFr;
  }
}

/// Extension pour les Strings
extension StringExtension on String {
  /// Capitalise la première lettre
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Tronque avec ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
