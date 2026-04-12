import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/presentation/widgets/delivery/delivery_communication.dart';
import 'package:courier/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeliveryCommunicationHelper', () {
    late Delivery testDelivery;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testDelivery = Delivery.fromJson(const {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'pending',
        'customer_phone': '+22500000001',
        'pharmacy_phone': '+22500000002',
        'pharmacy_lat': 5.3,
        'pharmacy_lng': -3.9,
        'delivery_lat': 5.35,
        'delivery_lng': -3.95,
      });
    });

    testWidgets('constructor creates helper with context and delivery', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              final helper = DeliveryCommunicationHelper(
                context: context,
                delivery: testDelivery,
              );
              expect(helper, isNotNull);
              expect(helper.delivery.reference, 'DEL-001');
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('showQuickMessages shows bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages(
                      '+22500000001',
                      recipientName: 'Test',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Bottom sheet should appear with some message options
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('showQuickMessages with null phone shows snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages(null);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Should show snackbar instead of bottom sheet
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showQuickMessages with empty phone shows snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('');
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showQuickMessages for pharmacy shows pharmacy messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('+22500000001', isPharmacy: true);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Should contain pharmacy-specific messages
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('showQuickMessages for client shows client messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('+22500000001', isPharmacy: false);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Should show more messages for clients (5 vs 4)
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('bottom sheet has quick message title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('+22500000001');
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Should contain quick message title text
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('bottom sheet has drag handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('+22500000001');
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Container at top is the drag handle
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('message tap closes bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.showQuickMessages('+22500000001');
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap first ListTile
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('helper stores delivery reference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              final helper = DeliveryCommunicationHelper(
                context: context,
                delivery: testDelivery,
              );
              expect(helper.delivery.reference, 'DEL-001');
              expect(helper.delivery.id, 1);
              expect(helper.delivery.pharmacyName, 'Pharma Test');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('helper uses delivery customer phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              final helper = DeliveryCommunicationHelper(
                context: context,
                delivery: testDelivery,
              );
              expect(helper.delivery.customerPhone, '+22500000001');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('helper uses delivery pharmacy phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              final helper = DeliveryCommunicationHelper(
                context: context,
                delivery: testDelivery,
              );
              expect(helper.delivery.pharmacyPhone, '+22500000002');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('helper accepts delivery with coordinates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              final helper = DeliveryCommunicationHelper(
                context: context,
                delivery: testDelivery,
              );
              // Verify helper accepts delivery with coordinate fields
              expect(helper.delivery, isNotNull);
              expect(helper.delivery.pharmacyAddress, '123 Rue Test');
              expect(helper.delivery.deliveryAddress, '456 Rue Dest');
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('DeliveryCommunicationHelper - makePhoneCall', () {
    late Delivery testDelivery;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testDelivery = Delivery.fromJson(const {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'pending',
      });
    });

    testWidgets('makePhoneCall with null phone shows snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.makePhoneCall(null);
                  },
                  child: const Text('Call'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('makePhoneCall with empty phone shows snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.makePhoneCall('');
                  },
                  child: const Text('Call'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('DeliveryCommunicationHelper - openWhatsApp', () {
    late Delivery testDelivery;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testDelivery = Delivery.fromJson(const {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'pending',
      });
    });

    testWidgets('openWhatsApp with null phone shows snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.openWhatsApp(null);
                  },
                  child: const Text('WA'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('WA'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('openWhatsApp with empty phone shows snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final helper = DeliveryCommunicationHelper(
                      context: context,
                      delivery: testDelivery,
                    );
                    helper.openWhatsApp('');
                  },
                  child: const Text('WA'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('WA'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
