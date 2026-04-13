import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/adaptive_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/on_call_provider.dart';

/// Sheet for creating a new on-call period.
class AddOnCallSheet extends ConsumerStatefulWidget {
  const AddOnCallSheet({super.key});

  @override
  ConsumerState<AddOnCallSheet> createState() => _AddOnCallSheetState();
}

class _AddOnCallSheetState extends ConsumerState<AddOnCallSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'night';
  TimeOfDay _startTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _activeShortcut;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nouvelle Période de Garde',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Muli',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Définissez vos horaires d'ouverture exceptionnelle",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _buildTypeSelector(),
            const SizedBox(height: 20),

            const Text(
              "Raccourcis rapides",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildQuickActionChip('Ce soir', () {
                    final now = DateTime.now();
                    setState(() {
                      _activeShortcut = 'Ce soir';
                      _selectedType = 'night';
                      _startDate = now;
                      _startTime = const TimeOfDay(hour: 20, minute: 0);
                      _endDate = now.add(const Duration(days: 1));
                      _endTime = const TimeOfDay(hour: 8, minute: 0);
                      _errorMessage = null;
                    });
                  }),
                  _buildQuickActionChip('Demain soir', () {
                    final tomorrow =
                        DateTime.now().add(const Duration(days: 1));
                    setState(() {
                      _activeShortcut = 'Demain soir';
                      _selectedType = 'night';
                      _startDate = tomorrow;
                      _startTime = const TimeOfDay(hour: 20, minute: 0);
                      _endDate = tomorrow.add(const Duration(days: 1));
                      _endTime = const TimeOfDay(hour: 8, minute: 0);
                      _errorMessage = null;
                    });
                  }),
                  _buildQuickActionChip('Ce Week-end', () {
                    var d = DateTime.now();
                    if (d.weekday == 5 && d.hour >= 20) {
                      d = d.add(const Duration(days: 7));
                    } else {
                      while (d.weekday != 5) {
                        d = d.add(const Duration(days: 1));
                      }
                    }
                    final friday = DateTime(d.year, d.month, d.day);
                    final monday = friday.add(const Duration(days: 3));
                    setState(() {
                      _activeShortcut = 'Ce Week-end';
                      _selectedType = 'weekend';
                      _startDate = friday;
                      _startTime = const TimeOfDay(hour: 20, minute: 0);
                      _endDate = monday;
                      _endTime = const TimeOfDay(hour: 8, minute: 0);
                      _errorMessage = null;
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'DÉBUT',
                    date: _startDate,
                    time: _startTime,
                    onDatePick: () => _pickDate(true),
                    onTimePick: () => _pickTime(true),
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                ),
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'FIN',
                    date: _endDate,
                    time: _endTime,
                    onDatePick: () => _pickDate(false),
                    onTimePick: () => _pickTime(false),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirmer la période',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(16),
          items: const [
            DropdownMenuItem(
                value: 'night',
                child: OnCallTypeItem(
                    type: 'night', label: 'Garde de Nuit')),
            DropdownMenuItem(
                value: 'weekend',
                child: OnCallTypeItem(
                    type: 'weekend', label: 'Garde Week-end')),
            DropdownMenuItem(
                value: 'holiday',
                child: OnCallTypeItem(
                    type: 'holiday', label: 'Garde Jours Fériés')),
            DropdownMenuItem(
                value: 'emergency',
                child: OnCallTypeItem(
                    type: 'emergency', label: 'Urgence')),
          ],
          onChanged: (v) => setState(() => _selectedType = v!),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    final isActive = _activeShortcut == label;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: AnimatedScale(
        scale: isActive ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required TimeOfDay time,
    required VoidCallback onDatePick,
    required VoidCallback onTimePick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onDatePick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM', 'fr').format(date)
                        : '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTimePick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    time.format(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await AdaptivePicker.showDate(
      context: context,
      initialDate: isStart ? _startDate! : _endDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await AdaptivePicker.showTime(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) return;
    if (_isSubmitting) return;

    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!end.isAfter(start)) {
      setState(() {
        _errorMessage = 'La date de fin doit être après la date de début.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(onCallProvider.notifier)
        .createOnCall(start, end, _selectedType);

    if (!mounted) return;

    if (success) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Garde programmée avec succès !'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final error = ref.read(onCallProvider).error ??
          'Erreur lors de l\'ajout de la garde.';
      setState(() {
        _isSubmitting = false;
        _errorMessage = _toReadableError(error);
      });
    }
  }

  String _toReadableError(String error) {
    if (error.contains('after or equal to now') ||
        error.contains('after_or_equal')) {
      return 'La date de début doit être dans le futur.';
    }
    if (error.contains('after:start_at') ||
        error.contains('after start')) {
      return 'La date de fin doit être après la date de début.';
    }
    if (error.contains('overlapping') ||
        error.contains('chevauchement') ||
        error.contains('existe déjà')) {
      return 'Une période de garde existe déjà sur cet intervalle.';
    }
    if (error.contains('ValidationException')) {
      return 'Données invalides. Vérifiez les dates et le type de garde.';
    }
    if (error.isNotEmpty && !error.contains('Exception:')) {
      return error;
    }
    return ErrorMessages.unknownError;
  }
}

/// Quick-start shift dialog for immediate on-call activation.
class QuickStartShiftDialog extends StatefulWidget {
  const QuickStartShiftDialog({super.key});

  @override
  State<QuickStartShiftDialog> createState() => _QuickStartShiftDialogState();
}

class _QuickStartShiftDialogState extends State<QuickStartShiftDialog> {
  String _selectedType = 'night';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Démarrer une garde'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sélectionnez le type de garde pour aujourd\'hui :'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'night', child: Text('Garde de Nuit')),
              DropdownMenuItem(
                  value: 'weekend', child: Text('Garde Week-end')),
              DropdownMenuItem(
                  value: 'holiday', child: Text('Garde Jours Fériés')),
              DropdownMenuItem(
                  value: 'emergency', child: Text('Urgence')),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 8),
          Text(
            'La garde commencera maintenant et se terminera demain à 08:00.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedType),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Activer'),
        ),
      ],
    );
  }
}

/// Displays on-call type with icon and color.
class OnCallTypeItem extends StatelessWidget {
  final String type;
  final String label;

  const OnCallTypeItem({super.key, required this.type, required this.label});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'night':
        icon = Icons.nights_stay;
        color = Colors.indigo;
        break;
      case 'weekend':
        icon = Icons.weekend;
        color = Colors.orange;
        break;
      case 'holiday':
        icon = Icons.celebration;
        color = Colors.purple;
        break;
      case 'emergency':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      default:
        icon = Icons.calendar_today;
        color = Colors.grey;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
