import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/address_remote_datasource.dart';
import '../../domain/entities/address_entity.dart';

class AddressesState {
  final List<AddressEntity> addresses;
  final bool isLoading;
  final String? error;
  final AddressEntity? selectedAddress;

  const AddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
    this.selectedAddress,
  });

  AddressesState copyWith({
    List<AddressEntity>? addresses,
    bool? isLoading,
    String? error,
    bool clearError = false,
    AddressEntity? selectedAddress,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }

  AddressEntity? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}

class AddressesNotifier extends StateNotifier<AddressesState> {
  final AddressRemoteDataSource remoteDataSource;

  AddressesNotifier({required this.remoteDataSource})
    : super(const AddressesState());

  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final models = await remoteDataSource.getAddresses();
      final addresses = models.map((m) => m.toEntity()).toList();
      state = state.copyWith(addresses: addresses, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to load addresses', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger vos adresses',
      );
    }
  }

  Future<AddressEntity?> createAddress({
    required String label,
    required String address,
    String? city,
    String? district,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final model = await remoteDataSource.createAddress(
        label: label,
        address: address,
        city: city,
        district: district,
        phone: phone,
        instructions: instructions,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      final entity = model.toEntity();
      state = state.copyWith(
        addresses: [...state.addresses, entity],
        isLoading: false,
      );
      return entity;
    } catch (e) {
      AppLogger.error('Failed to create address', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de créer l\'adresse',
      );
      return null;
    }
  }

  /// Convenience method used by the checkout flow to persist a manually entered
  /// address without duplicating the label-generation logic in the UI layer.
  Future<AddressEntity?> saveFromCheckout({
    required String address,
    required String city,
    required String phone,
    String labelHint = '',
    double? latitude,
    double? longitude,
  }) {
    final label = labelHint.isNotEmpty
        ? labelHint
        : 'Adresse ${DateTime.now().day}/${DateTime.now().month}';
    return createAddress(
      label: label,
      address: address,
      city: city,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isDefault: state.addresses.isEmpty,
    );
  }

  Future<void> deleteAddress(int id) async {
    try {
      await remoteDataSource.deleteAddress(id);
      final updated = state.addresses.where((a) => a.id != id).toList();
      state = state.copyWith(addresses: updated);
    } catch (e) {
      AppLogger.error('Failed to delete address', error: e);
      state = state.copyWith(error: 'Impossible de supprimer l\'adresse');
    }
  }

  Future<void> setDefaultAddress(int id) async {
    try {
      await remoteDataSource.setDefaultAddress(id);
      final updated = state.addresses.map((a) {
        return a.copyWith(isDefault: a.id == id);
      }).toList();
      state = state.copyWith(addresses: updated);
    } catch (e) {
      AppLogger.error('Failed to set default address', error: e);
      state = state.copyWith(
        error: 'Impossible de définir l\'adresse par défaut',
      );
    }
  }

  Future<void> updateAddress({
    required int id,
    String? label,
    String? address,
    String? city,
    String? phone,
    String? instructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final model = await remoteDataSource.updateAddress(
        id: id,
        label: label,
        address: address,
        city: city,
        phone: phone,
        instructions: instructions,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      final entity = model.toEntity();
      final updated = state.addresses
          .map((a) => a.id == id ? entity : a)
          .toList();
      state = state.copyWith(addresses: updated, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to update address', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de mettre à jour l\'adresse',
      );
      rethrow;
    }
  }
}
