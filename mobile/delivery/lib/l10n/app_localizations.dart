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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'DR-PHARMA Coursier'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ?'**
  String get noAccount;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// No description provided for @deliveries.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get deliveries;

  /// No description provided for @wallet.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille'**
  String get wallet;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @challenges.
  ///
  /// In fr, this message translates to:
  /// **'Défis'**
  String get challenges;

  /// No description provided for @online.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @goOnline.
  ///
  /// In fr, this message translates to:
  /// **'Passer en ligne'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In fr, this message translates to:
  /// **'Passer hors ligne'**
  String get goOffline;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @busy.
  ///
  /// In fr, this message translates to:
  /// **'Occupé'**
  String get busy;

  /// No description provided for @delivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get delivery;

  /// No description provided for @activeDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison en cours'**
  String get activeDelivery;

  /// No description provided for @noActiveDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison active'**
  String get noActiveDelivery;

  /// No description provided for @newDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle livraison'**
  String get newDelivery;

  /// No description provided for @acceptDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get acceptDelivery;

  /// No description provided for @rejectDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get rejectDelivery;

  /// No description provided for @startDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startDelivery;

  /// No description provided for @completeDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la livraison'**
  String get completeDelivery;

  /// No description provided for @deliveryCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Livraison terminée !'**
  String get deliveryCompleted;

  /// No description provided for @deliveryDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la livraison'**
  String get deliveryDetails;

  /// No description provided for @pickup.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get pickup;

  /// No description provided for @dropoff.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get dropoff;

  /// No description provided for @pickupAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de retrait'**
  String get pickupAddress;

  /// No description provided for @deliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get deliveryAddress;

  /// No description provided for @pharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get pharmacy;

  /// No description provided for @customer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get customer;

  /// No description provided for @orderNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° commande'**
  String get orderNumber;

  /// No description provided for @eta.
  ///
  /// In fr, this message translates to:
  /// **'Temps estimé'**
  String get eta;

  /// No description provided for @etaArrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée estimée'**
  String get etaArrival;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duration;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @km.
  ///
  /// In fr, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @navigate.
  ///
  /// In fr, this message translates to:
  /// **'Naviguer'**
  String get navigate;

  /// No description provided for @openInMaps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans Maps'**
  String get openInMaps;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @chat.
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @sendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tapez votre message...'**
  String get typeMessage;

  /// No description provided for @proofOfDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de livraison'**
  String get proofOfDelivery;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @signature.
  ///
  /// In fr, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @getSignature.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir la signature'**
  String get getSignature;

  /// No description provided for @clearSignature.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearSignature;

  /// No description provided for @confirmSignature.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmSignature;

  /// No description provided for @scanQRCode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le code QR'**
  String get scanQRCode;

  /// No description provided for @enterCodeManually.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code manuellement'**
  String get enterCodeManually;

  /// No description provided for @confirmationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de confirmation'**
  String get confirmationCode;

  /// No description provided for @walletBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get walletBalance;

  /// No description provided for @earnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains'**
  String get earnings;

  /// No description provided for @todayEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains du jour'**
  String get todayEarnings;

  /// No description provided for @weekEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains de la semaine'**
  String get weekEarnings;

  /// No description provided for @monthEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains du mois'**
  String get monthEarnings;

  /// No description provided for @totalEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains totaux'**
  String get totalEarnings;

  /// No description provided for @withdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get withdraw;

  /// No description provided for @withdrawFunds.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des fonds'**
  String get withdrawFunds;

  /// No description provided for @withdrawalRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demande de retrait'**
  String get withdrawalRequest;

  /// No description provided for @withdrawalHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des retraits'**
  String get withdrawalHistory;

  /// No description provided for @transactionHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des transactions'**
  String get transactionHistory;

  /// No description provided for @commission.
  ///
  /// In fr, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @bonus.
  ///
  /// In fr, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @penalty.
  ///
  /// In fr, this message translates to:
  /// **'Pénalité'**
  String get penalty;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @dateRange.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get dateRange;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get lastMonth;

  /// No description provided for @custom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get custom;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get accepted;

  /// No description provided for @pickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get pickedUp;

  /// No description provided for @inTransit.
  ///
  /// In fr, this message translates to:
  /// **'En transit'**
  String get inTransit;

  /// No description provided for @delivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get cancelled;

  /// No description provided for @failed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get failed;

  /// No description provided for @exportReport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le rapport'**
  String get exportReport;

  /// No description provided for @exportCSV.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get exportCSV;

  /// No description provided for @exportPDF.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get exportPDF;

  /// No description provided for @shareReport.
  ///
  /// In fr, this message translates to:
  /// **'Partager le rapport'**
  String get shareReport;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Activer les notifications'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver les notifications'**
  String get disableNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get pushNotifications;

  /// No description provided for @soundEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Son activé'**
  String get soundEnabled;

  /// No description provided for @vibrationEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Vibration activée'**
  String get vibrationEnabled;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get systemTheme;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @vehicleInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations véhicule'**
  String get vehicleInfo;

  /// No description provided for @vehicleType.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule'**
  String get vehicleType;

  /// No description provided for @motorcycle.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get motorcycle;

  /// No description provided for @car.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get car;

  /// No description provided for @bicycle.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get bicycle;

  /// No description provided for @licensePlate.
  ///
  /// In fr, this message translates to:
  /// **'Plaque d\'immatriculation'**
  String get licensePlate;

  /// No description provided for @documents.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @idCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte d\'identité'**
  String get idCard;

  /// No description provided for @drivingLicense.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get drivingLicense;

  /// No description provided for @vehicleRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Carte grise'**
  String get vehicleRegistration;

  /// No description provided for @insurance.
  ///
  /// In fr, this message translates to:
  /// **'Assurance'**
  String get insurance;

  /// No description provided for @uploadDocument.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger un document'**
  String get uploadDocument;

  /// No description provided for @support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get contactSupport;

  /// No description provided for @reportProblem.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get reportProblem;

  /// No description provided for @myTickets.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get myTickets;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'application'**
  String get appVersion;

  /// No description provided for @gamification.
  ///
  /// In fr, this message translates to:
  /// **'Gamification'**
  String get gamification;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In fr, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @xpPoints.
  ///
  /// In fr, this message translates to:
  /// **'Points XP'**
  String get xpPoints;

  /// No description provided for @badges.
  ///
  /// In fr, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @leaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboard;

  /// No description provided for @rank.
  ///
  /// In fr, this message translates to:
  /// **'Rang'**
  String get rank;

  /// No description provided for @weeklyRank.
  ///
  /// In fr, this message translates to:
  /// **'Classement hebdomadaire'**
  String get weeklyRank;

  /// No description provided for @monthlyRank.
  ///
  /// In fr, this message translates to:
  /// **'Classement mensuel'**
  String get monthlyRank;

  /// No description provided for @allTimeRank.
  ///
  /// In fr, this message translates to:
  /// **'Classement général'**
  String get allTimeRank;

  /// No description provided for @unlocked.
  ///
  /// In fr, this message translates to:
  /// **'Débloqué'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillé'**
  String get locked;

  /// No description provided for @progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progress;

  /// No description provided for @rewards.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get rewards;

  /// No description provided for @battery.
  ///
  /// In fr, this message translates to:
  /// **'Batterie'**
  String get battery;

  /// No description provided for @batterySaver.
  ///
  /// In fr, this message translates to:
  /// **'Économie de batterie'**
  String get batterySaver;

  /// No description provided for @batterySaverMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode économie de batterie'**
  String get batterySaverMode;

  /// No description provided for @batteryCritical.
  ///
  /// In fr, this message translates to:
  /// **'Batterie critique'**
  String get batteryCritical;

  /// No description provided for @batteryLow.
  ///
  /// In fr, this message translates to:
  /// **'Batterie faible'**
  String get batteryLow;

  /// No description provided for @batteryNormal.
  ///
  /// In fr, this message translates to:
  /// **'Batterie normale'**
  String get batteryNormal;

  /// No description provided for @charging.
  ///
  /// In fr, this message translates to:
  /// **'En charge'**
  String get charging;

  /// No description provided for @tutorial.
  ///
  /// In fr, this message translates to:
  /// **'Tutoriel'**
  String get tutorial;

  /// No description provided for @tutorials.
  ///
  /// In fr, this message translates to:
  /// **'Tutoriels'**
  String get tutorials;

  /// No description provided for @skipTutorial.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skipTutorial;

  /// No description provided for @nextStep.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get nextStep;

  /// No description provided for @previousStep.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previousStep;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @resetTutorials.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les tutoriels'**
  String get resetTutorials;

  /// No description provided for @liveTracking.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en direct'**
  String get liveTracking;

  /// No description provided for @shareLocation.
  ///
  /// In fr, this message translates to:
  /// **'Partager ma position'**
  String get shareLocation;

  /// No description provided for @stopSharing.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le partage'**
  String get stopSharing;

  /// No description provided for @trackingActive.
  ///
  /// In fr, this message translates to:
  /// **'Suivi actif'**
  String get trackingActive;

  /// No description provided for @trackingInactive.
  ///
  /// In fr, this message translates to:
  /// **'Suivi inactif'**
  String get trackingInactive;

  /// No description provided for @copyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié !'**
  String get linkCopied;

  /// No description provided for @shareWith.
  ///
  /// In fr, this message translates to:
  /// **'Partager avec...'**
  String get shareWith;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

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

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get submit;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau'**
  String get networkError;

  /// No description provided for @noInternet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get noInternet;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur'**
  String get serverError;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get sessionExpired;

  /// No description provided for @pleaseLogin.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous reconnecter'**
  String get pleaseLogin;

  /// No description provided for @somethingWentWrong.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get somethingWentWrong;

  /// No description provided for @offlineMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors-ligne'**
  String get offlineMode;

  /// No description provided for @offlineModeEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors-ligne activé'**
  String get offlineModeEnabled;

  /// No description provided for @backOnline.
  ///
  /// In fr, this message translates to:
  /// **'De retour en ligne'**
  String get backOnline;

  /// No description provided for @fcfa.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get fcfa;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie'**
  String get currency;

  /// No description provided for @locationPermission.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation'**
  String get locationPermission;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation requise'**
  String get locationPermissionRequired;

  /// No description provided for @enableLocation.
  ///
  /// In fr, this message translates to:
  /// **'Activer la localisation'**
  String get enableLocation;

  /// No description provided for @backgroundLocation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation en arrière-plan'**
  String get backgroundLocation;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @chooseSource.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une source'**
  String get chooseSource;

  /// Nombre de livraisons
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune livraison} =1{1 livraison} other{{count} livraisons}}'**
  String deliveriesCount(int count);

  /// Montant des gains
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA'**
  String earningsAmount(String amount);

  /// Message de salutation
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String greeting(String name);

  /// Message de passage de niveau
  ///
  /// In fr, this message translates to:
  /// **'Félicitations ! Vous êtes passé au niveau {level} !'**
  String levelUp(int level);

  /// Notification géofence pharmacie
  ///
  /// In fr, this message translates to:
  /// **'Vous approchez de la pharmacie {name}'**
  String approachingPharmacy(String name);

  /// Notification géofence client
  ///
  /// In fr, this message translates to:
  /// **'Vous approchez du client {name}'**
  String approachingClient(String name);

  /// Notification arrivée pharmacie
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé à la pharmacie !'**
  String get arrivedAtPharmacy;

  /// Notification arrivée client
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé chez le client !'**
  String get arrivedAtClient;

  /// Message TTS arrivée
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé à destination.'**
  String get arrivedAtDestination;

  /// Point de récupération
  ///
  /// In fr, this message translates to:
  /// **'Récupération'**
  String get pickupPoint;

  /// Point de livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get deliveryPoint;

  /// Indication pull-to-refresh
  ///
  /// In fr, this message translates to:
  /// **'Tirez vers le bas pour actualiser'**
  String get pullToRefresh;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune course trouvée'**
  String get noDeliveriesFound;

  /// Description paramètre géofence
  ///
  /// In fr, this message translates to:
  /// **'Notification automatique quand vous approchez de la pharmacie ou du client'**
  String get geofenceNotificationHint;

  /// Succès liveness
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité réussie !'**
  String get verificationSuccess;

  /// Échec liveness
  ///
  /// In fr, this message translates to:
  /// **'Vérification échouée: {error}'**
  String verificationFailed(String error);

  /// Succès capture selfie
  ///
  /// In fr, this message translates to:
  /// **'Selfie capturé avec succès'**
  String get selfieCaptured;

  /// Erreur taille image
  ///
  /// In fr, this message translates to:
  /// **'Image trop petite. Rapprochez-vous de la caméra.'**
  String get imageTooSmall;

  /// Succès inscription
  ///
  /// In fr, this message translates to:
  /// **'Inscription réussie !'**
  String get registrationSuccess;

  /// Info inscription
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a été soumise et est en cours de vérification.'**
  String get registrationPending;

  /// No description provided for @phoneNumberUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Numéro non disponible'**
  String get phoneNumberUnavailable;

  /// No description provided for @cannotLaunchNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer la navigation avec {app}'**
  String cannotLaunchNavigation(String app);

  /// No description provided for @cannotCall.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'appeler {phone}'**
  String cannotCall(String phone);

  /// No description provided for @quickMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message rapide'**
  String get quickMessage;

  /// No description provided for @enRouteToPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Je suis en route vers votre pharmacie'**
  String get enRouteToPharmacy;

  /// No description provided for @arrivedAtPharmacyMsg.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé devant la pharmacie'**
  String get arrivedAtPharmacyMsg;

  /// No description provided for @isOrderReady.
  ///
  /// In fr, this message translates to:
  /// **'La commande est-elle prête ?'**
  String get isOrderReady;

  /// No description provided for @cannotFindAddress.
  ///
  /// In fr, this message translates to:
  /// **'Je ne trouve pas l\'adresse'**
  String get cannotFindAddress;

  /// No description provided for @arrivingInFiveMin.
  ///
  /// In fr, this message translates to:
  /// **'J\'arrive dans 5 minutes'**
  String get arrivingInFiveMin;

  /// No description provided for @atYourBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Je suis en bas de votre immeuble'**
  String get atYourBuilding;

  /// No description provided for @pleaseComeDown.
  ///
  /// In fr, this message translates to:
  /// **'Pouvez-vous descendre svp ?'**
  String get pleaseComeDown;

  /// No description provided for @cannotFindYourAddress.
  ///
  /// In fr, this message translates to:
  /// **'Je ne trouve pas votre adresse'**
  String get cannotFindYourAddress;

  /// No description provided for @customerNotResponding.
  ///
  /// In fr, this message translates to:
  /// **'Le client ne répond pas'**
  String get customerNotResponding;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue Livreur'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez l\'équipe DR-PHARMA et livrez des médicaments essentiels. Chaque livraison compte !'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Gagnez plus'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos gains en temps réel, complétez des défis et montez en niveau pour débloquer des bonus.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In fr, this message translates to:
  /// **'Une commission est déduite de votre wallet à chaque livraison. Le reste est à vous ! Retirez vos gains à tout moment.'**
  String get onboardingDesc3;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @errorOccurredRetry.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get errorOccurredRetry;

  /// No description provided for @connectionTimeout.
  ///
  /// In fr, this message translates to:
  /// **'La connexion a pris trop de temps. Veuillez réessayer.'**
  String get connectionTimeout;

  /// No description provided for @connectionTimeoutCheck.
  ///
  /// In fr, this message translates to:
  /// **'La connexion a pris trop de temps. Vérifiez votre connexion.'**
  String get connectionTimeoutCheck;

  /// No description provided for @requestCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Requête annulée'**
  String get requestCancelled;

  /// No description provided for @securityError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de sécurité. Contactez le support.'**
  String get securityError;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue'**
  String get unexpectedError;

  /// No description provided for @slowConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion trop lente. Vérifiez votre connexion internet.'**
  String get slowConnection;

  /// No description provided for @slowUpload.
  ///
  /// In fr, this message translates to:
  /// **'Envoi des données trop lent. Réessayez.'**
  String get slowUpload;

  /// No description provided for @serverTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre.'**
  String get serverTimeout;

  /// No description provided for @cannotConnectServer.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de se connecter au serveur. Vérifiez votre connexion.'**
  String get cannotConnectServer;

  /// No description provided for @noInternetConnection.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get noInternetConnection;

  /// No description provided for @unknownConnectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion inconnue'**
  String get unknownConnectionError;

  /// No description provided for @serverCommunicationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de communication avec le serveur'**
  String get serverCommunicationError;

  /// No description provided for @invalidRequest.
  ///
  /// In fr, this message translates to:
  /// **'Requête invalide. Vérifiez les données saisies.'**
  String get invalidRequest;

  /// No description provided for @accessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé. Vous n\'avez pas les permissions nécessaires.'**
  String get accessDenied;

  /// No description provided for @resourceNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ressource introuvable.'**
  String get resourceNotFound;

  /// No description provided for @timeoutRetry.
  ///
  /// In fr, this message translates to:
  /// **'Délai d\'attente dépassé. Réessayez.'**
  String get timeoutRetry;

  /// No description provided for @dataConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit de données. L\'élément existe peut-être déjà.'**
  String get dataConflict;

  /// No description provided for @invalidData.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides. Vérifiez les informations saisies.'**
  String get invalidData;

  /// No description provided for @tooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de requêtes. Attendez un moment avant de réessayer.'**
  String get tooManyRequests;

  /// No description provided for @internalServerError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur interne du serveur. Réessayez plus tard.'**
  String get internalServerError;

  /// No description provided for @serviceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service temporairement indisponible.'**
  String get serviceUnavailable;

  /// No description provided for @estimatedDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée'**
  String get estimatedDuration;

  /// No description provided for @estimatedDurationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min estimées'**
  String estimatedDurationMinutes(int minutes);

  /// No description provided for @biometricAuthReason.
  ///
  /// In fr, this message translates to:
  /// **'Authentifiez-vous pour accéder à l\'application'**
  String get biometricAuthReason;

  /// No description provided for @loginWithCredentialsFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez d\'abord vous connecter avec vos identifiants'**
  String get loginWithCredentialsFirst;

  /// No description provided for @biometricError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur biométrique: {error}'**
  String biometricError(String error);

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @connectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre connexion internet.'**
  String get connectionFailed;

  /// No description provided for @incorrectCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects'**
  String get incorrectCredentials;

  /// No description provided for @checkEmailAndPassword.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email et mot de passe'**
  String get checkEmailAndPassword;

  /// No description provided for @resetPassword.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPassword;

  /// No description provided for @resetPasswordPhoneDesc.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre numéro de téléphone. Un code OTP vous sera envoyé par WhatsApp ou SMS.'**
  String get resetPasswordPhoneDesc;

  /// No description provided for @resetPasswordEmailDesc.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe.'**
  String get resetPasswordEmailDesc;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'+225 07 00 00 00 00'**
  String get phoneHint;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre@email.com'**
  String get emailHint;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get pleaseEnterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de réinitialisation a été envoyé à votre email.'**
  String get resetLinkSent;

  /// No description provided for @sendOtpCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code OTP'**
  String get sendOtpCode;

  /// No description provided for @sendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendLink;

  /// No description provided for @courierSpace.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE LIVREUR'**
  String get courierSpace;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour commencer vos livraisons'**
  String get loginSubtitle;

  /// No description provided for @emailOrPhone.
  ///
  /// In fr, this message translates to:
  /// **'Email ou Téléphone'**
  String get emailOrPhone;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get fieldRequired;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER LE CODE'**
  String get sendCode;

  /// No description provided for @signInButton.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get signInButton;

  /// No description provided for @or.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get or;

  /// No description provided for @biometricLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion biométrique'**
  String get biometricLogin;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get noAccountYet;

  /// No description provided for @becomeCourier.
  ///
  /// In fr, this message translates to:
  /// **'Devenir livreur'**
  String get becomeCourier;

  /// No description provided for @secure.
  ///
  /// In fr, this message translates to:
  /// **'Sécurisé'**
  String get secure;

  /// No description provided for @certified.
  ///
  /// In fr, this message translates to:
  /// **'Certifié'**
  String get certified;

  /// No description provided for @support247.
  ///
  /// In fr, this message translates to:
  /// **'Support 24/7'**
  String get support247;

  /// No description provided for @versionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);
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
