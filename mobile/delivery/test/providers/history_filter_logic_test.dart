import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/providers/history_providers.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/delivery_filters.dart';
import 'package:courier/data/repositories/delivery_repository.dart';

class MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  final testDeliveries = <Delivery>[
    const Delivery(
      id: 1,
      reference: 'REF-001',
      pharmacyName: 'Pharmacie Centrale',
      pharmacyAddress: '10 Rue A',
      customerName: 'Client 1',
      deliveryAddress: '20 Rue B',
      totalAmount: 5000,
      status: 'delivered',
      createdAt: '2024-06-15T10:00:00Z',
    ),
    const Delivery(
      id: 2,
      reference: 'REF-002',
      pharmacyName: 'Pharmacie Nord',
      pharmacyAddress: '30 Rue C',
      customerName: 'Client 2',
      deliveryAddress: '40 Rue D',
      totalAmount: 8000,
      status: 'delivered',
      createdAt: '2024-06-16T12:00:00Z',
    ),
    const Delivery(
      id: 3,
      reference: 'REF-003',
      pharmacyName: 'Pharmacie Centrale',
      pharmacyAddress: '10 Rue A',
      customerName: 'Client 3',
      deliveryAddress: '50 Rue E',
      totalAmount: 3000,
      status: 'cancelled',
      createdAt: '2024-06-17T14:00:00Z',
    ),
    const Delivery(
      id: 4,
      reference: 'REF-004',
      pharmacyName: 'Pharmacie Sud',
      pharmacyAddress: '60 Rue F',
      customerName: 'Client 4',
      deliveryAddress: '70 Rue G',
      totalAmount: 12000,
      status: 'delivered',
      createdAt: '2024-06-10T08:00:00Z',
    ),
  ];

  late MockDeliveryRepository mockRepo;

  setUp(() {
    mockRepo = MockDeliveryRepository();
    when(
      () => mockRepo.getDeliveries(status: 'history'),
    ).thenAnswer((_) async => testDeliveries);
  });

  group('filteredHistoryProvider - real logic', () {
    test('returns all deliveries with empty filters', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(filteredHistoryProvider.future);
      expect(result.length, 4);
    });

    test('filters by status delivered', () async {
      final container = ProviderContainer(
        overrides: [
          deliveryRepositoryProvider.overrideWithValue(mockRepo),
          historyFiltersProvider.overrideWith(() {
            return HistoryFiltersNotifier();
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setStatus('delivered');
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.every((d) => d.status == 'delivered'), isTrue);
      expect(result.length, 3);
    });

    test('filters by status cancelled', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setStatus('cancelled');
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.length, 1);
      expect(result.first.status, 'cancelled');
    });

    test('filters by date range', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container
          .read(historyFiltersProvider.notifier)
          .setDateRange(
            DateTime(2024, 6, 14),
            DateTime(2024, 6, 16, 23, 59, 59),
          );
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.length, 2); // June 15 and 16
    });

    test('filters by pharmacy name', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container
          .read(historyFiltersProvider.notifier)
          .setPharmacy(null, 'Centrale');
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.length, 2); // Two from Pharmacie Centrale
    });

    test('filters by min amount', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container
          .read(historyFiltersProvider.notifier)
          .setAmountRange(6000, null);
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.every((d) => d.totalAmount >= 6000), isTrue);
      expect(result.length, 2); // 8000 and 12000
    });

    test('filters by max amount', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container
          .read(historyFiltersProvider.notifier)
          .setAmountRange(null, 5000);
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.every((d) => d.totalAmount <= 5000), isTrue);
      expect(result.length, 2); // 5000 and 3000
    });

    test('sorts by amount ascending', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setSortBy(SortBy.amount);
      container
          .read(historyFiltersProvider.notifier)
          .setSortOrder(SortOrder.asc);
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.first.totalAmount, 3000);
      expect(result.last.totalAmount, 12000);
    });

    test('sorts by pharmacy name', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container
          .read(historyFiltersProvider.notifier)
          .setSortBy(SortBy.pharmacyName);
      container
          .read(historyFiltersProvider.notifier)
          .setSortOrder(SortOrder.asc);
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.first.pharmacyName, 'Pharmacie Centrale');
      expect(result.last.pharmacyName, 'Pharmacie Sud');
    });

    test('sorts by status', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setSortBy(SortBy.status);
      container
          .read(historyFiltersProvider.notifier)
          .setSortOrder(SortOrder.asc);
      await container.pump();
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.first.status, 'cancelled');
    });

    test('sorts descending by date by default', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      // Default: SortBy.date, SortOrder.desc
      final result = await container.read(filteredHistoryProvider.future);
      expect(result.first.createdAt, '2024-06-17T14:00:00Z');
      expect(result.last.createdAt, '2024-06-10T08:00:00Z');
    });
  });

  group('uniquePharmaciesProvider', () {
    test('returns unique pharmacy names sorted', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(uniquePharmaciesProvider.future);
      expect(result.length, 3); // Centrale, Nord, Sud
      expect(result.first.name, 'Pharmacie Centrale');
      expect(result.last.name, 'Pharmacie Sud');
    });
  });

  group('historyStatsProvider', () {
    test('calculates stats from filtered deliveries', () async {
      final container = ProviderContainer(
        overrides: [deliveryRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final stats = await container.read(historyStatsProvider.future);
      expect(stats.totalDeliveries, 4);
      expect(stats.delivered, 3);
      expect(stats.cancelled, 1);
    });
  });

  group('HistoryFiltersNotifier - presets', () {
    test('setPreset today sets today date range', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setPreset('today');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateTo, isNotNull);
      expect(filters.dateFrom!.day, DateTime.now().day);
    });

    test('setPreset week sets this week range', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setPreset('week');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateTo, isNotNull);
    });

    test('setPreset month sets this month range', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setPreset('month');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNotNull);
      expect(filters.dateFrom!.day, 1);
    });

    test('setPreset unknown resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(historyFiltersProvider.notifier).setPreset('unknown');
      final filters = container.read(historyFiltersProvider);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
    });
  });
}
