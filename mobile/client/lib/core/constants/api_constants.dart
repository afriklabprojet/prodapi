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
  static const String resendOtp = '/auth/resend';

  // ============================================================
  // ENDPOINTS - Products
  // ============================================================
  static const String products = '/products';
  static String productDetails(int id) => '/products/$id';
  static const String searchProducts = '/products';

  // ============================================================
  // ENDPOINTS - Orders
  // ============================================================
  static const String orders = '/customer/orders';
  static String orderDetails(int id) => '/customer/orders/$id';
  static String cancelOrder(int id) => '/customer/orders/$id/cancel';

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

  // ============================================================
  // ENDPOINTS - Notifications
  // ============================================================
  static const String notifications = '/notifications';
  static const String updateFcmToken = '/notifications/fcm-token';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // ============================================================
  // ENDPOINTS - Support & FAQ
  // ============================================================
  static const String supportFaqCustomer = '/support/faq/customer';

  // ============================================================
  // TIMEOUTS - Chargés depuis .env via EnvConfig
  // ============================================================
  static Duration get connectionTimeout => EnvConfig.connectionTimeout;
  static Duration get receiveTimeout => EnvConfig.receiveTimeout;
}
