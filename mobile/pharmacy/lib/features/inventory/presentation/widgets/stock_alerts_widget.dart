import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'stock_alert_card.dart';
import 'stock_alert_dialogs.dart';
import 'stock_alert_model.dart';
import 'stock_alert_settings_sheet.dart';

export 'stock_alert_model.dart' show StockAlert, StockAlertType;

/// Widget principal des alertes de stock
class StockAlertsWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  final int maxAlerts;
  final VoidCallback? onViewAll;
  
  const StockAlertsWidget({
    super.key,
    this.showHeader = true,
    this.maxAlerts = 5,
    this.onViewAll,
  });

  @override
  ConsumerState<StockAlertsWidget> createState() => _StockAlertsWidgetState();
}

class _StockAlertsWidgetState extends ConsumerState<StockAlertsWidget> {
  List<StockAlert> _alerts = [];
  StockAlertType? _filterType;
  bool _showDismissed = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/pharmacy/reports/stock-alerts');

      if (!mounted) return;

      final data = response.data['data'];
      final alertsJson = (data['alerts'] as List?) ?? [];

      setState(() {
        _alerts = alertsJson.map<StockAlert>((json) {
          final type = switch (json['type']?.toString()) {
            'out_of_stock' => StockAlertType.critical,
            'low_stock' => StockAlertType.low,
            'expiring_soon' => StockAlertType.expiring,
            'expired' => StockAlertType.expired,
            _ => StockAlertType.low,
          };
          return StockAlert(
            id: json['product_id']?.toString() ?? '',
            productId: json['product_id']?.toString() ?? '',
            productName: json['product_name']?.toString() ?? '',
            productImage: json['product_image']?.toString(),
            type: type,
            currentStock: (json['current_quantity'] as num?)?.toInt() ?? 0,
            threshold: (json['threshold'] as num?)?.toInt(),
            expirationDate: json['expiry_date'] != null
                ? DateTime.tryParse(json['expiry_date'].toString())
                : null,
            createdAt: DateTime.now(),
          );
        }).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _alerts = [];
          _isLoading = false;
          _errorMessage = 'Impossible de charger les alertes';
        });
      }
    }
  }

  List<StockAlert> get _filteredAlerts {
    return _alerts.where((alert) {
      if (!_showDismissed && alert.isDismissed) return false;
      if (_filterType != null && alert.type != _filterType) return false;
      return true;
    }).take(widget.maxAlerts).toList();
  }

  int get _unreadCount {
    return _alerts.where((a) => !a.isRead && !a.isDismissed).length;
  }

  int _getAlertCountByType(StockAlertType type) {
    return _alerts.where((a) => a.type == type && !a.isDismissed).length;
  }

  void _markAsRead(String alertId) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
      }
    });
  }

  void _dismissAlert(String alertId) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isDismissed: true);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _markAllAsRead() {
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    });
    HapticFeedback.lightImpact();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AlertSettingsSheet(),
    );
  }

  void _handleAlertAction(StockAlert alert) {
    switch (alert.type) {
      case StockAlertType.critical:
      case StockAlertType.low:
        showStockReorderDialog(context, alert);
        break;
      case StockAlertType.expiring:
      case StockAlertType.expired:
        showStockExpirationOptions(
          context,
          ref,
          alert,
          onDismissAlert: () => _dismissAlert(alert.id),
          onReloadAlerts: _loadAlerts,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    if (_errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadAlerts,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ));
    }

    final filteredAlerts = _filteredAlerts;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildHeader(),
          _buildFilterChips(),
          const SizedBox(height: 12),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          if (filteredAlerts.isEmpty)
            _buildEmptyState()
          else
            ...filteredAlerts.map((alert) => StockAlertCard(
              alert: alert,
              onTap: () => _markAsRead(alert.id),
              onDismiss: () => _dismissAlert(alert.id),
              onAction: () => _handleAlertAction(alert),
            )),
          if (widget.onViewAll != null && _alerts.length > widget.maxAlerts)
            _buildViewAllButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          Text(
            'Alertes de Stock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor(context),
            ),
          ),
          const SizedBox(width: 8),
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColor(context).withValues(alpha: 0.6)),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'show_dismissed':
                  setState(() => _showDismissed = !_showDismissed);
                  break;
                case 'settings':
                  _openSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Tout marquer comme lu'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'show_dismissed',
                child: Row(
                  children: [
                    Icon(_showDismissed ? Icons.visibility_off : Icons.visibility, size: 20),
                    const SizedBox(width: 8),
                    Text(_showDismissed ? 'Masquer ignorées' : 'Afficher ignorées'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Paramètres d\'alerte'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StockAlertFilterChip(
            label: 'Tous',
            count: _alerts.where((a) => !a.isDismissed).length,
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          StockAlertFilterChip(
            label: 'Rupture',
            count: _getAlertCountByType(StockAlertType.critical),
            color: Colors.red,
            isSelected: _filterType == StockAlertType.critical,
            onTap: () => setState(() => _filterType = StockAlertType.critical),
          ),
          StockAlertFilterChip(
            label: 'Stock bas',
            count: _getAlertCountByType(StockAlertType.low),
            color: Colors.orange,
            isSelected: _filterType == StockAlertType.low,
            onTap: () => setState(() => _filterType = StockAlertType.low),
          ),
          StockAlertFilterChip(
            label: 'Expiration',
            count: _getAlertCountByType(StockAlertType.expiring),
            color: Colors.orange,
            isSelected: _filterType == StockAlertType.expiring,
            onTap: () => setState(() => _filterType = StockAlertType.expiring),
          ),
          StockAlertFilterChip(
            label: 'Expirés',
            count: _getAlertCountByType(StockAlertType.expired),
            color: Colors.red.shade900,
            isSelected: _filterType == StockAlertType.expired,
            onTap: () => setState(() => _filterType = StockAlertType.expired),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: StockAlertSummaryCard(
            icon: Icons.error,
            iconColor: Colors.red,
            label: 'Ruptures',
            count: _getAlertCountByType(StockAlertType.critical),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StockAlertSummaryCard(
            icon: Icons.trending_down,
            iconColor: Colors.orange,
            label: 'Stock bas',
            count: _getAlertCountByType(StockAlertType.low),
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StockAlertSummaryCard(
            icon: Icons.schedule,
            iconColor: Colors.orange,
            label: 'Expirations',
            count: _getAlertCountByType(StockAlertType.expiring) + 
                   _getAlertCountByType(StockAlertType.expired),
            backgroundColor: Colors.orange.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tous vos stocks sont en ordre !',
            style: TextStyle(
              color: AppColors.textColor(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: widget.onViewAll,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Voir toutes les alertes'),
        ),
      ),
    );
  }
}
