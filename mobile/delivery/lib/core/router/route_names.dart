/// Route path constants for the delivery app.
abstract final class AppRoutes {
  // ── Auth / Onboarding ──
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otpVerification = '/otp-verification';

  // ── Status gates ──
  static const pendingApproval = '/pending-approval';
  static const kycResubmission = '/kyc-resubmission';
  static const livenessVerification = '/liveness-verification';

  // ── Dashboard (shell with bottom nav) ──
  static const dashboard = '/dashboard';
  static const home = '/dashboard/home';
  static const deliveries = '/dashboard/deliveries';
  static const statistics = '/dashboard/statistics';
  static const wallet = '/dashboard/wallet';
  static const profile = '/dashboard/profile';

  // ── Delivery ──
  static const deliveryDetails = '/delivery';
  static const deliveryChat = '/delivery/chat';
  static const deliveryRating = '/delivery/rating';
  static const deliveryDocuments = '/delivery/documents';
  static const deliveryScanner = '/delivery/scanner';

  // ── Settings ──
  static const settings = '/settings';
  static const editProfile = '/settings/edit-profile';
  static const changePassword = '/settings/change-password';
  static const batteryOptimization = '/settings/battery';
  static const tutorial = '/settings/tutorial';
  static const helpCenter = '/settings/help';
  static const accessibilitySettings = '/settings/accessibility';
  static const homeWidgetSettings = '/settings/home-widget';

  // ── Support ──
  static const support = '/support';
  static const createTicket = '/support/create';
  static const supportChat = '/support/chat';

  // ── Features ──
  static const gamification = '/gamification';
  static const challenges = '/gamification/challenges';
  static const historyExport = '/history-export';
  static const batchDeliveries = '/batch-deliveries';
  static const multiRoute = '/multi-route';
  static const paymentStatus = '/payment-status';
  static const paymentSuccess = '/payment/success';
  static const paymentError = '/payment/error';
  static const conversations = '/conversations';
  static const notificationCenter = '/notifications';
  static const shifts = '/shifts';
}
