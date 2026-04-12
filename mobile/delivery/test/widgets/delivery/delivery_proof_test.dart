import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:courier/core/services/delivery_proof_service.dart';
import 'package:courier/core/services/offline_service.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:courier/presentation/widgets/common/delivery_photo_capture.dart';
import 'package:courier/presentation/widgets/delivery/delivery_proof.dart';
import 'package:courier/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/widget_test_helpers.dart';

class FakeWalletRepository extends WalletRepository {
  FakeWalletRepository({required this.result, this.shouldThrow = false})
    : super(Dio());

  final Map<String, dynamic> result;
  final bool shouldThrow;

  @override
  Future<Map<String, dynamic>> canDeliver() async {
    if (shouldThrow) throw Exception('wallet check failed');
    return result;
  }
}

class FakeDeliveryProofService extends DeliveryProofService {
  FakeDeliveryProofService({this.shouldThrow = false, this.onUpload})
    : super(Dio());

  final bool shouldThrow;
  final void Function(int deliveryId, DeliveryProof proof)? onUpload;

  @override
  Future<void> uploadProof({
    required int deliveryId,
    required DeliveryProof proof,
  }) async {
    onUpload?.call(deliveryId, proof);
    if (shouldThrow) throw Exception('upload failed');
  }
}

void main() {
  group('DeliveryProofHelper', () {
    late Delivery testDelivery;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OfflineService.instance.resetForTesting();
      testDelivery = Delivery.fromJson(const {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'delivering',
        'customer_phone': '+22500000001',
        'pharmacy_phone': '+22500000002',
      });
    });

    testWidgets('constructor creates helper with context, ref and delivery', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper, isNotNull);
                expect(helper.delivery.reference, 'DEL-001');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper has delivery with correct pharmacy name', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper.delivery.pharmacyName, 'Pharma Test');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper has delivery with correct customer name', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper.delivery.customerName, 'Client Test');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper has delivery with correct amount', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper.delivery.totalAmount, 5000);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper has delivery with correct status', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper.delivery.status, 'delivering');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper has delivery with correct address', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: testDelivery,
                );
                expect(helper.delivery.deliveryAddress, '456 Rue Dest');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('DeliveryProofHelper - additional properties', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('helper with high amount delivery', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 100,
        'reference': 'DEL-100',
        'pharmacy_name': 'Grande Pharmacie',
        'pharmacy_address': '789 Blvd Principal',
        'customer_name': 'Client VIP',
        'delivery_address': '321 Rue Luxe',
        'total_amount': 500000,
        'delivery_fee': 3000,
        'commission': 600,
        'status': 'delivered',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(helper.delivery.totalAmount, 500000);
                expect(helper.delivery.deliveryFee, 3000);
                expect(helper.delivery.commission, 600);
                expect(helper.delivery.status, 'delivered');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper with cancelled delivery', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 50,
        'reference': 'DEL-050',
        'pharmacy_name': 'Pharmacie Annulée',
        'pharmacy_address': '100 Rue Annulation',
        'customer_name': 'Client Annulé',
        'delivery_address': '200 Rue Retour',
        'total_amount': 2000,
        'status': 'cancelled',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(helper.delivery.status, 'cancelled');
                expect(helper.delivery.reference, 'DEL-050');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper delivery has id', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 42,
        'reference': 'DEL-042',
        'pharmacy_name': 'Pharma 42',
        'pharmacy_address': 'Addr 42',
        'customer_name': 'Client 42',
        'delivery_address': 'Dest 42',
        'total_amount': 4200,
        'status': 'pending',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(helper.delivery.id, 42);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper with long pharmacy name', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 7,
        'reference': 'DEL-007',
        'pharmacy_name': 'Pharmacie Internationale du Plateau Central',
        'pharmacy_address': 'Avenue de la République, lot 123',
        'customer_name': 'Monsieur Jean-Pierre Kouamé Eboué',
        'delivery_address': 'Résidence Les Palmiers, Bâtiment C, Apt 42',
        'total_amount': 15000,
        'status': 'delivering',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(
                  helper.delivery.pharmacyName,
                  contains('Plateau Central'),
                );
                expect(helper.delivery.customerName, contains('Kouamé'));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper with zero amount delivery', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 99,
        'reference': 'DEL-099',
        'pharmacy_name': 'Pharma Gratuit',
        'pharmacy_address': 'Addr Gratuit',
        'customer_name': 'Client Gratuit',
        'delivery_address': 'Dest Gratuit',
        'total_amount': 0,
        'delivery_fee': 0,
        'status': 'delivered',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(helper.delivery.totalAmount, 0);
                expect(helper.delivery.deliveryFee, 0);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('helper delivery preserves phone numbers', (tester) async {
      final delivery = Delivery.fromJson(const {
        'id': 10,
        'reference': 'DEL-010',
        'pharmacy_name': 'Pharma Tel',
        'pharmacy_address': 'Addr',
        'customer_name': 'Client Tel',
        'delivery_address': 'Dest',
        'total_amount': 1000,
        'status': 'delivering',
        'customer_phone': '+22507070707',
        'pharmacy_phone': '+22508080808',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery,
                );
                expect(helper.delivery.customerPhone, '+22507070707');
                expect(helper.delivery.pharmacyPhone, '+22508080808');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('multiple helpers with different deliveries', (tester) async {
      final delivery1 = Delivery.fromJson(const {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma A',
        'pharmacy_address': 'Addr A',
        'customer_name': 'Client A',
        'delivery_address': 'Dest A',
        'total_amount': 1000,
        'status': 'delivered',
      });
      final delivery2 = Delivery.fromJson(const {
        'id': 2,
        'reference': 'DEL-002',
        'pharmacy_name': 'Pharma B',
        'pharmacy_address': 'Addr B',
        'customer_name': 'Client B',
        'delivery_address': 'Dest B',
        'total_amount': 2000,
        'status': 'cancelled',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonWidgetTestOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Consumer(
              builder: (context, ref, _) {
                final helper1 = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery1,
                );
                final helper2 = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: delivery2,
                );
                expect(helper1.delivery.id, 1);
                expect(helper2.delivery.id, 2);
                expect(helper1.delivery.status, 'delivered');
                expect(helper2.delivery.status, 'cancelled');
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('DeliveryProofHelper - interactions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OfflineService.instance.resetForTesting();
    });

    Widget buildHarness({
      List<Override> extra = const [],
      required Widget Function(BuildContext context, WidgetRef ref) builder,
    }) {
      return ProviderScope(
        overrides: commonWidgetTestOverrides(extra: extra),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Consumer(builder: (context, ref, _) => builder(context, ref)),
          ),
        ),
      );
    }

    testWidgets('showDeliveryProofDialog displays bottom sheet content', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          builder: (context, ref) {
            return ElevatedButton(
              onPressed: () async {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: Delivery.fromJson(const {
                    'id': 1,
                    'reference': 'DEL-001',
                    'pharmacy_name': 'Pharma Test',
                    'pharmacy_address': '123 Rue Test',
                    'customer_name': 'Client Test',
                    'delivery_address': '456 Rue Dest',
                    'total_amount': 5000,
                    'status': 'delivering',
                  }),
                );
                await helper.showDeliveryProofDialog();
              },
              child: const Text('Open proof'),
            );
          },
        ),
      );

      await tester.tap(find.text('Open proof'));
      await tester.pumpAndSettle();

      expect(find.text('Preuve de livraison'), findsOneWidget);
      expect(find.textContaining('Client: Client Test'), findsOneWidget);
      expect(find.text('📷 Photo du colis livré'), findsOneWidget);
      expect(find.textContaining('Signature du client'), findsOneWidget);
      expect(find.textContaining('Notes (optionnel)'), findsOneWidget);
      expect(find.text('Signer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.byType(DeliveryPhotoCapture), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.draw), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('showDeliveryProofDialog accepts notes input', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          buildHarness(
            builder: (context, ref) {
              return ElevatedButton(
                onPressed: () async {
                  final helper = DeliveryProofHelper(
                    context: context,
                    ref: ref,
                    delivery: Delivery.fromJson(const {
                      'id': 1,
                      'reference': 'DEL-001',
                      'pharmacy_name': 'Pharma Test',
                      'pharmacy_address': '123 Rue Test',
                      'customer_name': 'Client Test',
                      'delivery_address': '456 Rue Dest',
                      'total_amount': 5000,
                      'status': 'delivering',
                    }),
                  );
                  await helper.showDeliveryProofDialog();
                },
                child: const Text('Open dialog'),
              );
            },
          ),
        );

        await tester.tap(find.text('Open dialog'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField), 'Colis laissé au gardien');
        await tester.pump();

        expect(find.text('Colis laissé au gardien'), findsOneWidget);
        expect(find.text('Annuler'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('checkBalanceForDelivery returns true when allowed', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      bool? result;

      try {
        await tester.pumpWidget(
          buildHarness(
            extra: [
              walletRepositoryProvider.overrideWithValue(
                FakeWalletRepository(
                  result: const {
                    'can_deliver': true,
                    'balance': 1500,
                    'commission_amount': 200,
                  },
                ),
              ),
            ],
            builder: (context, ref) {
              return ElevatedButton(
                onPressed: () async {
                  final helper = DeliveryProofHelper(
                    context: context,
                    ref: ref,
                    delivery: Delivery.fromJson(const {
                      'id': 1,
                      'reference': 'DEL-001',
                      'pharmacy_name': 'Pharma Test',
                      'pharmacy_address': '123 Rue Test',
                      'customer_name': 'Client Test',
                      'delivery_address': '456 Rue Dest',
                      'total_amount': 5000,
                      'status': 'delivering',
                    }),
                  );
                  result = await helper.checkBalanceForDelivery();
                },
                child: const Text('Check balance'),
              );
            },
          ),
        );

        await tester.tap(find.text('Check balance'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(result, isTrue);
        expect(find.text('Solde Insuffisant'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('checkBalanceForDelivery shows low-balance dialog', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      bool? result;

      try {
        await tester.pumpWidget(
          buildHarness(
            extra: [
              walletRepositoryProvider.overrideWithValue(
                FakeWalletRepository(
                  result: const {
                    'can_deliver': false,
                    'balance': 50,
                    'commission_amount': 200,
                  },
                ),
              ),
            ],
            builder: (context, ref) {
              return ElevatedButton(
                onPressed: () async {
                  final helper = DeliveryProofHelper(
                    context: context,
                    ref: ref,
                    delivery: Delivery.fromJson(const {
                      'id': 1,
                      'reference': 'DEL-001',
                      'pharmacy_name': 'Pharma Test',
                      'pharmacy_address': '123 Rue Test',
                      'customer_name': 'Client Test',
                      'delivery_address': '456 Rue Dest',
                      'total_amount': 5000,
                      'status': 'delivering',
                    }),
                  );
                  result = await helper.checkBalanceForDelivery();
                },
                child: const Text('Check low balance'),
              );
            },
          ),
        );

        await tester.tap(find.text('Check low balance'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Solde Insuffisant'), findsOneWidget);
        expect(find.textContaining('Rechargez votre wallet'), findsOneWidget);
        expect(find.text('Plus tard'), findsOneWidget);
        expect(find.text('Recharger'), findsOneWidget);

        await tester.tap(find.text('Plus tard'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));

        expect(result, isFalse);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('checkBalanceForDelivery shows fallback snackbar on error', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      bool? result;

      try {
        await tester.pumpWidget(
          buildHarness(
            extra: [
              walletRepositoryProvider.overrideWithValue(
                FakeWalletRepository(result: const {}, shouldThrow: true),
              ),
            ],
            builder: (context, ref) {
              return ElevatedButton(
                onPressed: () async {
                  final helper = DeliveryProofHelper(
                    context: context,
                    ref: ref,
                    delivery: Delivery.fromJson(const {
                      'id': 1,
                      'reference': 'DEL-001',
                      'pharmacy_name': 'Pharma Test',
                      'pharmacy_address': '123 Rue Test',
                      'customer_name': 'Client Test',
                      'delivery_address': '456 Rue Dest',
                      'total_amount': 5000,
                      'status': 'delivering',
                    }),
                  );
                  result = await helper.checkBalanceForDelivery();
                },
                child: const Text('Trigger error'),
              );
            },
          ),
        );

        await tester.tap(find.text('Trigger error'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(result, isTrue);
        expect(
          find.textContaining('Impossible de vérifier le solde'),
          findsOneWidget,
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('uploadProof uses proof service when photo is provided', (
      tester,
    ) async {
      bool uploaded = false;
      int? uploadedId;
      final file = File('${Directory.systemTemp.path}/proof_test.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      await tester.pumpWidget(
        buildHarness(
          extra: [
            deliveryProofServiceProvider.overrideWithValue(
              FakeDeliveryProofService(
                onUpload: (deliveryId, proof) {
                  uploaded = true;
                  uploadedId = deliveryId;
                  expect(proof.photo, isNotNull);
                },
              ),
            ),
          ],
          builder: (context, ref) {
            return ElevatedButton(
              onPressed: () async {
                final helper = DeliveryProofHelper(
                  context: context,
                  ref: ref,
                  delivery: Delivery.fromJson(const {
                    'id': 1,
                    'reference': 'DEL-001',
                    'pharmacy_name': 'Pharma Test',
                    'pharmacy_address': '123 Rue Test',
                    'customer_name': 'Client Test',
                    'delivery_address': '456 Rue Dest',
                    'total_amount': 5000,
                    'status': 'delivering',
                  }),
                );
                await helper.uploadProof(deliveryId: 99, photo: file);
              },
              child: const Text('Upload proof'),
            );
          },
        ),
      );

      await tester.tap(find.text('Upload proof'));
      await tester.pumpAndSettle();

      expect(uploaded, isTrue);
      expect(uploadedId, 99);
    });


  });
}
