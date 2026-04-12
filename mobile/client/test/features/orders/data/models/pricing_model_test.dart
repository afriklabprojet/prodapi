import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/data/models/pricing_model.dart';
import 'package:drpharma_client/features/orders/domain/entities/pricing_entity.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // DeliveryPricingModel
  // ────────────────────────────────────────────────────────────────────────────
  group('DeliveryPricingModel', () {
    test('fromJson parses all fields', () {
      final model = DeliveryPricingModel.fromJson(<String, dynamic>{
        'base_fee': 500,
        'fee_per_km': 150,
        'min_fee': 400,
        'max_fee': 8000,
      });
      expect(model.baseFee, 500);
      expect(model.feePerKm, 150);
      expect(model.minFee, 400);
      expect(model.maxFee, 8000);
    });

    test('fromJson defaults when fields absent', () {
      final model = DeliveryPricingModel.fromJson(<String, dynamic>{});
      expect(model.baseFee, 200);
      expect(model.feePerKm, 100);
      expect(model.minFee, 300);
      expect(model.maxFee, 5000);
    });

    test('defaults() factory uses hardcoded defaults', () {
      final model = DeliveryPricingModel.defaults();
      expect(model.baseFee, 200);
      expect(model.feePerKm, 100);
      expect(model.minFee, 300);
      expect(model.maxFee, 5000);
    });

    test('toEntity returns DeliveryPricingEntity', () {
      expect(
        DeliveryPricingModel.defaults().toEntity(),
        isA<DeliveryPricingEntity>(),
      );
    });

    test('toEntity maps all fields', () {
      final entity = DeliveryPricingModel.fromJson(<String, dynamic>{
        'base_fee': 300,
        'fee_per_km': 120,
        'min_fee': 350,
        'max_fee': 6000,
      }).toEntity();
      expect(entity.baseFee, 300);
      expect(entity.feePerKm, 120);
      expect(entity.minFee, 350);
      expect(entity.maxFee, 6000);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // ServiceFeeConfigModel
  // ────────────────────────────────────────────────────────────────────────────
  group('ServiceFeeConfigModel', () {
    test('fromJson parses all fields', () {
      final model = ServiceFeeConfigModel.fromJson(<String, dynamic>{
        'enabled': false,
        'percentage': 5.0,
        'min': 200,
        'max': 3000,
      });
      expect(model.enabled, isFalse);
      expect(model.percentage, 5.0);
      expect(model.min, 200);
      expect(model.max, 3000);
    });

    test('fromJson defaults when absent', () {
      final model = ServiceFeeConfigModel.fromJson(<String, dynamic>{});
      expect(model.enabled, isTrue);
      expect(model.percentage, 3.0);
      expect(model.min, 100);
      expect(model.max, 2000);
    });

    test('defaults() factory', () {
      final model = ServiceFeeConfigModel.defaults();
      expect(model.enabled, isTrue);
      expect(model.percentage, 3.0);
    });

    test('toEntity maps', () {
      final entity = ServiceFeeConfigModel.defaults().toEntity();
      expect(entity, isA<ServiceFeeConfigEntity>());
      expect(entity.percentage, 3.0);
      expect(entity.enabled, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PaymentFeeConfigModel
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentFeeConfigModel', () {
    test('fromJson parses all fields', () {
      final model = PaymentFeeConfigModel.fromJson(<String, dynamic>{
        'enabled': false,
        'fixed_fee': 75,
        'percentage': 2.5,
      });
      expect(model.enabled, isFalse);
      expect(model.fixedFee, 75);
      expect(model.percentage, 2.5);
    });

    test('fromJson defaults', () {
      final model = PaymentFeeConfigModel.fromJson(<String, dynamic>{});
      expect(model.enabled, isTrue);
      expect(model.fixedFee, 50);
      expect(model.percentage, 1.5);
    });

    test('toEntity maps all fields', () {
      final entity = PaymentFeeConfigModel.defaults().toEntity();
      expect(entity.fixedFee, 50);
      expect(entity.percentage, 1.5);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PaymentModesModel
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentModesModel', () {
    test('fromJson parses all fields', () {
      final model = PaymentModesModel.fromJson(<String, dynamic>{
        'platform': false,
        'cash': true,
        'wallet': false,
      });
      expect(model.platformEnabled, isFalse);
      expect(model.cashEnabled, isTrue);
      expect(model.walletEnabled, isFalse);
    });

    test('fromJson defaults', () {
      final model = PaymentModesModel.fromJson(<String, dynamic>{});
      expect(model.platformEnabled, isTrue);
      expect(model.cashEnabled, isFalse);
      expect(model.walletEnabled, isTrue);
    });

    test('defaults() factory', () {
      final model = PaymentModesModel.defaults();
      expect(model.platformEnabled, isTrue);
      expect(model.cashEnabled, isFalse);
      expect(model.walletEnabled, isTrue);
    });

    test('toEntity maps fields', () {
      final entity = PaymentModesModel.fromJson(<String, dynamic>{
        'platform': true,
        'cash': true,
        'wallet': false,
      }).toEntity();
      expect(entity.cashEnabled, isTrue);
      expect(entity.walletEnabled, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PricingConfigModel (full config)
  // ────────────────────────────────────────────────────────────────────────────
  group('PricingConfigModel', () {
    final fullJson = <String, dynamic>{
      'delivery': <String, dynamic>{
        'base_fee': 300,
        'fee_per_km': 100,
        'min_fee': 300,
        'max_fee': 5000,
      },
      'service': <String, dynamic>{
        'service_fee': <String, dynamic>{
          'enabled': true,
          'percentage': 3.0,
          'min': 100,
          'max': 2000,
        },
        'payment_fee': <String, dynamic>{
          'enabled': true,
          'fixed_fee': 50,
          'percentage': 1.5,
        },
      },
      'payment_modes': <String, dynamic>{
        'platform': true,
        'cash': false,
        'wallet': true,
      },
    };

    test('fromJson parses nested delivery', () {
      final model = PricingConfigModel.fromJson(fullJson);
      expect(model.delivery.baseFee, 300);
    });

    test('fromJson parses nested service', () {
      final model = PricingConfigModel.fromJson(fullJson);
      expect(model.service.serviceFee.enabled, isTrue);
      expect(model.service.paymentFee.fixedFee, 50);
    });

    test('fromJson parses payment_modes', () {
      final model = PricingConfigModel.fromJson(fullJson);
      expect(model.paymentModes.platformEnabled, isTrue);
      expect(model.paymentModes.cashEnabled, isFalse);
    });

    test('fromJson with empty json uses defaults', () {
      final model = PricingConfigModel.fromJson(<String, dynamic>{});
      expect(model.delivery.baseFee, 200);
      expect(model.service.serviceFee.percentage, 3.0);
      expect(model.paymentModes.walletEnabled, isTrue);
    });

    test('defaults() factory', () {
      final model = PricingConfigModel.defaults();
      expect(model.delivery.minFee, 300);
      expect(model.paymentModes.cashEnabled, isFalse);
    });

    test('toEntity returns PricingConfigEntity', () {
      expect(
        PricingConfigModel.defaults().toEntity(),
        isA<PricingConfigEntity>(),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PricingCalculationModel
  // ────────────────────────────────────────────────────────────────────────────
  group('PricingCalculationModel', () {
    test('fromJson parses all fields', () {
      final model = PricingCalculationModel.fromJson(<String, dynamic>{
        'subtotal': 5000,
        'delivery_fee': 500,
        'service_fee': 150,
        'payment_fee': 75,
        'total_amount': 5725,
        'pharmacy_amount': 4850,
      });
      expect(model.subtotal, 5000);
      expect(model.deliveryFee, 500);
      expect(model.serviceFee, 150);
      expect(model.paymentFee, 75);
      expect(model.totalAmount, 5725);
      expect(model.pharmacyAmount, 4850);
    });

    test('fromJson defaults to 0 when fields absent', () {
      final model = PricingCalculationModel.fromJson(<String, dynamic>{});
      expect(model.subtotal, 0);
      expect(model.totalAmount, 0);
    });

    test('toEntity maps all fields', () {
      final entity = PricingCalculationModel.fromJson(<String, dynamic>{
        'subtotal': 3000,
        'delivery_fee': 300,
        'service_fee': 90,
        'payment_fee': 45,
        'total_amount': 3435,
        'pharmacy_amount': 2700,
      }).toEntity();
      expect(entity, isA<PricingCalculationEntity>());
      expect(entity.totalAmount, 3435);
      expect(entity.subtotal, 3000);
    });
  });
}
