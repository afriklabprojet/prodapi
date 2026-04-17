import 'package:flutter/material.dart';
import 'treatments_list_page.dart';

/// Point d'entrée pour la page des traitements
/// Redirige vers la version améliorée avec animations et recherche
class TreatmentsPage extends StatelessWidget {
  const TreatmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TreatmentsListPage();
  }
}
