import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'DR-PHARMA Pharmacie'**
  String get appName;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Veuillez vous reconnecter.'**
  String get sessionExpired;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get genericError;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours'**
  String get loading;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @selectStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get selectEndDate;

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre pharmacie'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccountYet;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register;

  /// No description provided for @biometricLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à DR-PHARMA'**
  String get biometricLogin;

  /// No description provided for @noSavedAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte sauvegardé. Connectez-vous d\'abord avec email/mot de passe.'**
  String get noSavedAccount;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Trop court'**
  String get passwordTooShort;

  /// No description provided for @passwordWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get passwordWeak;

  /// No description provided for @passwordMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get passwordMedium;

  /// No description provided for @passwordStrong.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get passwordStrong;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins {minLength} caractères'**
  String passwordMinLength(int minLength);

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @ordersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Commandes'**
  String get ordersTitle;

  /// No description provided for @ordersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos commandes en temps réel'**
  String get ordersSubtitle;

  /// No description provided for @inventoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventoryTitle;

  /// No description provided for @walletTitle.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille'**
  String get walletTitle;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @orderReference.
  ///
  /// In fr, this message translates to:
  /// **'Commande #{reference}'**
  String orderReference(String reference);

  /// No description provided for @orderConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Commande confirmée !'**
  String get orderConfirmed;

  /// No description provided for @orderReady.
  ///
  /// In fr, this message translates to:
  /// **'Commande prête !'**
  String get orderReady;

  /// No description provided for @orderRejected.
  ///
  /// In fr, this message translates to:
  /// **'Commande refusée'**
  String get orderRejected;

  /// No description provided for @confirmOrder.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get confirmOrder;

  /// No description provided for @markAsReady.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme prête'**
  String get markAsReady;

  /// No description provided for @rejectOrder.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande'**
  String get rejectOrder;

  /// No description provided for @rejectOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande'**
  String get rejectOrderTitle;

  /// No description provided for @rejectionReasonOutOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Produit en rupture de stock'**
  String get rejectionReasonOutOfStock;

  /// No description provided for @rejectionReasonInvalidPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance invalide'**
  String get rejectionReasonInvalidPrescription;

  /// No description provided for @rejectionReasonPharmacyClosed.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie fermée'**
  String get rejectionReasonPharmacyClosed;

  /// No description provided for @rejectionReasonImpossibleDelay.
  ///
  /// In fr, this message translates to:
  /// **'Délai de préparation impossible'**
  String get rejectionReasonImpossibleDelay;

  /// No description provided for @rejectionReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get rejectionReasonOther;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get statusConfirmed;

  /// No description provided for @statusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get statusReady;

  /// No description provided for @statusInDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get statusInDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get statusRejected;

  /// No description provided for @statusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payé'**
  String get statusUnpaid;

  /// No description provided for @emptyOrdersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calme plat pour l\'instant'**
  String get emptyOrdersTitle;

  /// No description provided for @emptyOrdersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On te notifie dès qu\'un client passe commande'**
  String get emptyOrdersSubtitle;

  /// No description provided for @emptyPrescriptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'ordonnance en attente'**
  String get emptyPrescriptionsTitle;

  /// No description provided for @emptyPrescriptionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les nouvelles ordonnances apparaîtront ici'**
  String get emptyPrescriptionsSubtitle;

  /// No description provided for @emptyInventoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton inventaire est vide'**
  String get emptyInventoryTitle;

  /// No description provided for @emptyInventorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes premiers produits'**
  String get emptyInventorySubtitle;

  /// No description provided for @emptyNotificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est lu !'**
  String get emptyNotificationsTitle;

  /// No description provided for @emptyNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, tu es à jour'**
  String get emptyNotificationsSubtitle;

  /// No description provided for @emptyTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Travaille en équipe'**
  String get emptyTeamTitle;

  /// No description provided for @emptyTeamSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invite tes collègues'**
  String get emptyTeamSubtitle;

  /// No description provided for @emptyChatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message'**
  String get emptyChatTitle;

  /// No description provided for @emptyChatSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quand un client te contacte, la conversation apparaît ici'**
  String get emptyChatSubtitle;

  /// No description provided for @deliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get deliveryFee;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @paymentMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMode;

  /// No description provided for @customerNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes du client'**
  String get customerNotes;

  /// No description provided for @prescriptionComplete.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance complète !'**
  String get prescriptionComplete;

  /// No description provided for @partialDispensation.
  ///
  /// In fr, this message translates to:
  /// **'Dispensation partielle'**
  String get partialDispensation;

  /// No description provided for @selectAtLeastOneMedication.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins un médicament à délivrer'**
  String get selectAtLeastOneMedication;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAll;

  /// No description provided for @filterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get filterPending;

  /// No description provided for @filterConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmées'**
  String get filterConfirmed;

  /// No description provided for @filterReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêtes'**
  String get filterReady;

  /// No description provided for @filterInDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get filterInDelivery;

  /// No description provided for @filterDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get filterDelivered;

  /// No description provided for @filterCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get filterCancelled;

  /// No description provided for @kycStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get kycStatusApproved;

  /// No description provided for @kycStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get kycStatusPending;

  /// No description provided for @kycStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get kycStatusRejected;

  /// No description provided for @supportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aide & Support'**
  String get supportTitle;

  /// No description provided for @termsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyTitle;

  /// No description provided for @securitySettings.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securitySettings;

  /// No description provided for @appearanceSettings.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearanceSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationSettings;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currency;

  /// No description provided for @enterEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get enterEmail;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'email invalide'**
  String get invalidEmailFormat;

  /// No description provided for @enterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get enterPassword;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @passwordHidden.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe masqué'**
  String get passwordHidden;

  /// No description provided for @passwordVisible.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe visible'**
  String get passwordVisible;

  /// No description provided for @verification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification...'**
  String get verification;

  /// No description provided for @loginWithBiometric.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec {biometricType}'**
  String loginWithBiometric(String biometricType);

  /// No description provided for @myPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Ma Pharmacie'**
  String get myPharmacy;

  /// No description provided for @pharmacist.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacien'**
  String get pharmacist;

  /// No description provided for @balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get balance;

  /// No description provided for @totalEarned.
  ///
  /// In fr, this message translates to:
  /// **'Total gagné'**
  String get totalEarned;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'erreur'**
  String get error;

  /// No description provided for @actionsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Actions requises'**
  String get actionsRequired;

  /// No description provided for @pendingOrdersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} commande{count, plural, =1{} other{s}} en attente'**
  String pendingOrdersCount(int count);

  /// No description provided for @pendingPrescriptionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} ordonnance{count, plural, =1{} other{s}} en attente'**
  String pendingPrescriptionsCount(int count);

  /// No description provided for @quickView.
  ///
  /// In fr, this message translates to:
  /// **'Vue rapide'**
  String get quickView;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'cette semaine'**
  String get thisWeek;

  /// No description provided for @ordersThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'{count} commandes cette sem.'**
  String ordersThisWeek(int count);

  /// No description provided for @criticalProducts.
  ///
  /// In fr, this message translates to:
  /// **'{count} produit{count, plural, =1{} other{s}} critique{count, plural, =1{} other{s}}'**
  String criticalProducts(int count);

  /// No description provided for @expiringSoon.
  ///
  /// In fr, this message translates to:
  /// **'{count} expire{count, plural, =1{} other{nt}} bientôt'**
  String expiringSoon(int count);

  /// No description provided for @expiredProducts.
  ///
  /// In fr, this message translates to:
  /// **'{count} produit{count, plural, =1{} other{s}} expiré{count, plural, =1{} other{s}} !'**
  String expiredProducts(int count);

  /// No description provided for @peakDay.
  ///
  /// In fr, this message translates to:
  /// **'Pic: {day}'**
  String peakDay(String day);

  /// No description provided for @noRecentOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande récente'**
  String get noRecentOrders;

  /// No description provided for @noRecentPrescriptions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ordonnance récente'**
  String get noRecentPrescriptions;

  /// No description provided for @revenueToday.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires du jour'**
  String get revenueToday;

  /// No description provided for @finances.
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get finances;

  /// No description provided for @orders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// No description provided for @prescriptions.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnances'**
  String get prescriptions;

  /// No description provided for @statusPendingConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation'**
  String get statusPendingConfirmation;

  /// No description provided for @statusReadyForPickup.
  ///
  /// In fr, this message translates to:
  /// **'Prête pour ramassage'**
  String get statusReadyForPickup;

  /// No description provided for @statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours de livraison'**
  String get statusInProgress;

  /// No description provided for @confirmDispensation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la dispensation'**
  String get confirmDispensation;

  /// No description provided for @dispenseCount.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez délivrer {count} médicament(s). Confirmer ?'**
  String dispenseCount(int count);

  /// No description provided for @orderSentToSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée au fournisseur'**
  String get orderSentToSupplier;

  /// No description provided for @order.
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get order;

  /// No description provided for @pinChanged.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN modifié avec succès'**
  String get pinChanged;

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

  /// No description provided for @orderStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get orderStatusReady;

  /// No description provided for @orderStatusInDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get orderStatusInDelivery;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get orderStatusRejected;

  /// No description provided for @orderStatusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payé'**
  String get orderStatusUnpaid;

  /// No description provided for @orderFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get orderFilterAll;

  /// No description provided for @orderFilterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get orderFilterPending;

  /// No description provided for @orderFilterConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmées'**
  String get orderFilterConfirmed;

  /// No description provided for @orderFilterReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêtes'**
  String get orderFilterReady;

  /// No description provided for @orderFilterInDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get orderFilterInDelivery;

  /// No description provided for @orderFilterDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get orderFilterDelivered;

  /// No description provided for @orderFilterCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get orderFilterCancelled;

  /// No description provided for @connectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connectionTitle;

  /// No description provided for @accessPharmacySpace.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à votre espace pharmacie'**
  String get accessPharmacySpace;

  /// No description provided for @noAccountYetQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de compte ?'**
  String get noAccountYetQuestion;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @modificationsPending.
  ///
  /// In fr, this message translates to:
  /// **'{count} modification{count, plural, =1{} other{s}} en attente'**
  String modificationsPending(int count);

  /// No description provided for @offlineModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors-ligne'**
  String get offlineModeLabel;

  /// No description provided for @syncJustNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchro: à l\'instant'**
  String get syncJustNow;

  /// No description provided for @syncMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Synchro: il y a {minutes} min'**
  String syncMinutesAgo(int minutes);

  /// No description provided for @syncHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Synchro: il y a {hours}h'**
  String syncHoursAgo(int hours);

  /// No description provided for @syncDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Synchro: il y a {days} jour{days, plural, =1{} other{s}}'**
  String syncDaysAgo(int days);

  /// No description provided for @syncPending.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en attente'**
  String get syncPending;

  /// No description provided for @reportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapports & Analytics'**
  String get reportsTitle;

  /// No description provided for @exportButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get exportButton;

  /// No description provided for @refreshButton.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshButton;

  /// No description provided for @overviewTab.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get overviewTab;

  /// No description provided for @salesTab.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get salesTab;

  /// No description provided for @ordersTab.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get ordersTab;

  /// No description provided for @inventoryTab.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventoryTab;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @actionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Action requise'**
  String get actionRequired;

  /// No description provided for @noOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get noOrders;

  /// No description provided for @delivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get delivered;

  /// No description provided for @pendingLabel.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get cancelledLabel;

  /// No description provided for @topProducts.
  ///
  /// In fr, this message translates to:
  /// **'Top 5 Produits'**
  String get topProducts;

  /// No description provided for @noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noDataAvailable;

  /// No description provided for @salesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} ventes'**
  String salesCount(int count);

  /// No description provided for @periodToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get periodToday;

  /// No description provided for @periodThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get periodThisMonth;

  /// No description provided for @periodThisQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Ce trimestre'**
  String get periodThisQuarter;

  /// No description provided for @periodThisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get periodThisYear;

  /// No description provided for @revenueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get revenueLabel;

  /// No description provided for @ordersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get ordersLabel;

  /// No description provided for @productsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get productsLabel;

  /// No description provided for @inStockSuffix.
  ///
  /// In fr, this message translates to:
  /// **'en stock'**
  String get inStockSuffix;

  /// No description provided for @alertsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alertsLabel;

  /// No description provided for @activeSuffix.
  ///
  /// In fr, this message translates to:
  /// **'actives'**
  String get activeSuffix;

  /// No description provided for @salesTrend.
  ///
  /// In fr, this message translates to:
  /// **'Évolution des ventes'**
  String get salesTrend;

  /// No description provided for @orderStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut des commandes'**
  String get orderStatus;

  /// No description provided for @exportInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Export en cours...'**
  String get exportInProgress;

  /// No description provided for @expiryAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes d\'expiration'**
  String get expiryAlerts;

  /// No description provided for @expiredBatches.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 lot expiré} other{{count} lots expirés}}'**
  String expiredBatches(int count);

  /// No description provided for @criticalBatches.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 lot critique (≤7j)} other{{count} lots critiques (≤7j)}}'**
  String criticalBatches(int count);

  /// No description provided for @warningBatches.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 lot à surveiller (≤30j)} other{{count} lots à surveiller (≤30j)}}'**
  String warningBatches(int count);

  /// No description provided for @batchNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° de lot'**
  String get batchNumber;

  /// No description provided for @lotNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° de lot interne'**
  String get lotNumber;

  /// No description provided for @expiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get expiryDate;

  /// No description provided for @batchQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité du lot'**
  String get batchQuantity;

  /// No description provided for @addBatch.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un lot'**
  String get addBatch;

  /// No description provided for @supplierLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get supplierLabel;
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
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
