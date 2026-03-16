import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/delivery_export_service.dart';

void main() {
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
