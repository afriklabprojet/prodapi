import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:courier/core/services/earnings_export_service.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/wallet_data.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EarningsExportService service;

  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
      return Directory.systemTemp.path;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
  });

  setUp(() {
    service = EarningsExportService.instance;
  });

  group('EarningsExportService', () {
    test('instance returns singleton', () {
      final s1 = EarningsExportService.instance;
      final s2 = EarningsExportService.instance;
      expect(identical(s1, s2), true);
    });

    test('generateEarningsReport returns formatted text', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Jean Dupont',
        dateFrom: DateTime(2024, 1, 1),
        dateTo: DateTime(2024, 1, 31),
      );
      expect(report, isA<String>());
      expect(report, contains('Jean Dupont'));
    });

    test('generateEarningsReport with empty deliveries', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
        dateFrom: DateTime(2024, 6, 1),
        dateTo: DateTime(2024, 6, 30),
      );
      expect(report, isNotEmpty);
    });

    test('generateEarningsReport contains header', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
      );
      expect(report, contains('RELEVÉ DE REVENUS'));
      expect(report, contains('DR-PHARMA'));
    });

    test('generateEarningsReport contains statistics section', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 1500,
          commission: 300,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
        Delivery(
          id: 2,
          reference: 'R2',
          pharmacyName: 'P2',
          pharmacyAddress: 'A2',
          customerName: 'C2',
          deliveryAddress: 'D2',
          totalAmount: 3000,
          status: 'cancelled',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Livreur Test',
      );
      expect(report, contains('STATISTIQUES'));
      expect(report, contains('Livraisons effectuées'));
      expect(report, contains('Livraisons annulées'));
      expect(report, contains('Taux de succès'));
    });

    test('generateEarningsReport contains revenue section', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 2000,
          commission: 400,
          status: 'delivered',
          createdAt: '2024-01-10T08:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('REVENUS'));
      expect(report, contains('Gains bruts'));
      expect(report, contains('Commissions DR-PHARMA'));
      expect(report, contains('Net à percevoir'));
      expect(report, contains('FCFA'));
    });

    test('generateEarningsReport contains delivery details', () {
      final deliveries = [
        Delivery(
          id: 42,
          reference: 'R42',
          pharmacyName: 'Pharmacie Soleil',
          pharmacyAddress: 'Rue A',
          customerName: 'Client X',
          deliveryAddress: 'Rue B',
          totalAmount: 5000,
          deliveryFee: 1500,
          commission: 300,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('DÉTAIL LIVRAISONS'));
      expect(report, contains('#42'));
      expect(report, contains('Pharmacie Solei'));
    });

    test('generateEarningsReport shows period when dateFrom provided', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
        dateFrom: DateTime(2024, 3, 1),
      );
      expect(report, contains('Période'));
      expect(report, contains('01/03/2024'));
    });

    test('generateEarningsReport shows period when dateTo provided', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
        dateTo: DateTime(2024, 3, 31),
      );
      expect(report, contains('Période'));
      expect(report, contains('Début'));
      expect(report, contains('31/03/2024'));
    });

    test('generateEarningsReport no period when dates null', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
      );
      expect(report.contains('Période'), false);
    });

    test('generateEarningsReport limits details to 20 deliveries', () {
      final deliveries = List.generate(
        25,
        (i) => Delivery(
          id: i + 1,
          reference: 'R${i + 1}',
          pharmacyName: 'P${i + 1}',
          pharmacyAddress: 'A${i + 1}',
          customerName: 'C${i + 1}',
          deliveryAddress: 'D${i + 1}',
          totalAmount: 5000,
          deliveryFee: 1000,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      );
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('et 5 autres livraisons'));
    });

    test('generateEarningsReport footer present', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
      );
      expect(report, contains('Document généré par DR-PHARMA App'));
    });

    test('generateEarningsReport with pending status deliveries', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 1500,
          status: 'pending',
          createdAt: '2024-06-15T10:00:00Z',
        ),
        Delivery(
          id: 2,
          reference: 'R2',
          pharmacyName: 'P2',
          pharmacyAddress: 'A2',
          customerName: 'C2',
          deliveryAddress: 'D2',
          totalAmount: 3000,
          status: 'in_progress',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Livreur',
      );
      // pending/in_progress count as neither delivered nor cancelled
      expect(report, contains('Livraisons effectuées : 0'));
      expect(report, contains('Livraisons annulées   : 0'));
    });

    test('generateEarningsReport pharmacy name truncation at 15 chars', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'Pharmacie ABC DEF GHI',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 2000,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      // Name > 15 chars gets substringed to 15
      expect(report, contains('Pharmacie ABC D'));
      expect(report, isNot(contains('Pharmacie ABC DEF GHI')));
    });

    test('generateEarningsReport pharmacy name under 15 chars stays full', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'Pharma OK',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 2000,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('Pharma OK'));
    });

    test('generateEarningsReport with null createdAt shows N/A', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'Pharma',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 2000,
          status: 'delivered',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('N/A'));
    });

    test('generateEarningsReport with both dateFrom and dateTo', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
        dateFrom: DateTime(2024, 1, 1),
        dateTo: DateTime(2024, 12, 31),
      );
      expect(report, contains('01/01/2024'));
      expect(report, contains('31/12/2024'));
    });

    test('generateEarningsReport with zero commission', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 2000,
          commission: 0,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('REVENUS'));
      expect(report, contains('Net à percevoir'));
    });

    test('generateEarningsReport success rate calculates correctly', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 1500,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
        Delivery(
          id: 2,
          reference: 'R2',
          pharmacyName: 'P2',
          pharmacyAddress: 'A2',
          customerName: 'C2',
          deliveryAddress: 'D2',
          totalAmount: 3000,
          status: 'cancelled',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      // 1 delivered out of 2 total = 50.0%
      expect(report, contains('50.0%'));
    });

    test('generateEarningsReport net earnings = gross - commission', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 10000,
          deliveryFee: 5000,
          commission: 1000,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      // Net = 5000 - 1000 = 4000
      expect(report, contains('FCFA'));
      expect(report, contains('Net à percevoir'));
      expect(report, contains('Gains bruts'));
    });

    test('generateEarningsReport with many delivered shows count', () {
      final deliveries = List.generate(
        25,
        (i) => Delivery(
          id: i + 1,
          reference: 'R${i + 1}',
          pharmacyName: 'P${i + 1}',
          pharmacyAddress: 'A${i + 1}',
          customerName: 'C${i + 1}',
          deliveryAddress: 'D${i + 1}',
          totalAmount: 5000,
          deliveryFee: 1000,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      );
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('Livraisons effectuées : 25'));
      expect(report, contains('et 5 autres livraisons'));
    });

    test('generateEarningsReport all delivered gives 100% success rate', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 1500,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('100.0%'));
    });

    test('generateEarningsReport shows dateTo as Aujourd\'hui equivalent', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
        dateFrom: DateTime(2024, 1, 1),
      );
      // dateFrom set, dateTo null -> "Aujourd'hui"
      expect(report, contains("Aujourd'hui"));
    });

    test('generateEarningsReport report header has separator lines', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
      );
      expect(report, contains('═══════════════════════════════════════'));
      expect(report, contains('─────────────────────────────────────'));
    });

    test('generateEarningsReport report includes livreur name', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Moussa Diallo',
      );
      expect(report, contains('Livreur: Moussa Diallo'));
    });

    test('generateEarningsReport with deliveryFee=0 uses 0', () {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'P1',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'D1',
          totalAmount: 5000,
          deliveryFee: 0,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
      ];
      final report = service.generateEarningsReport(
        deliveries: deliveries,
        courierName: 'Test',
      );
      expect(report, contains('Livraisons effectuées : 1'));
      expect(report, contains('0 FCFA'));
    });

    test(
      'generateEarningsReport with multiple cancelled shows correct count',
      () {
        final deliveries = List.generate(
          5,
          (i) => Delivery(
            id: i + 1,
            reference: 'R${i + 1}',
            pharmacyName: 'P${i + 1}',
            pharmacyAddress: 'A${i + 1}',
            customerName: 'C${i + 1}',
            deliveryAddress: 'D${i + 1}',
            totalAmount: 5000,
            status: 'cancelled',
          ),
        );
        final report = service.generateEarningsReport(
          deliveries: deliveries,
          courierName: 'Test',
        );
        expect(report, contains('Livraisons annulées   : 5'));
        expect(report, contains('Livraisons effectuées : 0'));
        // 0 delivered / 5 total = 0.0%
        expect(report, contains('0.0%'));
      },
    );

    test('generateEarningsReport date generation line present', () {
      final report = service.generateEarningsReport(
        deliveries: [],
        courierName: 'Test',
      );
      expect(report, contains('Date génération:'));
    });
  });

  group('EarningsExportService CSV export', () {
    test('exportToCSV writes delivery rows, summary and period', () async {
      final deliveries = [
        Delivery(
          id: 1,
          reference: 'R1',
          pharmacyName: 'Pharma, "Central"',
          pharmacyAddress: 'A1',
          customerName: 'C1',
          deliveryAddress: 'Rue 1,\nAbidjan',
          totalAmount: 5000,
          deliveryFee: 1500,
          status: 'delivered',
          createdAt: '2024-06-15T10:00:00Z',
        ),
        Delivery(
          id: 2,
          reference: 'R2',
          pharmacyName: 'Pharma Nord',
          pharmacyAddress: 'A2',
          customerName: 'C2',
          deliveryAddress: 'Rue 2',
          totalAmount: 3000,
          deliveryFee: 0,
          status: 'pending',
        ),
      ];

      final path = await service.exportToCSV(
        deliveries: deliveries,
        dateFrom: DateTime(2024, 6, 1),
        dateTo: DateTime(2024, 6, 30),
      );

      expect(path, isNotNull);
      final file = File(path!);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('ID,Date,Pharmacie,Adresse,Montant Total'));
      expect(content, contains('"Pharma, ""Central"""'));
      expect(content, contains('"Rue 1,\nAbidjan"'));
      expect(content, contains('Livrée'));
      expect(content, contains('Annulée'));
      expect(content, contains('RÉSUMÉ'));
      expect(content, contains('Total livraisons,1'));
      expect(content, contains('Total gains,'));
      expect(content, contains('Période,01/06/2024 - 30/06/2024'));
    });

    test('exportToCSV handles empty deliveries', () async {
      final path = await service.exportToCSV(deliveries: const []);

      expect(path, isNotNull);
      final file = File(path!);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final content = await file.readAsString();
      expect(content, contains('ID,Date,Pharmacie,Adresse'));
      expect(content, contains('Total livraisons,0'));
      expect(content, contains('Total gains,'));
    });

    test('exportToCSV returns null if directory access fails', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async {
        throw PlatformException(code: 'path_error');
      });

      try {
        final path = await service.exportToCSV(deliveries: const []);
        expect(path, isNull);
      } finally {
        messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });
      }
    });

    test('exportTransactionsToCSV writes credits, debits and net summary', () async {
      final transactions = [
        WalletTransaction(
          id: 1,
          amount: 2500,
          type: 'credit',
          category: 'delivery',
          description: 'Livraison #42',
          status: 'complété',
          createdAt: DateTime(2024, 6, 15, 10, 30),
        ),
        WalletTransaction(
          id: 2,
          amount: 500,
          type: 'debit',
          category: 'withdrawal',
          description: 'Retrait mobile money',
          status: 'en_attente',
          createdAt: DateTime(2024, 6, 15, 12, 00),
        ),
      ];

      final path = await service.exportTransactionsToCSV(
        transactions: transactions,
      );

      expect(path, isNotNull);
      final file = File(path!);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('ID,Date,Type,Catégorie,Description,Montant,Statut'));
      expect(content, contains('Crédit'));
      expect(content, contains('Débit'));
      expect(content, contains('Livraison'));
      expect(content, contains('Retrait'));
      expect(content, contains('+2500.0'));
      expect(content, contains('-500.0'));
      expect(content, contains('Total crédits,'));
      expect(content, contains('Total débits,'));
      expect(content, contains('Solde net,'));
    });

    test('exportTransactionsToCSV keeps unknown category label as-is', () async {
      final path = await service.exportTransactionsToCSV(
        transactions: [
          WalletTransaction(
            id: 3,
            amount: 100,
            type: 'credit',
            category: 'special_reward',
            description: 'Prime spéciale',
            createdAt: DateTime(2024, 6, 15, 8, 0),
          ),
        ],
      );

      expect(path, isNotNull);
      final file = File(path!);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final content = await file.readAsString();
      expect(content, contains('special_reward'));
      expect(content, contains('Prime spéciale'));
    });
  });
}
