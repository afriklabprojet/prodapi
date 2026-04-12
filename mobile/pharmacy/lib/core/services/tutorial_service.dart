import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

/// Clés pour le stockage des tutoriels vus.
class TutorialKeys {
  static const String dashboard = 'tutorial_dashboard_seen';
  static const String orderDetails = 'tutorial_order_details_seen';
  static const String prescriptionScan = 'tutorial_prescription_scan_seen';
  static const String inventory = 'tutorial_inventory_seen';
  static const String wallet = 'tutorial_wallet_seen';
  static const String statistics = 'tutorial_statistics_seen';
  // Nouveaux tutoriels contextuels pour les points de friction
  static const String prescriptionValidation =
      'tutorial_prescription_validation_seen';
  static const String courierHandoff = 'tutorial_courier_handoff_seen';
  static const String lowStockAlert = 'tutorial_low_stock_alert_seen';

  /// All keys for iteration in reset
  static const List<String> all = [
    dashboard,
    orderDetails,
    prescriptionScan,
    inventory,
    wallet,
    statistics,
    prescriptionValidation,
    courierHandoff,
    lowStockAlert,
  ];
}

/// Provider pour le TutorialService.
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

/// Service de gestion des coachmarks / tutoriels contextuels.
///
/// Remplace l'onboarding statique par des guides point-par-point
/// qui apparaissent au premier usage de chaque fonctionnalité.
class TutorialService {
  TutorialCoachMark? _currentTutorial;
  SharedPreferences? _prefs;

  /// Lazy-initialized SharedPreferences
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Vérifie si un tutoriel a déjà été vu.
  Future<bool> hasSeenTutorial(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key) ?? false;
  }

  /// Marque un tutoriel comme vu.
  Future<void> markTutorialAsSeen(String key) async {
    final prefs = await _preferences;
    await prefs.setBool(key, true);
  }

  /// Réinitialise tous les tutoriels (pour les tests ou paramètres).
  Future<void> resetAllTutorials() async {
    final prefs = await _preferences;
    await Future.wait(TutorialKeys.all.map(prefs.remove));
  }

  /// Affiche un tutoriel si pas encore vu.
  Future<void> showTutorialIfNeeded({
    required BuildContext context,
    required String tutorialKey,
    required List<TargetFocus> targets,
    VoidCallback? onFinish,
    VoidCallback? onSkip,
  }) async {
    if (await hasSeenTutorial(tutorialKey)) return;
    if (targets.isEmpty) return;

    // Léger délai pour laisser l'écran se construire
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    _currentTutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primary.withValues(alpha: 0.8),
      textSkip: 'PASSER',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      paddingFocus: 10,
      opacityShadow: 0.85,
      hideSkip: false,
      alignSkip: Alignment.topRight,
      onFinish: () async {
        await markTutorialAsSeen(tutorialKey);
        onFinish?.call();
      },
      onSkip: () {
        markTutorialAsSeen(tutorialKey);
        onSkip?.call();
        return true;
      },
      onClickTarget: (target) {
        // Feedback visuel au tap
      },
    );

    _currentTutorial!.show(context: context);
  }

  /// Ferme le tutoriel en cours s'il existe.
  void dismissCurrentTutorial() {
    _currentTutorial?.finish();
    _currentTutorial = null;
  }

  // =============================================================
  // CONSTRUCTEURS DE TARGETS PAR ÉCRAN
  // =============================================================

  /// Targets pour le dashboard pharmacie.
  static List<TargetFocus> buildDashboardTargets({
    required GlobalKey ordersKey,
    required GlobalKey statsKey,
    required GlobalKey walletKey,
    required GlobalKey scanKey,
  }) {
    return [
      _buildTarget(
        key: ordersKey,
        identify: 'orders',
        title: 'Vos commandes',
        description:
            'Consultez et gérez toutes les commandes en attente '
            'et en cours de livraison.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
      _buildTarget(
        key: statsKey,
        identify: 'stats',
        title: 'Statistiques',
        description:
            'Suivez vos performances : chiffre d\'affaires, '
            'commandes du jour, tendances.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
      _buildTarget(
        key: walletKey,
        identify: 'wallet',
        title: 'Portefeuille',
        description:
            'Votre solde et historique des transactions. '
            'Demandez un retrait à tout moment.',
        shape: ShapeLightFocus.Circle,
      ),
      _buildTarget(
        key: scanKey,
        identify: 'scan',
        title: 'Scanner une ordonnance',
        description:
            'Scannez les ordonnances avec reconnaissance OCR '
            'intelligente pour un traitement rapide.',
        shape: ShapeLightFocus.Circle,
      ),
    ];
  }

  /// Targets pour les détails d'une commande.
  static List<TargetFocus> buildOrderDetailsTargets({
    required GlobalKey statusKey,
    required GlobalKey productsKey,
    required GlobalKey actionsKey,
    GlobalKey? prescriptionKey,
  }) {
    final targets = <TargetFocus>[
      _buildTarget(
        key: statusKey,
        identify: 'status',
        title: 'Statut de la commande',
        description:
            'Visualisez l\'état actuel et l\'historique '
            'des changements de statut.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: productsKey,
        identify: 'products',
        title: 'Produits commandés',
        description:
            'Liste des médicaments avec quantités et stock. '
            'Modifiez la disponibilité si nécessaire.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: actionsKey,
        identify: 'actions',
        title: 'Actions',
        description:
            'Confirmez, refusez ou contactez le client '
            'directement depuis ces boutons.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
    ];

    if (prescriptionKey != null) {
      targets.insert(
        1,
        _buildTarget(
          key: prescriptionKey,
          identify: 'prescription',
          title: 'Ordonnance',
          description:
              'Consultez l\'ordonnance originale. '
              'Agrandissez pour vérifier les détails.',
          shape: ShapeLightFocus.RRect,
          radius: 8,
        ),
      );
    }

    return targets;
  }

  /// Targets pour l'inventaire.
  static List<TargetFocus> buildInventoryTargets({
    required GlobalKey searchKey,
    required GlobalKey filtersKey,
    required GlobalKey addProductKey,
    required GlobalKey productCardKey,
  }) {
    return [
      _buildTarget(
        key: searchKey,
        identify: 'search',
        title: 'Recherche rapide',
        description: 'Trouvez un produit par nom, code-barres ou catégorie.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
      _buildTarget(
        key: filtersKey,
        identify: 'filters',
        title: 'Filtres',
        description:
            'Filtrez par stock faible, catégorie, '
            'ou disponibilité.',
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      _buildTarget(
        key: productCardKey,
        identify: 'productCard',
        title: 'Fiche produit',
        description:
            'Tapez pour modifier prix, stock et détails. '
            'Glissez pour des actions rapides.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: addProductKey,
        identify: 'addProduct',
        title: 'Ajouter un produit',
        description:
            'Créez une nouvelle fiche produit avec scan '
            'du code-barres optionnel.',
        shape: ShapeLightFocus.Circle,
      ),
    ];
  }

  /// Targets pour le scan d'ordonnance.
  static List<TargetFocus> buildPrescriptionScanTargets({
    required GlobalKey cameraKey,
    required GlobalKey galleryKey,
    required GlobalKey flashKey,
  }) {
    return [
      _buildTarget(
        key: cameraKey,
        identify: 'camera',
        title: 'Capture',
        description:
            'Cadrez l\'ordonnance entière. La reconnaissance '
            'OCR détecte automatiquement les médicaments.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contentAlign: ContentAlign.bottom,
      ),
      _buildTarget(
        key: galleryKey,
        identify: 'gallery',
        title: 'Galerie',
        description: 'Sélectionnez une ordonnance depuis vos photos.',
        shape: ShapeLightFocus.Circle,
      ),
      _buildTarget(
        key: flashKey,
        identify: 'flash',
        title: 'Flash',
        description:
            'Activez le flash en cas de faible luminosité '
            'pour une meilleure reconnaissance.',
        shape: ShapeLightFocus.Circle,
      ),
    ];
  }

  /// Targets pour le portefeuille.
  static List<TargetFocus> buildWalletTargets({
    required GlobalKey balanceKey,
    required GlobalKey withdrawKey,
    required GlobalKey historyKey,
  }) {
    return [
      _buildTarget(
        key: balanceKey,
        identify: 'balance',
        title: 'Solde disponible',
        description:
            'Votre solde actuel, mis à jour en temps réel '
            'après chaque commande livrée.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
      _buildTarget(
        key: withdrawKey,
        identify: 'withdraw',
        title: 'Retrait',
        description:
            'Demandez un virement vers votre compte bancaire. '
            'Traité sous 24-48h.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
      _buildTarget(
        key: historyKey,
        identify: 'history',
        title: 'Historique',
        description:
            'Consultez toutes vos transactions : commissions, '
            'retraits, ajustements.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
    ];
  }

  // =============================================================
  // TUTORIELS CONTEXTUELS (points de friction)
  // =============================================================

  /// Targets pour la validation d'ordonnance (première ordonnance)
  static List<TargetFocus> buildPrescriptionValidationTargets({
    required GlobalKey prescriptionImageKey,
    required GlobalKey productsListKey,
    required GlobalKey validateButtonKey,
    GlobalKey? contactClientKey,
  }) {
    final targets = [
      _buildTarget(
        key: prescriptionImageKey,
        identify: 'prescriptionImage',
        title: 'L\'ordonnance originale',
        description:
            'Tapez pour agrandir et vérifier les détails. '
            'Comparez avec les produits détectés ci-dessous.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: productsListKey,
        identify: 'productsList',
        title: 'Produits détectés',
        description:
            'Cochez les produits disponibles. Vous pouvez '
            'modifier les quantités ou ajouter des alternatives.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
      _buildTarget(
        key: validateButtonKey,
        identify: 'validateButton',
        title: 'Envoyer le devis',
        description:
            'Le client reçoit votre proposition avec les prix. '
            'Il peut payer directement depuis l\'app.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
    ];

    if (contactClientKey != null) {
      targets.insert(
        2,
        _buildTarget(
          key: contactClientKey,
          identify: 'contactClient',
          title: 'Contacter le client',
          description:
              'Une question ? Appelez ou envoyez un message '
              'avant de valider l\'ordonnance.',
          shape: ShapeLightFocus.Circle,
        ),
      );
    }

    return targets;
  }

  /// Targets pour le passage livreur (première livraison)
  static List<TargetFocus> buildCourierHandoffTargets({
    required GlobalKey courierInfoKey,
    required GlobalKey orderItemsKey,
    required GlobalKey confirmHandoffKey,
  }) {
    return [
      _buildTarget(
        key: courierInfoKey,
        identify: 'courierInfo',
        title: 'Votre livreur',
        description:
            'Vérifiez l\'identité : nom et photo du livreur. '
            'Vous pouvez l\'appeler si besoin.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: orderItemsKey,
        identify: 'orderItems',
        title: 'Vérifiez la commande',
        description:
            'Assurez-vous que tous les produits sont bien '
            'emballés et correspondent à la liste.',
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
      _buildTarget(
        key: confirmHandoffKey,
        identify: 'confirmHandoff',
        title: 'Confirmer le ramassage',
        description:
            'Une fois la commande remise au livreur, '
            'confirmez ici. Le client sera notifié automatiquement.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
    ];
  }

  /// Targets pour l'alerte stock faible
  static List<TargetFocus> buildLowStockAlertTargets({
    required GlobalKey productCardKey,
    required GlobalKey stockFieldKey,
    required GlobalKey reorderButtonKey,
  }) {
    return [
      _buildTarget(
        key: productCardKey,
        identify: 'productCard',
        title: 'Produit en alerte',
        description:
            'Ce produit a un stock critique. Mettez à jour '
            'le stock après réception de livraison.',
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      _buildTarget(
        key: stockFieldKey,
        identify: 'stockField',
        title: 'Modifier le stock',
        description:
            'Entrez la nouvelle quantité. L\'historique '
            'des modifications est conservé.',
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      _buildTarget(
        key: reorderButtonKey,
        identify: 'reorderButton',
        title: 'Commander chez le grossiste',
        description:
            'Déclenchez une commande rapide auprès de '
            'votre fournisseur habituel.',
        shape: ShapeLightFocus.RRect,
        radius: 24,
      ),
    ];
  }

  // =============================================================
  // HELPERS PRIVÉS
  // =============================================================

  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const _descriptionStyle = TextStyle(
    color: Color(0xE6FFFFFF), // white with alpha 0.9
    fontSize: 16,
    height: 1.4,
  );

  static const _hintStyle = TextStyle(
    color: Color(0x99FFFFFF), // white with alpha 0.6
    fontSize: 13,
    fontStyle: FontStyle.italic,
  );

  static TargetFocus _buildTarget({
    required GlobalKey key,
    required String identify,
    required String title,
    required String description,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 8,
    ContentAlign contentAlign = ContentAlign.bottom,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      shape: shape,
      radius: radius,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: contentAlign,
          builder: (context, controller) =>
              _buildTargetContent(title, description),
        ),
      ],
    );
  }

  static Widget _buildTargetContent(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 10),
          Text(description, style: _descriptionStyle),
          const SizedBox(height: 20),
          const Row(
            children: [
              Text('Tapez pour continuer', style: _hintStyle),
              SizedBox(width: 8),
              Icon(Icons.touch_app, color: Color(0x99FFFFFF), size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
