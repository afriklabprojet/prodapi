import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/env_config.dart';

/// Constantes et endpoints de l'API
/// Utilise EnvConfig pour les URLs (configurables via .env)
class ApiConstants {
  // ============================================================
  // URLs - Chargées depuis .env via EnvConfig
  // ============================================================

  /// URL de base de l'API
  static String get baseUrl {
    final envUrl = EnvConfig.apiUrl;

    // En développement, adapter l'URL selon la plateforme
    if (EnvConfig.isDevelopment && envUrl.contains('localhost')) {
      return _adaptUrlForPlatform(envUrl);
    }

    return envUrl;
  }

  /// URL de stockage des fichiers
  static String get storageBaseUrl {
    final envUrl = EnvConfig.storageBaseUrl;

    if (EnvConfig.isDevelopment && envUrl.contains('localhost')) {
      return _adaptUrlForPlatform(envUrl);
    }

    return envUrl;
  }

  /// Adapte l'URL localhost pour Android emulator
  static String _adaptUrlForPlatform(String url) {
    if (kIsWeb) return url;

    if (Platform.isAndroid) {
      return url.replaceAll('localhost', '10.0.2.2');
    }

    return url;
  }

  /// Environnement actuel
  static bool get isDevelopment => EnvConfig.isDevelopment;
  static bool get isProduction => EnvConfig.isProduction;

  // ============================================================
  // ENDPOINTS - Authentication
  // ============================================================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me/update';
  static const String uploadAvatar = '/auth/avatar';
  static const String deleteAvatar = '/auth/avatar';
  static const String updatePassword = '/auth/password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify';
  static const String verifyFirebaseOtp = '/auth/verify-firebase';
  static const String socialGoogle = '/auth/social-google';
  static const String resendOtp = '/auth/resend';
  static const String firebaseToken = '/auth/firebase-token';

  // ============================================================
  // ENDPOINTS - Products
  // ============================================================
  static const String products = '/products';
  static String productDetails(int id) => '/products/$id';
  static const String searchProducts = '/products';
  static const String productsByCategory = '/products';

  // ============================================================
  // ENDPOINTS - Orders
  // ============================================================
  static const String orders = '/customer/orders';
  static String orderDetails(int id) => '/customer/orders/$id';
  static String cancelOrder(int id) => '/customer/orders/$id/cancel';
  static String rateOrder(int id) => '/customer/orders/$id/rate';
  static String productReviews(int id) => '/products/$id/reviews';

  // ============================================================
  // ENDPOINTS - Pharmacies
  // ============================================================
  static const String pharmacies = '/customer/pharmacies';
  static const String featuredPharmacies = '/customer/pharmacies/featured';
  static const String nearbyPharmacies = '/customer/pharmacies/nearby';
  static const String onDutyPharmacies = '/customer/pharmacies/on-duty';
  static String pharmacyDetails(int id) => '/customer/pharmacies/$id';

  // ============================================================
  // ENDPOINTS - Addresses
  // ============================================================
  static const String addresses = '/customer/addresses';
  static String addressDetails(int id) => '/customer/addresses/$id';
  static String setDefaultAddress(int id) => '/customer/addresses/$id/default';
  static const String addressDefault = '/customer/addresses/default';
  static const String addressLabels = '/customer/addresses/labels';

  // ============================================================
  // ENDPOINTS - Notifications
  // ============================================================
  static const String notifications = '/notifications';
  static const String updateFcmToken = '/notifications/fcm-token';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';
  static const String notificationPreferences = '/notifications/preferences';

  // ============================================================
  // ENDPOINTS - Wallet
  // ============================================================
  static const String wallet = '/customer/wallet';
  static const String walletTransactions = '/customer/wallet/transactions';
  static const String walletTopUp = '/customer/wallet/topup';
  static const String walletWithdraw = '/customer/wallet/withdraw';
  static const String walletPayOrder = '/customer/wallet/pay-order';

  // ENDPOINTS - Jeko Payments (Customer)
  static const String paymentInitiate = '/customer/payments/initiate';
  static const String paymentMethods = '/customer/payments/methods';
  static String paymentStatus(String reference) =>
      '/customer/payments/$reference/status';

  // ============================================================
  // ENDPOINTS - Prescriptions
  // ============================================================
  static const String prescriptions = '/customer/prescriptions';
  static String prescriptionDetails(int id) => '/customer/prescriptions/$id';
  static String prescriptionPay(int id) => '/customer/prescriptions/$id/pay';
  static const String prescriptionUpload = '/customer/prescriptions/upload';

  // ============================================================
  // ENDPOINTS - Loyalty
  // ============================================================
  static const String loyalty = '/customer/loyalty';
  static const String loyaltyRedeem = '/customer/loyalty/redeem';

  // ============================================================
  // ENDPOINTS - Support & FAQ
  // ============================================================
  static const String supportSettings = '/support/settings';
  static const String supportFaqCustomer = '/support/faq/customer';
  static const String validatePromoCode = '/promo-codes/validate';
  static const String pricing = '/pricing';
  static const String deliveryEstimate = '/delivery/estimate';
  static String deliveryChat(int deliveryId) =>
      '/customer/deliveries/$deliveryId/chat';

  // ============================================================
  // TIMEOUTS - Chargés depuis .env via EnvConfig
  // ============================================================
  static Duration get connectionTimeout => EnvConfig.connectionTimeout;
  static Duration get receiveTimeout => EnvConfig.receiveTimeout;
}
