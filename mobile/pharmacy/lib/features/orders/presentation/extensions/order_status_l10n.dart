import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/order_status.dart';

/// Extension de localisation pour [OrderStatus].
/// Utiliser `status.localizedLabel(l10n)` dans la couche présentation
/// au lieu de `status.displayLabel` (qui est un fallback non localisé).
extension OrderStatusL10n on OrderStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        OrderStatus.pending => l10n.orderStatusPending,
        OrderStatus.confirmed => l10n.orderStatusConfirmed,
        OrderStatus.ready => l10n.orderStatusReady,
        OrderStatus.inDelivery => l10n.orderStatusInDelivery,
        OrderStatus.delivered => l10n.orderStatusDelivered,
        OrderStatus.cancelled => l10n.orderStatusCancelled,
        OrderStatus.rejected => l10n.orderStatusRejected,
      };
}

/// Extension de localisation pour [OrderStatusFilter].
extension OrderStatusFilterL10n on OrderStatusFilter {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        OrderStatusFilter.all => l10n.orderFilterAll,
        OrderStatusFilter.pending => l10n.orderFilterPending,
        OrderStatusFilter.confirmed => l10n.orderFilterConfirmed,
        OrderStatusFilter.ready => l10n.orderFilterReady,
        OrderStatusFilter.inDelivery => l10n.orderFilterInDelivery,
        OrderStatusFilter.delivered => l10n.orderFilterDelivered,
        OrderStatusFilter.cancelled => l10n.orderFilterCancelled,
      };
}
