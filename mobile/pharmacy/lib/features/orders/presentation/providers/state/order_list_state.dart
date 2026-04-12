import '../../../domain/entities/order_entity.dart';
import '../../../domain/enums/order_status.dart';

/// Statuts possibles de la liste de commandes
enum OrderLoadStatus { initial, loading, loadingMore, loaded, error }

/// Métadonnées de pagination cursor-based
/// Compatible avec pagination offset (fallback) et cursor (recommandé)
class PaginationMeta {
  /// Curseur pour charger la page suivante (null = pas de page suivante)
  final String? nextCursor;

  /// Nombre d'éléments par page
  final int perPage;

  /// Nombre total estimé (peut être approximatif avec cursor)
  final int total;

  /// Indique s'il y a plus de données à charger
  final bool hasMore;

  const PaginationMeta({
    this.nextCursor,
    this.perPage = 20,
    this.total = 0,
    this.hasMore = false,
  });

  PaginationMeta copyWith({
    String? nextCursor,
    int? perPage,
    int? total,
    bool? hasMore,
  }) {
    return PaginationMeta(
      nextCursor: nextCursor,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Factory pour créer depuis une réponse API offset-based (fallback)
  factory PaginationMeta.fromOffsetPagination({
    required int currentPage,
    required int lastPage,
    int perPage = 20,
    int total = 0,
  }) {
    final hasMore = currentPage < lastPage;
    return PaginationMeta(
      // Convertir page en pseudo-cursor pour compatibilité
      nextCursor: hasMore ? '${currentPage + 1}' : null,
      perPage: perPage,
      total: total,
      hasMore: hasMore,
    );
  }

  /// Factory pour créer depuis une réponse API cursor-based
  factory PaginationMeta.fromCursorPagination({
    String? nextCursor,
    int perPage = 20,
    int total = 0,
  }) {
    return PaginationMeta(
      nextCursor: nextCursor,
      perPage: perPage,
      total: total,
      hasMore: nextCursor != null,
    );
  }
}

/// État de la liste de commandes
class OrderListState {
  final OrderLoadStatus status;
  final List<OrderEntity> orders;
  final String? errorMessage;
  final OrderStatusFilter activeFilter;
  final PaginationMeta pagination;

  const OrderListState({
    this.status = OrderLoadStatus.initial,
    this.orders = const [],
    this.errorMessage,
    this.activeFilter = OrderStatusFilter.pending,
    this.pagination = const PaginationMeta(),
  });

  bool get hasMore => pagination.hasMore;
  bool get isLoadingMore => status == OrderLoadStatus.loadingMore;

  OrderListState copyWith({
    OrderLoadStatus? status,
    List<OrderEntity>? orders,
    String? errorMessage,
    OrderStatusFilter? activeFilter,
    PaginationMeta? pagination,
  }) {
    return OrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
      pagination: pagination ?? this.pagination,
    );
  }

  /// Nombre de commandes en attente
  int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  /// Nombre de commandes confirmées
  int get confirmedCount =>
      orders.where((o) => o.status == OrderStatus.confirmed).length;

  /// Nombre de commandes prêtes
  int get readyCount =>
      orders.where((o) => o.status == OrderStatus.ready).length;

  /// Nombre de commandes livrées
  int get deliveredCount =>
      orders.where((o) => o.status == OrderStatus.delivered).length;

  @override
  String toString() =>
      'OrderListState(status: $status, orders: ${orders.length}, filter: ${activeFilter.apiValue})';
}
