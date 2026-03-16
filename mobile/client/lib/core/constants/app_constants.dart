class AppConstants {
  // App Info
  static const String appName = 'DR-PHARMA';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String tokenKey = 'access_token'; // Alias for consistency
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserPhone = 'user_phone';
  static const String userKey = 'user_data'; // For storing complete user object

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;

  // Phone number format (Côte d'Ivoire)
  static const String phoneRegex = r'^\+225\s?\d{2}\s?\d{2}\s?\d{2}\s?\d{2}$';
  static const int phoneLengthWithPrefix = 10; // e.g. 07xxxxxxxx

  // Payment Modes
  static const String paymentModePlatform = 'platform';
  static const String paymentModeOnDelivery = 'on_delivery';

  // Currency
  static const String currencyLocale = 'fr_CI';
  static const String currencySymbol = 'F CFA';

  // Timeouts
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Default Map Coordinates (Abidjan, Côte d'Ivoire)
  static const double defaultLatitude = 5.3600;
  static const double defaultLongitude = -4.0083;
}
