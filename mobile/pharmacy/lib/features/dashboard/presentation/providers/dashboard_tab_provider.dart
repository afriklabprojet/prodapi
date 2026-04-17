import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to communicate tab changes from HomeDashboardWidget to DashboardPage.
/// Writing to this provider triggers a tab switch in the parent DashboardPage.
/// Value -1 means "no navigation requested" (sentinel/idle state).
final dashboardTabProvider = StateProvider<int>((ref) => -1);
