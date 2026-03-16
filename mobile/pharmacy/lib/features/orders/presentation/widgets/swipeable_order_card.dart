import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Carte de commande avec actions par swipe
class SwipeableOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkReady;
  final VoidCallback? onViewDetails;

  const SwipeableOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onMarkReady,
    this.onViewDetails,
  });

  @override
  State<SwipeableOrderCard> createState() => _SwipeableOrderCardState();
}

class _SwipeableOrderCardState extends State<SwipeableOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  bool _isSwipingRight = false;

  static const double _swipeThreshold = 80;
  static const double _maxSwipe = 120;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-_maxSwipe, _maxSwipe);
      _isSwipingRight = _dragExtent > 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _swipeThreshold) {
      HapticFeedback.mediumImpact();
      if (_isSwipingRight) {
        // Accept action
        _performAction(widget.onAccept);
      } else {
        // Reject action
        _performAction(widget.onReject);
      }
    }
    _resetPosition();
  }

  void _performAction(VoidCallback? action) {
    action?.call();
  }

  void _resetPosition() {
    _animation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0).then((_) {
      setState(() => _dragExtent = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] as String;
    final canSwipe = status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // Background actions
          if (canSwipe) ...[
            // Accept background (right swipe)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: _dragExtent > _swipeThreshold ? 32 : 24,
                    ),
                    const SizedBox(width: 8),
                    if (_dragExtent > 40)
                      const Text(
                        'Accepter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Reject background (left swipe)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_dragExtent < -40)
                      const Text(
                        'Refuser',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.cancel,
                      color: Colors.white,
                      size: _dragExtent.abs() > _swipeThreshold ? 32 : 24,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Card
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final offset = _controller.isAnimating 
                  ? _animation.value 
                  : _dragExtent;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
              onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
              onTap: widget.onTap,
              child: _OrderCardContent(
                order: widget.order,
                onAccept: widget.onAccept,
                onReject: widget.onReject,
                onMarkReady: widget.onMarkReady,
                onViewDetails: widget.onViewDetails,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu de la carte de commande
class _OrderCardContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkReady;
  final VoidCallback? onViewDetails;

  const _OrderCardContent({
    required this.order,
    this.onAccept,
    this.onReject,
    this.onMarkReady,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final orderId = order['id'] as String;
    final customerName = order['customerName'] as String;
    final total = order['total'] as int;
    final itemCount = order['itemCount'] as int;
    final createdAt = order['createdAt'] as DateTime;
    final isPriority = order['isPriority'] as bool? ?? false;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPriority ? Colors.orange : Colors.grey.shade200,
          width: isPriority ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Order ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#$orderId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isPriority) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.priority_high,
                                        size: 12,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Urgent',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeAgo(createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    _StatusBadge(status: status),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Customer info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$itemCount article${itemCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$total FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: _buildActions(context, status),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return [
          _ActionButton(
            icon: Icons.close,
            label: 'Refuser',
            color: Colors.red,
            onTap: onReject,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.check,
              label: 'Accepter',
              color: Colors.green,
              isPrimary: true,
              onTap: onAccept,
            ),
          ),
        ];
      case 'confirmed':
        return [
          _ActionButton(
            icon: Icons.visibility,
            label: 'Détails',
            color: Colors.grey.shade600,
            onTap: onViewDetails,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.check_circle,
              label: 'Prête',
              color: Theme.of(context).colorScheme.primary,
              isPrimary: true,
              onTap: onMarkReady,
            ),
          ),
        ];
      default:
        return [
          Expanded(
            child: _ActionButton(
              icon: Icons.visibility,
              label: 'Voir les détails',
              color: Colors.grey.shade600,
              onTap: onViewDetails,
            ),
          ),
        ];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

/// Badge de statut
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'En attente';
        icon = Icons.access_time;
        break;
      case 'confirmed':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        label = 'Confirmée';
        icon = Icons.thumb_up;
        break;
      case 'ready':
        bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.primary;
        label = 'Prête';
        icon = Icons.inventory_2;
        break;
      case 'picked_up':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple;
        label = 'Récupérée';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Livrée';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        label = 'Annulée';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de filtrage des commandes
class OrderFiltersWidget extends StatefulWidget {
  final Function(Map<String, dynamic> filters)? onFiltersChanged;

  const OrderFiltersWidget({
    super.key,
    this.onFiltersChanged,
  });

  @override
  State<OrderFiltersWidget> createState() => _OrderFiltersWidgetState();
}

class _OrderFiltersWidgetState extends State<OrderFiltersWidget> {
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  bool _priorityOnly = false;
  String _sortBy = 'date_desc';

  final List<Map<String, dynamic>> _statuses = [
    {'value': null, 'label': 'Tous', 'icon': Icons.all_inclusive},
    {'value': 'pending', 'label': 'En attente', 'icon': Icons.access_time},
    {'value': 'confirmed', 'label': 'Confirmées', 'icon': Icons.thumb_up},
    {'value': 'ready', 'label': 'Prêtes', 'icon': Icons.inventory_2},
    {'value': 'delivered', 'label': 'Livrées', 'icon': Icons.check_circle},
    {'value': 'cancelled', 'label': 'Annulées', 'icon': Icons.cancel},
  ];

  void _notifyFiltersChanged() {
    widget.onFiltersChanged?.call({
      'status': _selectedStatus,
      'dateRange': _dateRange,
      'priorityOnly': _priorityOnly,
      'sortBy': _sortBy,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statuses.length,
            itemBuilder: (context, index) {
              final status = _statuses[index];
              final isSelected = status['value'] == _selectedStatus;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(status['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedStatus = status['value']);
                    _notifyFiltersChanged();
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Additional filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Date range picker
              Expanded(
                child: _FilterButton(
                  icon: Icons.calendar_today,
                  label: _dateRange != null
                      ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                      : 'Toutes les dates',
                  isActive: _dateRange != null,
                  onTap: () => _selectDateRange(context),
                ),
              ),
              const SizedBox(width: 8),
              
              // Priority filter
              _FilterButton(
                icon: Icons.priority_high,
                label: 'Urgent',
                isActive: _priorityOnly,
                onTap: () {
                  setState(() => _priorityOnly = !_priorityOnly);
                  _notifyFiltersChanged();
                },
              ),
              const SizedBox(width: 8),
              
              // Sort button
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _notifyFiltersChanged();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'date_desc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 18),
                        SizedBox(width: 8),
                        Text('Plus récentes'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'date_asc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 18),
                        SizedBox(width: 8),
                        Text('Plus anciennes'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'total_desc',
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, size: 18),
                        SizedBox(width: 8),
                        Text('Montant (haut)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'total_asc',
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, size: 18),
                        SizedBox(width: 8),
                        Text('Montant (bas)'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sort, size: 20),
                ),
              ),
            ],
          ),
        ),
        
        // Active filters summary
        if (_hasActiveFilters) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filtres actifs',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasActiveFilters {
    return _selectedStatus != null || _dateRange != null || _priorityOnly;
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _dateRange = null;
      _priorityOnly = false;
      _sortBy = 'date_desc';
    });
    _notifyFiltersChanged();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() => _dateRange = picked);
      _notifyFiltersChanged();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Bouton de filtre
class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Résumé des commandes groupées par statut
class OrdersSummaryWidget extends StatelessWidget {
  final Map<String, int> counts;
  final Function(String status)? onStatusTap;

  const OrdersSummaryWidget({
    super.key,
    required this.counts,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Aperçu des commandes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${counts.values.fold(0, (a, b) => a + b)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status cards
          Row(
            children: [
              _StatusCountCard(
                icon: Icons.access_time,
                label: 'En attente',
                count: counts['pending'] ?? 0,
                color: Colors.orange,
                onTap: () => onStatusTap?.call('pending'),
              ),
              const SizedBox(width: 8),
              _StatusCountCard(
                icon: Icons.inventory_2,
                label: 'Prêtes',
                count: counts['ready'] ?? 0,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => onStatusTap?.call('ready'),
              ),
              const SizedBox(width: 8),
              _StatusCountCard(
                icon: Icons.check_circle,
                label: 'Livrées',
                count: counts['delivered'] ?? 0,
                color: Colors.green,
                onTap: () => onStatusTap?.call('delivered'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _StatusCountCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
