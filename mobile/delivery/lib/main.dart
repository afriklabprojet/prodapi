import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/accessibility_service.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/auth_session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturer toutes les erreurs Flutter pour éviter l'écran blanc
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Envoyer à Crashlytics en production
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else {
      debugPrint('🔴 Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
  };

  // Configurer ErrorWidget pour afficher un écran visible en cas d'erreur
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Une erreur est survenue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (kDebugMode)
                  Text(
                    details.exception.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Capturer les erreurs async non-Flutter (Dart isolates) pour Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // ── CRITIQUE : Lancer l'UI IMMÉDIATEMENT ──
  // AUCUNE opération async avant runApp() — c'est la clé anti-ANR.
  // Firebase, SharedPreferences, etc. sont initialisés APRÈS dans le SplashScreen.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthSessionState>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _listenSessionExpiration();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  /// Écoute l'expiration de session pour rediriger vers le login automatiquement
  void _listenSessionExpiration() {
    _sessionSub = AuthSessionService.instance.sessionStream.listen((state) {
      if (state == AuthSessionState.expired) {
        final router = ref.read(routerProvider);
        if (kDebugMode) {
          debugPrint('🔐 [SESSION] Redirection vers LoginScreen');
        }
        router.go(AppRoutes.login);
        // Afficher le message après que la navigation soit terminée
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Session expirée. Veuillez vous reconnecter.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final a11y = ref.watch(accessibilityProvider);
    final router = ref.watch(routerProvider);

    // Choisir le thème en fonction du mode haut contraste
    final effectiveLightTheme = a11y.highContrast
        ? HighContrastTheme.light()
        : lightTheme;
    final effectiveDarkTheme = a11y.highContrast
        ? HighContrastTheme.dark()
        : darkTheme;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'DR-PHARMA Courier',
      theme: effectiveLightTheme,
      darkTheme: effectiveDarkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Appliquer le facteur d'échelle de texte et le texte gras
        // depuis les paramètres d'accessibilité
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(a11y.textScaleFactor),
            boldText: a11y.boldText || mediaQuery.boldText,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
