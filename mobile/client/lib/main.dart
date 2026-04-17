import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'config/providers.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/widgets/celebration_overlay.dart';
import 'core/services/app_logger.dart';
import 'core/services/firebase_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/infobip_messaging_service.dart';
import 'core/services/cache_service.dart';
import 'features/treatments/data/datasources/treatments_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Charger la configuration d'environnement
  await EnvConfig.init();
  EnvConfig.printConfig();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Crashlytics (must be after Firebase.initializeApp)
    await CrashlyticsService.init();
    AppLogger.info("Crashlytics initialized successfully");

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Configure foreground messaging + local notifications
    await FirebaseService.configureMessaging();
    AppLogger.info("Firebase initialized successfully");
  } catch (e, st) {
    AppLogger.error("Firebase initialization failed", error: e, stackTrace: st);
  }

  // Capturer les erreurs Flutter non capturées par Crashlytics
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textDirection: TextDirection.ltr,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.red),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  };

  // Initialize Infobip Mobile Messaging
  try {
    await InfobipMessagingService().initialize();
  } catch (e, st) {
    AppLogger.error("Infobip initialization failed", error: e, stackTrace: st);
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Hive cache
  try {
    await CacheService.init();
  } catch (e, st) {
    AppLogger.error("Cache initialization failed", error: e, stackTrace: st);
  }

  // Initialize treatments local datasource
  try {
    final treatmentsDatasource = TreatmentsLocalDatasource();
    await treatmentsDatasource.init();
  } catch (e, st) {
    AppLogger.error(
      "Treatments datasource initialization failed",
      error: e,
      stackTrace: st,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: router,
      builder: (context, child) => CelebrationOverlay(
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
    );
  }
}
