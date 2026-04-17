import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:drpharma_client/features/addresses/data/models/address_model.dart';
import 'package:drpharma_client/features/addresses/domain/entities/address_entity.dart';
import 'package:drpharma_client/features/addresses/presentation/providers/addresses_notifier.dart';

class MockAddressRemoteDataSource extends Mock
    implements AddressRemoteDataSource {}

AddressModel _makeModel({
  int id = 1,
  String label = 'Maison',
  String address = 'Rue des Fleurs',
  String? city = 'Abidjan',
  bool isDefault = false,
}) => AddressModel(
  id: id,
  label: label,
  address: address,
  city: city,
  isDefault: isDefault,
  fullAddress: '$address, ${city ?? ''}',
  hasCoordinates: false,
  createdAt: '2024-01-01T00:00:00.000Z',
  updatedAt: '2024-01-01T00:00:00.000Z',
);

AddressEntity _makeEntity({
  int id = 1,
  String label = 'Maison',
  bool isDefault = false,
}) => _makeModel(id: id, label: label, isDefault: isDefault).toEntity();

void main() {
  late MockAddressRemoteDataSource mockDs;
  late AddressesNotifier notifier;

  setUp(() {
    mockDs = MockAddressRemoteDataSource();
    notifier = AddressesNotifier(remoteDataSource: mockDs);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('AddressesState — defaultAddress getter', () {
    test('returns null when addresses list is empty', () {
      const s = AddressesState(addresses: []);
      expect(s.defaultAddress, isNull);
    });

    test('returns first address when none is marked as default', () {
      final a1 = _makeEntity(id: 1, isDefault: false);
      final a2 = _makeEntity(id: 2, isDefault: false);
      final s = AddressesState(addresses: [a1, a2]);
      expect(s.defaultAddress, a1);
    });

    test('returns the address marked as default', () {
      final a1 = _makeEntity(id: 1, isDefault: false);
      final a2 = _makeEntity(id: 2, isDefault: true);
      final a3 = _makeEntity(id: 3, isDefault: false);
      final s = AddressesState(addresses: [a1, a2, a3]);
      expect(s.defaultAddress!.id, 2);
    });
  });

  group('AddressesState — copyWith', () {
    test('clearError removes error', () {
      final s = const AddressesState(error: 'Erreur');
      expect(s.copyWith(clearError: true).error, isNull);
    });

    test('copyWith preserves error when not cleared', () {
      final s = const AddressesState(error: 'Erreur');
      expect(s.copyWith(isLoading: true).error, 'Erreur');
    });
  });

  group('AddressesNotifier — initial state', () {
    test('starts empty with no loading or error', () {
      expect(notifier.state.addresses, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });
  });

  group('AddressesNotifier — loadAddresses', () {
    test('success populates addresses list', () async {
      final models = [_makeModel(id: 1), _makeModel(id: 2)];
      when(() => mockDs.getAddresses()).thenAnswer((_) async => models);

      await notifier.loadAddresses();

      expect(notifier.state.addresses.length, 2);
      expect(notifier.state.addresses.first.id, 1);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('failure sets error message and clears loading', () async {
      when(
        () => mockDs.getAddresses(),
      ).thenThrow(Exception('réseau indisponible'));

      await notifier.loadAddresses();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.addresses, isEmpty);
    });
  });

  group('AddressesNotifier — createAddress', () {
    test('success appends new address and returns entity', () async {
      final model = _makeModel(id: 10, label: 'Bureau');
      when(
        () => mockDs.createAddress(
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenAnswer((_) async => model);

      final result = await notifier.createAddress(
        label: 'Bureau',
        address: 'Avenue du Général de Gaulle',
        city: 'Abidjan',
      );

      expect(result, isNotNull);
      expect(result!.id, 10);
      expect(notifier.state.addresses.length, 1);
      expect(notifier.state.isLoading, isFalse);
    });

    test('failure sets error and returns null', () async {
      when(
        () => mockDs.createAddress(
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenThrow(Exception('interne'));

      final result = await notifier.createAddress(
        label: 'Bureau',
        address: 'Av de Gaulle',
      );

      expect(result, isNull);
      expect(notifier.state.error, contains('adresse'));
      expect(notifier.state.isLoading, isFalse);
    });
  });

  group('AddressesNotifier — saveFromCheckout', () {
    test('uses labelHint when provided', () async {
      final model = _makeModel(id: 20, label: 'Domicile');
      when(
        () => mockDs.createAddress(
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenAnswer((_) async => model);

      await notifier.saveFromCheckout(
        address: 'Rue 10',
        city: 'Abidjan',
        phone: '+22507',
        labelHint: 'Domicile',
      );

      final captured = verify(
        () => mockDs.createAddress(
          label: captureAny(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).captured;
      expect(captured.first, 'Domicile');
    });

    test('generates auto label when labelHint is empty', () async {
      final model = _makeModel(id: 21);
      when(
        () => mockDs.createAddress(
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenAnswer((_) async => model);

      await notifier.saveFromCheckout(
        address: 'Rue 10',
        city: 'Abidjan',
        phone: '+22507',
      );

      final captured = verify(
        () => mockDs.createAddress(
          label: captureAny(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).captured;
      expect(captured.first, startsWith('Adresse '));
    });
  });

  group('AddressesNotifier — deleteAddress', () {
    test('success removes address from list', () async {
      // pre-populate
      when(
        () => mockDs.getAddresses(),
      ).thenAnswer((_) async => [_makeModel(id: 1), _makeModel(id: 2)]);
      await notifier.loadAddresses();

      when(() => mockDs.deleteAddress(1)).thenAnswer((_) async {});

      await notifier.deleteAddress(1);

      expect(notifier.state.addresses.length, 1);
      expect(notifier.state.addresses.first.id, 2);
    });

    test('failure sets error', () async {
      when(() => mockDs.deleteAddress(1)).thenThrow(Exception('server error'));

      await notifier.deleteAddress(1);

      expect(notifier.state.error, contains('supprimer'));
    });
  });

  group('AddressesNotifier — setDefaultAddress', () {
    test('success marks only the selected address as default', () async {
      when(() => mockDs.getAddresses()).thenAnswer(
        (_) async => [_makeModel(id: 1, isDefault: true), _makeModel(id: 2)],
      );
      await notifier.loadAddresses();

      when(
        () => mockDs.setDefaultAddress(2),
      ).thenAnswer((_) async => _makeModel(id: 2, isDefault: true));

      await notifier.setDefaultAddress(2);

      final addresses = notifier.state.addresses;
      expect(addresses.firstWhere((a) => a.id == 2).isDefault, isTrue);
      expect(addresses.firstWhere((a) => a.id == 1).isDefault, isFalse);
    });

    test('failure sets error', () async {
      when(
        () => mockDs.setDefaultAddress(99),
      ).thenThrow(Exception('not found'));

      await notifier.setDefaultAddress(99);

      expect(notifier.state.error, contains('défaut'));
    });
  });

  group('AddressesNotifier — updateAddress', () {
    test('success replaces updated address in list', () async {
      when(
        () => mockDs.getAddresses(),
      ).thenAnswer((_) async => [_makeModel(id: 1, label: 'Avant')]);
      await notifier.loadAddresses();

      final updatedModel = _makeModel(id: 1, label: 'Après');
      when(
        () => mockDs.updateAddress(
          id: any(named: 'id'),
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenAnswer((_) async => updatedModel);

      await notifier.updateAddress(id: 1, label: 'Après');

      expect(notifier.state.addresses.first.label, 'Après');
      expect(notifier.state.isLoading, isFalse);
    });

    test('failure sets error and rethrows', () async {
      when(
        () => mockDs.updateAddress(
          id: any(named: 'id'),
          label: any(named: 'label'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          phone: any(named: 'phone'),
          instructions: any(named: 'instructions'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          isDefault: any(named: 'isDefault'),
        ),
      ).thenThrow(Exception('server error'));

      await expectLater(
        notifier.updateAddress(id: 1, label: 'Mauvais'),
        throwsException,
      );
      expect(notifier.state.error, contains('mettre à jour'));
    });
  });
}
