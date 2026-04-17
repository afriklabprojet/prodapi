import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/pricing_entity.dart';

enum CartStatus { initial, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final List<CartItemEntity> items;
  final int? selectedPharmacyId;
  final String? selectedPharmacyName;
  final PricingConfigEntity? pricingConfig;
  final String? errorMessage;
  final double? calculatedDeliveryFee;
  final double? _deliveryDistanceKm;
  final String _paymentMode;

  const CartState({
    required this.status,
    required this.items,
    this.selectedPharmacyId,
    this.selectedPharmacyName,
    this.pricingConfig,
    this.errorMessage,
    this.calculatedDeliveryFee,
    double? deliveryDistanceKm,
    String paymentMode = 'on_delivery',
  })  : _deliveryDistanceKm = deliveryDistanceKm,
        _paymentMode = paymentMode;

  const CartState.initial()
      : status = CartStatus.initial,
        items = const [],
        selectedPharmacyId = null,
        selectedPharmacyName = null,
        pricingConfig = null,
        errorMessage = null,
        calculatedDeliveryFee = null,
        _deliveryDistanceKm = null,
        _paymentMode = 'on_delivery';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get itemCount => totalItems;

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee {
    if (calculatedDeliveryFee != null) return calculatedDeliveryFee!;
    if (pricingConfig == null) return 0.0;
    return pricingConfig!.delivery.baseFee.toDouble();
  }

  double get serviceFee {
    if (pricingConfig == null) return 0.0;
    final config = pricingConfig!.service.serviceFee;
    if (!config.enabled) return 0.0;
    final calculated = subtotal * config.percentage / 100;
    if (calculated < config.min) return config.min.toDouble();
    if (calculated > config.max) return config.max.toDouble();
    return calculated;
  }

  double get paymentFee {
    if (pricingConfig == null) return 0.0;
    final config = pricingConfig!.service.paymentFee;
    if (!config.enabled) return 0.0;
    return config.fixedFee.toDouble() + (subtotal * config.percentage / 100);
  }

  double get total => subtotal + deliveryFee + serviceFee + paymentFee;

  double get deliveryDistanceKm => _deliveryDistanceKm ?? 0;

  String get paymentMode => _paymentMode;

  bool get hasPrescriptionRequiredItems =>
      items.any((item) => item.product.requiresPrescription == true);

  List<String> get prescriptionRequiredProductNames =>
      items
          .where((item) => item.product.requiresPrescription == true)
          .map((item) => item.product.name)
          .toList();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Get a cart item by product ID
  CartItemEntity? getItem(int productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  CartState copyWith({
    CartStatus? status,
    List<CartItemEntity>? items,
    int? selectedPharmacyId,
    bool clearPharmacy = false,
    bool clearPharmacyId = false,
    String? selectedPharmacyName,
    PricingConfigEntity? pricingConfig,
    String? errorMessage,
    bool clearError = false,
    double? calculatedDeliveryFee,
    double? deliveryDistanceKm,
    bool clearDeliveryFee = false,
    String? paymentMode,
  }) {
    final shouldClearPharmacy = clearPharmacy || clearPharmacyId;
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedPharmacyId: shouldClearPharmacy
          ? null
          : (selectedPharmacyId ?? this.selectedPharmacyId),
      selectedPharmacyName: shouldClearPharmacy
          ? null
          : (selectedPharmacyName ?? this.selectedPharmacyName),
      pricingConfig: pricingConfig ?? this.pricingConfig,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      calculatedDeliveryFee: clearDeliveryFee
          ? null
          : (calculatedDeliveryFee ?? this.calculatedDeliveryFee),
      deliveryDistanceKm: clearDeliveryFee
          ? null
          : (deliveryDistanceKm ?? _deliveryDistanceKm),
      paymentMode: paymentMode ?? _paymentMode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedPharmacyId,
        selectedPharmacyName,
        pricingConfig,
        errorMessage,
        calculatedDeliveryFee,
        _deliveryDistanceKm,
        _paymentMode,
      ];
}
