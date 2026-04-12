import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/router/route_names.dart';

void main() {
  group('AppRoutes', () {
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
        expect(route.startsWith('/'), true, reason: 'Route "$route" must start with /');
      }
    });

    test('no duplicate routes', () {
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
      expect(routes.toSet().length, routes.length);
    });

    test('dashboard sub-routes follow /dashboard/ pattern', () {
      expect(AppRoutes.home, startsWith('/dashboard/'));
      expect(AppRoutes.deliveries, startsWith('/dashboard/'));
      expect(AppRoutes.statistics, startsWith('/dashboard/'));
      expect(AppRoutes.wallet, startsWith('/dashboard/'));
      expect(AppRoutes.profile, startsWith('/dashboard/'));
    });

    test('settings sub-routes follow /settings/ pattern', () {
      expect(AppRoutes.editProfile, startsWith('/settings/'));
      expect(AppRoutes.changePassword, startsWith('/settings/'));
      expect(AppRoutes.batteryOptimization, startsWith('/settings/'));
      expect(AppRoutes.tutorial, startsWith('/settings/'));
      expect(AppRoutes.helpCenter, startsWith('/settings/'));
      expect(AppRoutes.accessibilitySettings, startsWith('/settings/'));
      expect(AppRoutes.homeWidgetSettings, startsWith('/settings/'));
    });

    test('delivery sub-routes follow /delivery/ pattern', () {
      expect(AppRoutes.deliveryChat, startsWith('/delivery/'));
      expect(AppRoutes.deliveryRating, startsWith('/delivery/'));
      expect(AppRoutes.deliveryDocuments, startsWith('/delivery/'));
      expect(AppRoutes.deliveryScanner, startsWith('/delivery/'));
    });

    test('support sub-routes follow /support/ pattern', () {
      expect(AppRoutes.createTicket, startsWith('/support/'));
      expect(AppRoutes.supportChat, startsWith('/support/'));
    });

    test('specific route values', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.notificationCenter, '/notifications');
    });
  });
}
