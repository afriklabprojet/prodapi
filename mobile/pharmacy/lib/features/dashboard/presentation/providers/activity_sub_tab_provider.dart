import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls which sub-tab (0 = Commandes, 1 = Ordonnances) is shown in ActivityPage.
/// Write to this from the dashboard to deep-link to a specific sub-tab.
/// Value >= 0 means "switch to this sub-tab". Reset to 0 after read.
final activitySubTabProvider = StateProvider<int>((ref) => 0);
