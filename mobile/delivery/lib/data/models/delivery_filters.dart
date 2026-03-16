/// Modèle pour les filtres de l'historique des livraisons
class DeliveryFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status; // 'all', 'delivered', 'cancelled'
  final String? pharmacyId;
  final String? pharmacyName;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final double? minAmount;
  final double? maxAmount;

  const DeliveryFilters({
    this.dateFrom,
    this.dateTo,
    this.status,
    this.pharmacyId,
    this.pharmacyName,
    this.sortBy = SortBy.date,
    this.sortOrder = SortOrder.desc,
    this.minAmount,
    this.maxAmount,
  });

  /// Filtre par défaut (aucun filtre)
  factory DeliveryFilters.empty() => const DeliveryFilters();

  /// Filtre pour aujourd'hui
  factory DeliveryFilters.today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DeliveryFilters(
      dateFrom: startOfDay,
      dateTo: endOfDay,
    );
  }

  /// Filtre pour cette semaine
  factory DeliveryFilters.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DeliveryFilters(
      dateFrom: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      dateTo: now,
    );
  }

  /// Filtre pour ce mois
  factory DeliveryFilters.thisMonth() {
    final now = DateTime.now();
    return DeliveryFilters(
      dateFrom: DateTime(now.year, now.month, 1),
      dateTo: now,
    );
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters =>
      dateFrom != null ||
      dateTo != null ||
      (status != null && status != 'all') ||
      pharmacyId != null ||
      pharmacyName != null ||
      minAmount != null ||
      maxAmount != null ||
      sortBy != SortBy.date ||
      sortOrder != SortOrder.desc;

  /// Compte le nombre de filtres actifs
  int get activeFilterCount {
    int count = 0;
    if (dateFrom != null || dateTo != null) count++;
    if (status != null && status != 'all') count++;
    if (pharmacyId != null || pharmacyName != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (sortBy != SortBy.date) count++;
    return count;
  }

  DeliveryFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    String? pharmacyId,
    String? pharmacyName,
    SortBy? sortBy,
    SortOrder? sortOrder,
    double? minAmount,
    double? maxAmount,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearStatus = false,
    bool clearPharmacy = false,
    bool clearAmount = false,
  }) {
    return DeliveryFilters(
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      status: clearStatus ? null : (status ?? this.status),
      pharmacyId: clearPharmacy ? null : (pharmacyId ?? this.pharmacyId),
      pharmacyName: clearPharmacy ? null : (pharmacyName ?? this.pharmacyName),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryFilters &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.status == status &&
        other.pharmacyId == pharmacyId &&
        other.pharmacyName == pharmacyName &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount;
  }

  @override
  int get hashCode => Object.hash(
        dateFrom,
        dateTo,
        status,
        pharmacyId,
        pharmacyName,
        sortBy,
        sortOrder,
        minAmount,
        maxAmount,
      );
}

enum SortBy {
  date,
  amount,
  pharmacyName,
  status,
}

enum SortOrder {
  asc,
  desc,
}

extension SortByExtension on SortBy {
  String get label {
    switch (this) {
      case SortBy.date:
        return 'Date';
      case SortBy.amount:
        return 'Montant';
      case SortBy.pharmacyName:
        return 'Pharmacie';
      case SortBy.status:
        return 'Statut';
    }
  }
}

extension SortOrderExtension on SortOrder {
  String get label {
    switch (this) {
      case SortOrder.asc:
        return 'Croissant';
      case SortOrder.desc:
        return 'Décroissant';
    }
  }
}
