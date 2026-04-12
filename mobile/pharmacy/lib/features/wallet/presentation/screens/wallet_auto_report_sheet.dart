import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/statement_preference_service.dart';
import 'wallet_report_settings.dart';

Future<void> showWalletAutoReportSettingsSheet(
    BuildContext parentContext, WidgetRef ref) async {
  StatementPreference? currentPref;
  bool isLoading = true;
  final statementService =
      ref.read(statementPreferenceServiceProvider);

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        if (isLoading && currentPref == null) {
          statementService.getPreferences().then((pref) {
            setModalState(() {
              currentPref = pref;
              isLoading = false;
            });
          });
        }

        String frequency = currentPref != null
            ? StatementPreferenceService.frequencyToUi(
                currentPref!.frequency)
            : 'Mensuel';
        String format = currentPref != null
            ? currentPref!.format.toUpperCase()
            : 'PDF';
        bool autoSend = currentPref?.autoSend ?? true;
        String? nextSendLabel = currentPref?.nextSendLabel;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              : AutoReportSettingsContent(
                  initialFrequency: frequency,
                  initialFormat: format,
                  initialAutoSend: autoSend,
                  nextSendLabel: nextSendLabel,
                  onSave: (freq, fmt, auto) async {
                    final result =
                        await statementService.savePreferences(
                      frequency:
                          StatementPreferenceService.frequencyToApi(
                              freq),
                      format: fmt.toLowerCase(),
                      autoSend: auto,
                    );

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(parentContext)
                          .showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                result.success
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(result.message)),
                            ],
                          ),
                          backgroundColor: result.success
                              ? Colors.green
                              : Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
        );
      },
    ),
  );
}
