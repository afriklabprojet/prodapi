import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In fr, this message translates to:
  /// **'DR-PHARMA'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navMyCart.
  ///
  /// In fr, this message translates to:
  /// **'Mon Panier'**
  String get navMyCart;

  /// No description provided for @navNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get navProfile;

  /// No description provided for @navMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes Commandes'**
  String get navMyOrders;

  /// No description provided for @navCheckout.
  ///
  /// In fr, this message translates to:
  /// **'Validation de la commande'**
  String get navCheckout;

  /// No description provided for @navOrderDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la commande'**
  String get navOrderDetails;

  /// No description provided for @navOnDutyPharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacies de Garde'**
  String get navOnDutyPharmacies;

  /// No description provided for @navPrescriptionUpload.
  ///
  /// In fr, this message translates to:
  /// **'Upload d\'ordonnance'**
  String get navPrescriptionUpload;

  /// No description provided for @navEditAddress.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get navEditAddress;

  /// No description provided for @navTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get navTerms;

  /// No description provided for @navPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get navPrivacy;

  /// No description provided for @navLegal.
  ///
  /// In fr, this message translates to:
  /// **'Mentions Légales'**
  String get navLegal;

  /// No description provided for @navError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get navError;

  /// No description provided for @navTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get navTheme;

  /// No description provided for @homeMedications.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get homeMedications;

  /// No description provided for @homeAllProducts.
  ///
  /// In fr, this message translates to:
  /// **'Tous les produits'**
  String get homeAllProducts;

  /// No description provided for @homeGuard.
  ///
  /// In fr, this message translates to:
  /// **'Garde'**
  String get homeGuard;

  /// No description provided for @homePharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacies'**
  String get homePharmacies;

  /// No description provided for @homePrescription.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance'**
  String get homePrescription;

  /// No description provided for @homeServices.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get homeServices;

  /// No description provided for @homeFeatured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get homeFeatured;

  /// No description provided for @homeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get homeSeeAll;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get homeGreeting;

  /// No description provided for @promoFreeDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison Gratuite'**
  String get promoFreeDelivery;

  /// No description provided for @promoFirstOrder.
  ///
  /// In fr, this message translates to:
  /// **'Sur votre première commande'**
  String get promoFirstOrder;

  /// No description provided for @promoVitamins.
  ///
  /// In fr, this message translates to:
  /// **'Vitamines & Compléments'**
  String get promoVitamins;

  /// No description provided for @promoService24.
  ///
  /// In fr, this message translates to:
  /// **'Service 24h/24'**
  String get promoService24;

  /// No description provided for @promoOnDutyPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie de garde'**
  String get promoOnDutyPharmacy;

  /// No description provided for @onboardingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur DR-PHARMA'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get onboardingPrevious;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @authLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLogin;

  /// No description provided for @authCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authCreateAccount;

  /// No description provided for @authForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPassword;

  /// No description provided for @authLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get authLogout;

  /// No description provided for @authRegistrationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Inscription réussie !'**
  String get authRegistrationSuccess;

  /// No description provided for @authPhoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get authPhoneNumber;

  /// No description provided for @authPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPassword;

  /// No description provided for @authFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get authFirstName;

  /// No description provided for @authLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get authLastName;

  /// No description provided for @authEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authRememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get authRememberMe;

  /// No description provided for @authNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get authHaveAccount;

  /// No description provided for @authOtpSent.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé'**
  String get authOtpSent;

  /// No description provided for @authOtpVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get authOtpVerify;

  /// No description provided for @authAcceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les conditions d\'utilisation'**
  String get authAcceptTerms;

  /// No description provided for @btnRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get btnRetry;

  /// No description provided for @btnCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get btnCancel;

  /// No description provided for @btnBackToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get btnBackToHome;

  /// No description provided for @btnValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get btnValidate;

  /// No description provided for @btnOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @btnNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get btnNo;

  /// No description provided for @btnDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get btnDelete;

  /// No description provided for @btnEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get btnEdit;

  /// No description provided for @btnQuit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get btnQuit;

  /// No description provided for @btnRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get btnRefresh;

  /// No description provided for @btnClearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get btnClearSearch;

  /// No description provided for @btnBrowseProducts.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir les produits'**
  String get btnBrowseProducts;

  /// No description provided for @btnTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get btnTakePhoto;

  /// No description provided for @btnChooseGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get btnChooseGallery;

  /// No description provided for @btnSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get btnSave;

  /// No description provided for @cartAddToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get cartAddToCart;

  /// No description provided for @cartViewProducts.
  ///
  /// In fr, this message translates to:
  /// **'Voir les produits'**
  String get cartViewProducts;

  /// No description provided for @cartPlaceOrder.
  ///
  /// In fr, this message translates to:
  /// **'Passer la commande'**
  String get cartPlaceOrder;

  /// No description provided for @cartClearCart.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get cartClearCart;

  /// No description provided for @cartClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get cartClear;

  /// No description provided for @cartConfirmOrder.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande - {total}'**
  String cartConfirmOrder(String total);

  /// No description provided for @cartViewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get cartViewDetails;

  /// No description provided for @cartMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get cartMyOrders;

  /// No description provided for @cartCheckPayment.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le paiement'**
  String get cartCheckPayment;

  /// No description provided for @cartSimulatePayment.
  ///
  /// In fr, this message translates to:
  /// **'Simuler le paiement'**
  String get cartSimulatePayment;

  /// No description provided for @cartSendReview.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get cartSendReview;

  /// No description provided for @prescriptionSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une ordonnance'**
  String get prescriptionSend;

  /// No description provided for @prescriptionSendForValidation.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer pour validation'**
  String get prescriptionSendForValidation;

  /// No description provided for @prescriptionAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get prescriptionAddPhoto;

  /// No description provided for @prescriptionAddPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une ordonnance'**
  String get prescriptionAddPrescription;

  /// No description provided for @prescriptionConfirmPay.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et Payer'**
  String get prescriptionConfirmPay;

  /// No description provided for @prescriptionPay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get prescriptionPay;

  /// No description provided for @prescriptionViewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir détails'**
  String get prescriptionViewDetails;

  /// No description provided for @prescriptionNoPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo ajoutée'**
  String get prescriptionNoPhotos;

  /// No description provided for @pharmacyCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get pharmacyCall;

  /// No description provided for @pharmacyRoute.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get pharmacyRoute;

  /// No description provided for @pharmacyDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get pharmacyDetails;

  /// No description provided for @pharmacyEnableLocation.
  ///
  /// In fr, this message translates to:
  /// **'Activer la localisation'**
  String get pharmacyEnableLocation;

  /// No description provided for @pharmacyUpdatePosition.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la position'**
  String get pharmacyUpdatePosition;

  /// No description provided for @addressDeliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get addressDeliveryAddress;

  /// No description provided for @addressSelectDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une adresse de livraison'**
  String get addressSelectDelivery;

  /// No description provided for @addressAddForOrders.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une adresse pour faciliter vos commandes'**
  String get addressAddForOrders;

  /// No description provided for @addressDeliveryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de livraison'**
  String get addressDeliveryCode;

  /// No description provided for @addressDeliveryCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Communiquez ce code au livreur\npour confirmer la réception'**
  String get addressDeliveryCodeHint;

  /// No description provided for @addressSetDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme adresse par défaut'**
  String get addressSetDefault;

  /// No description provided for @addressDeliveryInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Instructions de livraison'**
  String get addressDeliveryInstructions;

  /// No description provided for @addressLocating.
  ///
  /// In fr, this message translates to:
  /// **'Localisation en cours...'**
  String get addressLocating;

  /// No description provided for @addressSaved.
  ///
  /// In fr, this message translates to:
  /// **'Adresse enregistrée'**
  String get addressSaved;

  /// No description provided for @addressNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse'**
  String get addressNew;

  /// No description provided for @addressForNextOrders.
  ///
  /// In fr, this message translates to:
  /// **'Pour vos prochaines commandes'**
  String get addressForNextOrders;

  /// No description provided for @addressDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'adresse'**
  String get addressDelete;

  /// No description provided for @addressAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get addressAdd;

  /// No description provided for @addressNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse'**
  String get addressNewTitle;

  /// No description provided for @addressSetAsDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir par défaut'**
  String get addressSetAsDefault;

  /// No description provided for @orderStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get orderStatusPending;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusConfirmedPlural.
  ///
  /// In fr, this message translates to:
  /// **'Confirmées'**
  String get orderStatusConfirmedPlural;

  /// No description provided for @orderStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get orderStatusReady;

  /// No description provided for @orderStatusDelivering.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get orderStatusDelivering;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusDeliveredPlural.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get orderStatusDeliveredPlural;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusCancelledPlural.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get orderStatusCancelledPlural;

  /// No description provided for @orderStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get orderStatusFailed;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Commande récupérée'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusDeliveredCheck.
  ///
  /// In fr, this message translates to:
  /// **'Livré ✓'**
  String get orderStatusDeliveredCheck;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusPreparingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'En préparation...'**
  String get orderStatusPreparingEllipsis;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In fr, this message translates to:
  /// **'En traitement'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get orderStatusValidated;

  /// No description provided for @orderStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejetée'**
  String get orderStatusRejected;

  /// No description provided for @orderStatusCancelledOn.
  ///
  /// In fr, this message translates to:
  /// **'Annulée le'**
  String get orderStatusCancelledOn;

  /// No description provided for @orderStatusPendingFull.
  ///
  /// In fr, this message translates to:
  /// **'Commande en attente'**
  String get orderStatusPendingFull;

  /// No description provided for @paymentOnline.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne'**
  String get paymentOnline;

  /// No description provided for @paymentOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get paymentOnDelivery;

  /// No description provided for @paymentChooseMethod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le moyen de paiement'**
  String get paymentChooseMethod;

  /// No description provided for @paymentInitializing.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation du paiement...'**
  String get paymentInitializing;

  /// No description provided for @paymentProcessing.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours...'**
  String get paymentProcessing;

  /// No description provided for @paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi !'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement a été effectué avec succès'**
  String get paymentSuccessMessage;

  /// No description provided for @paymentWaitingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation du paiement...'**
  String get paymentWaitingConfirmation;

  /// No description provided for @paymentConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le paiement'**
  String get paymentConfirm;

  /// No description provided for @paymentMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement:'**
  String get paymentMode;

  /// No description provided for @paymentDeliveryFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get paymentDeliveryFees;

  /// No description provided for @paymentProcessingFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais de paiement'**
  String get paymentProcessingFees;

  /// No description provided for @paymentOnlineFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais de traitement du paiement en ligne'**
  String get paymentOnlineFees;

  /// No description provided for @paymentOrderSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de la commande'**
  String get paymentOrderSummary;

  /// No description provided for @paymentSubtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get paymentSubtotal;

  /// No description provided for @paymentTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get paymentTotal;

  /// No description provided for @paymentAutoConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement sera automatiquement confirmé'**
  String get paymentAutoConfirm;

  /// No description provided for @emptyNoProducts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit'**
  String get emptyNoProducts;

  /// No description provided for @emptyNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get emptyNoResults;

  /// No description provided for @emptyNoOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get emptyNoOrders;

  /// No description provided for @emptyCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier vide'**
  String get emptyCart;

  /// No description provided for @emptyNoNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get emptyNoNotifications;

  /// No description provided for @emptyNoProfile.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil disponible'**
  String get emptyNoProfile;

  /// No description provided for @emptyNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get emptyNoData;

  /// No description provided for @emptyNoDataShort.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get emptyNoDataShort;

  /// No description provided for @emptyNoPharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pharmacie disponible'**
  String get emptyNoPharmacies;

  /// No description provided for @emptyNoOnDutyPharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pharmacie de garde'**
  String get emptyNoOnDutyPharmacies;

  /// No description provided for @emptyImageNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Image non disponible'**
  String get emptyImageNotAvailable;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur s\'est produite'**
  String get errorGeneric;

  /// No description provided for @errorGenericRetry.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get errorGenericRetry;

  /// No description provided for @errorUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue s\'est produite'**
  String get errorUnexpected;

  /// No description provided for @errorNoInternet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion Internet'**
  String get errorNoInternet;

  /// No description provided for @errorNoInternetLower.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get errorNoInternetLower;

  /// No description provided for @errorCheckConnection.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion et réessayez.'**
  String get errorCheckConnection;

  /// No description provided for @errorConnection.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get errorConnection;

  /// No description provided for @errorTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai de connexion dépassé'**
  String get errorTimeout;

  /// No description provided for @errorServerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de se connecter au serveur'**
  String get errorServerUnreachable;

  /// No description provided for @errorSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Veuillez vous reconnecter'**
  String get errorSessionExpired;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Accès non autorisé'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ressource non trouvée'**
  String get errorNotFound;

  /// No description provided for @errorInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides'**
  String get errorInvalidData;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de requêtes. Veuillez patienter'**
  String get errorTooManyRequests;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur. Veuillez réessayer plus tard'**
  String get errorServer;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service temporairement indisponible'**
  String get errorServiceUnavailable;

  /// No description provided for @errorInvalidRequest.
  ///
  /// In fr, this message translates to:
  /// **'Requête invalide'**
  String get errorInvalidRequest;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Requête annulée'**
  String get errorRequestCancelled;

  /// No description provided for @errorInvalidCertificate.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de sécurité invalide'**
  String get errorInvalidCertificate;

  /// No description provided for @errorDataConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit de données'**
  String get errorDataConflict;

  /// No description provided for @errorRequestTimeout.
  ///
  /// In fr, this message translates to:
  /// **'La requête a pris trop de temps'**
  String get errorRequestTimeout;

  /// No description provided for @errorInvalidServerData.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides reçues du serveur'**
  String get errorInvalidServerData;

  /// No description provided for @errorValidation.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de validation'**
  String get errorValidation;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @errorUpdating.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get errorUpdating;

  /// No description provided for @errorDeleting.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression'**
  String get errorDeleting;

  /// No description provided for @errorLoadingPrescriptions.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des ordonnances'**
  String get errorLoadingPrescriptions;

  /// No description provided for @errorLoadingDetails.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des détails'**
  String get errorLoadingDetails;

  /// No description provided for @errorPayment.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du paiement'**
  String get errorPayment;

  /// No description provided for @errorCalculatingFees.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du calcul des frais'**
  String get errorCalculatingFees;

  /// No description provided for @errorConnectionCheck.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Vérifiez votre internet.'**
  String get errorConnectionCheck;

  /// No description provided for @errorNetworkCheck.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau. Vérifiez votre connexion.'**
  String get errorNetworkCheck;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get errorUnknown;

  /// No description provided for @errorPaymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a échoué. Veuillez réessayer.'**
  String get errorPaymentFailed;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Veuillez réessayer plus tard.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorSessionExpiredNewCode.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Veuillez demander un nouveau code.'**
  String get errorSessionExpiredNewCode;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get validationPasswordRequired;

  /// No description provided for @validationPassword6Chars.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get validationPassword6Chars;

  /// No description provided for @validationPassword8Chars.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères'**
  String get validationPassword8Chars;

  /// No description provided for @validationPasswordUppercase.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins une majuscule'**
  String get validationPasswordUppercase;

  /// No description provided for @validationPasswordLowercase.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins une minuscule'**
  String get validationPasswordLowercase;

  /// No description provided for @validationPasswordDigit.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins un chiffre'**
  String get validationPasswordDigit;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le mot de passe'**
  String get validationConfirmPassword;

  /// No description provided for @validationPleaseConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer le mot de passe'**
  String get validationPleaseConfirmPassword;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un email valide'**
  String get validationEmailInvalid;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro de téléphone valide'**
  String get validationPhoneInvalid;

  /// No description provided for @validationAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un montant valide'**
  String get validationAmountInvalid;

  /// No description provided for @validationNumberInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre valide'**
  String get validationNumberInvalid;

  /// No description provided for @validationNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get validationNameRequired;

  /// No description provided for @validationAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre adresse'**
  String get validationAddressRequired;

  /// No description provided for @validationCityRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer la ville'**
  String get validationCityRequired;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro'**
  String get validationPhoneRequired;

  /// No description provided for @validationCurrentPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe actuel'**
  String get validationCurrentPasswordRequired;

  /// No description provided for @validationNewPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nouveau mot de passe'**
  String get validationNewPasswordRequired;

  /// No description provided for @validationConfirmNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get validationConfirmNewPassword;

  /// No description provided for @validationSelectionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez faire une sélection'**
  String get validationSelectionRequired;

  /// No description provided for @validationAcceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les conditions d\'utilisation'**
  String get validationAcceptTerms;

  /// No description provided for @searchPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une pharmacie...'**
  String get searchPharmacy;

  /// No description provided for @searchMedications.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des médicaments...'**
  String get searchMedications;

  /// No description provided for @searchMedication.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un médicament...'**
  String get searchMedication;

  /// No description provided for @searchOnDutyPharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des pharmacies de garde...'**
  String get searchOnDutyPharmacies;

  /// No description provided for @searchLoadingPharmacies.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des pharmacies...'**
  String get searchLoadingPharmacies;

  /// No description provided for @pharmacyStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get pharmacyStatusOpen;

  /// No description provided for @pharmacyStatusOpenFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte'**
  String get pharmacyStatusOpenFeminine;

  /// No description provided for @pharmacyStatusOpenPlural.
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get pharmacyStatusOpenPlural;

  /// No description provided for @pharmacyStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get pharmacyStatusClosed;

  /// No description provided for @pharmacyStatusClosedFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get pharmacyStatusClosedFeminine;

  /// No description provided for @pharmacyStatusOnDuty.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie de garde'**
  String get pharmacyStatusOnDuty;

  /// No description provided for @pharmacyAddressUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Adresse non disponible'**
  String get pharmacyAddressUnavailable;

  /// No description provided for @ratingFast.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get ratingFast;

  /// No description provided for @ratingPolite.
  ///
  /// In fr, this message translates to:
  /// **'Poli'**
  String get ratingPolite;

  /// No description provided for @ratingProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel'**
  String get ratingProfessional;

  /// No description provided for @ratingPunctual.
  ///
  /// In fr, this message translates to:
  /// **'Ponctuel'**
  String get ratingPunctual;

  /// No description provided for @ratingLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get ratingLate;

  /// No description provided for @ratingRude.
  ///
  /// In fr, this message translates to:
  /// **'Impoli'**
  String get ratingRude;

  /// No description provided for @ratingDamaged.
  ///
  /// In fr, this message translates to:
  /// **'Colis abîmé'**
  String get ratingDamaged;

  /// No description provided for @ratingGoodPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Bon emballage'**
  String get ratingGoodPackaging;

  /// No description provided for @ratingCorrectProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits conformes'**
  String get ratingCorrectProducts;

  /// No description provided for @ratingFastService.
  ///
  /// In fr, this message translates to:
  /// **'Service rapide'**
  String get ratingFastService;

  /// No description provided for @ratingMissingProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit manquant'**
  String get ratingMissingProduct;

  /// No description provided for @ratingPoorPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Emballage insuffisant'**
  String get ratingPoorPackaging;

  /// No description provided for @ratingLongWait.
  ///
  /// In fr, this message translates to:
  /// **'Attente longue'**
  String get ratingLongWait;

  /// No description provided for @ratingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évaluez votre commande'**
  String get ratingTitle;

  /// No description provided for @ratingCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire (optionnel)...'**
  String get ratingCommentHint;

  /// No description provided for @ratingThankYou.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get ratingThankYou;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEdit;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer vos informations personnelles'**
  String get profileEditSubtitle;

  /// No description provided for @profileMyAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get profileMyAddresses;

  /// No description provided for @profileMyAddressesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer vos adresses de livraison'**
  String get profileMyAddressesSubtitle;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer vos préférences de notification'**
  String get profileNotificationsSubtitle;

  /// No description provided for @profileHelpSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et Support'**
  String get profileHelpSupport;

  /// No description provided for @profileLegal.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get profileLegal;

  /// No description provided for @profileLegalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation et confidentialité'**
  String get profileLegalSubtitle;

  /// No description provided for @profileOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get profileOrders;

  /// No description provided for @profileDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get profileDelivered;

  /// No description provided for @profileTotalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total Dépensé'**
  String get profileTotalSpent;

  /// No description provided for @profileMemberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get profileMemberSince;

  /// No description provided for @profileDefaultAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse par défaut'**
  String get profileDefaultAddress;

  /// No description provided for @profileAccountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get profileAccountInfo;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profilePersonalInfo;

  /// No description provided for @profileOrderUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour de commande'**
  String get profileOrderUpdates;

  /// No description provided for @profileDeliveryAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de livraison'**
  String get profileDeliveryAlerts;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeSystemDescription.
  ///
  /// In fr, this message translates to:
  /// **'Suit le thème de l\'appareil'**
  String get themeSystemDescription;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeLightDescription.
  ///
  /// In fr, this message translates to:
  /// **'Toujours utiliser le thème clair'**
  String get themeLightDescription;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeDarkDescription.
  ///
  /// In fr, this message translates to:
  /// **'Toujours utiliser le thème sombre'**
  String get themeDarkDescription;

  /// No description provided for @dialogQuitApp.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'application'**
  String get dialogQuitApp;

  /// No description provided for @dialogQuitAppMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment quitter DR-PHARMA ?'**
  String get dialogQuitAppMessage;

  /// No description provided for @dialogCancelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get dialogCancelOrder;

  /// No description provided for @dialogCancelOrderMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler cette commande ?'**
  String get dialogCancelOrderMessage;

  /// No description provided for @dialogClearCartMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer tous les articles du panier ?'**
  String get dialogClearCartMessage;

  /// No description provided for @dialogDeleteAvatarMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer votre photo de profil ?'**
  String get dialogDeleteAvatarMessage;

  /// No description provided for @dialogNotificationDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Notification supprimée'**
  String get dialogNotificationDeleted;

  /// No description provided for @loadingGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loadingGeneric;

  /// No description provided for @loadingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours'**
  String get loadingInProgress;

  /// No description provided for @loadingSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get loadingSending;

  /// No description provided for @loadingProcessing.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours...'**
  String get loadingProcessing;

  /// No description provided for @loadingOrderProcessing.
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours de traitement...'**
  String get loadingOrderProcessing;

  /// No description provided for @successPrescriptionSent.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance envoyée avec succès !'**
  String get successPrescriptionSent;

  /// No description provided for @successAddressUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Adresse mise à jour avec succès'**
  String get successAddressUpdated;

  /// No description provided for @successGpsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS mise à jour'**
  String get successGpsUpdated;

  /// No description provided for @successPasswordUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe a été mis à jour avec succès'**
  String get successPasswordUpdated;

  /// No description provided for @permissionLocationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation refusée'**
  String get permissionLocationDenied;

  /// No description provided for @permissionLocationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La localisation est désactivée. Activez-la dans les paramètres.'**
  String get permissionLocationDisabled;

  /// No description provided for @miscAvatarChangeSoon.
  ///
  /// In fr, this message translates to:
  /// **'Changement d\'avatar - Bientôt disponible'**
  String get miscAvatarChangeSoon;

  /// No description provided for @miscCannotOpenEmail.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application email'**
  String get miscCannotOpenEmail;

  /// No description provided for @miscSinglePharmacyOrder.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez commander que dans une seule pharmacie à la fois'**
  String get miscSinglePharmacyOrder;

  /// No description provided for @miscDeliveryContact.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je vous contacte concernant ma livraison.'**
  String get miscDeliveryContact;

  /// No description provided for @miscDeleteAvatar.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'avatar'**
  String get miscDeleteAvatar;

  /// No description provided for @miscTrackDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Suivre la livraison'**
  String get miscTrackDelivery;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
