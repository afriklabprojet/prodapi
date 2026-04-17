/// Traducteur de messages d'erreur API anglais → français.
///
/// Filet de sécurité côté client : traduit les messages de validation
/// Laravel qui pourraient arriver en anglais (cache, fallback, etc.)
class ErrorTranslator {
  ErrorTranslator._();

  /// Traduit un message d'erreur en français s'il est en anglais.
  /// Retourne le message original s'il est déjà en français ou inconnu.
  static String toFrench(String message) {
    // Déjà en français ? On retourne tel quel.
    // Heuristique : contient des accents/mots français courants
    if (_looksLikeFrench(message)) return message;

    // Chercher une traduction exacte ou par pattern
    for (final entry in _exactTranslations.entries) {
      if (message.toLowerCase() == entry.key.toLowerCase()) {
        return entry.value;
      }
    }

    for (final entry in _patternTranslations.entries) {
      if (entry.key.hasMatch(message)) {
        return entry.key.firstMatch(message)!.groupCount > 0
            ? _applyPattern(entry.key, entry.value, message)
            : entry.value;
      }
    }

    return message;
  }

  /// Traduit une liste de messages de validation d'un champ.
  static List<String> translateAll(List<String> messages) {
    return messages.map(toFrench).toList();
  }

  /// Traduit toutes les erreurs de validation (Map<champ, [messages]>).
  static Map<String, List<String>> translateValidationErrors(
      Map<String, List<String>> errors) {
    return errors.map((key, value) => MapEntry(key, translateAll(value)));
  }

  static bool _looksLikeFrench(String text) {
    final frenchIndicators = [
      'é', 'è', 'ê', 'ë', 'à', 'â', 'ù', 'û', 'ô', 'î', 'ï', 'ç', 'œ',
      'doit', 'champ', 'obligatoire', 'déjà', 'utilisé',
      'valide', 'invalide', 'caractères', 'veuillez',
    ];
    final lowerText = text.toLowerCase();
    return frenchIndicators.any((indicator) => lowerText.contains(indicator));
  }

  static String _applyPattern(RegExp pattern, String template, String input) {
    final match = pattern.firstMatch(input)!;
    var result = template;
    for (var i = 1; i <= match.groupCount; i++) {
      result = result.replaceAll('{$i}', match.group(i) ?? '');
    }
    return result;
  }

  // ─── Traductions exactes ─────────────────────────────────────
  static final Map<String, String> _exactTranslations = {
    // Validation générale
    'The email has already been taken.':
        'Cette adresse email est déjà utilisée.',
    'The phone has already been taken.':
        'Ce numéro de téléphone est déjà utilisé.',
    'The phone number has already been taken.':
        'Ce numéro de téléphone est déjà utilisé.',
    'The license number has already been taken.':
        'Ce numéro de licence est déjà enregistré.',
    'The email field is required.': 'L\'adresse email est obligatoire.',
    'The password field is required.': 'Le mot de passe est obligatoire.',
    'The name field is required.': 'Le nom est obligatoire.',
    'The phone field is required.': 'Le numéro de téléphone est obligatoire.',
    'The address field is required.': 'L\'adresse est obligatoire.',
    'The city field is required.': 'La ville est obligatoire.',
    'The email must be a valid email address.':
        'L\'adresse email n\'est pas valide.',
    'The password must be at least 8 characters.':
        'Le mot de passe doit avoir au moins 8 caractères.',
    'The password must be at least 6 characters.':
        'Le mot de passe doit avoir au moins 6 caractères.',
    'The password confirmation does not match.':
        'La confirmation du mot de passe ne correspond pas.',
    'The provided credentials are incorrect.':
        'Les identifiants fournis sont incorrects.',
    'These credentials do not match our records.':
        'Ces identifiants ne correspondent pas à nos enregistrements.',
    'Too many login attempts. Please try again in :seconds seconds.':
        'Trop de tentatives. Réessayez dans quelques instants.',
    'The given data was invalid.': 'Les données fournies sont invalides.',
    'Unauthenticated.': 'Session expirée. Veuillez vous reconnecter.',
    'This action is unauthorized.': 'Action non autorisée.',
    'Server Error': 'Erreur serveur. Réessayez plus tard.',
    'Not Found': 'Ressource non trouvée.',
    'Forbidden': 'Accès refusé.',
    'Too Many Requests': 'Trop de requêtes. Patientez un moment.',
    'Service Unavailable': 'Service temporairement indisponible.',
    'Bad Request': 'Requête invalide.',
    'Method Not Allowed': 'Méthode non autorisée.',
    'Validation Error': 'Erreur de validation.',
    'The email is invalid.': 'L\'adresse email n\'est pas valide.',
    'The phone format is invalid.':
        'Le format du numéro de téléphone est invalide.',
    'The image must be an image.': 'Le fichier doit être une image.',
    'The image must not be greater than 2048 kilobytes.':
        'L\'image ne doit pas dépasser 2 Mo.',
    'The file must not be greater than 5120 kilobytes.':
        'Le fichier ne doit pas dépasser 5 Mo.',
  };

  // ─── Traductions par pattern (regex) ─────────────────────────
  static final Map<RegExp, String> _patternTranslations = {
    // "The X has already been taken."
    RegExp(r'^The (\w+) has already been taken\.$', caseSensitive: false):
        'Cette valeur est déjà utilisée.',

    // "The X field is required."
    RegExp(r'^The (\w+) field is required\.$', caseSensitive: false):
        'Ce champ est obligatoire.',

    // "The X must be at least Y characters."
    RegExp(r'^The (\w+) must be at least (\d+) characters?\.$',
            caseSensitive: false):
        'Ce champ doit avoir au moins {2} caractères.',

    // "The X must not be greater than Y characters."
    RegExp(r'^The (\w+) must not be greater than (\d+) characters?\.$',
            caseSensitive: false):
        'Ce champ ne doit pas dépasser {2} caractères.',

    // "The X must be a valid email address."
    RegExp(r'^The (\w+) must be a valid email address\.$',
            caseSensitive: false):
        'L\'adresse email n\'est pas valide.',

    // "The X format is invalid."
    RegExp(r'^The (\w+) format is invalid\.$', caseSensitive: false):
        'Le format est invalide.',

    // "The X must be a number."
    RegExp(r'^The (\w+) must be a number\.$', caseSensitive: false):
        'Ce champ doit être un nombre.',

    // "The X must be an integer."
    RegExp(r'^The (\w+) must be an integer\.$', caseSensitive: false):
        'Ce champ doit être un entier.',

    // "The X must be between Y and Z."
    RegExp(r'^The (\w+) must be between (\d+) and (\d+)\.$',
            caseSensitive: false):
        'Ce champ doit être entre {2} et {3}.',

    // "The selected X is invalid."
    RegExp(r'^The selected (\w+) is invalid\.$', caseSensitive: false):
        'La valeur sélectionnée est invalide.',

    // "The X must be at least Y."
    RegExp(r'^The (\w+) must be at least (\d+)\.$', caseSensitive: false):
        'La valeur minimum est {2}.',

    // "The X may not be greater than Y."
    RegExp(r'^The (\w+) may not be greater than (\d+)\.$',
            caseSensitive: false):
        'La valeur maximum est {2}.',
  };
}
