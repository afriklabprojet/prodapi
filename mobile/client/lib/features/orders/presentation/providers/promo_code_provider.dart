import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/app_logger.dart';

/// État d'un code promo validé
class PromoCodeState {
  final String? code;
  final double discount;
  final String? description;
  final bool isValidating;
  final String? error;

  const PromoCodeState({
    this.code,
    this.discount = 0,
    this.description,
    this.isValidating = false,
    this.error,
  });

  bool get hasDiscount => code != null && discount > 0;

  PromoCodeState copyWith({
    String? code,
    double? discount,
    String? description,
    bool? isValidating,
    String? error,
  }) {
    return PromoCodeState(
      code: code ?? this.code,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      isValidating: isValidating ?? this.isValidating,
      error: error,
    );
  }
}

/// Provider pour la gestion du code promo pendant le checkout
final promoCodeProvider =
    StateNotifierProvider.autoDispose<PromoCodeNotifier, PromoCodeState>(
  (ref) => PromoCodeNotifier(ref),
);

class PromoCodeNotifier extends StateNotifier<PromoCodeState> {
  final Ref _ref;

  PromoCodeNotifier(this._ref) : super(const PromoCodeState());

  Future<void> validate(String code, double orderAmount) async {
    if (code.trim().isEmpty) return;

    state = state.copyWith(isValidating: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiConstants.validatePromoCode,
        data: {
          'code': code.trim(),
          'order_amount': orderAmount,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final promoData = data['data'];
        
        // Parsing sécurisé du discount
        double discount = 0.0;
        final discountValue = promoData['discount'];
        if (discountValue is num) {
          discount = discountValue.toDouble();
        } else if (discountValue is String) {
          discount = double.tryParse(discountValue) ?? 0.0;
        }
        
        state = PromoCodeState(
          code: promoData['code'],
          discount: discount,
          description: promoData['description'],
          isValidating: false,
        );
      } else {
        state = PromoCodeState(
          isValidating: false,
          error: data['message'] ?? 'Code invalide',
        );
      }
    } catch (e) {
      AppLogger.error('Promo code validation failed', error: e);
      String errorMsg = 'Code promo invalide ou expiré.';
      if (e is DioException && e.response?.data is Map) {
        errorMsg = (e.response!.data as Map)['message'] as String? ?? errorMsg;
      }
      state = PromoCodeState(isValidating: false, error: errorMsg);
    }
  }

  void clear() {
    state = const PromoCodeState();
  }
}
