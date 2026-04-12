import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/router/route_names.dart';

/// Tests for Improvement 2: GoRouter Migration
/// Verifies all routes are correctly defined and consistent.

void main() {
  group('AppRoutes - Route consistency', () {
    test('all routes start with /', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otpVerification,
        AppRoutes.pendingApproval,
        AppRoutes.kycResubmission,
        AppRoutes.dashboard,
        AppRoutes.home,
        AppRoutes.deliveries,
        AppRoutes.statistics,
        AppRoutes.wallet,
        AppRoutes.profile,
        AppRoutes.deliveryDetails,
        AppRoutes.deliveryChat,
        AppRoutes.deliveryRating,
        AppRoutes.deliveryDocuments,
        AppRoutes.deliveryScanner,
        AppRoutes.settings,
        AppRoutes.editProfile,
        AppRoutes.changePassword,
        AppRoutes.batteryOptimization,
        AppRoutes.tutorial,
        AppRoutes.helpCenter,
        AppRoutes.accessibilitySettings,
        AppRoutes.homeWidgetSettings,
        AppRoutes.support,
        AppRoutes.createTicket,
        AppRoutes.supportChat,
        AppRoutes.gamification,
        AppRoutes.challenges,
        AppRoutes.historyExport,
        AppRoutes.batchDeliveries,
        AppRoutes.multiRoute,
        AppRoutes.paymentStatus,
        AppRoutes.conversations,
        AppRoutes.notificationCenter,
      ];

      for (final route in routes) {
        expect(
          route.startsWith('/'),
          isTrue,
          reason: 'Route "$route" should start with /',
        );
      }
    });

    test('no duplicate route paths', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otpVerification,
        AppRoutes.pendingApproval,
        AppRoutes.kycResubmission,
        AppRoutes.dashboard,
        AppRoutes.home,
        AppRoutes.deliveries,
        AppRoutes.statistics,
        AppRoutes.wallet,
        AppRoutes.profile,
        AppRoutes.deliveryDetails,
        AppRoutes.deliveryChat,
        AppRoutes.deliveryRating,
        AppRoutes.deliveryDocuments,
        AppRoutes.deliveryScanner,
        AppRoutes.settings,
        AppRoutes.editProfile,
        AppRoutes.changePassword,
        AppRoutes.batteryOptimization,
        AppRoutes.tutorial,
        AppRoutes.helpCenter,
        AppRoutes.accessibilitySettings,
        AppRoutes.homeWidgetSettings,
        AppRoutes.support,
        AppRoutes.createTicket,
        AppRoutes.supportChat,
        AppRoutes.gamification,
        AppRoutes.challenges,
        AppRoutes.historyExport,
        AppRoutes.batchDeliveries,
        AppRoutes.multiRoute,
        AppRoutes.paymentStatus,
        AppRoutes.conversations,
        AppRoutes.notificationCenter,
      ];

      final uniqueRoutes = routes.toSet();
      expect(
        uniqueRoutes.length,
        routes.length,
        reason: 'Duplicate route paths detected',
      );
    });

    test('no routes contain spaces or special characters', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otpVerification,
        AppRoutes.pendingApproval,
        AppRoutes.kycResubmission,
        AppRoutes.dashboard,
        AppRoutes.home,
        AppRoutes.deliveries,
        AppRoutes.statistics,
        AppRoutes.wallet,
        AppRoutes.profile,
        AppRoutes.deliveryDetails,
        AppRoutes.deliveryChat,
        AppRoutes.deliveryRating,
        AppRoutes.deliveryDocuments,
        AppRoutes.deliveryScanner,
        AppRoutes.settings,
        AppRoutes.editProfile,
        AppRoutes.changePassword,
        AppRoutes.batteryOptimization,
        AppRoutes.tutorial,
        AppRoutes.helpCenter,
        AppRoutes.accessibilitySettings,
        AppRoutes.homeWidgetSettings,
        AppRoutes.support,
        AppRoutes.createTicket,
        AppRoutes.supportChat,
        AppRoutes.gamification,
        AppRoutes.challenges,
        AppRoutes.historyExport,
        AppRoutes.batchDeliveries,
        AppRoutes.multiRoute,
        AppRoutes.paymentStatus,
        AppRoutes.conversations,
        AppRoutes.notificationCenter,
      ];

      final validPattern = RegExp(r'^/[a-z0-9/\-]*$');
      for (final route in routes) {
        expect(
          validPattern.hasMatch(route),
          isTrue,
          reason:
              'Route "$route" contains invalid characters (only lowercase, digits, /, - allowed)',
        );
      }
    });

    test('newly added routes exist', () {
      // Routes added during GoRouter migration
      expect(AppRoutes.accessibilitySettings, '/settings/accessibility');
      expect(AppRoutes.homeWidgetSettings, '/settings/home-widget');
      expect(AppRoutes.notificationCenter, '/notifications');
    });

    test('settings sub-routes follow /settings/ prefix', () {
      expect(AppRoutes.editProfile, startsWith('/settings/'));
      expect(AppRoutes.changePassword, startsWith('/settings/'));
      expect(AppRoutes.batteryOptimization, startsWith('/settings/'));
      expect(AppRoutes.tutorial, startsWith('/settings/'));
      expect(AppRoutes.helpCenter, startsWith('/settings/'));
      expect(AppRoutes.accessibilitySettings, startsWith('/settings/'));
      expect(AppRoutes.homeWidgetSettings, startsWith('/settings/'));
    });

    test('delivery sub-routes follow /delivery/ prefix', () {
      expect(AppRoutes.deliveryChat, startsWith('/delivery/'));
      expect(AppRoutes.deliveryRating, startsWith('/delivery/'));
      expect(AppRoutes.deliveryDocuments, startsWith('/delivery/'));
      expect(AppRoutes.deliveryScanner, startsWith('/delivery/'));
    });

    test('dashboard sub-routes follow /dashboard/ prefix', () {
      expect(AppRoutes.home, startsWith('/dashboard/'));
      expect(AppRoutes.deliveries, startsWith('/dashboard/'));
      expect(AppRoutes.statistics, startsWith('/dashboard/'));
      expect(AppRoutes.wallet, startsWith('/dashboard/'));
      expect(AppRoutes.profile, startsWith('/dashboard/'));
    });
  });
}
