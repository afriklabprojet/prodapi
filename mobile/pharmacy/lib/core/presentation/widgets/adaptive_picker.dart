import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Adaptive date and time pickers that use platform-appropriate UI.
/// 
/// On iOS: Uses CupertinoDatePicker in a modal sheet
/// On Android: Uses Material date/time picker dialogs
/// 
/// Usage:
/// ```dart
/// final date = await AdaptivePicker.showDate(
///   context: context,
///   initialDate: DateTime.now(),
/// );
/// ```
class AdaptivePicker {
  AdaptivePicker._();

  /// Shows a platform-adaptive date picker.
  static Future<DateTime?> showDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) async {
    final initial = initialDate ?? DateTime.now();
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);

    if (Platform.isIOS) {
      DateTime? selectedDate = initial;
      
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              _buildCupertinoToolbar(
                context: context,
                onCancel: () => Navigator.pop(context, false),
                onDone: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  minimumDate: first,
                  maximumDate: last,
                  onDateTimeChanged: (date) => selectedDate = date,
                ),
              ),
            ],
          ),
        ),
      );
      
      return confirmed == true ? selectedDate : null;
    }

    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
    );
  }

  /// Shows a platform-adaptive time picker.
  static Future<TimeOfDay?> showTime({
    required BuildContext context,
    TimeOfDay? initialTime,
    String? helpText,
  }) async {
    final initial = initialTime ?? TimeOfDay.now();

    if (Platform.isIOS) {
      DateTime selectedTime = DateTime(
        2024, 1, 1, 
        initial.hour, 
        initial.minute,
      );
      
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              _buildCupertinoToolbar(
                context: context,
                onCancel: () => Navigator.pop(context, false),
                onDone: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selectedTime,
                  use24hFormat: true,
                  onDateTimeChanged: (date) => selectedTime = date,
                ),
              ),
            ],
          ),
        ),
      );
      
      if (confirmed == true) {
        return TimeOfDay(hour: selectedTime.hour, minute: selectedTime.minute);
      }
      return null;
    }

    return showTimePicker(
      context: context,
      initialTime: initial,
      helpText: helpText,
    );
  }

  /// Shows a platform-adaptive date AND time picker.
  static Future<DateTime?> showDateTime({
    required BuildContext context,
    DateTime? initialDateTime,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final initial = initialDateTime ?? DateTime.now();
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);

    if (Platform.isIOS) {
      DateTime? selectedDateTime = initial;
      
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              _buildCupertinoToolbar(
                context: context,
                onCancel: () => Navigator.pop(context, false),
                onDone: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initial,
                  minimumDate: first,
                  maximumDate: last,
                  use24hFormat: true,
                  onDateTimeChanged: (date) => selectedDateTime = date,
                ),
              ),
            ],
          ),
        ),
      );
      
      return confirmed == true ? selectedDateTime : null;
    }

    // Android: Two-step (date then time)
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    
    if (date == null) return null;
    
    if (!context.mounted) return null;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    
    if (time == null) return null;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Shows a platform-adaptive date range picker.
  static Future<DateTimeRange?> showDateRange({
    required BuildContext context,
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) async {
    final now = DateTime.now();
    final initial = initialRange ?? DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 7)),
    );
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);

    if (Platform.isIOS) {
      // iOS: Use two separate date pickers
      DateTime? startDate = initial.start;
      DateTime? endDate = initial.end;
      final l10n = AppLocalizations.of(context);
      
      // Pick start date
      startDate = await showDate(
        context: context,
        initialDate: initial.start,
        firstDate: first,
        lastDate: last,
        helpText: l10n.selectStartDate,
      );
      
      if (startDate == null || !context.mounted) return null;
      
      // Pick end date
      endDate = await showDate(
        context: context,
        initialDate: initial.end,
        firstDate: startDate,
        lastDate: last,
        helpText: l10n.selectEndDate,
      );
      
      if (endDate == null) return null;
      
      return DateTimeRange(start: startDate, end: endDate);
    }

    return showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
    );
  }

  /// Shows a platform-adaptive generic picker (single item from list).
  static Future<T?> showPicker<T>({
    required BuildContext context,
    required List<T> items,
    required String Function(T) labelBuilder,
    T? initialItem,
    String? title,
  }) async {
    if (Platform.isIOS) {
      int selectedIndex = initialItem != null ? items.indexOf(initialItem) : 0;
      if (selectedIndex < 0) selectedIndex = 0;
      
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              _buildCupertinoToolbar(
                context: context,
                title: title,
                onCancel: () => Navigator.pop(context, false),
                onDone: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedIndex,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) => selectedIndex = index,
                  children: items.map((item) => Center(
                    child: Text(
                      labelBuilder(item),
                      style: const TextStyle(fontSize: 18),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      );
      
      return confirmed == true ? items[selectedIndex] : null;
    }

    // Android: Use simple dialog with radio list
    return showDialog<T>(
      context: context,
      builder: (context) {
        T? selected = initialItem;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: title != null ? Text(title) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // ignore: deprecated_member_use - RadioGroup migration planned
                children: items.map((item) => RadioListTile<T>(
                  value: item,
                  // ignore: deprecated_member_use
                  groupValue: selected,
                  title: Text(labelBuilder(item)),
                  // ignore: deprecated_member_use
                  onChanged: (value) => setState(() => selected = value),
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: Text(AppLocalizations.of(context).confirm),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the iOS-style toolbar for pickers.
  static Widget _buildCupertinoToolbar({
    required BuildContext context,
    String? title,
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onCancel,
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: CupertinoColors.systemBlue),
            ),
          ),
          if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onDone,
            child: Text(
              l10n.ok,
              style: const TextStyle(
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
