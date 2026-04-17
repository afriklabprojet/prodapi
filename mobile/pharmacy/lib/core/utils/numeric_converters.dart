/// Utilitaires de conversion numérique pour le parsing JSON
/// 
/// Ces fonctions gèrent les cas où l'API retourne des valeurs
/// sous forme de String, num, int ou null.
library;

/// Convertit une valeur dynamique (String ou num) en double
double safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Convertit une valeur dynamique nullable en double nullable
double? safeToDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Convertit une valeur dynamique en int
int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Convertit une valeur dynamique nullable en int nullable
int? safeToIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Convertit une valeur dynamique en String (gère null)
String safeToString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

/// Convertit une valeur dynamique en bool
bool safeToBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  return defaultValue;
}
