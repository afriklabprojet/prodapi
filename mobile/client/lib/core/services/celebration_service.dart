import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/providers.dart';
import 'app_logger.dart';

/// Types de célébration disponibles
enum CelebrationType {
  orderConfirmed,      // Commande confirmée
  firstOrder,          // Première commande
  fifthOrder,          // 5ème commande (milestone)
  tenthOrder,          // 10ème commande
  treatmentRenewal,    // Premier renouvellement de traitement
  walletTopUp,         // Premier rechargement wallet
  prescriptionScanned, // Première ordonnance scannée
}

/// Données pour une célébration
class CelebrationData {
  final CelebrationType type;
  final String title;
  final String message;
  final String? badgeText;
  final IconData icon;
  final List<Color> gradientColors;
  final bool showConfetti;

  const CelebrationData({
    required this.type,
    required this.title,
    required this.message,
    this.badgeText,
    required this.icon,
    required this.gradientColors,
    this.showConfetti = false,
  });
}

/// État des célébrations
class CelebrationState {
  final CelebrationData? currentCelebration;
  final bool isShowing;
  final int totalOrderCount;
  final Set<String> unlockedBadges;

  const CelebrationState({
    this.currentCelebration,
    this.isShowing = false,
    this.totalOrderCount = 0,
    this.unlockedBadges = const {},
  });

  CelebrationState copyWith({
    CelebrationData? currentCelebration,
    bool? isShowing,
    int? totalOrderCount,
    Set<String>? unlockedBadges,
  }) {
    return CelebrationState(
      currentCelebration: currentCelebration,
      isShowing: isShowing ?? this.isShowing,
      totalOrderCount: totalOrderCount ?? this.totalOrderCount,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}

/// Provider pour les célébrations
final celebrationProvider =
    StateNotifierProvider<CelebrationNotifier, CelebrationState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CelebrationNotifier(prefs);
});

class CelebrationNotifier extends StateNotifier<CelebrationState> {
  final SharedPreferences _prefs;

  static const _orderCountKey = 'celebration_order_count';
  static const _badgesKey = 'celebration_badges';
  static const _firstOrderKey = 'celebration_first_order_shown';
  static const _firstWalletKey = 'celebration_first_wallet_shown';
  static const _firstScanKey = 'celebration_first_scan_shown';
  static const _firstRenewalKey = 'celebration_first_renewal_shown';

  CelebrationNotifier(this._prefs) : super(const CelebrationState()) {
    _loadState();
  }

  void _loadState() {
    final orderCount = _prefs.getInt(_orderCountKey) ?? 0;
    final badges = (_prefs.getStringList(_badgesKey) ?? []).toSet();
    state = state.copyWith(
      totalOrderCount: orderCount,
      unlockedBadges: badges,
    );
  }

  /// Déclenche une célébration pour une commande confirmée
  Future<void> triggerOrderCelebration() async {
    HapticFeedback.heavyImpact();

    final newCount = state.totalOrderCount + 1;
    await _prefs.setInt(_orderCountKey, newCount);
    state = state.copyWith(totalOrderCount: newCount);

    CelebrationData celebration;

    // Vérifier les milestones
    if (newCount == 1) {
      final shown = _prefs.getBool(_firstOrderKey) ?? false;
      if (!shown) {
        celebration = const CelebrationData(
          type: CelebrationType.firstOrder,
          title: 'Première commande ! 🎉',
          message: 'Bienvenue dans la famille DR-PHARMA. Votre santé est entre de bonnes mains.',
          badgeText: 'Nouveau client',
          icon: Icons.celebration_rounded,
          gradientColors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          showConfetti: true,
        );
        await _prefs.setBool(_firstOrderKey, true);
        await _unlockBadge('first_order');
      } else {
        celebration = _getStandardOrderCelebration();
      }
    } else if (newCount == 5) {
      celebration = const CelebrationData(
        type: CelebrationType.fifthOrder,
        title: 'Client fidèle ! 🌟',
        message: '5 commandes ! Vous faites partie de nos meilleurs clients.',
        badgeText: '5 commandes',
        icon: Icons.star_rounded,
        gradientColors: [Color(0xFFF39C12), Color(0xFFE74C3C)],
        showConfetti: true,
      );
      await _unlockBadge('fifth_order');
    } else if (newCount == 10) {
      celebration = const CelebrationData(
        type: CelebrationType.tenthOrder,
        title: 'Client VIP ! 👑',
        message: '10 commandes ! Vous êtes un client privilégié DR-PHARMA.',
        badgeText: 'VIP',
        icon: Icons.workspace_premium_rounded,
        gradientColors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        showConfetti: true,
      );
      await _unlockBadge('vip');
    } else {
      celebration = _getStandardOrderCelebration();
    }

    state = state.copyWith(
      currentCelebration: celebration,
      isShowing: true,
    );
  }

  CelebrationData _getStandardOrderCelebration() {
    return const CelebrationData(
      type: CelebrationType.orderConfirmed,
      title: 'Commande confirmée !',
      message: 'Votre commande a été reçue et sera bientôt préparée.',
      icon: Icons.check_circle_rounded,
      gradientColors: [Color(0xFF00B894), Color(0xFF00CEC9)],
      showConfetti: false,
    );
  }

  /// Déclenche une célébration pour le premier renouvellement
  Future<void> triggerFirstRenewalCelebration() async {
    final shown = _prefs.getBool(_firstRenewalKey) ?? false;
    if (shown) return;

    HapticFeedback.mediumImpact();
    await _prefs.setBool(_firstRenewalKey, true);
    await _unlockBadge('first_renewal');

    state = state.copyWith(
      currentCelebration: const CelebrationData(
        type: CelebrationType.treatmentRenewal,
        title: 'Premier renouvellement ! 💊',
        message: 'Bravo ! Vous prenez soin de votre santé de manière régulière.',
        badgeText: 'Traitement suivi',
        icon: Icons.medication_rounded,
        gradientColors: [Color(0xFF00B894), Color(0xFF55EFC4)],
        showConfetti: true,
      ),
      isShowing: true,
    );
  }

  /// Déclenche une célébration pour le premier rechargement wallet
  Future<void> triggerFirstWalletTopUp() async {
    final shown = _prefs.getBool(_firstWalletKey) ?? false;
    if (shown) return;

    HapticFeedback.mediumImpact();
    await _prefs.setBool(_firstWalletKey, true);
    await _unlockBadge('first_wallet');

    state = state.copyWith(
      currentCelebration: const CelebrationData(
        type: CelebrationType.walletTopUp,
        title: 'Portefeuille activé ! 💰',
        message: 'Votre portefeuille DR-PHARMA est prêt. Payez en un instant !',
        badgeText: 'Wallet activé',
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Color(0xFFF39C12), Color(0xFFE67E22)],
        showConfetti: false,
      ),
      isShowing: true,
    );
  }

  /// Déclenche une célébration pour le premier scan d'ordonnance
  Future<void> triggerFirstPrescriptionScan() async {
    final shown = _prefs.getBool(_firstScanKey) ?? false;
    if (shown) return;

    HapticFeedback.mediumImpact();
    await _prefs.setBool(_firstScanKey, true);
    await _unlockBadge('first_scan');

    state = state.copyWith(
      currentCelebration: const CelebrationData(
        type: CelebrationType.prescriptionScanned,
        title: 'Scan réussi ! 📸',
        message: 'Votre ordonnance a été analysée par notre IA. Commander n\'a jamais été aussi simple.',
        badgeText: 'Scanner Pro',
        icon: Icons.document_scanner_rounded,
        gradientColors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
        showConfetti: false,
      ),
      isShowing: true,
    );
  }

  /// Ferme la célébration en cours
  void dismissCelebration() {
    state = state.copyWith(
      currentCelebration: null,
      isShowing: false,
    );
  }

  Future<void> _unlockBadge(String badgeId) async {
    final badges = Set<String>.from(state.unlockedBadges);
    badges.add(badgeId);
    await _prefs.setStringList(_badgesKey, badges.toList());
    state = state.copyWith(unlockedBadges: badges);
    AppLogger.info('Badge unlocked: $badgeId');
  }

  bool hasBadge(String badgeId) => state.unlockedBadges.contains(badgeId);
}
