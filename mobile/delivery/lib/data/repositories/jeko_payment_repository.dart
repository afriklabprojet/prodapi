import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';

final jekoPaymentRepositoryProvider = Provider<JekoPaymentRepository>((ref) {
  return JekoPaymentRepository(ref.read(dioProvider));
});

/// Méthodes de paiement JEKO disponibles
enum JekoPaymentMethod {
  wave('wave', 'Wave', 'assets/icons/wave.png'),
  orange('orange', 'Orange Money', 'assets/icons/orange_money.png'),
  mtn('mtn', 'MTN MoMo', 'assets/icons/mtn_momo.png'),
  moov('moov', 'Moov Money', 'assets/icons/moov_money.png'),
  djamo('djamo', 'Djamo', 'assets/icons/djamo.png');

  final String value;
  final String label;
  final String icon;

  const JekoPaymentMethod(this.value, this.label, this.icon);
}

/// Modèle de réponse pour l'initiation de paiement
class PaymentInitResponse {
  final String reference;
  final String redirectUrl;
  final double amount;
  final String currency;
  final String paymentMethod;

  PaymentInitResponse({
    required this.reference,
    required this.redirectUrl,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
  });

  factory PaymentInitResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitResponse(
      reference: json['reference'] ?? '',
      redirectUrl: json['redirect_url'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}

/// Modèle pour le statut de paiement
class PaymentStatusResponse {
  final String reference;
  final String status;
  final String statusLabel;
  final double amount;
  final String currency;
  final String paymentMethod;
  final bool isFinal;
  final String? completedAt;
  final String? errorMessage;

  PaymentStatusResponse({
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.isFinal,
    this.completedAt,
    this.errorMessage,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      reference: json['reference'] ?? '',
      status: json['payment_status'] ?? 'pending',
      statusLabel: json['payment_status_label'] ?? 'En attente',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      paymentMethod: json['payment_method'] ?? '',
      isFinal: json['is_final'] ?? false,
      completedAt: json['completed_at'],
      errorMessage: json['error_message'],
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed' || status == 'expired';
  bool get isPending => status == 'pending' || status == 'processing';
}

/// Repository pour les paiements JEKO
class JekoPaymentRepository {
  final Dio _dio;

  JekoPaymentRepository(this._dio);

  /// Initier un rechargement de wallet via JEKO
  Future<PaymentInitResponse> initiateWalletTopup({
    required double amount,
    required JekoPaymentMethod method,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.paymentsInitiate,
        data: {
          'type': 'wallet_topup',
          'amount': amount,
          'payment_method': method.value,
        },
        options: Options(
          // Utiliser les timeouts spécifiques pour les paiements
          sendTimeout: AppConfig.paymentConnectionTimeout,
          receiveTimeout: AppConfig.paymentReceiveTimeout,
        ),
      );

      final data = response.data;

      // L'API peut retourner soit { status: 'success', data: {...} }
      // soit { success: true, redirect_url: '...', ... } directement
      final isSuccess = data['status'] == 'success' || data['success'] == true;

      if (isSuccess) {
        // Cas 1: { status: 'success', data: {...} }
        if (data['data'] != null) {
          return PaymentInitResponse.fromJson(data['data']);
        }
        // Cas 2: { success: true, redirect_url: '...', ... } - données à la racine
        return PaymentInitResponse.fromJson(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de l\'initiation du paiement',
        );
      }
    } on DioException catch (e) {
      // Message d'erreur plus clair selon le type d'erreur
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message =
            'Le serveur met trop de temps à répondre. Veuillez réessayer.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else {
        message =
            SafeJsonUtils.safeData(e.response?.data)['message'] ??
            'Erreur de connexion';
      }
      throw Exception(message);
    }
  }

  /// Initier un paiement de commande via JEKO
  Future<PaymentInitResponse> initiateOrderPayment({
    required int orderId,
    required JekoPaymentMethod method,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.paymentsInitiate,
        data: {
          'type': 'order',
          'order_id': orderId,
          'payment_method': method.value,
        },
        options: Options(
          // Utiliser les timeouts spécifiques pour les paiements
          sendTimeout: AppConfig.paymentConnectionTimeout,
          receiveTimeout: AppConfig.paymentReceiveTimeout,
        ),
      );

      final data = response.data;
      final isSuccess = data['status'] == 'success' || data['success'] == true;

      if (isSuccess) {
        if (data['data'] != null) {
          return PaymentInitResponse.fromJson(data['data']);
        }
        return PaymentInitResponse.fromJson(data);
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de l\'initiation du paiement',
        );
      }
    } on DioException catch (e) {
      // Message d'erreur plus clair selon le type d'erreur
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message =
            'Le serveur met trop de temps à répondre. Veuillez réessayer.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else {
        message =
            SafeJsonUtils.safeData(e.response?.data)['message'] ??
            'Erreur de connexion';
      }
      throw Exception(message);
    }
  }

  /// Vérifier le statut d'un paiement
  Future<PaymentStatusResponse> checkPaymentStatus(String reference) async {
    try {
      final response = await _dio.get(ApiConstants.paymentStatus(reference));

      final data = response.data;
      final isSuccess = data['status'] == 'success' || data['success'] == true;

      if (isSuccess) {
        if (data['data'] != null) {
          return PaymentStatusResponse.fromJson(data['data']);
        }
        return PaymentStatusResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la vérification');
      }
    } on DioException catch (e) {
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Erreur de connexion';
      throw Exception(message);
    }
  }

  /// Obtenir les méthodes de paiement disponibles depuis l'API
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _dio.get(ApiConstants.paymentsMethods);

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      // Retourner les méthodes par défaut en cas d'erreur
      return JekoPaymentMethod.values
          .map((m) => {'value': m.value, 'label': m.label, 'icon': m.icon})
          .toList();
    }
  }

  /// Obtenir l'historique des paiements
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.paymentsHistory,
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de charger l\'historique des paiements.',
        ),
      );
    }
  }

  /// Annuler un paiement en attente
  Future<void> cancelPayment(String reference) async {
    try {
      final response = await _dio.post(ApiConstants.cancelPayment(reference));

      if (response.data['status'] != 'success') {
        throw Exception(
          response.data['message'] ?? 'Impossible d\'annuler le paiement',
        );
      }
    } on DioException catch (e) {
      final message =
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
          'Impossible d\'annuler le paiement';
      throw Exception(message);
    }
  }
}
