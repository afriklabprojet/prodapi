import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/config/providers.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/treatments/data/services/smart_refill_service.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/treatments/domain/repositories/treatments_repository.dart';
import 'package:drpharma_client/features/treatments/presentation/providers/treatments_provider.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────

class MockTreatmentsRepository extends Mock implements TreatmentsRepository {}

// ─────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────

TreatmentEntity _makeTreatment({
  String id = 't1',
  int productId = 1,
  String productName = 'Paracétamol',
  DateTime? nextRenewalDate,
  int? daysUntilRenewal,
  bool isActive = true,
  int renewalPeriodDays = 30,
}) {
  final now = DateTime.now();
  final renewalDate =
      nextRenewalDate ??
      (daysUntilRenewal != null
          ? now.add(Duration(days: daysUntilRenewal))
          : now.add(const Duration(days: 5)));

  return TreatmentEntity(
    id: id,
    productId: productId,
    productName: productName,
    renewalPeriodDays: renewalPeriodDays,
    nextRenewalDate: renewalDate,
    reminderEnabled: true,
    reminderDaysBefore: 3,
    isActive: isActive,
    createdAt: DateTime(2024),
  );
}

ProviderContainer _makeContainer({
  required SharedPreferences prefs,
  required MockTreatmentsRepository mockRepository,
}) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      treatmentsRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
}

void main() {
  late SharedPreferences prefs;
  late MockTreatmentsRepository mockRepository;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockRepository = MockTreatmentsRepository();
  });

  tearDown(() {
    container.dispose();
  });

  // ──────────────────────────────────────────────────────
  // SmartRefillNotifier
  // ──────────────────────────────────────────────────────
  group('SmartRefillNotifier', () {
    // ── initial state ──────────────────────────────────
    group('initial state', () {
      test('starts with empty state', () {
        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => const Right([]));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        final state = container.read(smartRefillProvider);
        expect(state.suggestions, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.lastChecked, isNull);
      });
    });

    // ── checkRefills ───────────────────────────────────
    group('checkRefills', () {
      test('generates suggestions for treatments within 7 days', () async {
        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: 2), // urgent
          _makeTreatment(id: 't2', daysUntilRenewal: 5), // upcoming
          _makeTreatment(id: 't3', daysUntilRenewal: 10), // > 7 days, ignored
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.length, 2);
        expect(state.urgentSuggestions.length, 1);
        expect(state.upcomingSuggestions.length, 1);
        expect(state.lastChecked, isNotNull);
        expect(state.isLoading, isFalse);
      });

      test('sets isLoading during refresh', () async {
        when(() => mockRepository.getTreatments()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return const Right([]);
        });

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        final future = container
            .read(smartRefillProvider.notifier)
            .checkRefills();

        // State should be loading immediately
        expect(container.read(smartRefillProvider).isLoading, isTrue);

        await future;

        expect(container.read(smartRefillProvider).isLoading, isFalse);
      });

      test('handles repository failure gracefully', () async {
        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Left(CacheFailure(message: 'DB error')));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions, isEmpty);
        expect(state.isLoading, isFalse);
      });

      test('excludes inactive treatments', () async {
        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: 2, isActive: false),
          _makeTreatment(id: 't2', daysUntilRenewal: 2, isActive: true),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.length, 1);
        expect(state.suggestions.first.treatment.id, 't2');
      });

      test('sorts by urgency then by days remaining', () async {
        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: 5), // upcoming (later)
          _makeTreatment(id: 't2', daysUntilRenewal: 1), // urgent
          _makeTreatment(id: 't3', daysUntilRenewal: 4), // upcoming (earlier)
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final suggestions = container.read(smartRefillProvider).suggestions;
        expect(suggestions[0].treatment.id, 't2'); // urgent first
        expect(suggestions[1].treatment.id, 't3'); // upcoming, 4 days
        expect(suggestions[2].treatment.id, 't1'); // upcoming, 5 days
      });
    });

    // ── urgency calculation ────────────────────────────
    group('urgency calculation', () {
      test('overdue treatment is urgent', () async {
        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: -2), // overdue
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.first.urgency, RefillUrgency.urgent);
      });

      test('today renewal is urgent', () async {
        final treatments = [_makeTreatment(id: 't1', daysUntilRenewal: 0)];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.first.urgency, RefillUrgency.urgent);
      });

      test('3 days is urgent', () async {
        final treatments = [_makeTreatment(id: 't1', daysUntilRenewal: 3)];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.first.urgency, RefillUrgency.urgent);
      });

      test('4-7 days is upcoming', () async {
        final treatments = [_makeTreatment(id: 't1', daysUntilRenewal: 5)];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.first.urgency, RefillUrgency.upcoming);
      });
    });

    // ── message generation ─────────────────────────────
    group('message generation', () {
      test('overdue message includes days overdue', () async {
        final treatments = [
          _makeTreatment(
            id: 't1',
            productName: 'Doliprane',
            daysUntilRenewal: -3,
          ),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final message = container
            .read(smartRefillProvider)
            .suggestions
            .first
            .message;
        expect(message, contains('il y a 3 jours'));
        expect(message, contains('Doliprane'));
      });

      test('today message contains today', () async {
        final treatments = [
          _makeTreatment(
            id: 't1',
            productName: 'Aspirine',
            daysUntilRenewal: 0,
          ),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final message = container
            .read(smartRefillProvider)
            .suggestions
            .first
            .message;
        expect(message, contains('aujourd\'hui'));
      });

      test('tomorrow message', () async {
        // Set renewal date to tomorrow at end of day to ensure daysUntilRenewal = 1
        final tomorrow = DateTime.now().add(const Duration(days: 1, hours: 12));
        final treatments = [
          _makeTreatment(
            id: 't1',
            productName: 'Ibuprofène',
            nextRenewalDate: tomorrow,
          ),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final message = container
            .read(smartRefillProvider)
            .suggestions
            .first
            .message;
        expect(message, contains('demain'));
      });
    });

    // ── dismissSuggestion ──────────────────────────────
    group('dismissSuggestion', () {
      test('removes suggestion from state', () async {
        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: 2),
          _makeTreatment(id: 't2', daysUntilRenewal: 3),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();
        expect(container.read(smartRefillProvider).suggestions.length, 2);

        await container
            .read(smartRefillProvider.notifier)
            .dismissSuggestion('t1');

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.length, 1);
        expect(state.suggestions.first.treatment.id, 't2');
      });

      test('persists dismissed ID to SharedPreferences', () async {
        final treatments = [_makeTreatment(id: 't1', daysUntilRenewal: 2)];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();
        await container
            .read(smartRefillProvider.notifier)
            .dismissSuggestion('t1');

        final dismissed = prefs.getStringList('smart_refill_dismissed');
        expect(dismissed, contains('t1'));
      });

      test('dismissed treatments excluded on next refresh', () async {
        // First, set up dismissed IDs
        await prefs.setStringList('smart_refill_dismissed', ['t1']);

        final treatments = [
          _makeTreatment(id: 't1', daysUntilRenewal: 2),
          _makeTreatment(id: 't2', daysUntilRenewal: 3),
        ];

        when(
          () => mockRepository.getTreatments(),
        ).thenAnswer((_) async => Right(treatments));

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        await container.read(smartRefillProvider.notifier).checkRefills();

        final state = container.read(smartRefillProvider);
        expect(state.suggestions.length, 1);
        expect(state.suggestions.first.treatment.id, 't2');
      });
    });

    // ── concurrent access ──────────────────────────────
    group('concurrent access', () {
      test('prevents concurrent checkRefills calls', () async {
        var callCount = 0;

        when(() => mockRepository.getTreatments()).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return const Right([]);
        });

        container = _makeContainer(
          prefs: prefs,
          mockRepository: mockRepository,
        );

        // Start two concurrent calls
        final future1 = container
            .read(smartRefillProvider.notifier)
            .checkRefills();
        final future2 = container
            .read(smartRefillProvider.notifier)
            .checkRefills();

        await Future.wait([future1, future2]);

        // Only one should have been executed
        expect(callCount, 1);
      });
    });
  });
}
