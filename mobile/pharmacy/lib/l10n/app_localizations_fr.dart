// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'DR-PHARMA Pharmacie';

  @override
  String get sessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get genericError => 'Une erreur est survenue';

  @override
  String get retry => 'Réessayer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get search => 'Rechercher';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get loading => 'Chargement en cours';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Terminé';

  @override
  String get selectStartDate => 'Date de début';

  @override
  String get selectEndDate => 'Date de fin';

  @override
  String get select => 'Sélectionner';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get login => 'Se connecter';

  @override
  String get loginTitle => 'Bienvenue';

  @override
  String get loginSubtitle => 'Connectez-vous à votre pharmacie';

  @override
  String get email => 'Adresse email';

  @override
  String get password => 'Mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get register => 'S\'inscrire';

  @override
  String get biometricLogin => 'Connectez-vous à DR-PHARMA';

  @override
  String get noSavedAccount =>
      'Aucun compte sauvegardé. Connectez-vous d\'abord avec email/mot de passe.';

  @override
  String get passwordTooShort => 'Trop court';

  @override
  String get passwordWeak => 'Faible';

  @override
  String get passwordMedium => 'Moyen';

  @override
  String get passwordStrong => 'Fort';

  @override
  String get emailRequired => 'L\'email est requis';

  @override
  String get emailInvalid => 'Email invalide';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String passwordMinLength(int minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères';
  }

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get ordersTitle => 'Mes Commandes';

  @override
  String get ordersSubtitle => 'Gérez vos commandes en temps réel';

  @override
  String get inventoryTitle => 'Inventaire';

  @override
  String get walletTitle => 'Portefeuille';

  @override
  String get profileTitle => 'Profil';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String orderReference(String reference) {
    return 'Commande #$reference';
  }

  @override
  String get orderConfirmed => 'Commande confirmée !';

  @override
  String get orderReady => 'Commande prête !';

  @override
  String get orderRejected => 'Commande refusée';

  @override
  String get confirmOrder => 'Confirmer la commande';

  @override
  String get markAsReady => 'Marquer comme prête';

  @override
  String get rejectOrder => 'Refuser la commande';

  @override
  String get rejectOrderTitle => 'Refuser la commande';

  @override
  String get rejectionReasonOutOfStock => 'Produit en rupture de stock';

  @override
  String get rejectionReasonInvalidPrescription => 'Ordonnance invalide';

  @override
  String get rejectionReasonPharmacyClosed => 'Pharmacie fermée';

  @override
  String get rejectionReasonImpossibleDelay =>
      'Délai de préparation impossible';

  @override
  String get rejectionReasonOther => 'Autre';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusConfirmed => 'Confirmée';

  @override
  String get statusReady => 'Prête';

  @override
  String get statusInDelivery => 'En livraison';

  @override
  String get statusDelivered => 'Livrée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get statusRejected => 'Refusée';

  @override
  String get statusUnpaid => 'Non payé';

  @override
  String get emptyOrdersTitle => 'Calme plat pour l\'instant';

  @override
  String get emptyOrdersSubtitle =>
      'On te notifie dès qu\'un client passe commande';

  @override
  String get emptyPrescriptionsTitle => 'Pas d\'ordonnance en attente';

  @override
  String get emptyPrescriptionsSubtitle =>
      'Les nouvelles ordonnances apparaîtront ici';

  @override
  String get emptyInventoryTitle => 'Ton inventaire est vide';

  @override
  String get emptyInventorySubtitle => 'Ajoute tes premiers produits';

  @override
  String get emptyNotificationsTitle => 'Tout est lu !';

  @override
  String get emptyNotificationsSubtitle => 'Bravo, tu es à jour';

  @override
  String get emptyTeamTitle => 'Travaille en équipe';

  @override
  String get emptyTeamSubtitle => 'Invite tes collègues';

  @override
  String get emptyChatTitle => 'Aucun message';

  @override
  String get emptyChatSubtitle =>
      'Quand un client te contacte, la conversation apparaît ici';

  @override
  String get deliveryFee => 'Frais de livraison';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get total => 'Total';

  @override
  String get paymentMode => 'Mode de paiement';

  @override
  String get customerNotes => 'Notes du client';

  @override
  String get prescriptionComplete => 'Ordonnance complète !';

  @override
  String get partialDispensation => 'Dispensation partielle';

  @override
  String get selectAtLeastOneMedication =>
      'Sélectionnez au moins un médicament à délivrer';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterPending => 'En attente';

  @override
  String get filterConfirmed => 'Confirmées';

  @override
  String get filterReady => 'Prêtes';

  @override
  String get filterInDelivery => 'En livraison';

  @override
  String get filterDelivered => 'Livrées';

  @override
  String get filterCancelled => 'Annulées';

  @override
  String get kycStatusApproved => 'Validé';

  @override
  String get kycStatusPending => 'En attente';

  @override
  String get kycStatusRejected => 'Rejeté';

  @override
  String get supportTitle => 'Aide & Support';

  @override
  String get termsTitle => 'Conditions d\'utilisation';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get securitySettings => 'Sécurité';

  @override
  String get appearanceSettings => 'Apparence';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get currency => 'FCFA';

  @override
  String get enterEmail => 'Veuillez entrer votre email';

  @override
  String get invalidEmailFormat => 'Format d\'email invalide';

  @override
  String get enterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get passwordHidden => 'Mot de passe masqué';

  @override
  String get passwordVisible => 'Mot de passe visible';

  @override
  String get verification => 'Vérification...';

  @override
  String loginWithBiometric(String biometricType) {
    return 'Se connecter avec $biometricType';
  }

  @override
  String get myPharmacy => 'Ma Pharmacie';

  @override
  String get pharmacist => 'Pharmacien';

  @override
  String get balance => 'Solde';

  @override
  String get totalEarned => 'Total gagné';

  @override
  String get error => 'erreur';

  @override
  String get actionsRequired => 'Actions requises';

  @override
  String pendingOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count commande$_temp0 en attente';
  }

  @override
  String pendingPrescriptionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count ordonnance$_temp0 en attente';
  }

  @override
  String get quickView => 'Vue rapide';

  @override
  String get thisWeek => 'cette semaine';

  @override
  String ordersThisWeek(int count) {
    return '$count commandes cette sem.';
  }

  @override
  String criticalProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count produit$_temp0 critique$_temp1';
  }

  @override
  String expiringSoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nt',
      one: '',
    );
    return '$count expire$_temp0 bientôt';
  }

  @override
  String expiredProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count produit$_temp0 expiré$_temp1 !';
  }

  @override
  String peakDay(String day) {
    return 'Pic: $day';
  }

  @override
  String get noRecentOrders => 'Aucune commande récente';

  @override
  String get noRecentPrescriptions => 'Aucune ordonnance récente';

  @override
  String get revenueToday => 'Chiffre d\'affaires du jour';

  @override
  String get finances => 'Finances';

  @override
  String get orders => 'Commandes';

  @override
  String get prescriptions => 'Ordonnances';

  @override
  String get statusPendingConfirmation => 'En attente de confirmation';

  @override
  String get statusReadyForPickup => 'Prête pour ramassage';

  @override
  String get statusInProgress => 'En cours de livraison';

  @override
  String get confirmDispensation => 'Confirmer la dispensation';

  @override
  String dispenseCount(int count) {
    return 'Vous allez délivrer $count médicament(s). Confirmer ?';
  }

  @override
  String get orderSentToSupplier => 'Commande envoyée au fournisseur';

  @override
  String get order => 'Commander';

  @override
  String get pinChanged => 'Code PIN modifié avec succès';

  @override
  String get orderStatusPending => 'En attente';

  @override
  String get orderStatusConfirmed => 'Confirmée';

  @override
  String get orderStatusReady => 'Prête';

  @override
  String get orderStatusInDelivery => 'En livraison';

  @override
  String get orderStatusDelivered => 'Livrée';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get orderStatusRejected => 'Refusée';

  @override
  String get orderStatusUnpaid => 'Non payé';

  @override
  String get orderFilterAll => 'Toutes';

  @override
  String get orderFilterPending => 'En attente';

  @override
  String get orderFilterConfirmed => 'Confirmées';

  @override
  String get orderFilterReady => 'Prêtes';

  @override
  String get orderFilterInDelivery => 'En livraison';

  @override
  String get orderFilterDelivered => 'Livrées';

  @override
  String get orderFilterCancelled => 'Annulées';

  @override
  String get connectionTitle => 'Connexion';

  @override
  String get accessPharmacySpace => 'Accédez à votre espace pharmacie';

  @override
  String get noAccountYetQuestion => 'Vous n\'avez pas de compte ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String modificationsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count modification$_temp0 en attente';
  }

  @override
  String get offlineModeLabel => 'Mode hors-ligne';

  @override
  String get syncJustNow => 'Synchro: à l\'instant';

  @override
  String syncMinutesAgo(int minutes) {
    return 'Synchro: il y a $minutes min';
  }

  @override
  String syncHoursAgo(int hours) {
    return 'Synchro: il y a ${hours}h';
  }

  @override
  String syncDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Synchro: il y a $days jour$_temp0';
  }

  @override
  String get syncPending => 'Synchronisation en attente';

  @override
  String get reportsTitle => 'Rapports & Analytics';

  @override
  String get exportButton => 'Exporter';

  @override
  String get refreshButton => 'Actualiser';

  @override
  String get overviewTab => 'Vue d\'ensemble';

  @override
  String get salesTab => 'Ventes';

  @override
  String get ordersTab => 'Commandes';

  @override
  String get inventoryTab => 'Inventaire';

  @override
  String get loadingError => 'Erreur de chargement';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get actionRequired => 'Action requise';

  @override
  String get noOrders => 'Aucune commande';

  @override
  String get delivered => 'Livrées';

  @override
  String get pendingLabel => 'En attente';

  @override
  String get cancelledLabel => 'Annulées';

  @override
  String get topProducts => 'Top 5 Produits';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String salesCount(int count) {
    return '$count ventes';
  }

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get periodThisWeek => 'Cette semaine';

  @override
  String get periodThisMonth => 'Ce mois';

  @override
  String get periodThisQuarter => 'Ce trimestre';

  @override
  String get periodThisYear => 'Cette année';

  @override
  String get revenueLabel => 'Chiffre d\'affaires';

  @override
  String get ordersLabel => 'Commandes';

  @override
  String get productsLabel => 'Produits';

  @override
  String get inStockSuffix => 'en stock';

  @override
  String get alertsLabel => 'Alertes';

  @override
  String get activeSuffix => 'actives';

  @override
  String get salesTrend => 'Évolution des ventes';

  @override
  String get orderStatus => 'Statut des commandes';

  @override
  String get exportInProgress => 'Export en cours...';

  @override
  String get expiryAlerts => 'Alertes d\'expiration';

  @override
  String expiredBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lots expirés',
      one: '1 lot expiré',
    );
    return '$_temp0';
  }

  @override
  String criticalBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lots critiques (≤7j)',
      one: '1 lot critique (≤7j)',
    );
    return '$_temp0';
  }

  @override
  String warningBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lots à surveiller (≤30j)',
      one: '1 lot à surveiller (≤30j)',
    );
    return '$_temp0';
  }

  @override
  String get batchNumber => 'N° de lot';

  @override
  String get lotNumber => 'N° de lot interne';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get batchQuantity => 'Quantité du lot';

  @override
  String get addBatch => 'Ajouter un lot';

  @override
  String get supplierLabel => 'Fournisseur';
}
