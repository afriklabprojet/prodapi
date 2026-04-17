import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env_config.dart';
import 'core/config/routes.dart';
import 'core/providers/core_providers.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/infobip_messaging_service.dart';
import 'core/services/order_alert_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/realtime_event_bus.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/state/auth_state.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/orders/presentation/providers/order_list_provider.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Types de notifications qui déclenchent une alerte et un refresh.
const _alertNotificationTypes = {'new_order', 'new_prescription'};

/// Types de notifications liés aux commandes.
const _orderNotificationTypes = {
  'new_order',
  'order_status_change',
  'order_ready',
};

// ─────────────────────────────────────────────────────────────────────────────
// Debug Logging Helper
// ─────────────────────────────────────────────────────────────────────────────

void _log(String message) {
  if (kDebugMode) debugPrint(message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Entry Point
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  _setupErrorHandlers();
  await EnvConfig.init();
  await _initializeFirebase();
  await _initializeInfobip();
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

/// Configure les handlers d'erreurs globaux.
void _setupErrorHandlers() {
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    _log('🔴 FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    _log('🔴 PlatformError: $error\n$stack');
    return true;
  };
}

/// Initialise Firebase (Analytics, Crashlytics, Performance).
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    await PerformanceService().initialize();
    await FirebaseAnalytics.instance.logAppOpen();
    _log('✅ Firebase initialized (Analytics + Crashlytics + Performance)');
  } catch (e) {
    _log('❌ Firebase initialization failed: $e');
  }
}

/// Initialise Infobip Mobile Messaging.
Future<void> _initializeInfobip() async {
  try {
    await InfobipMessagingService().initialize();
  } catch (e) {
    _log('❌ Infobip initialization failed: $e');
  }
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  Future<void> _initApp() async {
    final router = ref.read(routerProvider);
    await DeepLinkService.instance.initialize(router);

    await _initAuth(router);
    FlutterNativeSplash.remove();
    await _initNotifications(router);
  }

  /// Initialise l'authentification et traite les deep links en attente.
  Future<void> _initAuth(GoRouter router) async {
    try {
      await ref.read(authProvider.notifier).initialize();
      _log('✅ Auth initialized - checking saved session');

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated &&
          DeepLinkService.instance.hasPendingDeepLink) {
        DeepLinkService.instance.processPendingDeepLink();
      }
    } catch (e) {
      _log('❌ Error initializing auth: $e');
    }
  }

  /// Initialise les notifications et configure les handlers.
  Future<void> _initNotifications(GoRouter router) async {
    try {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.initialize();

      notifService.onNotificationTapped = (data) {
        _navigateFromNotification(data, router);
      };

      notifService.onForegroundMessage = (message) {
        ref.read(unreadCountNotifierProvider.notifier).refresh();

        final type =
            message.data['type'] ?? message.data['notification_type'] ?? '';
        final eventType = RealtimeEventBus.fromFcmType(type);
        if (eventType != null) {
          RealtimeEventBus().emit(
            eventType,
            data: message.data.cast<String, dynamic>(),
          );
        }

        if (_alertNotificationTypes.contains(type)) {
          ref.read(orderAlertServiceProvider).startAlert();
          ref.read(orderAlertActiveProvider.notifier).state = true;
          ref.read(orderListProvider.notifier).fetchOrders();
        }
      };
    } catch (e) {
      _log('❌ Error initializing notifications: $e');
    }
  }

  /// Navigue vers la page appropriée depuis un tap sur notification.
  void _navigateFromNotification(Map<String, dynamic> data, GoRouter router) {
    final type = data['type'] ?? data['notification_type'] ?? '';
    final resourceId = data['resource_id'] ?? data['order_id'] ?? data['id'];

    // Navigation basée sur le type de notification
    if (_orderNotificationTypes.contains(type) && resourceId != null) {
      router.push('/orders/$resourceId');
    } else if (type == 'chat' || type == 'new_message' || type == 'chat_message') {
      final deliveryId = data['delivery_id'];
      final orderId = data['order_id'];
      // Utiliser delivery_id si présent, sinon order_id
      final chatId = deliveryId ?? orderId;
      if (chatId != null) {
        router.push(
          '/chat',
          extra: ChatRouteData(
            deliveryId: int.tryParse(chatId.toString()) ?? 0,
            participantType: data['sender_type'] as String? ?? data['participant_type'] as String? ?? 'client',
            participantId:
                int.tryParse(data['participant_id']?.toString() ?? '') ?? 0,
            participantName: data['sender_name'] as String? ?? data['participant_name'] as String? ?? '',
          ),
        );
      } else {
        router.go('/dashboard');
      }
    } else {
      // Fallback pour prescription, payment, stock, etc.
      router.go(type.isEmpty ? '/notifications' : '/dashboard');
    }

    _log('📱 [Notification] Navigated for type=$type, resourceId=$resourceId');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    // Écouter les expirations de session (401 global)
    _listenSessionExpiry(context, router);

    final accentColor = themeState.customAccentColor != null
        ? AppThemes.accentColors[themeState.customAccentColor!]
        : null;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final (lightTheme, darkTheme) = _buildThemes(
          themeState: themeState,
          accentColor: accentColor,
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
        );

        return MaterialApp.router(
          title: 'DR-PHARMA Pharmacie',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', '')],
          locale: const Locale('fr', ''),
        );
      },
    );
  }

  /// Écoute les expirations de session et redirige vers login.
  void _listenSessionExpiry(BuildContext context, GoRouter router) {
    ref.listen<bool>(sessionExpiredProvider, (_, sessionExpired) {
      if (sessionExpired) {
        _log('🔐 [Main] Session expired - redirecting to login');
        ref.read(sessionExpiredProvider.notifier).state = false;
        ref.read(authProvider.notifier).logout();
        router.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  /// Construit les thèmes light et dark selon la configuration.
  (ThemeData, ThemeData) _buildThemes({
    required ThemeState themeState,
    required Color? accentColor,
    required ColorScheme? lightDynamic,
    required ColorScheme? darkDynamic,
  }) {
    final useDynamicColor =
        themeState.useDynamicColors &&
        accentColor == null &&
        lightDynamic != null;

    if (useDynamicColor) {
      return (
        AppThemes.lightThemeFromColorScheme(lightDynamic.harmonized()),
        AppThemes.darkThemeFromColorScheme(darkDynamic!.harmonized()),
      );
    }
    return (
      AppThemes.lightTheme(accentColor: accentColor),
      AppThemes.darkTheme(accentColor: accentColor),
    );
  }
}
