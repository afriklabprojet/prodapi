import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour l'onglet d'info sélectionné dans le dashboard
/// (Finances, Commandes, Ordonnances)
final selectedInfoTabProvider = StateProvider<int>((ref) => 0);

/// Provider pour le segment financier sélectionné (Jour/Semaine/Mois)
final selectedFinanceSegmentProvider = StateProvider<int>((ref) => 0);
