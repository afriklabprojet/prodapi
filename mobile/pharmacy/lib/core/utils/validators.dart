/// Utilitaires de validation pour les formulaires.
///
/// Fournit des validateurs réutilisables et typés pour tous les champs
/// de l'application pharmacie (email, téléphone, adresse, produits, etc.).
library;

/// Résultat d'une validation.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  /// Convertit en String? pour usage direct dans les validators Flutter.
  String? get error => errorMessage;
}

/// Configuration de pays pour la validation téléphone.
class PhoneCountryConfig {
  final String name;
  final String code;
  final List<String> prefixes;
  final int length;
  final List<String> indicators;

  const PhoneCountryConfig({
    required this.name,
    required this.code,
    required this.prefixes,
    required this.length,
    required this.indicators,
  });

  static const ivoryCoast = PhoneCountryConfig(
    name: 'Côte d\'Ivoire',
    code: 'CI',
    prefixes: ['01', '05', '07', '08'], // Mobile: Orange, MTN, Moov
    length: 10,
    indicators: ['+225', '00225', '225'],
  );

  static const senegal = PhoneCountryConfig(
    name: 'Sénégal',
    code: 'SN',
    prefixes: ['70', '76', '77', '78'], // Orange, Free, Expresso
    length: 9,
    indicators: ['+221', '00221', '221'],
  );

  static const france = PhoneCountryConfig(
    name: 'France',
    code: 'FR',
    prefixes: ['06', '07'], // Mobiles
    length: 10,
    indicators: ['+33', '0033', '33'],
  );

  static const mali = PhoneCountryConfig(
    name: 'Mali',
    code: 'ML',
    prefixes: ['60', '61', '62', '63', '64', '65', '66', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79'],
    length: 8,
    indicators: ['+223', '00223', '223'],
  );

  static const burkina = PhoneCountryConfig(
    name: 'Burkina Faso',
    code: 'BF',
    prefixes: ['50', '51', '52', '54', '55', '56', '57', '58', '60', '61', '62', '63', '64', '65', '66', '67', '68', '69', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79'],
    length: 8,
    indicators: ['+226', '00226', '226'],
  );

  /// Tous les pays supportés.
  static const List<PhoneCountryConfig> allCountries = [
    ivoryCoast,
    senegal,
    france,
    mali,
    burkina,
  ];
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
  // TÉLÉPHONE MULTI-PAYS
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide un numéro de téléphone multi-pays.
  /// Détecte automatiquement le pays basé sur l'indicatif.
  static ValidationResult validatePhone(
    String? value, {
    PhoneCountryConfig? country,
    bool allowAllCountries = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid(
        'Le numéro de téléphone est requis',
      );
    }

    // Nettoie le numéro (garde uniquement les chiffres et le +)
    String cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Détecte le pays si non spécifié
    PhoneCountryConfig? detectedCountry = country;
    if (detectedCountry == null && allowAllCountries) {
      detectedCountry = _detectCountry(cleaned);
    }
    detectedCountry ??= PhoneCountryConfig.ivoryCoast;

    // Supprime l'indicatif pays si présent
    for (final indicator in detectedCountry.indicators) {
      if (cleaned.startsWith(indicator)) {
        cleaned = cleaned.substring(indicator.length);
        break;
      }
    }

    // Ne garder que les chiffres
    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    // Vérifie la longueur
    if (cleaned.length < detectedCountry.length) {
      return ValidationResult.invalid(
        'Le numéro doit contenir ${detectedCountry.length} chiffres (${detectedCountry.name})',
      );
    }

    if (cleaned.length > 15) {
      return const ValidationResult.invalid('Numéro de téléphone trop long');
    }

    // Vérifie le préfixe si longueur exacte
    if (cleaned.length == detectedCountry.length) {
      final prefix = cleaned.substring(0, 2);
      if (!detectedCountry.prefixes.contains(prefix)) {
        return ValidationResult.invalid(
          'Préfixe invalide pour ${detectedCountry.name}',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// Détecte le pays basé sur l'indicatif téléphonique.
  static PhoneCountryConfig? _detectCountry(String phone) {
    for (final country in PhoneCountryConfig.allCountries) {
      for (final indicator in country.indicators) {
        if (phone.startsWith(indicator)) {
          return country;
        }
      }
    }
    return null;
  }

  /// Normalise un numéro de téléphone au format E.164.
  static String normalizePhone(String value, {PhoneCountryConfig? country}) {
    String cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');

    // Détecte le pays
    final detectedCountry =
        country ?? _detectCountry(cleaned) ?? PhoneCountryConfig.ivoryCoast;

    // Supprime les indicatifs existants
    for (final indicator in detectedCountry.indicators) {
      if (cleaned.startsWith(indicator)) {
        cleaned = cleaned.substring(indicator.length);
        break;
      }
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    return '+${detectedCountry.indicators.first.replaceAll('+', '')}$cleaned';
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
  // PHARMACIE - SPÉCIFIQUE
  // ══════════════════════════════════════════════════════════════════════════

  /// Valide le nom d'une pharmacie.
  static ValidationResult validatePharmacyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid(
        'Le nom de la pharmacie est requis',
      );
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

    return const ValidationResult.valid();
  }

  /// Valide une adresse.
  static ValidationResult validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('L\'adresse est requise');
    }

    final trimmed = value.trim();

    if (trimmed.length < 10) {
      return const ValidationResult.invalid(
        'L\'adresse doit être plus détaillée',
      );
    }

    if (trimmed.length > 255) {
      return const ValidationResult.invalid(
        'L\'adresse ne peut pas dépasser 255 caractères',
      );
    }

    return const ValidationResult.valid();
  }

  /// Valide un montant (prix produit, retrait, etc.).
  static ValidationResult validateAmount(
    String? value, {
    double minAmount = 0,
    double maxAmount = 10000000,
    String? fieldName,
  }) {
    final label = fieldName ?? 'Le montant';
    
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$label est requis');
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(cleaned);

    if (amount == null) {
      return ValidationResult.invalid('$label invalide');
    }

    if (amount < minAmount) {
      return ValidationResult.invalid(
        '$label minimum: ${minAmount.toStringAsFixed(0)} FCFA',
      );
    }

    if (amount > maxAmount) {
      return ValidationResult.invalid(
        '$label maximum: ${maxAmount.toStringAsFixed(0)} FCFA',
      );
    }

    return const ValidationResult.valid();
  }

  /// Valide une quantité de produit.
  static ValidationResult validateQuantity(
    String? value, {
    int minQty = 1,
    int maxQty = 9999,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('La quantité est requise');
    }

    final qty = int.tryParse(value.trim());

    if (qty == null) {
      return const ValidationResult.invalid('Quantité invalide');
    }

    if (qty < minQty) {
      return ValidationResult.invalid('Quantité minimum: $minQty');
    }

    if (qty > maxQty) {
      return ValidationResult.invalid('Quantité maximum: $maxQty');
    }

    return const ValidationResult.valid();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS FLUTTER
  // ══════════════════════════════════════════════════════════════════════════

  /// Convertit un ValidationResult en validator Flutter.
  static String? Function(String?) asFlutterValidator(
    ValidationResult Function(String?) validator,
  ) {
    return (value) => validator(value).error;
  }

  /// Validator Flutter pour nom.
  static String? nameValidator(String? value) => validateName(value).error;

  /// Validator Flutter pour email.
  static String? emailValidator(String? value) => validateEmail(value).error;

  /// Validator Flutter pour téléphone.
  static String? phoneValidator(String? value) => validatePhone(value).error;

  /// Validator Flutter pour mot de passe.
  static String? passwordValidator(String? value) =>
      validatePassword(value).error;

  /// Validator Flutter pour champ requis simple.
  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }
}
