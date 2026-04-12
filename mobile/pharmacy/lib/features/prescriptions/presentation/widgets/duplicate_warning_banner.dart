import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/prescription_remote_datasource.dart' show DuplicateInfo;

/// Warning banner showing that a prescription image has been submitted before.
/// Displays details about the original prescription and its dispensing history.
class DuplicateWarningBanner extends StatelessWidget {
  final DuplicateInfo duplicateInfo;

  const DuplicateWarningBanner({
    super.key,
    required this.duplicateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_copy, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚫ DOUBLON DÉTECTÉ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette image d\'ordonnance a déjà été soumise (Ordonnance #${duplicateInfo.prescriptionId}).\n'
                  'Statut: ${duplicateInfo.fulfillmentStatus == "full" ? "Entièrement délivrée" : "Partiellement délivrée"} '
                  '(${duplicateInfo.dispensingCount} dispensation(s))',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (duplicateInfo.firstDispensedAt != null)
                  Text(
                    'Première dispensation: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.tryParse(duplicateInfo.firstDispensedAt!) ?? DateTime.now())}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
