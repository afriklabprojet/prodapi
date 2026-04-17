import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/safe_json_utils.dart';
import '../models/wallet_data.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(dioProvider));
});

class WalletRepository {
  final Dio _dio;

  WalletRepository(this._dio);

  /// Récupérer les données du wallet (solde, transactions, stats)
  Future<WalletData> getWalletData() async {
    // Tenter de lire le cache d'abord
    final cache = CacheService.instance;
    final cached = await cache.getCachedWallet();
    if (cached != null) {
      if (kDebugMode) debugPrint('💾 [WALLET] Serving from cache');
      return WalletData.fromJson(cached);
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '📱 [WALLET] Fetching wallet data from: ${ApiConstants.wallet}',
        );
      }
      final response = await _dio.get(ApiConstants.wallet);
      if (kDebugMode) debugPrint('✅ [WALLET] Data received successfully');
      final rawData = response.data['data'];
      final data = rawData is Map<String, dynamic>
          ? rawData
          : SafeJsonUtils.safeData(rawData);

      // Sauvegarder dans le cache
      await cache.cacheWallet(data);

      return WalletData.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WALLET] Error: $e');
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = SafeJsonUtils.safeData(e.response?.data)['message'];

        if (kDebugMode) {
          debugPrint('   Status code: $statusCode');
          debugPrint('   Message: $message');
          debugPrint(
            '   URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}',
          );
        }

        if (statusCode == 404) {
          throw Exception(
            'Endpoint wallet non trouvé. Vérifiez la configuration du serveur.',
          );
        } else if (statusCode == 403) {
          final errorCode = SafeJsonUtils.safeData(
            e.response?.data,
          )['error_code'];
          if (errorCode == 'INCOMPLETE_KYC') {
            // Retourner un wallet vide pour que l'écran charge normalement
            return const WalletData(balance: 0.0, canDeliver: false);
          }
          throw Exception(
            message ??
                'Profil coursier non trouvé. Veuillez vous connecter avec un compte livreur.',
          );
        } else if (statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else if (message != null) {
          throw Exception(message);
        }
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de charger le portefeuille.',
        ),
      );
    }
  }

  /// Vérifier si le coursier peut effectuer une livraison
  Future<Map<String, dynamic>> canDeliver() async {
    try {
      final response = await _dio.get(ApiConstants.walletCanDeliver);
      return response.data['data'];
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        throw Exception(
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
              'Profil coursier non trouvé.',
        );
      }
      throw Exception('Impossible de vérifier l\'éligibilité aux livraisons.');
    }
  }

  /// Recharger le wallet
  Future<Map<String, dynamic>> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.walletTopUp,
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'payment_reference': paymentReference,
        },
      );
      // Invalider le cache wallet après rechargement
      await CacheService.instance.invalidateWallet();
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
              'Erreur lors du rechargement',
        );
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible d\'effectuer le rechargement.',
        ),
      );
    }
  }

  /// Demander un retrait vers Mobile Money
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.walletWithdraw,
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'phone_number': phoneNumber,
        },
      );
      // Invalider le cache wallet après retrait
      await CacheService.instance.invalidateWallet();
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
              'Erreur lors de la demande de retrait',
        );
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible d\'effectuer le retrait.',
        ),
      );
    }
  }

  /// Récupérer l'historique détaillé des gains avec filtres
  /// [period]: 'all', 'today', 'week', 'month'
  /// [category]: 'all', 'delivery', 'commission', 'bonus', 'deduction', 'topup', 'withdrawal'
  Future<Map<String, dynamic>> getEarningsHistory({
    String period = 'all',
    String category = 'all',
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.walletEarningsHistory,
        queryParameters: {
          'period': period,
          'category': category,
          'page': page,
          'limit': limit,
        },
      );
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          SafeJsonUtils.safeData(e.response?.data)['message'] ??
              'Erreur lors de la récupération de l\'historique',
        );
      }
      throw Exception(
        ErrorHandler.getReadableMessage(
          e,
          defaultMessage: 'Impossible de charger l\'historique.',
        ),
      );
    }
  }
}
