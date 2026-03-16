import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Système de tutoriel interactif avancé avec spotlight
/// ====================================================

/// Clé globale pour accéder aux widgets à highlighter
final Map<String, GlobalKey> tutorialTargetKeys = {};

/// Enregistre une clé de widget pour le tutoriel
GlobalKey registerTutorialTarget(String id) {
  tutorialTargetKeys[id] ??= GlobalKey();
  return tutorialTargetKeys[id]!;
}

/// Type d'animation du spotlight
enum SpotlightShape { circle, rectangle, roundedRectangle }

/// Configuration d'un step interactif
class InteractiveTutorialStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String? targetWidgetKey;
  final SpotlightShape spotlightShape;
  final double spotlightPadding;
  final Alignment tooltipAlignment;
  final String? actionLabel;
  final bool allowInteraction;
  final Duration? autoAdvanceDelay;
  final List<String>? tips;

  const InteractiveTutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.targetWidgetKey,
    this.spotlightShape = SpotlightShape.roundedRectangle,
    this.spotlightPadding = 8.0,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.actionLabel,
    this.allowInteraction = false,
    this.autoAdvanceDelay,
    this.tips,
  });
}

/// Définition d'un tutoriel complet
class InteractiveTutorial {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<InteractiveTutorialStep> steps;
  final int estimatedMinutes;
  final List<String> prerequisites;

  const InteractiveTutorial({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.steps,
    this.estimatedMinutes = 2,
    this.prerequisites = const [],
  });
}

/// Tous les tutoriels interactifs disponibles
class InteractiveTutorials {
  static const welcomeTour = InteractiveTutorial(
    id: 'welcome_tour',
    name: 'Découverte de l\'app',
    description: 'Apprenez les bases de l\'application',
    icon: Icons.explore,
    color: Colors.blue,
    estimatedMinutes: 3,
    steps: [
      InteractiveTutorialStep(
        id: 'welcome_intro',
        title: 'Bienvenue ! 👋',
        description: 'Suivez ce guide rapide pour découvrir toutes les fonctionnalités de l\'app DR-PHARMA Coursier.',
        icon: Icons.waving_hand,
        tips: [
          'Vous pouvez revoir ce tutoriel à tout moment',
          'Chaque section a son propre guide',
        ],
      ),
      InteractiveTutorialStep(
        id: 'home_overview',
        title: 'Écran d\'accueil',
        description: 'C\'est votre tableau de bord principal. Vous y verrez vos statistiques du jour et les commandes disponibles.',
        icon: Icons.home,
        targetWidgetKey: 'home_stats_card',
        spotlightShape: SpotlightShape.roundedRectangle,
      ),
      InteractiveTutorialStep(
        id: 'go_online',
        title: 'Passez en ligne',
        description: 'Appuyez sur ce bouton pour commencer à recevoir des commandes. Le bouton devient vert quand vous êtes actif.',
        icon: Icons.power_settings_new,
        targetWidgetKey: 'go_online_button',
        spotlightShape: SpotlightShape.circle,
        spotlightPadding: 16,
        allowInteraction: true,
      ),
      InteractiveTutorialStep(
        id: 'navigation_bar',
        title: 'Navigation',
        description: 'Utilisez la barre de navigation pour accéder aux différentes sections: Accueil, Courses, Portefeuille et Profil.',
        icon: Icons.menu,
        targetWidgetKey: 'bottom_navigation',
        spotlightShape: SpotlightShape.rectangle,
      ),
      InteractiveTutorialStep(
        id: 'notifications',
        title: 'Notifications',
        description: 'Vous recevrez des alertes pour les nouvelles commandes. Activez les notifications pour ne rien manquer !',
        icon: Icons.notifications,
        targetWidgetKey: 'notification_bell',
        spotlightShape: SpotlightShape.circle,
      ),
    ],
  );

  static const deliveryFlow = InteractiveTutorial(
    id: 'delivery_flow',
    name: 'Effectuer une livraison',
    description: 'Le processus complet de A à Z',
    icon: Icons.local_shipping,
    color: Colors.orange,
    estimatedMinutes: 4,
    steps: [
      InteractiveTutorialStep(
        id: 'new_order',
        title: 'Nouvelle commande',
        description: 'Quand une commande arrive, vous avez 30 secondes pour l\'accepter. Une carte s\'affiche avec tous les détails.',
        icon: Icons.notifications_active,
        tips: [
          'Distance et temps estimés',
          'Commission affichée clairement',
          'Adresses de pickup et livraison',
        ],
      ),
      InteractiveTutorialStep(
        id: 'accept_order',
        title: 'Accepter la commande',
        description: 'Glissez vers la droite ou appuyez sur "Accepter" pour prendre la commande. Vous serez guidé vers la pharmacie.',
        icon: Icons.swipe_right,
        actionLabel: 'Compris !',
      ),
      InteractiveTutorialStep(
        id: 'navigate_pharmacy',
        title: 'Aller à la pharmacie',
        description: 'Suivez l\'itinéraire sur la carte. Appuyez sur le bouton GPS pour ouvrir Google Maps ou Waze.',
        icon: Icons.directions,
        targetWidgetKey: 'navigate_button',
      ),
      InteractiveTutorialStep(
        id: 'pickup_confirm',
        title: 'Confirmer le retrait',
        description: 'À la pharmacie, vérifiez la commande et appuyez sur "Commande récupérée" pour passer à la livraison.',
        icon: Icons.inventory,
        allowInteraction: true,
      ),
      InteractiveTutorialStep(
        id: 'navigate_customer',
        title: 'Livrer au client',
        description: 'Suivez maintenant l\'itinéraire vers l\'adresse du client. L\'app calcule le meilleur chemin.',
        icon: Icons.person_pin_circle,
      ),
      InteractiveTutorialStep(
        id: 'delivery_proof',
        title: 'Preuves de livraison',
        description: 'Prenez une photo du colis livré et/ou obtenez la signature du client pour confirmer.',
        icon: Icons.camera_alt,
        targetWidgetKey: 'proof_button',
        tips: [
          'Photo obligatoire pour validation',
          'Signature optionnelle mais recommandée',
        ],
      ),
      InteractiveTutorialStep(
        id: 'complete_delivery',
        title: 'Terminer la livraison',
        description: 'Confirmez la livraison. Votre commission est immédiatement ajoutée à votre portefeuille !',
        icon: Icons.check_circle,
        actionLabel: 'Super !',
      ),
    ],
  );

  static const walletGuide = InteractiveTutorial(
    id: 'wallet_guide',
    name: 'Gérer ses gains',
    description: 'Portefeuille et retraits',
    icon: Icons.account_balance_wallet,
    color: Colors.green,
    estimatedMinutes: 2,
    steps: [
      InteractiveTutorialStep(
        id: 'wallet_balance',
        title: 'Votre solde',
        description: 'En haut de l\'écran, vous voyez votre solde disponible. Ce montant peut être retiré à tout moment.',
        icon: Icons.account_balance,
        targetWidgetKey: 'wallet_balance',
      ),
      InteractiveTutorialStep(
        id: 'wallet_history',
        title: 'Historique',
        description: 'Chaque transaction est listée: commissions gagnées, bonus, retraits effectués.',
        icon: Icons.history,
      ),
      InteractiveTutorialStep(
        id: 'wallet_withdraw',
        title: 'Retirer de l\'argent',
        description: 'Appuyez sur "Retirer" pour transférer vos gains vers Mobile Money ou votre compte bancaire.',
        icon: Icons.payments,
        targetWidgetKey: 'withdraw_button',
        allowInteraction: true,
      ),
      InteractiveTutorialStep(
        id: 'wallet_export',
        title: 'Exporter les rapports',
        description: 'Générez un PDF ou CSV de vos revenus pour votre comptabilité.',
        icon: Icons.download,
        actionLabel: 'Compris !',
      ),
    ],
  );

  static const navigationTips = InteractiveTutorial(
    id: 'navigation_tips',
    name: 'Navigation GPS',
    description: 'Optimisez vos trajets',
    icon: Icons.navigation,
    color: Colors.purple,
    estimatedMinutes: 2,
    steps: [
      InteractiveTutorialStep(
        id: 'map_overview',
        title: 'Carte interactive',
        description: 'La carte affiche votre position en temps réel et l\'itinéraire vers votre destination.',
        icon: Icons.map,
        targetWidgetKey: 'delivery_map',
      ),
      InteractiveTutorialStep(
        id: 'navigation_apps',
        title: 'Apps de navigation',
        description: 'Choisissez entre Google Maps, Waze ou Apple Maps selon vos préférences dans les paramètres.',
        icon: Icons.apps,
      ),
      InteractiveTutorialStep(
        id: 'multi_route',
        title: 'Livraisons multiples',
        description: 'Avec plusieurs commandes, l\'app optimise automatiquement l\'ordre des livraisons.',
        icon: Icons.route,
        tips: [
          'Moins de kilomètres = plus de temps',
          'L\'algorithme prend en compte le trafic',
        ],
      ),
      InteractiveTutorialStep(
        id: 'eta_tracking',
        title: 'Temps estimé',
        description: 'L\'ETA (temps d\'arrivée estimé) se met à jour en temps réel selon votre vitesse.',
        icon: Icons.access_time,
        actionLabel: 'Parfait !',
      ),
    ],
  );

  static const gamificationGuide = InteractiveTutorial(
    id: 'gamification_guide',
    name: 'Défis & Récompenses',
    description: 'Gagnez des bonus',
    icon: Icons.emoji_events,
    color: Colors.amber,
    estimatedMinutes: 2,
    steps: [
      InteractiveTutorialStep(
        id: 'xp_system',
        title: 'Points d\'expérience',
        description: 'Chaque livraison vous rapporte des XP. Accumulez-en pour monter de niveau !',
        icon: Icons.star,
      ),
      InteractiveTutorialStep(
        id: 'daily_challenges',
        title: 'Défis quotidiens',
        description: 'Nouveaux défis chaque jour: nombre de livraisons, distance parcourue, etc.',
        icon: Icons.flag,
        targetWidgetKey: 'challenges_card',
      ),
      InteractiveTutorialStep(
        id: 'badges',
        title: 'Badges à débloquer',
        description: 'Accomplissez des objectifs spéciaux pour gagner des badges permanents.',
        icon: Icons.military_tech,
      ),
      InteractiveTutorialStep(
        id: 'leaderboard',
        title: 'Classement',
        description: 'Comparez-vous aux autres coursiers. Les meilleurs gagnent des bonus hebdomadaires !',
        icon: Icons.leaderboard,
        targetWidgetKey: 'leaderboard_section',
        actionLabel: 'Allons-y !',
      ),
    ],
  );

  static const offlineModeGuide = InteractiveTutorial(
    id: 'offline_mode',
    name: 'Mode hors-ligne',
    description: 'Travailler sans réseau',
    icon: Icons.cloud_off,
    color: Colors.blueGrey,
    estimatedMinutes: 1,
    steps: [
      InteractiveTutorialStep(
        id: 'offline_detection',
        title: 'Détection automatique',
        description: 'L\'app détecte automatiquement la perte de connexion et active le mode hors-ligne.',
        icon: Icons.signal_wifi_off,
      ),
      InteractiveTutorialStep(
        id: 'offline_data',
        title: 'Données disponibles',
        description: 'Vos livraisons en cours, profil et solde restent accessibles même sans internet.',
        icon: Icons.storage,
      ),
      InteractiveTutorialStep(
        id: 'offline_sync',
        title: 'Synchronisation',
        description: 'Dès que le réseau revient, toutes vos actions sont automatiquement synchronisées.',
        icon: Icons.sync,
        actionLabel: 'OK !',
      ),
    ],
  );

  /// Liste de tous les tutoriels
  static List<InteractiveTutorial> get all => [
    welcomeTour,
    deliveryFlow,
    walletGuide,
    navigationTips,
    gamificationGuide,
    offlineModeGuide,
  ];

  /// Récupère un tutoriel par ID
  static InteractiveTutorial? getById(String id) {
    return all.where((t) => t.id == id).firstOrNull;
  }
}

/// État du tutoriel interactif en cours
class InteractiveTutorialState {
  final InteractiveTutorial? activeTutorial;
  final int currentStepIndex;
  final bool isPaused;
  final Set<String> completedTutorials;

  const InteractiveTutorialState({
    this.activeTutorial,
    this.currentStepIndex = 0,
    this.isPaused = false,
    this.completedTutorials = const {},
  });

  InteractiveTutorialStep? get currentStep {
    if (activeTutorial == null) return null;
    if (currentStepIndex >= activeTutorial!.steps.length) return null;
    return activeTutorial!.steps[currentStepIndex];
  }

  bool get isActive => activeTutorial != null && !isPaused;

  bool get isLastStep {
    if (activeTutorial == null) return false;
    return currentStepIndex >= activeTutorial!.steps.length - 1;
  }

  double get progress {
    if (activeTutorial == null) return 0;
    return (currentStepIndex + 1) / activeTutorial!.steps.length;
  }

  InteractiveTutorialState copyWith({
    InteractiveTutorial? activeTutorial,
    int? currentStepIndex,
    bool? isPaused,
    Set<String>? completedTutorials,
    bool clearActiveTutorial = false,
  }) {
    return InteractiveTutorialState(
      activeTutorial: clearActiveTutorial ? null : (activeTutorial ?? this.activeTutorial),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isPaused: isPaused ?? this.isPaused,
      completedTutorials: completedTutorials ?? this.completedTutorials,
    );
  }
}

/// Service de gestion des tutoriels interactifs
class InteractiveTutorialService extends Notifier<InteractiveTutorialState> {
  static const _prefsKey = 'completed_interactive_tutorials';

  @override
  InteractiveTutorialState build() {
    _loadCompletedTutorials();
    return const InteractiveTutorialState();
  }

  Future<void> _loadCompletedTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_prefsKey) ?? [];
    state = state.copyWith(completedTutorials: Set.from(completed));
  }

  Future<void> _saveCompletedTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.completedTutorials.toList());
  }

  /// Démarre un tutoriel
  void startTutorial(String tutorialId) {
    final tutorial = InteractiveTutorials.getById(tutorialId);
    if (tutorial == null) return;

    state = state.copyWith(
      activeTutorial: tutorial,
      currentStepIndex: 0,
      isPaused: false,
    );
  }

  /// Passe au step suivant
  void nextStep() {
    if (!state.isActive) return;

    if (state.isLastStep) {
      completeTutorial();
    } else {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  /// Revient au step précédent
  void previousStep() {
    if (!state.isActive || state.currentStepIndex == 0) return;
    state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
  }

  /// Va à un step spécifique
  void goToStep(int index) {
    if (!state.isActive) return;
    if (index < 0 || index >= state.activeTutorial!.steps.length) return;
    state = state.copyWith(currentStepIndex: index);
  }

  /// Met en pause le tutoriel
  void pauseTutorial() {
    if (!state.isActive) return;
    state = state.copyWith(isPaused: true);
  }

  /// Reprend le tutoriel
  void resumeTutorial() {
    if (state.activeTutorial == null || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
  }

  /// Termine et sauvegarde le tutoriel comme complété
  Future<void> completeTutorial() async {
    if (state.activeTutorial == null) return;

    final completed = Set<String>.from(state.completedTutorials);
    completed.add(state.activeTutorial!.id);

    state = state.copyWith(
      completedTutorials: completed,
      clearActiveTutorial: true,
      currentStepIndex: 0,
    );

    await _saveCompletedTutorials();
  }

  /// Annule le tutoriel en cours
  void cancelTutorial() {
    state = state.copyWith(
      clearActiveTutorial: true,
      currentStepIndex: 0,
      isPaused: false,
    );
  }

  /// Vérifie si un tutoriel est complété
  bool isCompleted(String tutorialId) {
    return state.completedTutorials.contains(tutorialId);
  }

  /// Réinitialise tous les tutoriels
  Future<void> resetAllTutorials() async {
    state = state.copyWith(completedTutorials: {});
    await _saveCompletedTutorials();
  }

  /// Démarre le tutoriel de bienvenue si non complété
  Future<bool> startWelcomeTutorialIfNeeded() async {
    await _loadCompletedTutorials();
    
    if (!isCompleted('welcome_tour')) {
      startTutorial('welcome_tour');
      return true;
    }
    return false;
  }
}

/// Provider pour le service de tutoriel interactif
final interactiveTutorialProvider =
    NotifierProvider<InteractiveTutorialService, InteractiveTutorialState>(
  InteractiveTutorialService.new,
);

/// Provider pour vérifier si un tutoriel est complété
final isTutorialCompletedProvider = Provider.family<bool, String>((ref, tutorialId) {
  return ref.watch(interactiveTutorialProvider).completedTutorials.contains(tutorialId);
});

/// Provider pour la progression totale des tutoriels
final tutorialProgressProvider = Provider<double>((ref) {
  final state = ref.watch(interactiveTutorialProvider);
  final total = InteractiveTutorials.all.length;
  final completed = state.completedTutorials.length;
  return completed / total;
});
