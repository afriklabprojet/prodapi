import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Provider pour le datasource distant de l'inventaire
final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryRemoteDataSourceImpl(apiClient: apiClient);
});

/// Provider pour le repository de l'inventaire
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final remoteDataSource = ref.watch(inventoryRemoteDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final offlineStorage = ref.watch(offlineStorageProvider);
  return InventoryRepositoryImpl(
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
    cacheService: cacheService,
    offlineStorage: offlineStorage,
  );
});
