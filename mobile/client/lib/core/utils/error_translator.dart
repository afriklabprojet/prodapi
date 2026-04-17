/// Traducteur centralisé de messages d'erreur techniques → messages utilisateur.
///
/// Convertit les messages bruts de l'API Laravel (validation, auth, serveur)
/// en messages clairs et compréhensibles pour l'utilisateur final.
class ErrorTranslator {
  ErrorTranslator._();

  /// Messages exacts → remplacement direct
  static const _exactMap = <String, String>{
    // Validation Laravel FR
    'La valeur du champ email est déjà utilisée.':
        'Cette adresse email est déjà associée à un compte.\nConnectez-vous ou utilisez un autre email.',
    'La valeur du champ phone est déjà utilisée.':
        'Ce numéro est déjà associé à un compte.\nConnectez-vous ou utilisez un autre numéro.',
    'La valeur du champ telephone est déjà utilisée.':
        'Ce numéro est déjà associé à un compte.',
    'Le champ email est obligatoire.': 'Veuillez saisir votre adresse email.',
    'Le champ password est obligatoire.': 'Veuillez saisir votre mot de passe.',
    'Le champ mot de passe est obligatoire.':
        'Veuillez saisir votre mot de passe.',
    'Le champ name est obligatoire.': 'Veuillez saisir votre nom.',
    'Le champ nom est obligatoire.': 'Veuillez saisir votre nom.',
    'Le champ phone est obligatoire.':
        'Veuillez saisir votre numéro de téléphone.',
    'Le champ telephone est obligatoire.':
        'Veuillez saisir votre numéro de téléphone.',
    'Le champ email doit être une adresse email valide.':
        'L\'adresse email saisie n\'est pas valide.',
    'Le champ email n\'est pas valide.':
        'L\'adresse email saisie n\'est pas valide.',
    'Le champ password doit contenir au moins 8 caractères.':
        'Le mot de passe doit contenir au moins 8 caractères.',
    'Le champ mot de passe doit contenir au moins 8 caractères.':
        'Le mot de passe doit contenir au moins 8 caractères.',
    'La confirmation du champ password ne correspond pas.':
        'Les mots de passe ne correspondent pas.',
    'La confirmation du champ mot de passe ne correspond pas.':
        'Les mots de passe ne correspondent pas.',

    // Validation Laravel EN (fallback si locale non FR)
    'The email has already been taken.':
        'Cette adresse email est déjà associée à un compte.',
    'The phone has already been taken.':
        'Ce numéro est déjà associé à un compte.',
    'The email field is required.': 'Veuillez saisir votre adresse email.',
    'The password field is required.': 'Veuillez saisir votre mot de passe.',
    'The name field is required.': 'Veuillez saisir votre nom.',
    'The phone field is required.':
        'Veuillez saisir votre numéro de téléphone.',
    'The email must be a valid email address.':
        'L\'adresse email saisie n\'est pas valide.',
    'The password must be at least 8 characters.':
        'Le mot de passe doit contenir au moins 8 caractères.',
    'The password confirmation does not match.':
        'Les mots de passe ne correspondent pas.',
    'These credentials do not match our records.':
        'Email ou mot de passe incorrect.',
    'The provided credentials are incorrect.':
        'Email ou mot de passe incorrect.',

    // Messages serveur courants
    'Unauthenticated.': 'Votre session a expiré. Veuillez vous reconnecter.',
    'Too Many Attempts.': 'Trop de tentatives. Réessayez dans quelques minutes.',
    'Server Error': 'Service temporairement indisponible. Réessayez plus tard.',
    'Erreur de validation': 'Veuillez vérifier les informations saisies.',
  };

  /// Patterns regex → message utilisateur
  static final _patterns = <_ErrorPattern>[
    // "La valeur du champ X est déjà utilisée"
    _ErrorPattern(
      RegExp(r'la valeur du champ (\w+) est déjà utilisée', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        return '$field est déjà associé(e) à un compte.';
      },
    ),
    // "Le champ X est obligatoire"
    _ErrorPattern(
      RegExp(r'le champ (\w+) est obligatoire', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        return 'Veuillez renseigner $field.';
      },
    ),
    // "Le champ X doit contenir au moins N caractères"
    _ErrorPattern(
      RegExp(r'le champ (\w+) doit contenir au moins (\d+) caractères', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        final count = match.group(2) ?? '';
        return '$field doit contenir au moins $count caractères.';
      },
    ),
    // "Le champ X doit être une adresse email valide"
    _ErrorPattern(
      RegExp(r'le champ (\w+) doit être une adresse email valide', caseSensitive: false),
      (_) => 'L\'adresse email saisie n\'est pas valide.',
    ),
    // "Le champ X n'est pas valide" / "n'est pas un X valide"
    _ErrorPattern(
      RegExp(r"le champ (\w+) n'est pas (un \w+ )?valide", caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        return '$field n\'est pas valide. Veuillez vérifier votre saisie.';
      },
    ),
    // "La confirmation du champ X ne correspond pas"
    _ErrorPattern(
      RegExp(r'la confirmation du champ (\w+) ne correspond pas', caseSensitive: false),
      (_) => 'Les mots de passe ne correspondent pas.',
    ),
    // "Le champ X doit être supérieur à N"
    _ErrorPattern(
      RegExp(r'le champ (\w+) doit être supérieur à (\d+)', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        final min = match.group(2) ?? '';
        return '$field doit être supérieur à $min.';
      },
    ),
    // EN: "The X has already been taken"
    _ErrorPattern(
      RegExp(r'the (\w+) has already been taken', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        return '$field est déjà associé(e) à un compte.';
      },
    ),
    // EN: "The X field is required"
    _ErrorPattern(
      RegExp(r'the (\w+) field is required', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        return 'Veuillez renseigner $field.';
      },
    ),
    // EN: "The X must be at least N characters"
    _ErrorPattern(
      RegExp(r'the (\w+) must be at least (\d+) characters', caseSensitive: false),
      (match) {
        final field = _friendlyField(match.group(1) ?? '');
        final count = match.group(2) ?? '';
        return '$field doit contenir au moins $count caractères.';
      },
    ),
  ];

  /// Noms de champs techniques → libellés humains
  static const _fieldNames = <String, String>{
    'email': 'L\'adresse email',
    'password': 'Le mot de passe',
    'phone': 'Le numéro de téléphone',
    'telephone': 'Le numéro de téléphone',
    'name': 'Le nom',
    'nom': 'Le nom',
    'address': 'L\'adresse',
    'adresse': 'L\'adresse',
    'password_confirmation': 'La confirmation du mot de passe',
    'city': 'La ville',
    'ville': 'La ville',
    'quantity': 'La quantité',
    'quantite': 'La quantité',
  };

  static String _friendlyField(String raw) {
    return _fieldNames[raw.toLowerCase()] ?? 'Ce champ';
  }

  /// Point d'entrée principal : transforme un message technique en message clair.
  static String toUserFriendly(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Une erreur est survenue. Veuillez réessayer.';

    // 1. Correspondance exacte
    final exact = _exactMap[trimmed];
    if (exact != null) return exact;

    // 2. Correspondance par pattern
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(trimmed);
      if (match != null) return pattern.transform(match);
    }

    // 3. Si le message est court et ne contient pas de jargon technique, le garder
    if (trimmed.length < 120 &&
        !trimmed.contains('Exception') &&
        !trimmed.contains('Error') &&
        !trimmed.contains('stack') &&
        !trimmed.contains('null') &&
        !trimmed.contains('type \'')) {
      return trimmed;
    }

    // 4. Fallback sécurisé
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Traduit une map d'erreurs de validation (clé → liste de messages).
  static Map<String, List<String>> translateErrors(
    Map<String, List<String>> errors,
  ) {
    return errors.map(
      (key, messages) => MapEntry(
        key,
        messages.map(toUserFriendly).toList(),
      ),
    );
  }
}

class _ErrorPattern {
  final RegExp regex;
  final String Function(RegExpMatch match) transform;

  const _ErrorPattern(this.regex, this.transform);
}
