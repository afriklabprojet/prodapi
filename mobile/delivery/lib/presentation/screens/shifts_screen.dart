import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/courier_shift.dart';
import '../providers/shift_provider.dart';

/// Écran de gestion des créneaux de travail.
/// Permet de voir les créneaux disponibles, réserver, et gérer ses shifts.
class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charger les slots au démarrage
    Future.microtask(() {
      ref.read(shiftProvider.notifier).loadAvailableSlots();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftProvider);

    // Écouter les erreurs
    ref.listen<ShiftState>(shiftProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mes Créneaux'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(shiftProvider.notifier).loadAll();
              ref.read(shiftProvider.notifier).loadAvailableSlots();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disponibles', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Mes Shifts', icon: Icon(Icons.work_history)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Shift actif (bannière en haut)
          if (shiftState.activeShift != null)
            _ActiveShiftBanner(shift: shiftState.activeShift!),

          // Contenu onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1 : Créneaux disponibles
                _AvailableSlotsTab(
                  daySlots: shiftState.availableSlots,
                  isLoading: shiftState.isSlotsLoading,
                  bookingSlotId: shiftState.bookingSlotId,
                  isBooking: shiftState.isBooking,
                ),
                // Tab 2 : Mes shifts
                _MyShiftsTab(
                  shifts: shiftState.myShifts,
                  isLoading: shiftState.isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bannière shift actif ───

class _ActiveShiftBanner extends ConsumerWidget {
  final CourierShift shift;
  const _ActiveShiftBanner({required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_filled, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHIFT EN COURS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shift.startTime} – ${shift.endTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${shift.deliveriesCompleted} livraison${shift.deliveriesCompleted > 1 ? "s" : ""}'
                  '${shift.remainingMinutes != null ? " • ${shift.remainingMinutes}min restantes" : ""}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Terminer le shift ?'),
                  content: Text(
                    shift.guaranteedBonus > 0
                        ? 'Votre bonus de ${shift.guaranteedBonus.formatCurrency(symbol: "F")} sera crédité.'
                        : 'Vous allez terminer votre créneau de travail.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Terminer'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(shiftProvider.notifier).endShift(shift.id);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Créneaux disponibles ───

class _AvailableSlotsTab extends ConsumerWidget {
  final List<DaySlots> daySlots;
  final bool isLoading;
  final int? bookingSlotId;
  final bool isBooking;

  const _AvailableSlotsTab({
    required this.daySlots,
    required this.isLoading,
    this.bookingSlotId,
    required this.isBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && daySlots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (daySlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun créneau disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  ref.read(shiftProvider.notifier).loadAvailableSlots(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(shiftProvider.notifier).loadAvailableSlots(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: daySlots.length,
        itemBuilder: (context, index) {
          final day = daySlots[index];
          return _DaySection(
            daySlots: day,
            bookingSlotId: bookingSlotId,
            isBooking: isBooking,
          );
        },
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DaySlots daySlots;
  final int? bookingSlotId;
  final bool isBooking;

  const _DaySection({
    required this.daySlots,
    this.bookingSlotId,
    required this.isBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatted = _formatDate(daySlots.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            dateFormatted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
        ...daySlots.slots.map(
          (slot) => _SlotCard(
            slot: slot,
            isBooking: isBooking && bookingSlotId == slot.id,
            onBook: slot.spotsRemaining > 0 && slot.status == 'open'
                ? () => _onBook(context, ref, slot)
                : null,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _onBook(
    BuildContext context,
    WidgetRef ref,
    ShiftSlot slot,
  ) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Réserver ${slot.shiftLabel} ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 ${_formatDate(daySlots.date)}'),
            Text('🕐 ${slot.startTime} – ${slot.endTime}'),
            if (slot.bonusAmount > 0)
              Text(
                '💰 Bonus garanti : ${slot.bonusAmount.formatCurrency(symbol: "F")}',
              ),
            Text(
              '👥 ${slot.spotsRemaining} place${slot.spotsRemaining > 1 ? "s" : ""} restante${slot.spotsRemaining > 1 ? "s" : ""}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(shiftProvider.notifier).bookSlot(slot.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Créneau ${slot.shiftLabel} réservé !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dtDay = DateTime(dt.year, dt.month, dt.day);
      final diff = dtDay.difference(today).inDays;

      if (diff == 0) return "Aujourd'hui";
      if (diff == 1) return 'Demain';
      return DateFormat('EEEE d MMMM', 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _SlotCard extends StatelessWidget {
  final ShiftSlot slot;
  final bool isBooking;
  final VoidCallback? onBook;

  const _SlotCard({required this.slot, required this.isBooking, this.onBook});

  @override
  Widget build(BuildContext context) {
    final isFull = slot.spotsRemaining <= 0 || slot.status != 'open';
    final hasBonus = slot.bonusAmount > 0;
    final fillRate = slot.capacity > 0 ? slot.bookedCount / slot.capacity : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isFull ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isFull ? Colors.grey.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icône type de shift
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasBonus ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                ShiftType.icons[slot.shiftType] ?? '📅',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slot.shiftLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isFull ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (hasBonus) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${slot.bonusAmount} F',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${slot.startTime} – ${slot.endTime}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isFull ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barre de remplissage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fillRate,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fillRate > 0.8 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFull
                            ? 'Complet'
                            : '${slot.spotsRemaining} place${slot.spotsRemaining > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isFull ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Bouton réserver
            if (!isFull)
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: isBooking ? null : onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: hasBonus
                        ? Colors.orange.shade700
                        : const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Réserver'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Mes Shifts ───

class _MyShiftsTab extends ConsumerWidget {
  final List<CourierShift> shifts;
  final bool isLoading;

  const _MyShiftsTab({required this.shifts, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && shifts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun créneau réservé',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Réservez un créneau pour recevoir un bonus garanti',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Trier : actifs en premier, puis par date
    final sorted = List<CourierShift>.from(shifts)
      ..sort((a, b) {
        final aActive = ShiftStatus.isActive(a.status) ? 0 : 1;
        final bActive = ShiftStatus.isActive(b.status) ? 0 : 1;
        if (aActive != bActive) return aActive.compareTo(bActive);
        return a.date.compareTo(b.date);
      });

    return RefreshIndicator(
      onRefresh: () => ref.read(shiftProvider.notifier).loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          return _MyShiftCard(shift: sorted[index]);
        },
      ),
    );
  }
}

class _MyShiftCard extends ConsumerWidget {
  final CourierShift shift;
  const _MyShiftCard({required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ShiftStatus.isActive(shift.status);
    final canStart = shift.status == ShiftStatus.confirmed;
    final canCancel = shift.status == ShiftStatus.confirmed;

    final formattedDate = _formatShiftDate(shift.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? const BorderSide(color: Color(0xFF2E7D32), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  ShiftType.icons[shift.shiftType] ?? '📅',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${shift.startTime} – ${shift.endTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: shift.status),
              ],
            ),

            const SizedBox(height: 10),

            // Métriques
            Row(
              children: [
                _MetricChip(
                  icon: Icons.delivery_dining,
                  label: '${shift.deliveriesCompleted}',
                ),
                const SizedBox(width: 10),
                if (shift.guaranteedBonus > 0)
                  _MetricChip(
                    icon: Icons.attach_money,
                    label:
                        '${shift.calculatedBonus ?? shift.guaranteedBonus} F',
                    color: Colors.orange,
                  ),
                const SizedBox(width: 10),
                if (shift.violationsCount > 0)
                  _MetricChip(
                    icon: Icons.warning_amber,
                    label: '${shift.violationsCount}',
                    color: Colors.red,
                  ),
              ],
            ),

            // Actions
            if (canStart || canCancel) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCancel)
                    TextButton(
                      onPressed: () => _confirmCancel(context, ref),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (canStart)
                    FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await ref
                            .read(shiftProvider.notifier)
                            .startShift(shift.id);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Démarrer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler ce créneau ?'),
        content: const Text(
          'L\'annulation libèrera la place pour un autre livreur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(shiftProvider.notifier).cancelShift(shift.id);
    }
  }

  String _formatShiftDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM', 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      'confirmed' => (Colors.blue.shade800, Colors.blue.shade50),
      'in_progress' => (Colors.green.shade800, Colors.green.shade50),
      'completed' => (Colors.grey.shade700, Colors.grey.shade100),
      'cancelled' => (Colors.red.shade700, Colors.red.shade50),
      'no_show' => (Colors.orange.shade800, Colors.orange.shade50),
      _ => (Colors.grey.shade600, Colors.grey.shade50),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ShiftStatus.label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetricChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
