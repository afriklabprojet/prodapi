import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/adaptive_dialog.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../data/models/on_call_model.dart';
import '../providers/on_call_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/add_on_call_sheet.dart';

class OnCallPage extends ConsumerStatefulWidget {
  const OnCallPage({super.key});

  @override
  ConsumerState<OnCallPage> createState() => _OnCallPageState();
}

class _OnCallPageState extends ConsumerState<OnCallPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection.name == 'reverse') {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  OnCallModel? _getActiveShift(List<OnCallModel> onCalls) {
    final now = DateTime.now();
    try {
      // Find a shift that is either active now OR starts very soon (e.g. within 5 mins)
      // This handles the case where we create a shift "starting in 1 min" to satisfy backend
      // but want it to appear active immediately.
      return onCalls.firstWhere((shift) {
        final isEffectivelyActive =
            shift.isActive &&
            shift.startAt.isBefore(now.add(const Duration(minutes: 5))) &&
            shift.endAt.isAfter(now);
        return isEffectivelyActive;
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleToggle(bool value, OnCallModel? activeShift) async {
    if (value) {
      // Turn ON -> Create Shift
      final type = await showDialog<String>(
        context: context,
        builder: (context) => const QuickStartShiftDialog(),
      );

      if (type != null) {
        // Default: Now to Tomorrow 8am
        final now = DateTime.now();
        // Add 2 minutes to satisfy backend "after:now" if strictly checked,
        // or rely on backend tolerance. Safe bet: ensure start is valid.
        // Actually, if I want to be "On Call Now", I want it effective immediately.
        // Let's try sending now().add(Duration(minutes: 1))
        final start = now.add(const Duration(minutes: 1));

        // Define end based on type? Or default 24h?
        // Let's assume default is Next Day 8:00 AM for Night/Holiday
        DateTime end = DateTime(now.year, now.month, now.day + 1, 8, 0);
        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 1));
        }

        final success = await ref
            .read(onCallProvider.notifier)
            .createOnCall(start, end, type);

        if (mounted) {
          if (success) {
            ErrorSnackBar.showSuccess(
              context,
              'Mode garde activé avec succès !',
            );
          } else {
            final err = ref.read(onCallProvider).error;
            ErrorSnackBar.showError(
              context,
              err ?? 'Impossible d\'activer le mode garde. Veuillez réessayer.',
            );
          }
        }
      }
    } else {
      // Turn OFF -> Delete/Stop Shift
      if (activeShift == null) return;

      final confirm = await AdaptiveDialog.showConfirm(
        context: context,
        title: 'Terminer la garde ?',
        content: 'Voulez-vous vraiment désactiver le mode garde maintenant ?',
        confirmLabel: 'Désactiver',
        isDestructive: true,
      );

      if (confirm == true) {
        final success = await ref
            .read(onCallProvider.notifier)
            .deleteOnCall(activeShift.id);
        if (success && mounted) {
          ErrorSnackBar.showInfo(context, 'Mode garde désactivé');
        }
      }
    }
  }

  Widget _buildStatusToggle(OnCallModel? activeShift, BuildContext context) {
    final isOn = activeShift != null;
    return Container(
      color: AppColors.cardColor(context),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOn ? AppColors.primaryLight : AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOn ? AppColors.primary : Colors.grey.shade200,
            width: isOn ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOn ? AppColors.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOn ? Icons.local_pharmacy : Icons.local_pharmacy_outlined,
                color: isOn ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOn ? 'Vous êtes de garde' : 'Mode garde inactif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOn ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOn
                        ? 'Fin prévue : ${DateFormat('HH:mm').format(activeShift.endAt)}'
                        : 'Activez pour recevoir des commandes d\'urgence',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isOn,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => _handleToggle(val, activeShift),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onCallProvider);
    final activeShift = _getActiveShift(state.onCalls);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Gestion des gardes',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1 : 0,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddOnCallSheet(context),
            label: const Text(
              'Planifier',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            icon: const Icon(Icons.calendar_today, size: 20),
            backgroundColor: AppColors.primary,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusToggle(activeShift, context),
          Expanded(
            child: Column(
              children: [
                if (state.onCalls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Gardes programmées',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.onCalls.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: state.isLoading && state.onCalls.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null && state.onCalls.isEmpty
                      ? _buildErrorState(state.error!)
                      : state.onCalls.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(onCallProvider.notifier).getOnCalls(),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            itemCount: state.onCalls.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final onCall = state.onCalls[index];
                              // Highlight active shift in list too if needed, but toggle handles it.
                              return _buildOnCallCard(onCall);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnCallCard(OnCallModel onCall) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOnCallDetails(onCall),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatusBadge(onCall),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateRange(onCall.startAt, onCall.endAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('HH:mm').format(onCall.startAt)} - ${DateFormat('HH:mm').format(onCall.endAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(onCall),
                  tooltip: 'Supprimer',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(OnCallModel onCall) async {
    final confirm = await AdaptiveDialog.showConfirm(
      context: context,
      title: 'Supprimer',
      content: 'Voulez-vous supprimer cette période de garde ?',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await ref.read(onCallProvider.notifier).deleteOnCall(onCall.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _showOnCallDetails(OnCallModel onCall) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: onCall.isActive
                        ? AppColors.primaryLight
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(onCall.type),
                    color: onCall.isActive ? AppColors.primary : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeName(onCall.type),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        onCall.isActive ? 'Garde active' : 'Garde programmée',
                        style: TextStyle(
                          color: onCall.isActive
                              ? AppColors.primary
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              Icons.calendar_today,
              'Début',
              DateFormat(
                'EEEE d MMMM yyyy à HH:mm',
                'fr',
              ).format(onCall.startAt),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Fin',
              DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr').format(onCall.endAt),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.timelapse,
              'Durée',
              _formatDuration(onCall.endAt.difference(onCall.startAt)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(onCall);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'night':
        return 'Garde de nuit';
      case 'weekday':
        return 'Garde de semaine';
      case 'weekend':
        return 'Garde de week-end';
      case 'holiday':
        return 'Garde jour férié';
      default:
        return 'Garde';
    }
  }

  Widget _buildStatusBadge(OnCallModel onCall) {
    final isActive = onCall.isActive;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(onCall.type),
            color: isActive ? AppColors.primary : Colors.grey.shade400,
            size: 24,
          ),
        ),
        if (isActive)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'night':
        return Icons.nights_stay;
      case 'weekend':
        return Icons.weekend;
      case 'holiday':
        return Icons.celebration;
      case 'emergency':
        return Icons.local_hospital;
      default:
        return Icons.calendar_today;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = DateFormat('dd MMM').format(start);
    final endStr = DateFormat('dd MMM').format(end);
    if (start.day == end.day &&
        start.month == end.month &&
        start.year == end.year) {
      return '$startStr ${DateFormat('yyyy').format(start)}';
    }
    return '$startStr - $endStr ${DateFormat('yyyy').format(end)}';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFF57C00),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Impossible de charger les gardes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(onCallProvider.notifier).getOnCalls(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 40,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucune garde programmée",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ajoutez vos créneaux de garde pour informer les patients de votre disponibilité.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOnCallSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddOnCallSheet(),
    );
  }
}
