import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Adaptive dialog utilities that show platform-appropriate dialogs.
/// 
/// On iOS: Uses Cupertino dialogs with native iOS styling
/// On Android: Uses Material 3 dialogs
/// 
/// Usage:
/// ```dart
/// final confirmed = await AdaptiveDialog.showConfirm(
///   context: context,
///   title: 'Confirmer',
///   content: 'Voulez-vous continuer?',
/// );
/// ```
class AdaptiveDialog {
  AdaptiveDialog._();

  /// Shows a platform-adaptive confirmation dialog.
  /// Returns `true` if confirmed, `false` if cancelled, `null` if dismissed.
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final confirm = confirmLabel ?? l10n.confirm;
    final cancel = cancelLabel ?? l10n.cancel;

    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              isDefaultAction: !isDestructive,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancel),
          ),
          isDestructive
              ? FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirm),
                )
              : FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirm),
                ),
        ],
      ),
    );
  }

  /// Shows a platform-adaptive alert dialog (info only, single OK button).
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String? okLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    final ok = okLabel ?? l10n.ok;

    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: Text(ok),
            ),
          ],
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ok),
          ),
        ],
      ),
    );
  }

  /// Shows a platform-adaptive text input dialog.
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? placeholder,
    String? confirmLabel,
    String? cancelLabel,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
  }) {
    final l10n = AppLocalizations.of(context);
    final confirm = confirmLabel ?? l10n.confirm;
    final cancel = cancelLabel ?? l10n.cancel;
    final controller = TextEditingController(text: initialValue);

    if (Platform.isIOS) {
      return showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Column(
            children: [
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message),
              ],
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                maxLines: maxLines,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(confirm),
            ),
          ],
        ),
      );
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: placeholder,
                border: const OutlineInputBorder(),
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirm),
          ),
        ],
      ),
    );
  }

  /// Shows a platform-adaptive action sheet / bottom action dialog.
  static Future<T?> showActions<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<AdaptiveAction<T>> actions,
    AdaptiveAction<T>? cancelAction,
  }) {
    final l10n = AppLocalizations.of(context);

    if (Platform.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          message: message != null ? Text(message) : null,
          actions: actions.map((action) => CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            isDefaultAction: action.isDefault,
            onPressed: () => Navigator.pop(context, action.value),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(action.label),
              ],
            ),
          )).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, cancelAction?.value),
            child: Text(cancelAction?.label ?? l10n.cancel),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...actions.map((action) => ListTile(
              leading: action.icon != null 
                  ? Icon(action.icon, color: action.isDestructive ? Colors.red : null)
                  : null,
              title: Text(
                action.label,
                style: TextStyle(
                  color: action.isDestructive ? Colors.red : null,
                  fontWeight: action.isDefault ? FontWeight.bold : null,
                ),
              ),
              onTap: () => Navigator.pop(context, action.value),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Shows a platform-adaptive loading dialog.
  static Future<void> showLoading({
    required BuildContext context,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context);
    final loadingMsg = message ?? l10n.loading;

    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: CupertinoAlertDialog(
            content: Row(
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(loadingMsg)),
              ],
            ),
          ),
        ),
      );
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(child: Text(loadingMsg)),
            ],
          ),
        ),
      ),
    );
  }

  /// Hides the current loading dialog.
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Represents an action in an adaptive action sheet.
class AdaptiveAction<T> {
  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;
  final bool isDefault;

  const AdaptiveAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
    this.isDefault = false,
  });
}
