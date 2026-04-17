import '../../domain/enums/order_status.dart';

/// Extension de localisation pour [OrderStatus].
/// Utilise `displayLabel` de l'enum directement (app 100% française).
extension OrderStatusL10n on OrderStatus {
  String get localizedLabel => displayLabel;
}

/// Extension de localisation pour [OrderStatusFilter].
extension OrderStatusFilterL10n on OrderStatusFilter {
  String get localizedLabel => displayLabel;
}
