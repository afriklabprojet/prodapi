import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/delivery.dart';
import '../../data/models/scanned_document.dart';
import '../../data/models/user.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/login_screen_redesign.dart';
import '../../presentation/screens/register_screen_redesign.dart';
import '../../presentation/screens/otp_verification_screen.dart';
import '../../presentation/screens/pending_approval_screen.dart';
import '../../presentation/screens/kyc_resubmission_screen.dart';
import '../../presentation/screens/liveness_verification_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/delivery_details_screen.dart';
import '../../presentation/screens/enhanced_chat_screen.dart';
import '../../presentation/screens/rating_screen.dart';
import '../../presentation/screens/document_scanner_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/edit_profile_screen.dart';
import '../../presentation/screens/change_password_screen.dart';
import '../../presentation/screens/battery_optimization_screen.dart';
import '../../presentation/screens/interactive_tutorial_screen.dart';
import '../../presentation/screens/help_center_screen.dart';
import '../../presentation/screens/support_tickets_screen.dart';
import '../../presentation/screens/create_ticket_screen.dart';
import '../../presentation/screens/support_ticket_chat_screen.dart';
import '../../presentation/screens/gamification_screen.dart';
import '../../presentation/screens/challenges_screen.dart';
import '../../presentation/screens/history_export_screen.dart';
import '../../presentation/screens/batch_deliveries_screen.dart';
import '../../presentation/screens/multi_route_screen.dart';
import '../../presentation/screens/payment_status_screen.dart';
import '../../presentation/screens/payment_callback_screen.dart';
import '../../presentation/screens/settings/accessibility_settings_screen.dart';
import '../../presentation/screens/settings/home_widget_settings_screen.dart';
import '../../presentation/widgets/notifications/notification_widgets.dart';
import '../../data/repositories/jeko_payment_repository.dart';
import 'route_names.dart';

/// Clé globale pour accéder au navigateur depuis les services (session expiry, etc.)
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider GoRouter — accessible partout via ref.watch(routerProvider)
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Redirect pour convertir les deep links drpharma-courier:// en paths locaux
    redirect: (context, state) {
      final location = state.uri.toString();
      debugPrint('[GoRouter] Location: $location');

      // Gérer les deep links avec schéma drpharma-courier://
      if (location.startsWith('drpharma-courier://') ||
          location.startsWith('drpharma://')) {
        // Extraire le path et query du deep link
        final uri = Uri.parse(location);
        final path = '/${uri.host}${uri.path}';
        final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
        final newLocation = '$path$query';
        debugPrint('[GoRouter] Deep link redirect: $location -> $newLocation');
        return newLocation;
      }

      return null; // Pas de redirect nécessaire
    },
    routes: [
      // ── Auth / Onboarding ──
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreenRedesign(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreenRedesign(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            identifier: extra['identifier'] as String,
            purpose: extra['purpose'] as OtpPurpose? ?? OtpPurpose.verification,
          );
        },
      ),

      // ── Status gates ──
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return PendingApprovalScreen(
            status: extra['status'] ?? 'pending_approval',
            message:
                extra['message'] ??
                'Votre compte est en attente de validation.',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.kycResubmission,
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return KycResubmissionScreen(
            rejectionReason: extra?['rejectionReason'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.livenessVerification,
        builder: (context, state) => const LivenessVerificationScreen(),
      ),

      // ── Dashboard ──
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // ── Delivery ──
      GoRoute(
        path: AppRoutes.deliveryDetails,
        pageBuilder: (context, state) {
          final delivery = state.extra as Delivery;
          return CustomTransitionPage(
            key: state.pageKey,
            // opaque: false permet de voir la page en dessous pendant la transition
            opaque: false,
            child: DeliveryDetailsScreen(delivery: delivery),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  final slideTween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: Curves.easeInOutCubic));
                  // Ajouter un fade pour une transition plus fluide
                  final fadeTween = Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).chain(CurveTween(curve: Curves.easeIn));
                  return FadeTransition(
                    opacity: animation.drive(fadeTween),
                    child: SlideTransition(
                      position: animation.drive(slideTween),
                      child: child,
                    ),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deliveryChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return EnhancedChatScreen(
            orderId: extra['orderId'] as int,
            target: extra['target'] as String,
            targetName: extra['targetName'] as String,
            targetAvatar: extra['targetAvatar'] as String?,
            targetPhone: extra['targetPhone'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deliveryRating,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RatingScreen(
            deliveryId: extra['deliveryId'] as int,
            customerName: extra['customerName'] as String,
            customerAddress: extra['customerAddress'] as String?,
            initialRating: extra['initialRating'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deliveryDocuments,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return DeliveryDocumentsScreen(
            deliveryId: extra['deliveryId'] as int,
            deliveryReference: extra['deliveryReference'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deliveryScanner,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DocumentScannerScreen(
            deliveryId: extra['deliveryId'] as int?,
            preselectedType: extra['preselectedType'] as DocumentType?,
            autoStartCapture: extra['autoStartCapture'] as bool? ?? false,
          );
        },
      ),

      // ── Settings ──
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          final user = state.extra as User;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.batteryOptimization,
        builder: (context, state) => const BatteryOptimizationScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (context, state) => const InteractiveTutorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessibilitySettings,
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeWidgetSettings,
        builder: (context, state) => const HomeWidgetSettingsScreen(),
      ),

      // ── Support ──
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportTicketsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createTicket,
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: AppRoutes.supportChat,
        builder: (context, state) {
          final ticketId = state.extra as int;
          return SupportTicketChatScreen(ticketId: ticketId);
        },
      ),

      // ── Features ──
      GoRoute(
        path: AppRoutes.gamification,
        builder: (context, state) => const GamificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.challenges,
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: AppRoutes.historyExport,
        builder: (context, state) => const HistoryExportScreen(),
      ),
      GoRoute(
        path: AppRoutes.batchDeliveries,
        builder: (context, state) => const BatchDeliveriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.multiRoute,
        builder: (context, state) => const MultiRouteScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentStatus,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentStatusScreen(
            amount: extra['amount'] as double,
            method: extra['method'] as JekoPaymentMethod,
            onSuccess: extra['onSuccess'] as VoidCallback?,
            onCancel: extra['onCancel'] as VoidCallback?,
          );
        },
      ),
      // Deep link callbacks de paiement JEKO
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          final reference = state.uri.queryParameters['reference'];
          debugPrint('[PaymentCallback] Success callback received: $reference');
          return PaymentCallbackScreen(isSuccess: true, reference: reference);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentError,
        builder: (context, state) {
          final reference = state.uri.queryParameters['reference'];
          final reason = state.uri.queryParameters['reason'];
          debugPrint(
            '[PaymentCallback] Error callback: $reference, reason: $reason',
          );
          return PaymentCallbackScreen(
            isSuccess: false,
            reference: reference,
            reason: reason,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.conversations,
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationCenter,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
});
