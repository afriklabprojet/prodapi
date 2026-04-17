import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/prescription_detail_provider.dart';

/// Modèle de données pour un médicament dans la section de dispensation
class MedicationItem {
  final String name;
  final String? dosage;
  final int qtyPrescribed;
  final int qtyDispensed;
  final int remaining;
  final int? productId;
  final double? price;
  final bool inStock;
  final double? confidence;

  MedicationItem({
    required this.name,
    this.dosage,
    required this.qtyPrescribed,
    required this.qtyDispensed,
    required this.remaining,
    this.productId,
    this.price,
    this.inStock = false,
    this.confidence,
  });

  /// Retourne le nom complet avec dosage si disponible
  String get fullName =>
      dosage != null && dosage!.isNotEmpty ? '$name $dosage' : name;
}

/// Construit la liste unifiée de médicaments à partir des données d'analyse
List<MedicationItem> buildMedicationList(PrescriptionDetailState detailState) {
  final prescription = detailState.prescription;
  final analysisResult = detailState.analysisResult;

  final medications =
      analysisResult?.extractedMedications ??
      prescription.extractedMedications ??
      [];
  final matched =
      analysisResult?.matchedProducts ?? prescription.matchedProducts ?? [];

  final medList = <MedicationItem>[];
  final seenNames = <String>{};

  // Étiquettes à filtrer (formulaires imprimés)
  const formLabels = [
    'polyclinique',
    'internationale',
    'chirurgien',
    'sexe',
    'examen',
    'demandé',
    'demande',
    'groupe',
    'indication',
    'adresse',
    'médecin',
    'medecin',
    'demandeur',
    'service',
    'telephone',
    'téléphone',
    'assurance',
    'matricule',
    'profession',
    'nationalité',
    'naissance',
    'chambre',
    'poids',
    'taille',
    'tension',
    'diagnostic',
    'observation',
    'allergie',
    'urgence',
    'play',
    'here',
    'pavillon',
    'bâtiment',
  ];

  for (final med in medications) {
    if (med is Map) {
      final name = (med['name'] ?? med['matched_text'] ?? '').toString();
      if (name.isEmpty || seenNames.contains(name)) continue;

      final confidence = (med['confidence'] as num?)?.toDouble() ?? 0.5;
      if (confidence < 0.5) continue;

      final nameLower = name.toLowerCase();
      if (formLabels.any((label) => nameLower.contains(label))) continue;

      seenNames.add(name);
      final qtyPrescribed = (med['quantity'] as num?)?.toInt() ?? 1;
      final dispensedQty = prescription.getDispensedQuantity(name);
      final dosage = (med['dosage'] as String?)?.trim();

      Map? matchedItem;
      for (final m in matched) {
        if (m is Map &&
            (m['medication'] == name || m['product_name'] == name)) {
          matchedItem = m;
          break;
        }
      }

      medList.add(
        MedicationItem(
          name: name,
          dosage: dosage,
          qtyPrescribed: qtyPrescribed,
          qtyDispensed: dispensedQty,
          remaining: (qtyPrescribed - dispensedQty).clamp(0, 99),
          productId: (matchedItem?['product_id'] as num?)?.toInt(),
          price: (matchedItem?['price'] as num?)?.toDouble(),
          inStock: matchedItem != null,
          confidence: confidence,
        ),
      );
    }
  }

  // Matched non listés dans extracted
  for (final m in matched) {
    if (m is Map) {
      final name = (m['medication'] ?? m['product_name'] ?? '').toString();
      if (name.isEmpty || seenNames.contains(name)) continue;
      seenNames.add(name);
      final dispensedQty = prescription.getDispensedQuantity(name);
      medList.add(
        MedicationItem(
          name: name,
          qtyPrescribed: 1,
          qtyDispensed: dispensedQty,
          remaining: (1 - dispensedQty).clamp(0, 99),
          productId: (m['product_id'] as num?)?.toInt(),
          price: (m['price'] as num?)?.toDouble(),
          inStock: true,
        ),
      );
    }
  }

  return medList;
}

/// Section de dispensation des médicaments — widget extrait
class PrescriptionDispenseSection extends StatelessWidget {
  final PrescriptionDetailState detailState;
  final List<MedicationItem> medList;
  final bool isDispensing;
  final ValueChanged<MapEntry<String, bool>> onToggleMedication;
  final VoidCallback onDispense;

  const PrescriptionDispenseSection({
    super.key,
    required this.detailState,
    required this.medList,
    required this.isDispensing,
    required this.onToggleMedication,
    required this.onDispense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final prescription = detailState.prescription;

    if (prescription.isFullyDispensed) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.block, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              const Text(
                'ORDONNANCE COMPLÈTEMENT DÉLIVRÉE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tous les médicaments ont été fournis.',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      );
    }

    if (medList.isEmpty) return const SizedBox.shrink();

    final dispensableMeds = medList.where((m) => m.remaining > 0).toList();

    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_pharmacy, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Dispensation des médicaments',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cochez les médicaments que vous allez délivrer',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            // En-tête tableau
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Médicament',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Presc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Déliv.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      'Reste',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            for (final med in medList)
              _MedicationRow(
                med: med,
                isDark: isDark,
                isSelected: detailState.selectedMedications[med.name] == true,
                onChanged: (v) =>
                    onToggleMedication(MapEntry(med.name, v ?? false)),
              ),
            const SizedBox(height: 16),
            if (dispensableMeds.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isDispensing ? null : onDispense,
                  icon: isDispensing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    isDispensing
                        ? 'Dispensation en cours...'
                        : 'Délivrer les médicaments sélectionnés',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final MedicationItem med;
  final bool isDark;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _MedicationRow({
    required this.med,
    required this.isDark,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fullyDispensed = med.remaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: fullyDispensed
            ? (isDark
                  ? Colors.red.shade900.withValues(alpha: 0.2)
                  : Colors.red.shade50)
            : isSelected
            ? (isDark
                  ? Colors.green.shade900.withValues(alpha: 0.2)
                  : Colors.green.shade50)
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: fullyDispensed
                ? Icon(Icons.check_circle, color: Colors.red.shade400, size: 20)
                : Checkbox(
                    value: isSelected,
                    onChanged: onChanged,
                    activeColor: Colors.green,
                  ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        med.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: fullyDispensed
                              ? (isDark ? Colors.grey[500] : Colors.grey)
                              : (isDark ? Colors.white : Colors.black87),
                          decoration: fullyDispensed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge confiance faible si < 70%
                    if (med.confidence != null &&
                        med.confidence! < 0.7 &&
                        !fullyDispensed)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 10,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${(med.confidence! * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (med.price != null)
                  Text(
                    '${med.price!.toStringAsFixed(0)} FCFA${med.inStock ? "" : " (Rupture)"}',
                    style: TextStyle(
                      fontSize: 10,
                      color: med.inStock
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${med.qtyPrescribed}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${med.qtyDispensed}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: med.qtyDispensed > 0
                    ? Colors.orange.shade700
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: med.qtyDispensed > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: fullyDispensed
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${med.remaining}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: fullyDispensed
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
