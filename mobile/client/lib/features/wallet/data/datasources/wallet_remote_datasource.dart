import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSource(this.apiClient);

  Future<WalletModel> getWallet() async {
    final response = await apiClient.get(ApiConstants.wallet);
    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return WalletModel.fromJson(rawData);
  }

  Future<List<WalletTransactionModel>> getTransactions({
    int limit = AppConstants.walletPageSize,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (category != null) queryParams['category'] = category;

    final response = await apiClient.get(
      ApiConstants.walletTransactions,
      queryParameters: queryParams,
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! List) return [];
    return rawData
        .map((json) =>
            WalletTransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Initier un rechargement via Jeko (retourne redirect_url + reference)
  Future<Map<String, dynamic>> initiateTopUp({
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await apiClient.post(
      ApiConstants.paymentInitiate,
      data: {
        'type': 'wallet_topup',
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return rawData;
  }

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String reference) async {
    final response = await apiClient.get(
      ApiConstants.paymentStatus(reference),
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return rawData;
  }

  Future<Map<String, dynamic>> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    final response = await apiClient.post(
      ApiConstants.walletTopUp,
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_reference': ?paymentReference,
      },
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return rawData;
  }

  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    final response = await apiClient.post(
      ApiConstants.walletWithdraw,
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'phone_number': phoneNumber,
      },
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return rawData;
  }

  Future<Map<String, dynamic>> payOrder({
    required double amount,
    required String orderReference,
  }) async {
    final response = await apiClient.post(
      ApiConstants.walletPayOrder,
      data: {
        'amount': amount,
        'order_reference': orderReference,
      },
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    return rawData;
  }
}
