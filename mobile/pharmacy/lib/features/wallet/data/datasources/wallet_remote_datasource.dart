import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';

/// Interface abstraite pour la source de données wallet
abstract class WalletRemoteDataSource {
  /// Récupère les données du portefeuille
  Future<Map<String, dynamic>> getWalletData();

  /// Récupère les statistiques par période
  Future<Map<String, dynamic>> getStatsByPeriod(String period);

  /// Demande de retrait
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    String? accountDetails,
    String? phone,
    String? pin,
  });

  /// Enregistrer les informations bancaires
  Future<void> saveBankInfo({
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? iban,
  });

  /// Enregistrer les informations Mobile Money
  Future<void> saveMobileMoneyInfo({
    required String operator,
    required String phoneNumber,
    required String accountName,
    bool isPrimary = true,
  });

  /// Récupérer les paramètres de seuil de retrait
  Future<Map<String, dynamic>> getWithdrawalSettings();

  /// Configurer le seuil de retrait automatique
  Future<Map<String, dynamic>> setWithdrawalThreshold({
    required double threshold,
    required bool autoWithdraw,
  });

  /// Exporter les transactions
  Future<Map<String, dynamic>> exportTransactions({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Récupérer les informations de paiement
  Future<Map<String, dynamic>> getPaymentInfo();

  /// Configurer le code PIN de retrait (première fois)
  Future<Map<String, dynamic>> setWithdrawalPin(String pin);

  /// Modifier le code PIN de retrait
  Future<Map<String, dynamic>> changeWithdrawalPin({
    required String currentPin,
    required String newPin,
  });

  /// Demander la réinitialisation du PIN (envoie OTP)
  Future<Map<String, dynamic>> requestPinReset();

  /// Confirmer la réinitialisation du PIN avec OTP
  Future<Map<String, dynamic>> confirmPinReset({
    required String otp,
    required String newPin,
  });
}

/// Implémentation utilisant ApiClient
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient _apiClient;
  static const String _endpoint = '/pharmacy/wallet';

  WalletRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> getWalletData() async {
    final response = await _apiClient.get(_endpoint);
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getStatsByPeriod(String period) async {
    final response = await _apiClient.get(
      '$_endpoint/stats',
      queryParameters: {'period': period},
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    String? accountDetails,
    String? phone,
    String? pin,
  }) async {
    final response = await _apiClient.post(
      '$_endpoint/withdraw',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'account_details': accountDetails,
        'phone': phone,
        'pin': pin,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> saveBankInfo({
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? iban,
  }) async {
    await _apiClient.post(
      '$_endpoint/bank-info',
      data: {
        'bank_name': bankName,
        'holder_name': holderName,
        'account_number': accountNumber,
        'iban': iban,
      },
    );
  }

  @override
  Future<void> saveMobileMoneyInfo({
    required String operator,
    required String phoneNumber,
    required String accountName,
    bool isPrimary = true,
  }) async {
    await _apiClient.post(
      '$_endpoint/mobile-money',
      data: {
        'operator': operator,
        'phone_number': phoneNumber,
        'account_name': accountName,
        'is_primary': isPrimary,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getWithdrawalSettings() async {
    final response = await _apiClient.get('$_endpoint/threshold');
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> setWithdrawalThreshold({
    required double threshold,
    required bool autoWithdraw,
  }) async {
    final response = await _apiClient.post(
      '$_endpoint/threshold',
      data: {'threshold': threshold, 'auto_withdraw': autoWithdraw},
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> exportTransactions({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiClient.get(
      '$_endpoint/export',
      queryParameters: {
        'format': format,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      },
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getPaymentInfo() async {
    final response = await _apiClient.get('$_endpoint/payment-info');
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> setWithdrawalPin(String pin) async {
    final response = await _apiClient.post(
      '$_endpoint/pin/set',
      data: {'pin': pin, 'pin_confirmation': pin},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> changeWithdrawalPin({
    required String currentPin,
    required String newPin,
  }) async {
    final response = await _apiClient.post(
      '$_endpoint/pin/change',
      data: {
        'current_pin': currentPin,
        'new_pin': newPin,
        'new_pin_confirmation': newPin,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> requestPinReset() async {
    final response = await _apiClient.post('$_endpoint/pin/reset-request');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> confirmPinReset({
    required String otp,
    required String newPin,
  }) async {
    final response = await _apiClient.post(
      '$_endpoint/pin/reset-confirm',
      data: {'otp': otp, 'new_pin': newPin, 'new_pin_confirmation': newPin},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Extract data from API response
  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] != null &&
          responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    throw Exception('Format de réponse invalide');
  }
}

/// Provider pour WalletRemoteDataSource
final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRemoteDataSourceImpl(apiClient: apiClient);
});
