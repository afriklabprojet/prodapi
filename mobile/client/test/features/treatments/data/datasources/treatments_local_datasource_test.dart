import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:drpharma_client/features/treatments/data/datasources/treatments_local_datasource.dart';
import 'package:drpharma_client/features/treatments/data/models/treatment_model.dart';

TreatmentModel _makeTreatment({
  String id = 'test-id',
  bool isActive = true,
  DateTime? nextRenewalDate,
  int reminderDaysBefore = 3,
  int renewalPeriodDays = 30,
}) {
  return TreatmentModel(
    id: id,
    productId: 1,
    productName: 'Paracetamol',
    renewalPeriodDays: renewalPeriodDays,
    isActive: isActive,
    nextRenewalDate: nextRenewalDate,
    reminderDaysBefore: reminderDaysBefore,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late Directory tempDir;
  late TreatmentsLocalDatasource datasource;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TreatmentModelAdapter());
    }
  });

  setUp(() async {
    datasource = TreatmentsLocalDatasource();
    await datasource.init();
  });

  tearDown(() async {
    await datasource.close();
    // Delete box file between tests
    final boxFile = File('${tempDir.path}/treatments.hive');
    if (boxFile.existsSync()) boxFile.deleteSync();
    final lockFile = File('${tempDir.path}/treatments.lock');
    if (lockFile.existsSync()) lockFile.deleteSync();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  // ── init ─────────────────────────────────────────────
  group('init', () {
    test('initializes without throwing', () async {
      expect(datasource.box, isNotNull);
    });

    test('box accessor auto-initializes when not yet initialized', () async {
      // The datasource now auto-initializes when box is accessed
      // This is the new "auto-healing" behavior
      final ds = TreatmentsLocalDatasource();
      // Should NOT throw - it auto-initializes
      final boxFuture = ds.box;
      expect(boxFuture, isA<Future<Box<TreatmentModel>>>());
      final b = await boxFuture;
      expect(b, isA<Box<TreatmentModel>>());
    });
  });

  // ── getAllTreatments ──────────────────────────────────
  group('getAllTreatments', () {
    test('returns empty list when no treatments', () async {
      final result = await datasource.getAllTreatments();
      expect(result, isEmpty);
    });

    test('returns only active treatments', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'a1', isActive: true));
      await datasource.datasourcePut(
        _makeTreatment(id: 'a2', isActive: false),
      );

      final result = await datasource.getAllTreatments();
      expect(result.length, 1);
      expect(result.first.id, 'a1');
    });

    test('sorts by nextRenewalDate ascending', () async {
      final soon = DateTime.now().add(const Duration(days: 5));
      final later = DateTime.now().add(const Duration(days: 20));
      await datasource.datasourcePut(
        _makeTreatment(id: 'b1', nextRenewalDate: later),
      );
      await datasource.datasourcePut(
        _makeTreatment(id: 'b2', nextRenewalDate: soon),
      );

      final result = await datasource.getAllTreatments();
      expect(result.first.id, 'b2');
    });
  });

  // ── getTreatmentsNeedingRenewal ───────────────────────
  group('getTreatmentsNeedingRenewal', () {
    test('returns empty when no active treatments', () async {
      final result = await datasource.getTreatmentsNeedingRenewal();
      expect(result, isEmpty);
    });

    test('returns treatment within reminder window', () async {
      final inWindow = DateTime.now().add(
        const Duration(days: 2),
      ); // within 3 days
      await datasource.datasourcePut(
        _makeTreatment(
          id: 'c1',
          nextRenewalDate: inWindow,
          reminderDaysBefore: 3,
        ),
      );
      final result = await datasource.getTreatmentsNeedingRenewal();
      expect(result.length, 1);
    });

    test('excludes treatment outside reminder window', () async {
      final farOut = DateTime.now().add(const Duration(days: 10));
      await datasource.datasourcePut(
        _makeTreatment(
          id: 'c2',
          nextRenewalDate: farOut,
          reminderDaysBefore: 3,
        ),
      );
      final result = await datasource.getTreatmentsNeedingRenewal();
      expect(result, isEmpty);
    });

    test('excludes inactive treatments', () async {
      final inWindow = DateTime.now().add(const Duration(days: 1));
      await datasource.datasourcePut(
        _makeTreatment(
          id: 'c3',
          isActive: false,
          nextRenewalDate: inWindow,
          reminderDaysBefore: 3,
        ),
      );
      final result = await datasource.getTreatmentsNeedingRenewal();
      expect(result, isEmpty);
    });
  });

  // ── getTreatmentById ──────────────────────────────────
  group('getTreatmentById', () {
    test('returns null for unknown id', () async {
      final result = await datasource.getTreatmentById('nonexistent');
      expect(result, isNull);
    });

    test('returns treatment by id', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'd1'));
      final result = await datasource.getTreatmentById('d1');
      expect(result?.id, 'd1');
    });
  });

  // ── addTreatment ──────────────────────────────────────
  group('addTreatment', () {
    test('adds treatment and returns it with same id', () async {
      final t = _makeTreatment(id: 'e1');
      final result = await datasource.addTreatment(t);
      expect(result.id, 'e1');

      final stored = await datasource.getTreatmentById('e1');
      expect(stored, isNotNull);
    });

    test('generates id when id is empty', () async {
      final t = _makeTreatment(id: '');
      final result = await datasource.addTreatment(t);
      expect(result.id, isNotEmpty);
    });

    test('sets nextRenewalDate when null', () async {
      final t = _makeTreatment(
        id: 'e2',
        nextRenewalDate: null,
        renewalPeriodDays: 30,
      );
      final result = await datasource.addTreatment(t);
      expect(result.nextRenewalDate, isNotNull);
    });

    test('preserves existing nextRenewalDate', () async {
      final date = DateTime(2025, 6, 15);
      final t = _makeTreatment(id: 'e3', nextRenewalDate: date);
      final result = await datasource.addTreatment(t);
      expect(result.nextRenewalDate, date);
    });
  });

  // ── updateTreatment ───────────────────────────────────
  group('updateTreatment', () {
    test('updates and returns the updated treatment', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'f1'));

      final updated = TreatmentModel(
        id: 'f1',
        productId: 2,
        productName: 'Ibuprofen',
        renewalPeriodDays: 60,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );
      final result = await datasource.updateTreatment(updated);
      expect(result.productName, 'Ibuprofen');
    });
  });

  // ── deleteTreatment (soft delete) ─────────────────────
  group('deleteTreatment', () {
    test('marks treatment as inactive', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'g1'));
      await datasource.deleteTreatment('g1');

      final stored = await datasource.getTreatmentById('g1');
      expect(stored?.isActive, false);
    });

    test('does nothing if treatment not found', () async {
      // Should complete without throwing
      await datasource.deleteTreatment('nonexistent');
    });
  });

  // ── hardDeleteTreatment ───────────────────────────────
  group('hardDeleteTreatment', () {
    test('removes treatment from box', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'h1'));
      await datasource.hardDeleteTreatment('h1');

      final stored = await datasource.getTreatmentById('h1');
      expect(stored, isNull);
    });
  });

  // ── markAsOrdered ─────────────────────────────────────
  group('markAsOrdered', () {
    test('updates lastOrderedAt and nextRenewalDate', () async {
      await datasource.datasourcePut(
        _makeTreatment(id: 'i1', renewalPeriodDays: 30),
      );

      final result = await datasource.markAsOrdered('i1');
      expect(result.lastOrderedAt, isNotNull);
      expect(result.nextRenewalDate, isNotNull);
    });

    test('throws for unknown treatment id', () async {
      expect(
        () => datasource.markAsOrdered('nonexistent'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── toggleReminder ────────────────────────────────────
  group('toggleReminder', () {
    test('enables reminder', () async {
      final t = TreatmentModel(
        id: 'j1',
        productId: 1,
        productName: 'Aspirin',
        renewalPeriodDays: 30,
        reminderEnabled: false,
        createdAt: DateTime(2024, 1, 1),
      );
      await datasource.datasourcePut(t);
      final result = await datasource.toggleReminder('j1', true);
      expect(result.reminderEnabled, true);
    });

    test('disables reminder', () async {
      await datasource.datasourcePut(_makeTreatment(id: 'j2'));
      final result = await datasource.toggleReminder('j2', false);
      expect(result.reminderEnabled, false);
    });

    test('throws for unknown treatment id', () async {
      expect(
        () => datasource.toggleReminder('nonexistent', true),
        throwsA(isA<Exception>()),
      );
    });
  });
}

// Extension helper to put a TreatmentModel directly in the box
extension _DatasourceHelper on TreatmentsLocalDatasource {
  Future<void> datasourcePut(TreatmentModel t) async =>
      (await box).put(t.id, t);
}
