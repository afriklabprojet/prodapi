import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen_redesign.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/auth_session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Capturer toutes les erreurs Flutter pour éviter l'écran blanc
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
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

  // ── CRITIQUE : Lancer l'UI IMMÉDIATEMENT ──
  // AUCUNE opération async avant runApp() — c'est la clé anti-ANR.
  // Firebase, SharedPreferences, etc. sont initialisés APRÈS dans le SplashScreen.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  /// Clé globale de navigation pour permettre la redirection depuis les services
  static final navigatorKey = GlobalKey<NavigatorState>();

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
        final navigator = MyApp.navigatorKey.currentState;
        if (navigator != null) {
          if (kDebugMode) debugPrint('🔐 [SESSION] Redirection vers LoginScreen');
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreenRedesign()),
            (_) => false,
          );
          // Afficher le message après que la navigation soit terminée
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = MyApp.navigatorKey.currentContext;
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'DR-PHARMA Courier',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
