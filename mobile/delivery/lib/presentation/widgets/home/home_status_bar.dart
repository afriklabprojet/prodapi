import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/courier_profile.dart';
import '../../../data/models/wallet_data.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../battery/battery_indicator_widget.dart';
import '../notifications/notification_widgets.dart';
import '../../screens/advanced_dashboard_screen.dart';

/// Provider pour le solde du wallet sur l'écran d'accueil
final homeWalletProvider = FutureProvider.autoDispose<WalletData?>((ref) async {
  try {
    return await ref.read(walletRepositoryProvider).getWalletData();
  } catch (e) {
    return null;
  }
});

/// Barre de statut en haut de l'écran d'accueil (solde + profil)
class HomeStatusBar extends ConsumerWidget {
  final AsyncValue<CourierProfile> profileAsync;

  const HomeStatusBar({super.key, required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWalletPill(context),
              Row(
                children: [
                  const BatteryIndicatorWidget(compact: true),
                  const SizedBox(width: 8),
                  const NotificationIconButton(),
                ],
              ),
              _buildProfileInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdvancedDashboardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.monetization_on, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Consumer(
              builder: (context, ref, _) {
                final walletAsync = ref.watch(homeWalletProvider);
                return walletAsync.when(
                  data: (walletData) {
                    final balance = walletData?.balance ?? 0;
                    final balanceFormatted = NumberFormat("#,##0", "fr_FR").format(balance);
                    return Row(
                      children: [
                        Text(
                          '$balanceFormatted F',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ],
                    );
                  },
                  loading: () => SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      color: Colors.green.shade300,
                      backgroundColor: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  error: (error, stack) => Text(
                    '--- FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return profileAsync.when(
      data: (profile) => Row(
        children: [
          Text(
            profile.name.split(' ').first,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, size: 20, color: Colors.blue),
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const Icon(Icons.error_outline),
    );
  }
}
