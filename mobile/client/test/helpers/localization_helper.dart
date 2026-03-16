/// Shared localization helpers for tests
/// Import this file anytime a test needs AppLocalizations
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';

/// Localization delegates to use in test MaterialApp
final testLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Supported locales for tests
const testSupportedLocales = [
  Locale('fr'),
  Locale('en'),
];

/// Wraps a widget with a localized MaterialApp for testing
Widget createLocalizedTestWidget({
  required Widget child,
  Locale locale = const Locale('fr'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: child,
  );
}
