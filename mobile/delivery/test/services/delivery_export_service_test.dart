import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:courier/core/services/delivery_export_service.dart';
import 'package:courier/data/models/delivery.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });
  group('DeliveryExportService', () {
    group('ExportType', () {
      test('has pdf and csv values', () {
        expect(ExportType.values.length, 2);
        expect(ExportType.values, contains(ExportType.pdf));
        expect(ExportType.values, contains(ExportType.csv));
      });

      test('pdf name is correct', () {
        expect(ExportType.pdf.name, 'pdf');
      });

      test('csv name is correct', () {
        expect(ExportType.csv.name, 'csv');
      });
    });

    group('HistoryStats', () {
      test('creates with required fields', () {
        const stats = HistoryStats(
          totalDeliveries: 10,
          deliveredCount: 8,
          cancelledCount: 2,
          totalEarnings: 25000,
          averageEarnings: 2500,
          totalDistance: 45.5,
        );

        expect(stats.totalDeliveries, 10);
        expect(stats.deliveredCount, 8);
        expect(stats.cancelledCount, 2);
        expect(stats.totalEarnings, 25000);
        expect(stats.averageEarnings, 2500);
        expect(stats.totalDistance, 45.5);
      });

      test('is immutable', () {
        const stats = HistoryStats(
          totalDeliveries: 5,
          deliveredCount: 4,
          cancelledCount: 1,
          totalEarnings: 10000,
          averageEarnings: 2000,
          totalDistance: 20.0,
        );

        // Values should remain constant
        expect(stats.totalDeliveries, 5);
        expect(stats.totalEarnings, 10000);
      });

      test('handles zero values', () {
        const stats = HistoryStats(
          totalDeliveries: 0,
          deliveredCount: 0,
          cancelledCount: 0,
          totalEarnings: 0,
          averageEarnings: 0,
          totalDistance: 0,
        );

        expect(stats.totalDeliveries, 0);
        expect(stats.averageEarnings, 0);
      });
    });

    group('ExportedFile', () {
      test('creates with required fields', () {
        final file = ExportedFile(
          path: '/path/to/file.pdf',
          name: 'export_2024_01.pdf',
          size: 1024,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          type: ExportType.pdf,
        );

        expect(file.path, '/path/to/file.pdf');
        expect(file.name, 'export_2024_01.pdf');
        expect(file.size, 1024);
        expect(file.type, ExportType.pdf);
      });

      test('formattedSize shows bytes for small files', () {
        final file = ExportedFile(
          path: '/test.pdf',
          name: 'test.pdf',
          size: 512,
          createdAt: DateTime.now(),
          type: ExportType.pdf,
        );

        expect(file.formattedSize, '512 B');
      });

      test('formattedSize shows KB for medium files', () {
        final file = ExportedFile(
          path: '/test.pdf',
          name: 'test.pdf',
          size: 2048, // 2 KB
          createdAt: DateTime.now(),
          type: ExportType.pdf,
        );

        expect(file.formattedSize, '2.0 KB');
      });

      test('formattedSize shows MB for large files', () {
        final file = ExportedFile(
          path: '/test.pdf',
          name: 'test.pdf',
          size: 2 * 1024 * 1024, // 2 MB
          createdAt: DateTime.now(),
          type: ExportType.pdf,
        );

        expect(file.formattedSize, '2.0 MB');
      });

      test('formattedSize handles KB with decimals', () {
        final file = ExportedFile(
          path: '/test.csv',
          name: 'test.csv',
          size: 1536, // 1.5 KB
          createdAt: DateTime.now(),
          type: ExportType.csv,
        );

        expect(file.formattedSize, '1.5 KB');
      });

      test('supports csv type', () {
        final file = ExportedFile(
          path: '/export.csv',
          name: 'export.csv',
          size: 256,
          createdAt: DateTime.now(),
          type: ExportType.csv,
        );

        expect(file.type, ExportType.csv);
      });
    });

    group('HistoryStats.fromDeliveries', () {
      Delivery makeDelivery({
        required int id,
        required String status,
        double? commission,
        double? distanceKm,
      }) {
        return Delivery(
          id: id,
          reference: 'REF-$id',
          pharmacyName: 'Pharma $id',
          pharmacyAddress: 'Addr $id',
          customerName: 'Client $id',
          deliveryAddress: 'Dest $id',
          totalAmount: 5000,
          status: status,
          commission: commission,
          distanceKm: distanceKm,
        );
      }

      test('empty list gives zeros', () {
        final stats = HistoryStats.fromDeliveries([]);
        expect(stats.totalDeliveries, 0);
        expect(stats.deliveredCount, 0);
        expect(stats.cancelledCount, 0);
        expect(stats.totalEarnings, 0);
        expect(stats.averageEarnings, 0);
        expect(stats.totalDistance, 0);
      });

      test('counts delivered and cancelled', () {
        final deliveries = [
          makeDelivery(id: 1, status: 'delivered', commission: 500),
          makeDelivery(id: 2, status: 'delivered', commission: 700),
          makeDelivery(id: 3, status: 'cancelled'),
          makeDelivery(id: 4, status: 'pending'),
        ];
        final stats = HistoryStats.fromDeliveries(deliveries);
        expect(stats.totalDeliveries, 4);
        expect(stats.deliveredCount, 2);
        expect(stats.cancelledCount, 1);
      });

      test('totalEarnings sums commissions of delivered only', () {
        final deliveries = [
          makeDelivery(id: 1, status: 'delivered', commission: 1000),
          makeDelivery(id: 2, status: 'delivered', commission: 2000),
          makeDelivery(id: 3, status: 'cancelled', commission: 500),
        ];
        final stats = HistoryStats.fromDeliveries(deliveries);
        expect(stats.totalEarnings, 3000);
      });

      test('averageEarnings divides by total deliveries', () {
        final deliveries = [
          makeDelivery(id: 1, status: 'delivered', commission: 1000),
          makeDelivery(id: 2, status: 'pending'),
        ];
        final stats = HistoryStats.fromDeliveries(deliveries);
        // 1000 / 2 = 500
        expect(stats.averageEarnings, 500);
      });

      test('totalDistance sums all deliveries', () {
        final deliveries = [
          makeDelivery(id: 1, status: 'delivered', distanceKm: 5.5),
          makeDelivery(id: 2, status: 'cancelled', distanceKm: 3.2),
          makeDelivery(id: 3, status: 'pending', distanceKm: null),
        ];
        final stats = HistoryStats.fromDeliveries(deliveries);
        expect(stats.totalDistance, closeTo(8.7, 0.01));
      });

      test('null commissions treated as 0', () {
        final deliveries = [
          makeDelivery(id: 1, status: 'delivered', commission: null),
        ];
        final stats = HistoryStats.fromDeliveries(deliveries);
        expect(stats.totalEarnings, 0);
      });
    });

    group('generateHistoryCsv', () {
      test('generates CSV with headers and data', () async {
        final deliveries = [
          Delivery(
            id: 42,
            reference: 'REF-042',
            pharmacyName: 'Pharmacie Centrale',
            pharmacyAddress: '123 Rue A',
            customerName: 'Jean Dupont',
            deliveryAddress: '456 Rue B',
            totalAmount: 15000,
            deliveryFee: 1500,
            commission: 750,
            distanceKm: 3.5,
            status: 'delivered',
            createdAt: '2024-06-15T10:30:00Z',
          ),
        ];
        final csv = await DeliveryExportService.generateHistoryCsv(
          deliveries: deliveries,
        );
        // Headers
        expect(csv, contains('ID'));
        expect(csv, contains('Pharmacie'));
        expect(csv, contains('Commission'));
        // Data
        expect(csv, contains('42'));
        expect(csv, contains('REF-042'));
        expect(csv, contains('Pharmacie Centrale'));
        expect(csv, contains('Jean Dupont'));
        expect(csv, contains('15000'));
        expect(csv, contains('750'));
        expect(csv, contains('Livrée'));
      });

      test('translates status labels in CSV', () async {
        final deliveries = [
          Delivery(
            id: 1,
            reference: 'R1',
            pharmacyName: 'P1',
            pharmacyAddress: 'A1',
            customerName: 'C1',
            deliveryAddress: 'D1',
            totalAmount: 1000,
            status: 'cancelled',
          ),
          Delivery(
            id: 2,
            reference: 'R2',
            pharmacyName: 'P2',
            pharmacyAddress: 'A2',
            customerName: 'C2',
            deliveryAddress: 'D2',
            totalAmount: 2000,
            status: 'pending',
          ),
          Delivery(
            id: 3,
            reference: 'R3',
            pharmacyName: 'P3',
            pharmacyAddress: 'A3',
            customerName: 'C3',
            deliveryAddress: 'D3',
            totalAmount: 3000,
            status: 'active',
          ),
        ];
        final csv = await DeliveryExportService.generateHistoryCsv(
          deliveries: deliveries,
        );
        expect(csv, contains('Annulée'));
        expect(csv, contains('En attente'));
        expect(csv, contains('En cours'));
      });

      test('handles empty deliveries list', () async {
        final csv = await DeliveryExportService.generateHistoryCsv(
          deliveries: [],
        );
        // Should still have headers
        expect(csv, contains('ID'));
        expect(csv, contains('Commission'));
      });

      test('handles null optional fields', () async {
        final deliveries = [
          Delivery(
            id: 1,
            reference: 'R1',
            pharmacyName: 'P1',
            pharmacyAddress: 'A1',
            customerName: 'C1',
            deliveryAddress: 'D1',
            totalAmount: 1000,
            status: 'pending',
            deliveryFee: null,
            commission: null,
            distanceKm: null,
            createdAt: null,
          ),
        ];
        final csv = await DeliveryExportService.generateHistoryCsv(
          deliveries: deliveries,
        );
        expect(csv, contains('0')); // delivery_fee defaults to 0
      });
    });

    group('generateHistoryPdf', () {
      test('generates non-empty PDF bytes', () async {
        final deliveries = [
          Delivery(
            id: 1,
            reference: 'R1',
            pharmacyName: 'P1',
            pharmacyAddress: 'A1',
            customerName: 'C1',
            deliveryAddress: 'D1',
            totalAmount: 5000,
            commission: 500,
            status: 'delivered',
            createdAt: '2024-01-15T10:00:00Z',
          ),
        ];
        final bytes = await DeliveryExportService.generateHistoryPdf(
          deliveries: deliveries,
          courierName: 'Test Courier',
          periodLabel: 'Janvier 2024',
        );
        expect(bytes, isNotEmpty);
        // PDF magic number
        expect(bytes[0], 0x25); // '%'
      });

      test('generates PDF without optional params', () async {
        final bytes = await DeliveryExportService.generateHistoryPdf(
          deliveries: [],
          courierName: 'Test',
        );
        expect(bytes, isNotEmpty);
      });

      test('generates PDF with HistoryStats', () async {
        const stats = HistoryStats(
          totalDeliveries: 10,
          deliveredCount: 8,
          cancelledCount: 2,
          totalEarnings: 25000,
          averageEarnings: 2500,
          totalDistance: 50.0,
        );
        final bytes = await DeliveryExportService.generateHistoryPdf(
          deliveries: [],
          courierName: 'Test',
          stats: stats,
        );
        expect(bytes, isNotEmpty);
      });
    });

    group('Service provider', () {
      test('deliveryExportServiceProvider exists', () {
        expect(deliveryExportServiceProvider, isNotNull);
      });

      test('savedExportsProvider exists', () {
        expect(savedExportsProvider, isNotNull);
      });
    });
  });
}
