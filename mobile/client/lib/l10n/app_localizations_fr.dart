// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'DR-PHARMA';

  @override
  String get navHome => 'Accueil';

  @override
  String get navMyCart => 'Mon Panier';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Mon Profil';

  @override
  String get navMyOrders => 'Mes Commandes';

  @override
  String get navCheckout => 'Validation de la commande';

  @override
  String get navOrderDetails => 'Détails de la commande';

  @override
  String get navOnDutyPharmacies => 'Pharmacies de Garde';

  @override
  String get navPrescriptionUpload => 'Upload d\'ordonnance';

  @override
  String get navEditAddress => 'Modifier l\'adresse';

  @override
  String get navTerms => 'Conditions d\'utilisation';

  @override
  String get navPrivacy => 'Politique de confidentialité';

  @override
  String get navLegal => 'Mentions Légales';

  @override
  String get navError => 'Erreur';

  @override
  String get navTheme => 'Thème';

  @override
  String get homeMedications => 'Médicaments';

  @override
  String get homeAllProducts => 'Tous les produits';

  @override
  String get homeGuard => 'Garde';

  @override
  String get homePharmacies => 'Pharmacies';

  @override
  String get homePrescription => 'Ordonnance';

  @override
  String get homeServices => 'Services';

  @override
  String get homeFeatured => 'À la une';

  @override
  String get homeSeeAll => 'Voir tout';

  @override
  String get homeGreeting => 'Bonjour,';

  @override
  String get promoFreeDelivery => 'Livraison Gratuite';

  @override
  String get promoFirstOrder => 'Sur votre première commande';

  @override
  String get promoVitamins => 'Vitamines & Compléments';

  @override
  String get promoService24 => 'Service 24h/24';

  @override
  String get promoOnDutyPharmacy => 'Pharmacie de garde';

  @override
  String get onboardingWelcome => 'Bienvenue sur DR-PHARMA';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingPrevious => 'Précédent';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get authLogin => 'Se connecter';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authLogout => 'Déconnexion';

  @override
  String get authRegistrationSuccess => 'Inscription réussie !';

  @override
  String get authPhoneNumber => 'Numéro de téléphone';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authFirstName => 'Prénom';

  @override
  String get authLastName => 'Nom';

  @override
  String get authEmail => 'Email';

  @override
  String get authRememberMe => 'Se souvenir de moi';

  @override
  String get authNoAccount => 'Pas encore de compte ?';

  @override
  String get authHaveAccount => 'Déjà un compte ?';

  @override
  String get authOtpSent => 'Code envoyé';

  @override
  String get authOtpVerify => 'Vérifier le code';

  @override
  String get authAcceptTerms => 'J\'accepte les conditions d\'utilisation';

  @override
  String get btnRetry => 'Réessayer';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnBackToHome => 'Retour à l\'accueil';

  @override
  String get btnValidate => 'Valider';

  @override
  String get btnOk => 'OK';

  @override
  String get btnNo => 'Non';

  @override
  String get btnDelete => 'Supprimer';

  @override
  String get btnEdit => 'Modifier';

  @override
  String get btnQuit => 'Quitter';

  @override
  String get btnRefresh => 'Actualiser';

  @override
  String get btnClearSearch => 'Effacer la recherche';

  @override
  String get btnBrowseProducts => 'Parcourir les produits';

  @override
  String get btnTakePhoto => 'Prendre une photo';

  @override
  String get btnChooseGallery => 'Choisir depuis la galerie';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get cartAddToCart => 'Ajouter au panier';

  @override
  String get cartViewProducts => 'Voir les produits';

  @override
  String get cartPlaceOrder => 'Passer la commande';

  @override
  String get cartClearCart => 'Vider le panier';

  @override
  String get cartClear => 'Vider';

  @override
  String cartConfirmOrder(String total) {
    return 'Confirmer la commande - $total';
  }

  @override
  String get cartViewDetails => 'Voir les détails';

  @override
  String get cartMyOrders => 'Mes commandes';

  @override
  String get cartCheckPayment => 'Vérifier le paiement';

  @override
  String get cartSimulatePayment => 'Simuler le paiement';

  @override
  String get cartSendReview => 'Envoyer mon avis';

  @override
  String get prescriptionSend => 'Envoyer une ordonnance';

  @override
  String get prescriptionSendForValidation => 'Envoyer pour validation';

  @override
  String get prescriptionAddPhoto => 'Ajouter une photo';

  @override
  String get prescriptionAddPrescription => 'Ajouter une ordonnance';

  @override
  String get prescriptionConfirmPay => 'Confirmer et Payer';

  @override
  String get prescriptionPay => 'Payer';

  @override
  String get prescriptionViewDetails => 'Voir détails';

  @override
  String get prescriptionNoPhotos => 'Aucune photo ajoutée';

  @override
  String get pharmacyCall => 'Appeler';

  @override
  String get pharmacyRoute => 'Itinéraire';

  @override
  String get pharmacyDetails => 'Détails';

  @override
  String get pharmacyEnableLocation => 'Activer la localisation';

  @override
  String get pharmacyUpdatePosition => 'Mettre à jour la position';

  @override
  String get addressDeliveryAddress => 'Adresse de livraison';

  @override
  String get addressSelectDelivery =>
      'Veuillez sélectionner une adresse de livraison';

  @override
  String get addressAddForOrders =>
      'Ajoutez une adresse pour faciliter vos commandes';

  @override
  String get addressDeliveryCode => 'Code de livraison';

  @override
  String get addressDeliveryCodeHint =>
      'Communiquez ce code au livreur\npour confirmer la réception';

  @override
  String get addressSetDefault => 'Définir comme adresse par défaut';

  @override
  String get addressDeliveryInstructions => 'Instructions de livraison';

  @override
  String get addressLocating => 'Localisation en cours...';

  @override
  String get addressSaved => 'Adresse enregistrée';

  @override
  String get addressNew => 'Nouvelle adresse';

  @override
  String get addressForNextOrders => 'Pour vos prochaines commandes';

  @override
  String get addressDelete => 'Supprimer l\'adresse';

  @override
  String get addressAdd => 'Ajouter une adresse';

  @override
  String get addressNewTitle => 'Nouvelle adresse';

  @override
  String get addressSetAsDefault => 'Définir par défaut';

  @override
  String get orderStatusPending => 'En attente';

  @override
  String get orderStatusConfirmed => 'Confirmée';

  @override
  String get orderStatusConfirmedPlural => 'Confirmées';

  @override
  String get orderStatusReady => 'Prête';

  @override
  String get orderStatusDelivering => 'En livraison';

  @override
  String get orderStatusDelivered => 'Livrée';

  @override
  String get orderStatusDeliveredPlural => 'Livrées';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get orderStatusCancelledPlural => 'Annulées';

  @override
  String get orderStatusFailed => 'Échouée';

  @override
  String get orderStatusPickedUp => 'Commande récupérée';

  @override
  String get orderStatusDeliveredCheck => 'Livré ✓';

  @override
  String get orderStatusPreparing => 'En préparation';

  @override
  String get orderStatusPreparingEllipsis => 'En préparation...';

  @override
  String get orderStatusProcessing => 'En traitement';

  @override
  String get orderStatusValidated => 'Validée';

  @override
  String get orderStatusRejected => 'Rejetée';

  @override
  String get orderStatusCancelledOn => 'Annulée le';

  @override
  String get orderStatusPendingFull => 'Commande en attente';

  @override
  String get paymentOnline => 'Paiement en ligne';

  @override
  String get paymentOnDelivery => 'Paiement à la livraison';

  @override
  String get paymentChooseMethod => 'Choisir le moyen de paiement';

  @override
  String get paymentInitializing => 'Initialisation du paiement...';

  @override
  String get paymentProcessing => 'Paiement en cours...';

  @override
  String get paymentSuccess => 'Paiement réussi !';

  @override
  String get paymentSuccessMessage =>
      'Votre paiement a été effectué avec succès';

  @override
  String get paymentWaitingConfirmation =>
      'En attente de confirmation du paiement...';

  @override
  String get paymentConfirm => 'Confirmer le paiement';

  @override
  String get paymentMode => 'Mode de paiement:';

  @override
  String get paymentDeliveryFees => 'Frais de livraison';

  @override
  String get paymentProcessingFees => 'Frais de paiement';

  @override
  String get paymentOnlineFees => 'Frais de traitement du paiement en ligne';

  @override
  String get paymentOrderSummary => 'Résumé de la commande';

  @override
  String get paymentSubtotal => 'Sous-total';

  @override
  String get paymentTotal => 'Total';

  @override
  String get paymentAutoConfirm => 'Le paiement sera automatiquement confirmé';

  @override
  String get emptyNoProducts => 'Aucun produit';

  @override
  String get emptyNoResults => 'Aucun résultat';

  @override
  String get emptyNoOrders => 'Aucune commande';

  @override
  String get emptyCart => 'Panier vide';

  @override
  String get emptyNoNotifications => 'Aucune notification';

  @override
  String get emptyNoProfile => 'Aucun profil disponible';

  @override
  String get emptyNoData => 'Aucune donnée disponible';

  @override
  String get emptyNoDataShort => 'Aucune donnée';

  @override
  String get emptyNoPharmacies => 'Aucune pharmacie disponible';

  @override
  String get emptyNoOnDutyPharmacies => 'Aucune pharmacie de garde';

  @override
  String get emptyImageNotAvailable => 'Image non disponible';

  @override
  String get errorGeneric => 'Une erreur s\'est produite';

  @override
  String get errorGenericRetry =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get errorUnexpected => 'Une erreur inattendue s\'est produite';

  @override
  String get errorNoInternet => 'Pas de connexion Internet';

  @override
  String get errorNoInternetLower => 'Pas de connexion internet';

  @override
  String get errorCheckConnection => 'Vérifiez votre connexion et réessayez.';

  @override
  String get errorConnection => 'Erreur de connexion';

  @override
  String get errorTimeout => 'Délai de connexion dépassé';

  @override
  String get errorServerUnreachable => 'Impossible de se connecter au serveur';

  @override
  String get errorSessionExpired =>
      'Session expirée. Veuillez vous reconnecter';

  @override
  String get errorUnauthorized => 'Accès non autorisé';

  @override
  String get errorNotFound => 'Ressource non trouvée';

  @override
  String get errorInvalidData => 'Données invalides';

  @override
  String get errorTooManyRequests => 'Trop de requêtes. Veuillez patienter';

  @override
  String get errorServer => 'Erreur serveur. Veuillez réessayer plus tard';

  @override
  String get errorServiceUnavailable => 'Service temporairement indisponible';

  @override
  String get errorInvalidRequest => 'Requête invalide';

  @override
  String get errorRequestCancelled => 'Requête annulée';

  @override
  String get errorInvalidCertificate => 'Certificat de sécurité invalide';

  @override
  String get errorDataConflict => 'Conflit de données';

  @override
  String get errorRequestTimeout => 'La requête a pris trop de temps';

  @override
  String get errorInvalidServerData => 'Données invalides reçues du serveur';

  @override
  String get errorValidation => 'Erreur de validation';

  @override
  String get errorLoadingNotifications =>
      'Erreur lors du chargement des notifications';

  @override
  String get errorUpdating => 'Erreur lors de la mise à jour';

  @override
  String get errorDeleting => 'Erreur lors de la suppression';

  @override
  String get errorLoadingPrescriptions =>
      'Erreur lors du chargement des ordonnances';

  @override
  String get errorLoadingDetails => 'Erreur lors du chargement des détails';

  @override
  String get errorPayment => 'Erreur lors du paiement';

  @override
  String get errorCalculatingFees => 'Erreur lors du calcul des frais';

  @override
  String get errorConnectionCheck =>
      'Erreur de connexion. Vérifiez votre internet.';

  @override
  String get errorNetworkCheck => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorUnknown => 'Erreur inconnue';

  @override
  String get errorPaymentFailed => 'Le paiement a échoué. Veuillez réessayer.';

  @override
  String get errorTooManyAttempts =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get errorSessionExpiredNewCode =>
      'Session expirée. Veuillez demander un nouveau code.';

  @override
  String get validationPasswordRequired => 'Le mot de passe est requis';

  @override
  String get validationPassword6Chars =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get validationPassword8Chars =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get validationPasswordUppercase =>
      'Le mot de passe doit contenir au moins une majuscule';

  @override
  String get validationPasswordLowercase =>
      'Le mot de passe doit contenir au moins une minuscule';

  @override
  String get validationPasswordDigit =>
      'Le mot de passe doit contenir au moins un chiffre';

  @override
  String get validationConfirmPassword => 'Confirmez le mot de passe';

  @override
  String get validationPleaseConfirmPassword =>
      'Veuillez confirmer le mot de passe';

  @override
  String get validationEmailInvalid => 'Veuillez entrer un email valide';

  @override
  String get validationPhoneInvalid =>
      'Veuillez entrer un numéro de téléphone valide';

  @override
  String get validationAmountInvalid => 'Veuillez entrer un montant valide';

  @override
  String get validationNumberInvalid => 'Veuillez entrer un nombre valide';

  @override
  String get validationNameRequired => 'Le nom est requis';

  @override
  String get validationAddressRequired => 'Veuillez entrer votre adresse';

  @override
  String get validationCityRequired => 'Veuillez entrer la ville';

  @override
  String get validationPhoneRequired => 'Veuillez entrer votre numéro';

  @override
  String get validationCurrentPasswordRequired =>
      'Veuillez entrer votre mot de passe actuel';

  @override
  String get validationNewPasswordRequired =>
      'Veuillez entrer un nouveau mot de passe';

  @override
  String get validationConfirmNewPassword =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get validationSelectionRequired => 'Veuillez faire une sélection';

  @override
  String get validationAcceptTerms =>
      'Veuillez accepter les conditions d\'utilisation';

  @override
  String get searchPharmacy => 'Rechercher une pharmacie...';

  @override
  String get searchMedications => 'Rechercher des médicaments...';

  @override
  String get searchMedication => 'Rechercher un médicament...';

  @override
  String get searchOnDutyPharmacies => 'Recherche des pharmacies de garde...';

  @override
  String get searchLoadingPharmacies => 'Chargement des pharmacies...';

  @override
  String get pharmacyStatusOpen => 'Ouvert';

  @override
  String get pharmacyStatusOpenFeminine => 'Ouverte';

  @override
  String get pharmacyStatusOpenPlural => 'Ouvertes';

  @override
  String get pharmacyStatusClosed => 'Fermé';

  @override
  String get pharmacyStatusClosedFeminine => 'Fermée';

  @override
  String get pharmacyStatusOnDuty => 'Pharmacie de garde';

  @override
  String get pharmacyAddressUnavailable => 'Adresse non disponible';

  @override
  String get ratingFast => 'Rapide';

  @override
  String get ratingPolite => 'Poli';

  @override
  String get ratingProfessional => 'Professionnel';

  @override
  String get ratingPunctual => 'Ponctuel';

  @override
  String get ratingLate => 'En retard';

  @override
  String get ratingRude => 'Impoli';

  @override
  String get ratingDamaged => 'Colis abîmé';

  @override
  String get ratingGoodPackaging => 'Bon emballage';

  @override
  String get ratingCorrectProducts => 'Produits conformes';

  @override
  String get ratingFastService => 'Service rapide';

  @override
  String get ratingMissingProduct => 'Produit manquant';

  @override
  String get ratingPoorPackaging => 'Emballage insuffisant';

  @override
  String get ratingLongWait => 'Attente longue';

  @override
  String get ratingTitle => 'Évaluez votre commande';

  @override
  String get ratingCommentHint => 'Ajouter un commentaire (optionnel)...';

  @override
  String get ratingThankYou => 'Merci pour votre avis !';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get profileEditSubtitle => 'Changer vos informations personnelles';

  @override
  String get profileMyAddresses => 'Mes adresses';

  @override
  String get profileMyAddressesSubtitle => 'Gérer vos adresses de livraison';

  @override
  String get profileNotificationsSubtitle =>
      'Gérer vos préférences de notification';

  @override
  String get profileHelpSupport => 'Aide et Support';

  @override
  String get profileLegal => 'Mentions légales';

  @override
  String get profileLegalSubtitle =>
      'Conditions d\'utilisation et confidentialité';

  @override
  String get profileOrders => 'Commandes';

  @override
  String get profileDelivered => 'Livrées';

  @override
  String get profileTotalSpent => 'Total Dépensé';

  @override
  String get profileMemberSince => 'Membre depuis';

  @override
  String get profileDefaultAddress => 'Adresse par défaut';

  @override
  String get profileAccountInfo => 'Informations du compte';

  @override
  String get profilePersonalInfo => 'Informations personnelles';

  @override
  String get profileOrderUpdates => 'Mises à jour de commande';

  @override
  String get profileDeliveryAlerts => 'Alertes de livraison';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeSystemDescription => 'Suit le thème de l\'appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeLightDescription => 'Toujours utiliser le thème clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeDarkDescription => 'Toujours utiliser le thème sombre';

  @override
  String get dialogQuitApp => 'Quitter l\'application';

  @override
  String get dialogQuitAppMessage => 'Voulez-vous vraiment quitter DR-PHARMA ?';

  @override
  String get dialogCancelOrder => 'Annuler la commande';

  @override
  String get dialogCancelOrderMessage =>
      'Êtes-vous sûr de vouloir annuler cette commande ?';

  @override
  String get dialogClearCartMessage =>
      'Êtes-vous sûr de vouloir supprimer tous les articles du panier ?';

  @override
  String get dialogDeleteAvatarMessage =>
      'Voulez-vous vraiment supprimer votre photo de profil ?';

  @override
  String get dialogNotificationDeleted => 'Notification supprimée';

  @override
  String get loadingGeneric => 'Chargement...';

  @override
  String get loadingInProgress => 'Chargement en cours';

  @override
  String get loadingSending => 'Envoi en cours...';

  @override
  String get loadingProcessing => 'Traitement en cours...';

  @override
  String get loadingOrderProcessing => 'Commande en cours de traitement...';

  @override
  String get successPrescriptionSent => 'Ordonnance envoyée avec succès !';

  @override
  String get successAddressUpdated => 'Adresse mise à jour avec succès';

  @override
  String get successGpsUpdated => 'Position GPS mise à jour';

  @override
  String get successPasswordUpdated =>
      'Votre mot de passe a été mis à jour avec succès';

  @override
  String get permissionLocationDenied => 'Permission de localisation refusée';

  @override
  String get permissionLocationDisabled =>
      'La localisation est désactivée. Activez-la dans les paramètres.';

  @override
  String get miscAvatarChangeSoon =>
      'Changement d\'avatar - Bientôt disponible';

  @override
  String get miscCannotOpenEmail => 'Impossible d\'ouvrir l\'application email';

  @override
  String get miscSinglePharmacyOrder =>
      'Vous ne pouvez commander que dans une seule pharmacie à la fois';

  @override
  String get miscDeliveryContact =>
      'Bonjour, je vous contacte concernant ma livraison.';

  @override
  String get miscDeleteAvatar => 'Supprimer l\'avatar';

  @override
  String get miscTrackDelivery => 'Suivre la livraison';
}
