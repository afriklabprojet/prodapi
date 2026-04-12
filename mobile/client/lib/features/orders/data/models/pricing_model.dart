import '../../domain/entities/pricing_entity.dart';

/// Model pour la configuration de tarification (Data Layer)
/// Responsabilité: sérialisation/désérialisation JSON + mapping vers Entity
class PricingConfigModel {
  final DeliveryPricingModel delivery;
  final ServicePricingModel service;
  final PaymentModesModel paymentModes;

  PricingConfigModel({
    required this.delivery,
    required this.service,
    required this.paymentModes,
  });

  factory PricingConfigModel.fromJson(Map<String, dynamic> json) {
    return PricingConfigModel(
      delivery: DeliveryPricingModel.fromJson(json['delivery'] ?? {}),
      service: ServicePricingModel.fromJson(json['service'] ?? {}),
      paymentModes: PaymentModesModel.fromJson(json['payment_modes'] ?? {}),
    );
  }

  factory PricingConfigModel.defaults() {
    return PricingConfigModel(
      delivery: DeliveryPricingModel.defaults(),
      service: ServicePricingModel.defaults(),
      paymentModes: PaymentModesModel.defaults(),
    );
  }

  /// Mapper vers Entity (Domain Layer)
  PricingConfigEntity toEntity() {
    return PricingConfigEntity(
      delivery: delivery.toEntity(),
      service: service.toEntity(),
      paymentModes: paymentModes.toEntity(),
    );
  }
}

/// Model pour tarification livraison
class DeliveryPricingModel {
  final int baseFee;
  final int feePerKm;
  final int minFee;
  final int maxFee;

  DeliveryPricingModel({
    required this.baseFee,
    required this.feePerKm,
    required this.minFee,
    required this.maxFee,
  });

  factory DeliveryPricingModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPricingModel(
      baseFee: (json['base_fee'] as num?)?.toInt() ?? 200,
      feePerKm: (json['fee_per_km'] as num?)?.toInt() ?? 100,
      minFee: (json['min_fee'] as num?)?.toInt() ?? 300,
      maxFee: (json['max_fee'] as num?)?.toInt() ?? 5000,
    );
  }

  factory DeliveryPricingModel.defaults() {
    return DeliveryPricingModel(
      baseFee: 200,
      feePerKm: 100,
      minFee: 300,
      maxFee: 5000,
    );
  }

  DeliveryPricingEntity toEntity() {
    return DeliveryPricingEntity(
      baseFee: baseFee,
      feePerKm: feePerKm,
      minFee: minFee,
      maxFee: maxFee,
    );
  }
}

/// Model pour tarification service et paiement
class ServicePricingModel {
  final ServiceFeeConfigModel serviceFee;
  final PaymentFeeConfigModel paymentFee;

  ServicePricingModel({
    required this.serviceFee,
    required this.paymentFee,
  });

  factory ServicePricingModel.fromJson(Map<String, dynamic> json) {
    return ServicePricingModel(
      serviceFee: ServiceFeeConfigModel.fromJson(json['service_fee'] ?? {}),
      paymentFee: PaymentFeeConfigModel.fromJson(json['payment_fee'] ?? {}),
    );
  }

  factory ServicePricingModel.defaults() {
    return ServicePricingModel(
      serviceFee: ServiceFeeConfigModel.defaults(),
      paymentFee: PaymentFeeConfigModel.defaults(),
    );
  }

  ServicePricingEntity toEntity() {
    return ServicePricingEntity(
      serviceFee: serviceFee.toEntity(),
      paymentFee: paymentFee.toEntity(),
    );
  }
}

/// Model pour frais de service
class ServiceFeeConfigModel {
  final bool enabled;
  final double percentage;
  final int min;
  final int max;

  ServiceFeeConfigModel({
    required this.enabled,
    required this.percentage,
    required this.min,
    required this.max,
  });

  factory ServiceFeeConfigModel.fromJson(Map<String, dynamic> json) {
    return ServiceFeeConfigModel(
      enabled: json['enabled'] as bool? ?? true,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 3.0,
      min: (json['min'] as num?)?.toInt() ?? 100,
      max: (json['max'] as num?)?.toInt() ?? 2000,
    );
  }

  factory ServiceFeeConfigModel.defaults() {
    return ServiceFeeConfigModel(
      enabled: true,
      percentage: 3,
      min: 100,
      max: 2000,
    );
  }

  ServiceFeeConfigEntity toEntity() {
    return ServiceFeeConfigEntity(
      enabled: enabled,
      percentage: percentage,
      min: min,
      max: max,
    );
  }
}

/// Model pour frais de paiement
class PaymentFeeConfigModel {
  final bool enabled;
  final int fixedFee;
  final double percentage;

  PaymentFeeConfigModel({
    required this.enabled,
    required this.fixedFee,
    required this.percentage,
  });

  factory PaymentFeeConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentFeeConfigModel(
      enabled: json['enabled'] as bool? ?? true,
      fixedFee: (json['fixed_fee'] as num?)?.toInt() ?? 50,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 1.5,
    );
  }

  factory PaymentFeeConfigModel.defaults() {
    return PaymentFeeConfigModel(
      enabled: true,
      fixedFee: 50,
      percentage: 1.5,
    );
  }

  PaymentFeeConfigEntity toEntity() {
    return PaymentFeeConfigEntity(
      enabled: enabled,
      fixedFee: fixedFee,
      percentage: percentage,
    );
  }
}

/// Model pour modes de paiement
class PaymentModesModel {
  final bool platformEnabled;
  final bool cashEnabled;
  final bool walletEnabled;

  PaymentModesModel({
    required this.platformEnabled,
    required this.cashEnabled,
    required this.walletEnabled,
  });

  factory PaymentModesModel.fromJson(Map<String, dynamic> json) {
    return PaymentModesModel(
      platformEnabled: json['platform'] as bool? ?? true,
      cashEnabled: json['cash'] as bool? ?? false,
      walletEnabled: json['wallet'] as bool? ?? true,
    );
  }

  factory PaymentModesModel.defaults() {
    return PaymentModesModel(
      platformEnabled: true,
      cashEnabled: false,
      walletEnabled: true,
    );
  }

  PaymentModesEntity toEntity() {
    return PaymentModesEntity(
      platformEnabled: platformEnabled,
      cashEnabled: cashEnabled,
      walletEnabled: walletEnabled,
    );
  }
}

/// Model pour résultat calcul frais
class PricingCalculationModel {
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final int paymentFee;
  final int totalAmount;
  final int pharmacyAmount;

  PricingCalculationModel({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.paymentFee,
    required this.totalAmount,
    required this.pharmacyAmount,
  });

  factory PricingCalculationModel.fromJson(Map<String, dynamic> json) {
    return PricingCalculationModel(
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
      serviceFee: (json['service_fee'] as num?)?.toInt() ?? 0,
      paymentFee: (json['payment_fee'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      pharmacyAmount: (json['pharmacy_amount'] as num?)?.toInt() ?? 0,
    );
  }

  PricingCalculationEntity toEntity() {
    return PricingCalculationEntity(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      paymentFee: paymentFee,
      totalAmount: totalAmount,
      pharmacyAmount: pharmacyAmount,
    );
  }
}

/// Alias pour compatibilité
typedef PricingModel = PricingConfigModel;
