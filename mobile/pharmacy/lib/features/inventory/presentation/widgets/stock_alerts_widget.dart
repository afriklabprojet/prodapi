import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/inventory_di_providers.dart';

/// Types d'alertes de stock
enum StockAlertType {
  critical, // Stock à 0
  low,      // Stock bas (< seuil)
  expiring, // Expiration proche
  expired,  // Expiré
}

/// Modèle d'alerte de stock
class StockAlert {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final StockAlertType type;
  final int currentStock;
  final int? threshold;
  final DateTime? expirationDate;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  const StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.type,
    required this.currentStock,
    this.threshold,
    this.expirationDate,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  StockAlert copyWith({
    bool? isRead,
    bool? isDismissed,
  }) {
    return StockAlert(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      type: type,
      currentStock: currentStock,
      threshold: threshold,
      expirationDate: expirationDate,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

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
            id: json['id']?.toString() ?? '',
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
          // Header
          if (widget.showHeader) _buildHeader(),
          
          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 12),
          
          // Alert summary cards
          _buildSummaryCards(),
          const SizedBox(height: 16),
          
          // Alerts list
          if (filteredAlerts.isEmpty)
            _buildEmptyState()
          else
            ...filteredAlerts.map((alert) => _StockAlertCard(
              alert: alert,
              onTap: () => _markAsRead(alert.id),
              onDismiss: () => _dismissAlert(alert.id),
              onAction: () => _handleAlertAction(alert),
            )),
          
          // View all button
          if (widget.onViewAll != null && _alerts.length > widget.maxAlerts)
            _buildViewAllButton(),
          
          // Add bottom padding for safety
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
          _FilterChip(
            label: 'Tous',
            count: _alerts.where((a) => !a.isDismissed).length,
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          _FilterChip(
            label: 'Rupture',
            count: _getAlertCountByType(StockAlertType.critical),
            color: Colors.red,
            isSelected: _filterType == StockAlertType.critical,
            onTap: () => setState(() => _filterType = StockAlertType.critical),
          ),
          _FilterChip(
            label: 'Stock bas',
            count: _getAlertCountByType(StockAlertType.low),
            color: Colors.orange,
            isSelected: _filterType == StockAlertType.low,
            onTap: () => setState(() => _filterType = StockAlertType.low),
          ),
          _FilterChip(
            label: 'Expiration',
            count: _getAlertCountByType(StockAlertType.expiring),
            color: Colors.orange,
            isSelected: _filterType == StockAlertType.expiring,
            onTap: () => setState(() => _filterType = StockAlertType.expiring),
          ),
          _FilterChip(
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
          child: _SummaryCard(
            icon: Icons.error,
            iconColor: Colors.red,
            label: 'Ruptures',
            count: _getAlertCountByType(StockAlertType.critical),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_down,
            iconColor: Colors.orange,
            label: 'Stock bas',
            count: _getAlertCountByType(StockAlertType.low),
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
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
      builder: (context) => const _AlertSettingsSheet(),
    );
  }

  void _handleAlertAction(StockAlert alert) {
    switch (alert.type) {
      case StockAlertType.critical:
      case StockAlertType.low:
        // Navigate to reorder page
        _showReorderDialog(alert);
        break;
      case StockAlertType.expiring:
      case StockAlertType.expired:
        // Show options for expiring products
        _showExpirationOptions(alert);
        break;
    }
  }

  void _showReorderDialog(StockAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commander du stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produit: ${alert.productName}'),
            const SizedBox(height: 8),
            Text('Stock actuel: ${alert.currentStock}'),
            if (alert.threshold != null)
              Text('Seuil d\'alerte: ${alert.threshold}'),
            const SizedBox(height: 16),
            const Text('Quantité à commander:'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: '${(alert.threshold ?? 20) * 2}',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'unités',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Commande envoyée au fournisseur'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Commander', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExpirationOptions(StockAlert alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alert.productName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert.type == StockAlertType.expired
                  ? 'Ce produit est expiré'
                  : 'Ce produit expire bientôt',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _ActionTile(
              icon: Icons.discount,
              iconColor: Colors.orange,
              title: 'Appliquer une promotion',
              subtitle: 'Réduire le prix pour écouler le stock',
              onTap: () {
                Navigator.of(context).pop();
                _showPromotionDialog(context, alert);
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              iconColor: Colors.red,
              title: 'Retirer du stock',
              subtitle: 'Marquer comme perte',
              onTap: () {
                Navigator.of(context).pop();
                _showLossDialog(context, alert);
              },
            ),
            if (alert.type == StockAlertType.expiring)
              _ActionTile(
                icon: Icons.access_time,
                iconColor: Colors.orange,
                title: 'Reporter le rappel',
                subtitle: 'Rappeler dans 7 jours',
                onTap: () {
                  Navigator.of(context).pop();
                  _dismissAlert(alert.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, StockAlert alert) {
    double discountPercentage = 10.0;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.discount, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Appliquer une promotion'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.medication, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Discount percentage
                const Text(
                  'Réduction',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: discountPercentage,
                        min: 5,
                        max: 70,
                        divisions: 13,
                        label: '${discountPercentage.toInt()}%',
                        onChanged: (value) {
                          setDialogState(() {
                            discountPercentage = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${discountPercentage.toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date range
                const Text(
                  'Période de promotion',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              startDate = date;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate.add(const Duration(days: 7));
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Début',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${startDate.day}/${startDate.month}/${startDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 180)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${endDate.day}/${endDate.month}/${endDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Call the API to apply promotion
                _applyPromotion(
                  int.tryParse(alert.productId) ?? 0,
                  discountPercentage,
                  startDate,
                  endDate,
                );
              },
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('Appliquer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLossDialog(BuildContext context, StockAlert alert) {
    final quantityController = TextEditingController(text: '${alert.currentStock}');
    String selectedReason = 'Produit expiré';
    final notesController = TextEditingController();
    
    final reasons = [
      'Produit expiré',
      'Produit endommagé',
      'Erreur d\'inventaire',
      'Vol/Perte',
      'Rappel fournisseur',
      'Autre',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Retirer du stock'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.medication, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Stock actuel: ${alert.currentStock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Quantity
                const Text(
                  'Quantité à retirer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: 'unités',
                    hintText: 'Quantité',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reason
                const Text(
                  'Raison de la perte',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((reason) {
                    final isSelected = selectedReason == reason;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = reason;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: isSelected ? Colors.red.shade800 : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Notes
                const Text(
                  'Notes (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Ajouter des détails...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer une quantité valide'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                // Call the API to mark as loss
                _markAsLoss(
                  int.tryParse(alert.productId) ?? 0,
                  quantity,
                  selectedReason,
                  notesController.text.isNotEmpty ? notesController.text : null,
                );
              },
              icon: const Icon(Icons.delete, color: Colors.white, size: 18),
              label: const Text('Retirer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      quantityController.dispose();
      notesController.dispose();
    });
  }

  Future<void> _applyPromotion(
    int productId,
    double discountPercentage,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Application de la promotion...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await ref.read(inventoryRepositoryProvider).applyPromotion(
        productId,
        discountPercentage,
        endDate: endDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Promotion de ${discountPercentage.toInt()}% appliquée'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          // Reload alerts after successful action
          _loadAlerts();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsLoss(
    int productId,
    int quantity,
    String reason,
    String? notes,
  ) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Mise à jour du stock...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await ref.read(inventoryRepositoryProvider).markAsLoss(
        productId,
        quantity,
        reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('$quantity unité(s) retirée(s) du stock'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          // Reload alerts after successful action
          _loadAlerts();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Carte d'alerte individuelle
class _StockAlertCard extends StatelessWidget {
  final StockAlert alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  const _StockAlertCard({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
    required this.onAction,
  });

  Color get _alertColor {
    switch (alert.type) {
      case StockAlertType.critical:
        return Colors.red;
      case StockAlertType.low:
        return Colors.orange;
      case StockAlertType.expiring:
        return Colors.orange;
      case StockAlertType.expired:
        return Colors.red.shade900;
    }
  }

  Color _alertBgColor(BuildContext context) {
    final isDark = AppColors.isDark(context);
    switch (alert.type) {
      case StockAlertType.critical:
        return isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1);
      case StockAlertType.low:
        return isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.1);
      case StockAlertType.expiring:
        return isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
      case StockAlertType.expired:
        return isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
    }
  }

  IconData get _alertIcon {
    switch (alert.type) {
      case StockAlertType.critical:
        return Icons.error;
      case StockAlertType.low:
        return Icons.trending_down;
      case StockAlertType.expiring:
        return Icons.schedule;
      case StockAlertType.expired:
        return Icons.event_busy;
    }
  }

  String get _alertTitle {
    switch (alert.type) {
      case StockAlertType.critical:
        return 'Rupture de stock';
      case StockAlertType.low:
        return 'Stock bas';
      case StockAlertType.expiring:
        return 'Expiration proche';
      case StockAlertType.expired:
        return 'Produit expiré';
    }
  }

  String get _alertSubtitle {
    switch (alert.type) {
      case StockAlertType.critical:
        return 'Stock à 0';
      case StockAlertType.low:
        return '${alert.currentStock} restants (seuil: ${alert.threshold})';
      case StockAlertType.expiring:
        final days = alert.expirationDate?.difference(DateTime.now()).inDays ?? 0;
        return 'Expire dans $days jours';
      case StockAlertType.expired:
        final days = DateTime.now().difference(alert.expirationDate!).inDays;
        return 'Expiré depuis $days jours';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.visibility_off, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alert.isRead 
                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade200) 
                  : _alertColor.withValues(alpha: 0.3),
              width: alert.isRead ? 1 : 2,
            ),
            boxShadow: alert.isRead ? null : [
              BoxShadow(
                color: _alertColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Alert icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _alertBgColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_alertIcon, color: _alertColor, size: 24),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (!alert.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: _alertColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              _alertTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _alertColor,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _alertSubtitle,
                        style: TextStyle(
                          color: AppColors.textColor(context).withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                
                // Action button
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textColor(context).withValues(alpha: 0.4)),
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Theme.of(context).colorScheme.primary) 
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textColor(context).withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.3) 
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textColor(context).withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Summary card
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color backgroundColor;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: iconColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action tile for bottom sheet
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

/// Settings sheet for alert configuration
class _AlertSettingsSheet extends StatefulWidget {
  const _AlertSettingsSheet();

  @override
  State<_AlertSettingsSheet> createState() => _AlertSettingsSheetState();
}

class _AlertSettingsSheetState extends State<_AlertSettingsSheet> {
  int _defaultThreshold = 20;
  int _expirationWarningDays = 30;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Paramètres d\'alerte',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: AppColors.textColor(context),
              ),
            ),
          ),
          Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          
          // Default threshold
          ListTile(
            leading: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
            title: Text('Seuil d\'alerte par défaut', style: TextStyle(color: AppColors.textColor(context))),
            subtitle: Text('$_defaultThreshold unités', style: TextStyle(color: AppColors.textColor(context).withValues(alpha: 0.6))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: AppColors.textColor(context)),
                  onPressed: () {
                    if (_defaultThreshold > 5) {
                      setState(() => _defaultThreshold -= 5);
                    }
                  },
                ),
                Text('$_defaultThreshold', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColor(context))),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppColors.textColor(context)),
                  onPressed: () {
                    setState(() => _defaultThreshold += 5);
                  },
                ),
              ],
            ),
          ),
          
          // Expiration warning
          ListTile(
            leading: Icon(Icons.event, color: Colors.orange),
            title: Text('Alerte d\'expiration', style: TextStyle(color: AppColors.textColor(context))),
            subtitle: Text('$_expirationWarningDays jours avant', style: TextStyle(color: AppColors.textColor(context).withValues(alpha: 0.6))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: AppColors.textColor(context)),
                  onPressed: () {
                    if (_expirationWarningDays > 7) {
                      setState(() => _expirationWarningDays -= 7);
                    }
                  },
                ),
                Text('$_expirationWarningDays', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColor(context))),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppColors.textColor(context)),
                  onPressed: () {
                    setState(() => _expirationWarningDays += 7);
                  },
                ),
              ],
            ),
          ),
          
          Divider(color: AppColors.isDark(context) ? Colors.grey.shade700 : Colors.grey.shade300),
          
          // Push notifications
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            title: Text('Notifications push', style: TextStyle(color: AppColors.textColor(context))),
            subtitle: Text('Recevoir des alertes sur votre téléphone', style: TextStyle(color: AppColors.textColor(context).withValues(alpha: 0.6))),
            secondary: Icon(Icons.notifications, color: AppColors.textColor(context).withValues(alpha: 0.7)),
          ),
          
          // Email notifications
          SwitchListTile(
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            title: Text('Notifications email', style: TextStyle(color: AppColors.textColor(context))),
            subtitle: Text('Recevoir un résumé quotidien par email', style: TextStyle(color: AppColors.textColor(context).withValues(alpha: 0.6))),
            secondary: Icon(Icons.email, color: AppColors.textColor(context).withValues(alpha: 0.7)),
          ),
          
          // Sound
          SwitchListTile(
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
            title: Text('Son d\'alerte', style: TextStyle(color: AppColors.textColor(context))),
            subtitle: Text('Jouer un son lors d\'une alerte critique', style: TextStyle(color: AppColors.textColor(context).withValues(alpha: 0.6))),
            secondary: Icon(Icons.volume_up, color: AppColors.textColor(context).withValues(alpha: 0.7)),
          ),
          
          // Save button
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres sauvegardés'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
