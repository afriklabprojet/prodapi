import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Liste des tutoriels disponibles
enum TutorialType {
  /// Premier lancement de l'app
  welcome,
  
  /// Comment accepter une livraison
  acceptDelivery,
  
  /// Navigation vers pharmacie/client
  navigation,
  
  /// Compléter une livraison (photo, signature)
  completeDelivery,
  
  /// Utilisation du wallet
  wallet,
  
  /// Défis et gamification
  challenges,
  
  /// Mode hors-ligne
  offlineMode,
}

/// Un step dans un tutoriel
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String? targetKey; // Key du widget à highlight
  final Alignment? tooltipAlignment;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
    this.tooltipAlignment,
    this.actionLabel,
    this.onAction,
  });
}

/// 📘 Tutoriels disponibles dans l'app
class Tutorials {
  static const welcome = [
    TutorialStep(
      title: 'Bienvenue sur DR-PHARMA Coursier !',
      description: 'Cette application vous permet de livrer des médicaments depuis les pharmacies partenaires jusqu\'aux clients.',
      icon: Icons.waving_hand,
    ),
    TutorialStep(
      title: 'Passez en ligne',
      description: 'Cliquez sur le bouton "Passer en ligne" pour commencer à recevoir des commandes.',
      icon: Icons.power_settings_new,
      targetKey: 'go_online_button',
    ),
    TutorialStep(
      title: 'Acceptez les commandes',
      description: 'Quand une commande arrive, vous aurez quelques secondes pour l\'accepter. Ne ratez pas vos opportunités !',
      icon: Icons.notifications_active,
    ),
    TutorialStep(
      title: 'Gagnez de l\'argent',
      description: 'Chaque livraison vous rapporte une commission. Consultez votre wallet pour voir vos gains.',
      icon: Icons.monetization_on,
    ),
  ];
  
  static const acceptDelivery = [
    TutorialStep(
      title: 'Nouvelle commande !',
      description: 'Une carte apparaît avec les détails : pharmacie, destination et montant estimé.',
      icon: Icons.delivery_dining,
    ),
    TutorialStep(
      title: 'Vérifiez les détails',
      description: 'Distance totale, temps estimé et commission sont affichés. Évaluez si la course vous convient.',
      icon: Icons.info_outline,
    ),
    TutorialStep(
      title: 'Accepter ou refuser',
      description: 'Glissez vers la droite pour accepter, ou attendez que le temps expire pour passer.',
      icon: Icons.swipe,
      actionLabel: 'Compris !',
    ),
  ];
  
  static const navigation = [
    TutorialStep(
      title: 'Navigation intégrée',
      description: 'La carte affiche votre itinéraire vers la pharmacie, puis vers le client.',
      icon: Icons.map,
    ),
    TutorialStep(
      title: 'ETA en temps réel',
      description: 'L\'heure d\'arrivée estimée se met à jour selon le trafic.',
      icon: Icons.access_time,
      targetKey: 'eta_badge',
    ),
    TutorialStep(
      title: 'Ouvrir dans Maps',
      description: 'Appuyez sur le bouton GPS pour ouvrir l\'itinéraire dans Google Maps ou Waze.',
      icon: Icons.navigation,
      actionLabel: 'Super !',
    ),
  ];
  
  static const completeDelivery = [
    TutorialStep(
      title: 'Récupération à la pharmacie',
      description: 'À la pharmacie, vérifiez la commande et confirmez le retrait.',
      icon: Icons.local_pharmacy,
    ),
    TutorialStep(
      title: 'Livraison au client',
      description: 'Remettez les médicaments au client à l\'adresse indiquée.',
      icon: Icons.person_pin_circle,
    ),
    TutorialStep(
      title: 'Preuves de livraison',
      description: 'Prenez une photo et/ou récupérez une signature pour confirmer la livraison.',
      icon: Icons.camera_alt,
      targetKey: 'proof_button',
    ),
    TutorialStep(
      title: 'Validation finale',
      description: 'Confirmez la livraison pour recevoir votre commission immédiatement !',
      icon: Icons.check_circle,
      actionLabel: 'Terminer',
    ),
  ];
  
  static const wallet = [
    TutorialStep(
      title: 'Votre portefeuille',
      description: 'Tous vos gains sont stockés ici. Consultez votre solde à tout moment.',
      icon: Icons.account_balance_wallet,
    ),
    TutorialStep(
      title: 'Historique des transactions',
      description: 'Chaque livraison, bonus ou retrait est enregistré avec les détails.',
      icon: Icons.history,
    ),
    TutorialStep(
      title: 'Retrait d\'argent',
      description: 'Demandez un retrait vers votre compte Mobile Money ou bancaire.',
      icon: Icons.payments,
      targetKey: 'withdraw_button',
    ),
    TutorialStep(
      title: 'Exporter vos revenus',
      description: 'Générez un rapport CSV ou PDF de vos gains pour votre comptabilité.',
      icon: Icons.download,
      actionLabel: 'Compris !',
    ),
  ];
  
  static const challenges = [
    TutorialStep(
      title: 'Défis & Bonus',
      description: 'Relevez des défis pour gagner des bonus supplémentaires !',
      icon: Icons.emoji_events,
    ),
    TutorialStep(
      title: 'Gamification',
      description: 'Gagnez des XP, montez en niveau et débloquez des badges.',
      icon: Icons.military_tech,
      targetKey: 'leaderboard_button',
    ),
    TutorialStep(
      title: 'Classement',
      description: 'Comparez-vous aux autres livreurs et visez le top !',
      icon: Icons.leaderboard,
      actionLabel: 'Allons-y !',
    ),
  ];
  
  static const offlineMode = [
    TutorialStep(
      title: 'Mode hors-ligne',
      description: 'Pas de réseau ? L\'app continue de fonctionner avec les données en cache.',
      icon: Icons.cloud_off,
    ),
    TutorialStep(
      title: 'Synchronisation',
      description: 'Vos actions sont sauvegardées et envoyées dès que la connexion revient.',
      icon: Icons.sync,
    ),
    TutorialStep(
      title: 'Données disponibles',
      description: 'Vos livraisons actives, solde et profil restent accessibles.',
      icon: Icons.storage,
      actionLabel: 'OK !',
    ),
  ];
  
  static List<TutorialStep> getSteps(TutorialType type) {
    switch (type) {
      case TutorialType.welcome: return welcome;
      case TutorialType.acceptDelivery: return acceptDelivery;
      case TutorialType.navigation: return navigation;
      case TutorialType.completeDelivery: return completeDelivery;
      case TutorialType.wallet: return wallet;
      case TutorialType.challenges: return challenges;
      case TutorialType.offlineMode: return offlineMode;
    }
  }
}

/// Service gérant l'état des tutoriels
class TutorialService {
  static const String _prefix = 'tutorial_completed_';
  
  /// Vérifier si un tutoriel a été complété
  Future<bool> isCompleted(TutorialType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix${type.name}') ?? false;
  }
  
  /// Marquer un tutoriel comme complété
  Future<void> markCompleted(TutorialType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${type.name}', true);
  }
  
  /// Réinitialiser tous les tutoriels
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in TutorialType.values) {
      await prefs.remove('$_prefix${type.name}');
    }
  }
  
  /// Réinitialiser un tutoriel spécifique
  Future<void> reset(TutorialType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix${type.name}');
  }
  
  /// Vérifier si c'est le premier lancement
  Future<bool> isFirstLaunch() async {
    return !(await isCompleted(TutorialType.welcome));
  }
}

/// Provider pour le service de tutoriel
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

/// Provider pour vérifier si un tutoriel est complété
final tutorialCompletedProvider = FutureProvider.family<bool, TutorialType>((ref, type) async {
  final service = ref.watch(tutorialServiceProvider);
  return service.isCompleted(type);
});

/// Provider pour vérifier le premier lancement
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(tutorialServiceProvider);
  return service.isFirstLaunch();
});
