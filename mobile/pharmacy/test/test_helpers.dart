// Test helpers and mocks for Pharmacy app tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/user_entity.dart';
import 'package:drpharma_pharmacy/features/auth/domain/entities/pharmacy_entity.dart';
import 'package:drpharma_pharmacy/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_pharmacy/features/inventory/domain/entities/product_entity.dart';

// Mock classes
class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Fake classes for fallback values
class FakeUri extends Fake implements Uri {}
class FakeOptions extends Fake implements Options {}
class FakeRequestOptions extends Fake implements RequestOptions {}

/// Setup fallback values for mocktail
void setupFallbackValues() {
  registerFallbackValue(FakeUri());
  registerFallbackValue(FakeOptions());
  registerFallbackValue(FakeRequestOptions());
}

/// Test data factory for creating test entities
class TestDataFactory {
  static UserEntity createUser({
    int id = 1,
    String name = 'Test Pharmacist',
    String email = 'pharmacist@test.com',
    String phone = '+225 01 02 03 04 05',
    String? role = 'pharmacist',
    List<PharmacyEntity>? pharmacies,
  }) {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      pharmacies: pharmacies ?? [createPharmacy()],
    );
  }

  static PharmacyEntity createPharmacy({
    int id = 1,
    String name = 'Pharmacie Test',
    String? address = '123 Rue Test, Abidjan',
    String? city = 'Abidjan',
    String? phone = '+225 27 22 00 00 00',
    String? email = 'pharmacie@test.com',
    String status = 'active',
    String? licenseNumber = 'LIC-12345',
  }) {
    return PharmacyEntity(
      id: id,
      name: name,
      address: address,
      city: city,
      phone: phone,
      email: email,
      status: status,
      licenseNumber: licenseNumber,
    );
  }

  static OrderEntity createOrder({
    int id = 1,
    String reference = 'DR-TEST001',
    String status = 'pending',
    String paymentMode = 'platform',
    double totalAmount = 5000.0,
    String customerName = 'Client Test',
    String customerPhone = '+225 07 07 07 07 07',
    String? deliveryAddress = 'Cocody, Abidjan',
    DateTime? createdAt,
    List<OrderItemEntity>? items,
    int? itemsCount,
  }) {
    final orderItems = items ?? [createOrderItem()];
    return OrderEntity(
      id: id,
      reference: reference,
      status: status,
      paymentMode: paymentMode,
      totalAmount: totalAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt ?? DateTime.now(),
      items: orderItems,
      itemsCount: itemsCount ?? orderItems.length,
    );
  }

  static OrderItemEntity createOrderItem({
    String name = 'Paracétamol 500mg',
    int quantity = 2,
    double unitPrice = 500.0,
    double? totalPrice,
  }) {
    return OrderItemEntity(
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice ?? (unitPrice * quantity),
    );
  }

  static ProductEntity createProduct({
    int id = 1,
    String name = 'Paracétamol 500mg',
    String description = 'Antalgique et antipyrétique',
    double price = 500.0,
    int stockQuantity = 100,
    String category = 'Médicaments',
    String? barcode = '3760012345678',
    bool requiresPrescription = false,
    bool isAvailable = true,
    DateTime? expiryDate,
  }) {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      category: category,
      barcode: barcode,
      requiresPrescription: requiresPrescription,
      isAvailable: isAvailable,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
    );
  }

  static List<ProductEntity> createProductList({int count = 5}) {
    return List.generate(
      count,
      (index) => createProduct(
        id: index + 1,
        name: 'Produit ${index + 1}',
        stockQuantity: (index + 1) * 20,
      ),
    );
  }

  static List<OrderEntity> createOrderList({int count = 5}) {
    final statuses = ['pending', 'confirmed', 'ready', 'delivered', 'cancelled'];
    return List.generate(
      count,
      (index) => createOrder(
        id: index + 1,
        reference: 'DR-TEST00${index + 1}',
        status: statuses[index % statuses.length],
        totalAmount: (index + 1) * 1000.0,
      ),
    );
  }
}

/// Widget test helper to wrap widgets with necessary providers
Widget createTestableWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(body: child),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      locale: const Locale('fr', 'FR'),
    ),
  );
}

/// Extension for easier testing with Riverpod
extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpProviderWidget(
    Widget widget, {
    List<Override>? overrides,
    Duration? duration,
  }) async {
    await pumpWidget(createTestableWidget(widget, overrides: overrides));
    if (duration != null) {
      await pump(duration);
    }
  }
}
