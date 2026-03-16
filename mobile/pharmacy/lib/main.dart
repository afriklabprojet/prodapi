import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/routes.dart';
import 'core/config/env_config.dart';
import 'core/providers/core_providers.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'core/services/infobip_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('🔴 FlutterError: ${details.exceptionAsString()}');
    }
  };

  // Capture async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('🔴 PlatformError: $error\n$stack');
    }
    return true;
  };

  // Initialiser la configuration d'environnement
  await EnvConfig.init();
  EnvConfig.printConfig();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    if (kDebugMode) debugPrint("❌ Firebase initialization failed: $e");
  }

  // Initialize Infobip Mobile Messaging
  try {
    await InfobipMessagingService().initialize();
  } catch (e) {
    if (kDebugMode) debugPrint("❌ Infobip initialization failed: $e");
  }

  await initializeDateFormatting('fr', null);

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const PharmacyApp(),
    ),
  );
}

class PharmacyApp extends ConsumerStatefulWidget {
  const PharmacyApp({super.key});

  @override
  ConsumerState<PharmacyApp> createState() => _PharmacyAppState();
}

class _PharmacyAppState extends ConsumerState<PharmacyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth and notifications after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    try {
      // Initialiser l'authentification (restaurer la session si token présent)
      await ref.read(authProvider.notifier).initialize();
      if (kDebugMode) debugPrint("✅ Auth initialized - checking saved session");
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error initializing auth: $e");
    }
    
    try {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.initialize();
      // When a push notification arrives in foreground, refresh unread badge
      notifService.onForegroundMessage = (_) {
        ref.read(unreadCountNotifierProvider.notifier).refresh();
      };
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error initializing notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    
    // 🔐 Écouter les expirations de session (401 global)
    ref.listen<bool>(sessionExpiredProvider, (previous, sessionExpired) {
      if (sessionExpired) {
        if (kDebugMode) debugPrint('🔐 [Main] Session expired - redirecting to login');
        // Reset the flag immediately to avoid re-triggering
        ref.read(sessionExpiredProvider.notifier).state = false;
        // Logout et redirection
        ref.read(authProvider.notifier).logout();
        router.go('/login');
        // Afficher un message à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
    
    // Obtenir la couleur d'accent dynamique
    Color? accentColor;
    if (themeState.customAccentColor != null) {
      final colorKey = themeState.customAccentColor!;
      accentColor = AppThemes.accentColors[colorKey];
    }

    return MaterialApp.router(
      title: 'DR-PHARMA Pharmacie',
      theme: AppThemes.lightTheme(accentColor: accentColor),
      darkTheme: AppThemes.darkTheme(accentColor: accentColor),
      themeMode: themeState.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''), // French
      ],
      locale: const Locale('fr', ''),
    );
  }
}