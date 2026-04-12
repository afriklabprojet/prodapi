/// Utilitaires de validation pour les formulaires.
///
/// Fournit des validateurs réutilisables et typés pour tous les champs
/// de l'application (email, téléphone, mot de passe, plaque, permis, etc.).
library;

/// Résultat d'une validation.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  /// Convertit en String? pour usage direct dans les validators Flutter.
  String? get error => errorMessage;
}

/// Classe utilitaire de validation.
class Validators {
  Validators._();

  // ══════════════════════════════════════════════════════════════════════════
  // IDENTITÉ
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide un nom complet (prénom + nom).
  /// - Minimum 3 caractères
  /// - Pas de chiffres
  /// - Pas de caractères spéciaux (sauf tirets et apostrophes)
  static ValidationResult validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('Le nom est requis');
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return const ValidationResult.invalid(
        'Le nom doit contenir au moins 3 caractères',
      );
    }

    if (trimmed.length > 100) {
      return const ValidationResult.invalid(
        'Le nom ne peut pas dépasser 100 caractères',
      );
    }

    // Pas de chiffres dans un nom
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return const ValidationResult.invalid(
        'Le nom ne doit pas contenir de chiffres',
      );
    }

    // Autorise lettres (y compris accentuées), espaces, tirets, apostrophes
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(trimmed)) {
      return const ValidationResult.invalid(
        'Le nom contient des caractères invalides',
      );
    }

    return const ValidationResult.valid();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMAIL
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide une adresse email.
  /// - Format standard RFC 5322 simplifié
  /// - Domaine avec au moins 2 caractères TLD
  static ValidationResult validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('L\'email est requis');
    }

    final trimmed = value.trim().toLowerCase();

    // RFC 5322 simplifié
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return const ValidationResult.invalid('Format d\'email invalide');
    }

    // Vérifie le TLD (au moins 2 caractères)
    final parts = trimmed.split('@');
    if (parts.length == 2) {
      final domain = parts[1];
      final tld = domain.split('.').last;
      if (tld.length < 2) {
        return const ValidationResult.invalid('Domaine email invalide');
      }
    }

    return const ValidationResult.valid();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TÉLÉPHONE
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide un numéro de téléphone (format Côte d'Ivoire).
  /// - 10 chiffres (numéros mobiles ivoiriens)
  /// - Accepte +225, 00225, ou sans indicatif
  /// - Opérateurs CI: 07/08 (Orange), 05 (MTN), 01 (Moov)
  static ValidationResult validatePhone(
    String? value, {
    bool ivoryCoastOnly = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid(
        'Le numéro de téléphone est requis',
      );
    }

    // Nettoie le numéro (garde uniquement les chiffres et le +)
    String cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Supprime l'indicatif Côte d'Ivoire si présent
    if (cleaned.startsWith('+225')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00225')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('225') && cleaned.length > 10) {
      cleaned = cleaned.substring(3);
    }

    // Ne garder que les chiffres
    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    // Longueur exacte pour CI (10 chiffres depuis 2021)
    if (cleaned.length < 10) {
      return const ValidationResult.invalid(
        'Le numéro doit contenir 10 chiffres',
      );
    }

    if (cleaned.length > 15) {
      return const ValidationResult.invalid('Numéro de téléphone trop long');
    }

    // Validation spécifique Côte d'Ivoire
    if (ivoryCoastOnly && cleaned.length == 10) {
      // Préfixes mobiles CI:
      // Orange: 07, 08
      // MTN: 05
      // Moov: 01
      final prefix = cleaned.substring(0, 2);
      final validMobilePrefixes = ['01', '05', '07', '08'];

      // Préfixes fixes CI: 20, 21, 22, 23, 24, 25, 27, 30, 31, 32, 33, 34, 36
      final validFixedPrefixes = [
        '20',
        '21',
        '22',
        '23',
        '24',
        '25',
        '27',
        '30',
        '31',
        '32',
        '33',
        '34',
        '36',
      ];

      if (!validMobilePrefixes.contains(prefix) &&
          !validFixedPrefixes.contains(prefix)) {
        return const ValidationResult.invalid(
          'Préfixe invalide. Utilisez 01, 05, 07 ou 08 pour mobile',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// Normalise un numéro de téléphone au format E.164 (+225XXXXXXXXXX)
  static String normalizePhone(String value) {
    String cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Supprime les indicatifs existants
    if (cleaned.startsWith('+225')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00225')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('225') && cleaned.length > 10) {
      cleaned = cleaned.substring(3);
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    return '+225$cleaned';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOT DE PASSE
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide la force d'un mot de passe.
  /// - Minimum 8 caractères
  /// - Au moins 1 majuscule, 1 minuscule, 1 chiffre
  /// - Au moins 1 caractère spécial (recommandé)
  static ValidationResult validatePassword(
    String? value, {
    bool strict = false,
  }) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Le mot de passe est requis');
    }

    if (value.length < 8) {
      return const ValidationResult.invalid(
        'Le mot de passe doit contenir au moins 8 caractères',
      );
    }

    if (value.length > 128) {
      return const ValidationResult.invalid(
        'Le mot de passe ne peut pas dépasser 128 caractères',
      );
    }

    // Mode strict : exige majuscule, minuscule, chiffre, spécial
    if (strict) {
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return const ValidationResult.invalid(
          'Le mot de passe doit contenir au moins une minuscule',
        );
      }
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return const ValidationResult.invalid(
          'Le mot de passe doit contenir au moins une majuscule',
        );
      }
      if (!RegExp(r'\d').hasMatch(value)) {
        return const ValidationResult.invalid(
          'Le mot de passe doit contenir au moins un chiffre',
        );
      }
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return const ValidationResult.invalid(
          'Le mot de passe doit contenir au moins un caractère spécial',
        );
      }
    }

    // Vérifie les patterns faibles courants
    final weakPatterns = ['12345678', 'password', 'qwertyui', 'abcdefgh'];
    if (weakPatterns.any((p) => value.toLowerCase().contains(p))) {
      return const ValidationResult.invalid('Le mot de passe est trop simple');
    }

    return const ValidationResult.valid();
  }

  /// Calcule un score de force du mot de passe (0-100).
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Longueur
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Diversité de caractères
    if (RegExp(r'[a-z]').hasMatch(password)) score += 15;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 15;
    if (RegExp(r'\d').hasMatch(password)) score += 15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 15;

    // Pénalités
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 10; // Répétitions
    if (RegExp(r'^[a-zA-Z]+$').hasMatch(password)) {
      score -= 10; // Lettres seules
    }

    return score.clamp(0, 100);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VÉHICULE
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide un numéro de permis de conduire ivoirien.
  /// Format: lettres + chiffres (variable)
  static ValidationResult validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('Le numéro de permis est requis');
    }

    // Nettoie les espaces et tirets
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

    if (cleaned.length < 8) {
      return const ValidationResult.invalid(
        'Le numéro de permis est trop court',
      );
    }

    if (cleaned.length > 20) {
      return const ValidationResult.invalid(
        'Le numéro de permis est trop long',
      );
    }

    // Doit contenir des lettres et des chiffres
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned)) {
      return const ValidationResult.invalid(
        'Le numéro de permis ne doit contenir que des lettres et chiffres',
      );
    }

    // Doit avoir au moins 2 lettres et au moins 4 chiffres
    final letters = RegExp(r'[A-Z]').allMatches(cleaned).length;
    final digits = RegExp(r'\d').allMatches(cleaned).length;

    if (letters < 2) {
      return const ValidationResult.invalid(
        'Le numéro de permis doit contenir au moins 2 lettres',
      );
    }

    if (digits < 4) {
      return const ValidationResult.invalid(
        'Le numéro de permis doit contenir au moins 4 chiffres',
      );
    }

    return const ValidationResult.valid();
  }

  /// Valide une plaque d'immatriculation ivoirienne.
  /// Format nouveau (depuis 2019): XXXX AA YY (ex: 1234 AB 01)
  /// Formats anciens: diverses séries régionales
  static ValidationResult validateVehicleRegistration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('L\'immatriculation est requise');
    }

    // Nettoie et met en majuscules
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

    if (cleaned.length < 6) {
      return const ValidationResult.invalid(
        'L\'immatriculation est trop courte',
      );
    }

    if (cleaned.length > 12) {
      return const ValidationResult.invalid(
        'L\'immatriculation est trop longue',
      );
    }

    // Format général: chiffres et lettres
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned)) {
      return const ValidationResult.invalid(
        'L\'immatriculation ne doit contenir que des lettres et chiffres',
      );
    }

    // Vérification basique du format
    final hasDigits = RegExp(r'\d').hasMatch(cleaned);
    final hasLetters = RegExp(r'[A-Z]').hasMatch(cleaned);

    if (!hasDigits || !hasLetters) {
      return const ValidationResult.invalid(
        'L\'immatriculation doit contenir des chiffres et des lettres',
      );
    }

    return const ValidationResult.valid();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GÉNÉRIQUES
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide qu'un champ n'est pas vide.
  static ValidationResult required(
    String? value, {
    String fieldName = 'Ce champ',
  }) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName est requis');
    }
    return const ValidationResult.valid();
  }

  /// Valide une longueur minimale.
  static ValidationResult minLength(
    String? value,
    int min, {
    String fieldName = 'Ce champ',
  }) {
    if (value == null || value.length < min) {
      return ValidationResult.invalid(
        '$fieldName doit contenir au moins $min caractères',
      );
    }
    return const ValidationResult.valid();
  }

  /// Valide une longueur maximale.
  static ValidationResult maxLength(
    String? value,
    int max, {
    String fieldName = 'Ce champ',
  }) {
    if (value != null && value.length > max) {
      return ValidationResult.invalid(
        '$fieldName ne peut pas dépasser $max caractères',
      );
    }
    return const ValidationResult.valid();
  }

  /// Valide un montant numérique.
  static ValidationResult validateAmount(
    String? value, {
    double min = 0,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('Le montant est requis');
    }

    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));

    if (amount == null) {
      return const ValidationResult.invalid('Montant invalide');
    }

    if (amount < min) {
      return ValidationResult.invalid(
        'Le montant minimum est ${min.toStringAsFixed(0)} FCFA',
      );
    }

    if (max != null && amount > max) {
      return ValidationResult.invalid(
        'Le montant maximum est ${max.toStringAsFixed(0)} FCFA',
      );
    }

    return const ValidationResult.valid();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS FLUTTER FORM
  // ══════════════════════════════════════════════════════════════════════════

  /// Convertit un validateur en format Flutter Form validator.
  static String? Function(String?) toFormValidator(
    ValidationResult Function(String?) validator,
  ) {
    return (value) => validator(value).error;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SANITIZATION
// ══════════════════════════════════════════════════════════════════════════

/// Utilitaires de nettoyage et sanitization des entrées utilisateur.
class InputSanitizer {
  InputSanitizer._();

  /// Longueur maximale par défaut pour les champs texte.
  static const int defaultMaxLength = 500;

  /// Longueur maximale pour les messages/commentaires.
  static const int maxMessageLength = 2000;

  /// Longueur maximale pour les notes courtes.
  static const int maxNoteLength = 200;

  /// Nettoie une chaîne de caractères basique.
  /// - Supprime les espaces en début/fin
  /// - Remplace les espaces multiples par un seul
  /// - Tronque à la longueur max
  static String sanitizeText(
    String? input, {
    int maxLength = defaultMaxLength,
  }) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, input.length > maxLength ? maxLength : input.length);
  }

  /// Nettoie un nom (prénom/nom).
  static String sanitizeName(String? input) {
    if (input == null || input.isEmpty) return '';

    // Supprime tout sauf lettres, espaces, tirets, apostrophes
    return input
        .trim()
        .replaceAll(RegExp(r"[^a-zA-ZÀ-ÿ\s\-']"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, input.length > 100 ? 100 : input.length);
  }

  /// Nettoie un email.
  static String sanitizeEmail(String? input) {
    if (input == null || input.isEmpty) return '';

    return input.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
  }

  /// Nettoie un numéro de téléphone.
  /// Garde uniquement les chiffres et le + initial.
  static String sanitizePhone(String? input) {
    if (input == null || input.isEmpty) return '';

    final trimmed = input.trim();
    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  /// Nettoie un message/commentaire.
  /// - Supprime les caractères de contrôle
  /// - Limite la longueur
  /// - Préserve les sauts de ligne (max 2 consécutifs)
  static String sanitizeMessage(
    String? input, {
    int maxLength = maxMessageLength,
  }) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // Supprime les caractères de contrôle sauf newline et tab
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Max 2 newlines consécutifs
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Espaces multiples -> un seul
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .substring(0, input.length > maxLength ? maxLength : input.length);
  }

  /// Nettoie une note courte.
  static String sanitizeNote(String? input) {
    return sanitizeText(input, maxLength: maxNoteLength);
  }

  /// Nettoie un code (confirmation, OTP, etc.).
  /// Garde uniquement les caractères alphanumériques.
  static String sanitizeCode(String? input, {int maxLength = 10}) {
    if (input == null || input.isEmpty) return '';

    final cleaned = input.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Nettoie un montant (garde chiffres et point décimal).
  static String sanitizeAmount(String? input) {
    if (input == null || input.isEmpty) return '';

    // Garde uniquement chiffres et un seul point
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');

    // S'assure qu'il n'y a qu'un seul point décimal
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return '${parts[0]}.${parts.sublist(1).join('')}';
    }

    return cleaned;
  }

  /// Vérifie si une chaîne contient des caractères potentiellement dangereux.
  /// Utile pour la détection de tentatives d'injection.
  static bool containsSuspiciousContent(String? input) {
    if (input == null || input.isEmpty) return false;

    // Patterns suspects (scripts, SQL injection basique)
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick=, onerror=, etc.
      RegExp(
        '[\'"];?\\s*(drop|delete|update|insert|select)\\s+',
        caseSensitive: false,
      ),
      RegExp(r'--\s*$'), // SQL comment
      RegExp(r'\{\{.*\}\}'), // Template injection
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Échappe les caractères HTML.
  static String escapeHtml(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

/// Extension pour chaîner les validations.
extension ValidationResultExtension on ValidationResult {
  /// Chaîne avec un autre validateur si celui-ci est valide.
  ValidationResult and(ValidationResult Function() next) {
    if (!isValid) return this;
    return next();
  }
}
