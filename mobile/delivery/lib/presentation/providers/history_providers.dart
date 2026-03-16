import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery.dart';
import '../../data/models/delivery_filters.dart';
import '../../data/repositories/delivery_repository.dart';

/// Provider pour les filtres de l'historique
final historyFiltersProvider = NotifierProvider<HistoryFiltersNotifier, DeliveryFilters>(HistoryFiltersNotifier.new);

class HistoryFiltersNotifier extends Notifier<DeliveryFilters> {
  @override
  DeliveryFilters build() => DeliveryFilters.empty();

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setPharmacy(String? id, String? name) {
    state = state.copyWith(pharmacyId: id, pharmacyName: name);
  }

  void setSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setSortOrder(SortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void setAmountRange(double? min, double? max) {
    state = state.copyWith(minAmount: min, maxAmount: max);
  }

  void setPreset(String preset) {
    switch (preset) {
      case 'today':
        state = DeliveryFilters.today();
        break;
      case 'week':
        state = DeliveryFilters.thisWeek();
        break;
      case 'month':
        state = DeliveryFilters.thisMonth();
        break;
      default:
        state = DeliveryFilters.empty();
    }
  }

  void clearFilters() {
    state = DeliveryFilters.empty();
  }

  void clearDateRange() {
    state = state.copyWith(clearDateFrom: true, clearDateTo: true);
  }

  void clearStatus() {
    state = state.copyWith(clearStatus: true);
  }

  void clearPharmacy() {
    state = state.copyWith(clearPharmacy: true);
  }
}

/// Provider pour l'historique filtré des livraisons
final filteredHistoryProvider = FutureProvider<List<Delivery>>((ref) async {
  final filters = ref.watch(historyFiltersProvider);
  final repository = ref.read(deliveryRepositoryProvider);
  
  // Récupère toutes les livraisons historiques
  final deliveries = await repository.getDeliveries(status: 'history');
  
  // Applique les filtres côté client
  return _applyFilters(deliveries, filters);
});

/// Provider pour les pharmacies uniques (pour le filtre)
final uniquePharmaciesProvider = FutureProvider<List<PharmacyOption>>((ref) async {
  final repository = ref.read(deliveryRepositoryProvider);
  final deliveries = await repository.getDeliveries(status: 'history');
  
  final pharmacies = <String, PharmacyOption>{};
  for (final delivery in deliveries) {
    final name = delivery.pharmacyName;
    if (!pharmacies.containsKey(name)) {
      pharmacies[name] = PharmacyOption(
        id: delivery.id.toString(), // ID de livraison comme proxy
        name: name,
      );
    }
  }
  
  return pharmacies.values.toList()..sort((a, b) => a.name.compareTo(b.name));
});

/// Provider pour les statistiques de l'historique
final historyStatsProvider = FutureProvider<HistoryStats>((ref) async {
  final deliveries = await ref.watch(filteredHistoryProvider.future);
  
  int delivered = 0;
  int cancelled = 0;
  double totalEarnings = 0;
  
  for (final delivery in deliveries) {
    if (delivery.status == 'delivered') {
      delivered++;
      totalEarnings += delivery.deliveryFee ?? 0;
    } else if (delivery.status == 'cancelled') {
      cancelled++;
    }
  }
  
  return HistoryStats(
    totalDeliveries: deliveries.length,
    delivered: delivered,
    cancelled: cancelled,
    totalEarnings: totalEarnings,
  );
});

List<Delivery> _applyFilters(List<Delivery> deliveries, DeliveryFilters filters) {
  var result = deliveries.toList();
  
  // Filtre par statut
  if (filters.status != null && filters.status != 'all') {
    result = result.where((d) => d.status == filters.status).toList();
  }
  
  // Filtre par date
  if (filters.dateFrom != null) {
    result = result.where((d) {
      final date = DateTime.tryParse(d.createdAt ?? '');
      return date != null && !date.isBefore(filters.dateFrom!);
    }).toList();
  }
  
  if (filters.dateTo != null) {
    result = result.where((d) {
      final date = DateTime.tryParse(d.createdAt ?? '');
      return date != null && !date.isAfter(filters.dateTo!);
    }).toList();
  }
  
  // Filtre par pharmacie
  if (filters.pharmacyName != null && filters.pharmacyName!.isNotEmpty) {
    result = result.where((d) => 
      d.pharmacyName.toLowerCase().contains(filters.pharmacyName!.toLowerCase())
    ).toList();
  }
  
  // Filtre par montant
  if (filters.minAmount != null) {
    result = result.where((d) => d.totalAmount >= filters.minAmount!).toList();
  }
  
  if (filters.maxAmount != null) {
    result = result.where((d) => d.totalAmount <= filters.maxAmount!).toList();
  }
  
  // Tri
  result.sort((a, b) {
    int comparison;
    switch (filters.sortBy) {
      case SortBy.date:
        final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
        comparison = dateA.compareTo(dateB);
        break;
      case SortBy.amount:
        comparison = a.totalAmount.compareTo(b.totalAmount);
        break;
      case SortBy.pharmacyName:
        comparison = a.pharmacyName.compareTo(b.pharmacyName);
        break;
      case SortBy.status:
        comparison = a.status.compareTo(b.status);
        break;
    }
    return filters.sortOrder == SortOrder.desc ? -comparison : comparison;
  });
  
  return result;
}

/// Option de pharmacie pour le filtre
class PharmacyOption {
  final String id;
  final String name;
  
  const PharmacyOption({required this.id, required this.name});
}

/// Statistiques de l'historique
class HistoryStats {
  final int totalDeliveries;
  final int delivered;
  final int cancelled;
  final double totalEarnings;
  
  const HistoryStats({
    required this.totalDeliveries,
    required this.delivered,
    required this.cancelled,
    required this.totalEarnings,
  });
  
  double get successRate => 
    totalDeliveries > 0 ? (delivered / totalDeliveries) * 100 : 0;
}
