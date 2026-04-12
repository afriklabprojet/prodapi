// ...existing code...
import '../config/app_config.dart';

class ApiConstants {
  /// Base URL - utilise la configuration centralisée
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String registerCourier = '/auth/register/courier';
  static const String updatePassword = '/auth/password';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify';
  static const String resendOtp = '/auth/resend';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  // updateProfile: utiliser updateMe ('/auth/me/update') à la place

  // Courier
  static const String profile = '/courier/profile';
  static const String updateCourierProfile = '/courier/profile/update';
  static const String availability = '/courier/availability/toggle';
  static const String location = '/courier/location/update';
  static const String deliveries = '/courier/deliveries';
  static const String wallet = '/courier/wallet';
  static const String walletTopUp = '/courier/wallet/topup';
  static const String walletWithdraw = '/courier/wallet/withdraw';
  static const String walletCanDeliver = '/courier/wallet/can-deliver';
  static const String walletEarningsHistory =
      '/courier/wallet/earnings-history';

  // Statistics
  static const String statistics = '/courier/statistics';
  static const String leaderboard = '/courier/statistics/leaderboard';

  // Challenges & Bonuses
  static const String challenges = '/courier/challenges';
  static const String bonuses = '/courier/bonuses';

  static String acceptDelivery(int id) => '/courier/deliveries/$id/accept';
  static String deliveryShow(int id) => '/courier/deliveries/$id';
  static String pickupDelivery(int id) => '/courier/deliveries/$id/pickup';
  static String completeDelivery(int id) => '/courier/deliveries/$id/deliver';
  static String rejectDelivery(int id) => '/courier/deliveries/$id/reject';
  static String rateCustomer(int deliveryId) =>
      '/courier/deliveries/$deliveryId/rate-customer';

  // Batch deliveries
  static const String batchAcceptDeliveries =
      '/courier/deliveries/batch-accept';
  static const String deliveriesRoute = '/courier/deliveries/route';

  static String messages(int orderId) => '/courier/orders/$orderId/messages';

  // JEKO Payments
  static const String paymentsInitiate = '/courier/payments/initiate';
  static const String paymentsMethods = '/courier/payments/methods';
  static const String paymentsHistory = '/courier/payments';
  static String paymentStatus(String reference) =>
      '/courier/payments/$reference/status';
  static String cancelPayment(String reference) =>
      '/courier/payments/$reference/cancel';

  // Auth - Profile updates
  static const String updateMe = '/auth/me/update';
  static const String uploadAvatar = '/auth/avatar';
  static const String deleteAvatar = '/auth/avatar';

  // Challenges & Bonuses (dynamic)
  static String claimChallenge(int challengeId) =>
      '/courier/challenges/$challengeId/claim';
  static const String calculateBonus = '/courier/bonuses/calculate';

  // Liveness (KYC biometric verification)
  static const String livenessStart = '/liveness/start';
  static const String livenessValidate = '/liveness/validate';
  static const String livenessValidateFile = '/liveness/validate/file';
  static String livenessStatus(String sessionId) =>
      '/liveness/status/$sessionId';
  static String livenessCancel(String sessionId) =>
      '/liveness/cancel/$sessionId';
  static String livenessScore(String sessionId) => '/liveness/score/$sessionId';
  static const String livenessHistory = '/liveness/history';

  // Support
  static const String supportTickets = '/support/tickets';
  static const String supportTicketsStats = '/support/tickets/stats';
  static const String supportFaqCourier = '/support/faq/courier';
  static String supportTicketDetail(int id) => '/support/tickets/$id';
  static String supportTicketMessages(int id) =>
      '/support/tickets/$id/messages';
  static String supportTicketResolve(int id) => '/support/tickets/$id/resolve';
  static String supportTicketClose(int id) => '/support/tickets/$id/close';
}
