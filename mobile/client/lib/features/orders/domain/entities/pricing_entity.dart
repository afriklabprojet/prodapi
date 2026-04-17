import 'package:equatable/equatable.dart';

/// Entité de configuration de tarification
class PricingConfigEntity extends Equatable {
  final DeliveryPricingEntity delivery;
  final ServicePricingEntity service;
  final PaymentModesEntity paymentModes;

  const PricingConfigEntity({
    required this.delivery,
    required this.service,
    this.paymentModes = const PaymentModesEntity(),
  });

  @override
  List<Object?> get props => [delivery, service, paymentModes];
}

/// Pricing livraison
class DeliveryPricingEntity extends Equatable {
  final int baseFee;
  final int feePerKm;
  final int minFee;
  final int maxFee;

  const DeliveryPricingEntity({
    required this.baseFee,
    required this.feePerKm,
    required this.minFee,
    required this.maxFee,
  });

  @override
  List<Object?> get props => [baseFee, feePerKm, minFee, maxFee];
}

/// Pricing service
class ServicePricingEntity extends Equatable {
  final ServiceFeeConfigEntity serviceFee;
  final PaymentFeeConfigEntity paymentFee;

  const ServicePricingEntity({
    required this.serviceFee,
    required this.paymentFee,
  });

  @override
  List<Object?> get props => [serviceFee, paymentFee];
}

/// Config frais de service
class ServiceFeeConfigEntity extends Equatable {
  final bool enabled;
  final double percentage;
  final int min;
  final int max;

  const ServiceFeeConfigEntity({
    required this.enabled,
    required this.percentage,
    required this.min,
    required this.max,
  });

  @override
  List<Object?> get props => [enabled, percentage, min, max];
}

/// Config frais de paiement
class PaymentFeeConfigEntity extends Equatable {
  final bool enabled;
  final int fixedFee;
  final double percentage;

  const PaymentFeeConfigEntity({
    required this.enabled,
    required this.fixedFee,
    required this.percentage,
  });

  @override
  List<Object?> get props => [enabled, fixedFee, percentage];
}

/// Config modes de paiement activés (configurable depuis le dashboard admin)
class PaymentModesEntity extends Equatable {
  final bool platformEnabled;
  final bool cashEnabled;
  final bool walletEnabled;

  const PaymentModesEntity({
    this.platformEnabled = true,
    this.cashEnabled = false,
    this.walletEnabled = true,
  });

  @override
  List<Object?> get props => [platformEnabled, cashEnabled, walletEnabled];
}

/// Résultat de calcul de tarification
class PricingCalculationEntity extends Equatable {
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final int paymentFee;
  final int totalAmount;
  final int pharmacyAmount;

  const PricingCalculationEntity({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.paymentFee,
    required this.totalAmount,
    required this.pharmacyAmount,
  });

  @override
  List<Object?> get props => [subtotal, deliveryFee, serviceFee, paymentFee, totalAmount, pharmacyAmount];
}
