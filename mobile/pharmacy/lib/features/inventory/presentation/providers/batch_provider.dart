import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_batch_entity.dart';
import 'inventory_di_providers.dart';

/// Provider pour les lots avec alertes d'expiration.
/// Retourne tous les lots qui expirent dans les 90 prochains jours
/// ou qui sont déjà expirés, triés par urgence.
final expiryAlertsProvider =
    FutureProvider.autoDispose<List<ProductBatchEntity>>((ref) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      final result = await repository.getProductBatches();

      return result.fold((failure) => <ProductBatchEntity>[], (batches) {
        final alertBatches =
            batches.where((b) => b.isExpired || b.isWarning).toList()
              ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        return alertBatches;
      });
    });

/// Résumé des alertes d'expiration pour le dashboard
class ExpiryAlertSummary {
  final int expiredCount;
  final int criticalCount;
  final int warningCount;
  final int totalAlertCount;

  const ExpiryAlertSummary({
    required this.expiredCount,
    required this.criticalCount,
    required this.warningCount,
  }) : totalAlertCount = expiredCount + criticalCount + warningCount;

  bool get hasAlerts => totalAlertCount > 0;
}

/// Provider dérivé : résumé des alertes pour le dashboard
final expiryAlertSummaryProvider =
    FutureProvider.autoDispose<ExpiryAlertSummary>((ref) async {
      final batches = await ref.watch(expiryAlertsProvider.future);

      return ExpiryAlertSummary(
        expiredCount: batches.where((b) => b.isExpired).length,
        criticalCount: batches.where((b) => b.isCritical).length,
        warningCount: batches
            .where((b) => b.isExpiringSoon && !b.isCritical)
            .length,
      );
    });
