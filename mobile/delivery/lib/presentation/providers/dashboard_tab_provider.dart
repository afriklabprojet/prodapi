import 'package:riverpod/riverpod.dart';

/// Index des onglets du Dashboard
/// 0 = Home, 1 = Deliveries, 2 = Statistics, 3 = Wallet, 4 = Profile
class DashboardTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final dashboardTabProvider = NotifierProvider<DashboardTabNotifier, int>(
  DashboardTabNotifier.new,
);
