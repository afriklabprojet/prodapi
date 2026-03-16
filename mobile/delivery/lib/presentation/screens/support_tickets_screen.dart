import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/support_ticket.dart';
import '../../data/repositories/support_repository.dart';
import '../widgets/common/common_widgets.dart';
import 'support_ticket_chat_screen.dart';
import 'create_ticket_screen.dart';
import '../../core/utils/responsive.dart';

/// Provider pour la liste des tickets
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repository = ref.read(supportRepositoryProvider);
  return repository.getTickets();
});

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.shade600,
                      Colors.indigo.shade800,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mes demandes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.r.sp(24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Support client',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Filtres par statut
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tous',
                    isSelected: _filterStatus == 'all',
                    onSelected: () => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ouverts',
                    isSelected: _filterStatus == 'open',
                    onSelected: () => setState(() => _filterStatus = 'open'),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'En cours',
                    isSelected: _filterStatus == 'in_progress',
                    onSelected: () => setState(() => _filterStatus = 'in_progress'),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Résolus',
                    isSelected: _filterStatus == 'resolved',
                    onSelected: () => setState(() => _filterStatus = 'resolved'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Fermés',
                    isSelected: _filterStatus == 'closed',
                    onSelected: () => setState(() => _filterStatus = 'closed'),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Liste des tickets
          ticketsAsync.when(
            data: (tickets) {
              final filtered = _filterTickets(tickets);
              
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    filterStatus: _filterStatus,
                    onCreateTicket: () => _navigateToCreateTicket(context),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TicketCard(
                    ticket: filtered[index],
                    onTap: () => _navigateToChat(context, filtered[index]),
                  ),
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: AppLoadingWidget(),
            ),
            error: (error, _) => SliverFillRemaining(
              child: AppErrorWidget(
                message: error.toString(),
                title: 'Erreur de chargement',
                onRetry: () => ref.invalidate(supportTicketsProvider),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTicket(context),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau ticket'),
      ),
    );
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets) {
    if (_filterStatus == 'all') return tickets;
    return tickets.where((t) => t.status == _filterStatus).toList();
  }

  Future<void> _navigateToCreateTicket(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
    );
    if (result == true) {
      ref.invalidate(supportTicketsProvider);
    }
  }

  Future<void> _navigateToChat(BuildContext context, SupportTicket ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupportTicketChatScreen(ticketId: ticket.id)),
    );
    ref.invalidate(supportTicketsProvider);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.indigo;
    
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : context.secondaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filterStatus;
  final VoidCallback onCreateTicket;

  const _EmptyState({
    required this.filterStatus,
    required this.onCreateTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                filterStatus == 'all' ? Icons.inbox : Icons.filter_list,
                size: 64,
                color: Colors.indigo.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filterStatus == 'all'
                  ? 'Aucune demande'
                  : 'Aucun ticket ${_getStatusLabel(filterStatus)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filterStatus == 'all'
                  ? 'Vous n\'avez pas encore créé de ticket de support'
                  : 'Aucun ticket avec ce statut',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.secondaryText,
              ),
            ),
            if (filterStatus == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreateTicket,
                icon: const Icon(Icons.add),
                label: const Text('Créer un ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'ouvert';
      case 'in_progress':
        return 'en cours';
      case 'resolved':
        return 'résolu';
      case 'closed':
        return 'fermé';
      default:
        return '';
    }
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = TicketStatus.fromValue(ticket.status);
    final category = TicketCategory.fromValue(ticket.category);
    final priority = TicketPriority.fromValue(ticket.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec référence et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.reference ?? '#${ticket.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.tertiaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),

              // Sujet
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Catégorie et priorité
              Row(
                children: [
                  _CategoryBadge(category: category),
                  const SizedBox(width: 8),
                  _PriorityBadge(priority: priority),
                  const Spacer(),
                  if (ticket.unreadCount != null && ticket.unreadCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ticket.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Dernier message ou description
              if (ticket.latestMessage != null) ...[
                const Divider(),
                Row(
                  children: [
                    Icon(
                      ticket.latestMessage!.isFromSupport
                          ? Icons.support_agent
                          : Icons.person,
                      size: 16,
                      color: context.iconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.latestMessage!.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Date
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.access_time, size: 14, color: context.iconColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.tertiaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays}j';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TicketStatus.open:
        color = Colors.orange;
        break;
      case TicketStatus.inProgress:
        color = Colors.blue;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final TicketCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(), size: 14, color: context.secondaryText),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 11,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case TicketCategory.order:
        return Icons.shopping_bag;
      case TicketCategory.delivery:
        return Icons.delivery_dining;
      case TicketCategory.payment:
        return Icons.payment;
      case TicketCategory.account:
        return Icons.person;
      case TicketCategory.appBug:
        return Icons.bug_report;
      case TicketCategory.other:
        return Icons.help_outline;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TicketPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TicketPriority.low:
        color = Colors.grey;
        break;
      case TicketPriority.medium:
        color = Colors.orange;
        break;
      case TicketPriority.high:
        color = Colors.red;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          priority.label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
