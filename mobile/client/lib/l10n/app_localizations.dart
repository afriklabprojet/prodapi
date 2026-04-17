import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Classe de localisation générée pour DR-PHARMA
/// Supporte français (par défaut) et anglais
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // ============================================================
  // Strings communes
  // ============================================================
  String get appName => 'DR-PHARMA';
  String get ok => locale.languageCode == 'fr' ? 'OK' : 'OK';
  String get cancel => locale.languageCode == 'fr' ? 'Annuler' : 'Cancel';
  String get confirm => locale.languageCode == 'fr' ? 'Confirmer' : 'Confirm';
  String get retry => locale.languageCode == 'fr' ? 'Réessayer' : 'Retry';
  String get save => locale.languageCode == 'fr' ? 'Enregistrer' : 'Save';
  String get delete => locale.languageCode == 'fr' ? 'Supprimer' : 'Delete';
  String get loading =>
      locale.languageCode == 'fr' ? 'Chargement...' : 'Loading...';
  String get error => locale.languageCode == 'fr' ? 'Erreur' : 'Error';
  String get success => locale.languageCode == 'fr' ? 'Succès' : 'Success';

  // ============================================================
  // Auth
  // ============================================================
  String get login => locale.languageCode == 'fr' ? 'Connexion' : 'Login';
  String get logout => locale.languageCode == 'fr' ? 'Déconnexion' : 'Logout';
  String get register =>
      locale.languageCode == 'fr' ? 'Créer un compte' : 'Register';
  String get email => locale.languageCode == 'fr' ? 'E-mail' : 'Email';
  String get password =>
      locale.languageCode == 'fr' ? 'Mot de passe' : 'Password';
  String get phone => locale.languageCode == 'fr' ? 'Téléphone' : 'Phone';
  String get firstName => locale.languageCode == 'fr' ? 'Prénom' : 'First name';
  String get lastName => locale.languageCode == 'fr' ? 'Nom' : 'Last name';

  // ============================================================
  // Navigation
  // ============================================================
  String get home => locale.languageCode == 'fr' ? 'Accueil' : 'Home';
  String get orders => locale.languageCode == 'fr' ? 'Commandes' : 'Orders';
  String get pharmacies =>
      locale.languageCode == 'fr' ? 'Pharmacies' : 'Pharmacies';
  String get profile => locale.languageCode == 'fr' ? 'Profil' : 'Profile';
  String get cart => locale.languageCode == 'fr' ? 'Panier' : 'Cart';

  // ============================================================
  // Products
  // ============================================================
  String get products =>
      locale.languageCode == 'fr' ? 'Médicaments' : 'Medications';
  String get searchProducts => locale.languageCode == 'fr'
      ? 'Rechercher un médicament'
      : 'Search medication';
  String get addToCart =>
      locale.languageCode == 'fr' ? 'Ajouter au panier' : 'Add to cart';
  String get outOfStock =>
      locale.languageCode == 'fr' ? 'Rupture de stock' : 'Out of stock';
  String get requiresPrescription => locale.languageCode == 'fr'
      ? 'Ordonnance requise'
      : 'Prescription required';

  // ============================================================
  // Panier et Commandes
  // ============================================================
  String get emptyCart => locale.languageCode == 'fr'
      ? 'Votre panier est vide'
      : 'Your cart is empty';
  String get checkout => locale.languageCode == 'fr' ? 'Commander' : 'Checkout';
  String get subtotal =>
      locale.languageCode == 'fr' ? 'Sous-total' : 'Subtotal';
  String get deliveryFee =>
      locale.languageCode == 'fr' ? 'Frais de livraison' : 'Delivery fee';
  String get total => locale.languageCode == 'fr' ? 'Total' : 'Total';
  String get freeDelivery =>
      locale.languageCode == 'fr' ? 'Livraison gratuite' : 'Free delivery';
  String get quantity => locale.languageCode == 'fr' ? 'Quantité' : 'Quantity';
  String get orderPlaced =>
      locale.languageCode == 'fr' ? 'Commande passée' : 'Order placed';
  String get orderConfirmed =>
      locale.languageCode == 'fr' ? 'Commande confirmée' : 'Order confirmed';
  String get orderPreparing =>
      locale.languageCode == 'fr' ? 'En préparation' : 'Preparing';
  String get orderReady => locale.languageCode == 'fr'
      ? 'Prête pour livraison'
      : 'Ready for delivery';
  String get orderDelivering =>
      locale.languageCode == 'fr' ? 'En cours de livraison' : 'Delivering';
  String get orderDelivered =>
      locale.languageCode == 'fr' ? 'Livrée' : 'Delivered';
  String get orderCancelled =>
      locale.languageCode == 'fr' ? 'Annulée' : 'Cancelled';
  String get trackOrder =>
      locale.languageCode == 'fr' ? 'Suivre ma commande' : 'Track my order';
  String get reorder =>
      locale.languageCode == 'fr' ? 'Commander à nouveau' : 'Reorder';

  // ============================================================
  // Ordonnances
  // ============================================================
  String get prescriptions =>
      locale.languageCode == 'fr' ? 'Ordonnances' : 'Prescriptions';
  String get uploadPrescription => locale.languageCode == 'fr'
      ? 'Télécharger une ordonnance'
      : 'Upload prescription';
  String get scanPrescription => locale.languageCode == 'fr'
      ? 'Scanner une ordonnance'
      : 'Scan prescription';
  String get prescriptionHistory => locale.languageCode == 'fr'
      ? 'Historique des ordonnances'
      : 'Prescription history';
  String get prescriptionPending => locale.languageCode == 'fr'
      ? 'En attente de validation'
      : 'Pending validation';
  String get prescriptionValidated =>
      locale.languageCode == 'fr' ? 'Validée' : 'Validated';
  String get prescriptionRejected =>
      locale.languageCode == 'fr' ? 'Rejetée' : 'Rejected';
  String get renewPrescription => locale.languageCode == 'fr'
      ? 'Renouveler l\'ordonnance'
      : 'Renew prescription';

  // ============================================================
  // Adresses
  // ============================================================
  String get addresses =>
      locale.languageCode == 'fr' ? 'Adresses' : 'Addresses';
  String get addAddress =>
      locale.languageCode == 'fr' ? 'Ajouter une adresse' : 'Add address';
  String get editAddress =>
      locale.languageCode == 'fr' ? 'Modifier l\'adresse' : 'Edit address';
  String get deleteAddress =>
      locale.languageCode == 'fr' ? 'Supprimer l\'adresse' : 'Delete address';
  String get defaultAddress =>
      locale.languageCode == 'fr' ? 'Adresse par défaut' : 'Default address';
  String get setAsDefault =>
      locale.languageCode == 'fr' ? 'Définir par défaut' : 'Set as default';
  String get street => locale.languageCode == 'fr' ? 'Rue' : 'Street';
  String get city => locale.languageCode == 'fr' ? 'Ville' : 'City';
  String get commune => locale.languageCode == 'fr' ? 'Commune' : 'District';
  String get landmark =>
      locale.languageCode == 'fr' ? 'Point de repère' : 'Landmark';
  String get deliveryInstructions => locale.languageCode == 'fr'
      ? 'Instructions de livraison'
      : 'Delivery instructions';

  // ============================================================
  // Paiement
  // ============================================================
  String get payment => locale.languageCode == 'fr' ? 'Paiement' : 'Payment';
  String get paymentMethod =>
      locale.languageCode == 'fr' ? 'Mode de paiement' : 'Payment method';
  String get cash => locale.languageCode == 'fr'
      ? 'Espèces à la livraison'
      : 'Cash on delivery';
  String get mobileMoney =>
      locale.languageCode == 'fr' ? 'Mobile Money' : 'Mobile Money';
  String get orangeMoney =>
      locale.languageCode == 'fr' ? 'Orange Money' : 'Orange Money';
  String get mtnMoney =>
      locale.languageCode == 'fr' ? 'MTN Money' : 'MTN Money';
  String get moovMoney =>
      locale.languageCode == 'fr' ? 'Moov Money' : 'Moov Money';
  String get wave => locale.languageCode == 'fr' ? 'Wave' : 'Wave';
  String get paymentSuccessful =>
      locale.languageCode == 'fr' ? 'Paiement réussi' : 'Payment successful';
  String get paymentFailed =>
      locale.languageCode == 'fr' ? 'Paiement échoué' : 'Payment failed';
  String get payNow =>
      locale.languageCode == 'fr' ? 'Payer maintenant' : 'Pay now';

  // ============================================================
  // Profil
  // ============================================================
  String get editProfile =>
      locale.languageCode == 'fr' ? 'Modifier le profil' : 'Edit profile';
  String get personalInfo => locale.languageCode == 'fr'
      ? 'Informations personnelles'
      : 'Personal information';
  String get settings =>
      locale.languageCode == 'fr' ? 'Paramètres' : 'Settings';
  String get notifications =>
      locale.languageCode == 'fr' ? 'Notifications' : 'Notifications';
  String get language => locale.languageCode == 'fr' ? 'Langue' : 'Language';
  String get darkMode =>
      locale.languageCode == 'fr' ? 'Mode sombre' : 'Dark mode';
  String get helpSupport =>
      locale.languageCode == 'fr' ? 'Aide et support' : 'Help & support';
  String get aboutUs => locale.languageCode == 'fr' ? 'À propos' : 'About us';
  String get termsConditions => locale.languageCode == 'fr'
      ? 'Conditions générales'
      : 'Terms & conditions';
  String get privacyPolicy => locale.languageCode == 'fr'
      ? 'Politique de confidentialité'
      : 'Privacy policy';
  String get logoutConfirm => locale.languageCode == 'fr'
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to logout?';

  // ============================================================
  // Pharmacies
  // ============================================================
  String get nearbyPharmacies => locale.languageCode == 'fr'
      ? 'Pharmacies à proximité'
      : 'Nearby pharmacies';
  String get openNow => locale.languageCode == 'fr' ? 'Ouvert' : 'Open now';
  String get closed => locale.languageCode == 'fr' ? 'Fermé' : 'Closed';
  String get open24h =>
      locale.languageCode == 'fr' ? 'Ouvert 24h/24' : 'Open 24 hours';
  String get pharmacyDetails => locale.languageCode == 'fr'
      ? 'Détails de la pharmacie'
      : 'Pharmacy details';
  String get viewProducts =>
      locale.languageCode == 'fr' ? 'Voir les produits' : 'View products';
  String get distance => locale.languageCode == 'fr' ? 'Distance' : 'Distance';
  String get estimatedTime =>
      locale.languageCode == 'fr' ? 'Temps estimé' : 'Estimated time';
  String get callPharmacy =>
      locale.languageCode == 'fr' ? 'Appeler la pharmacie' : 'Call pharmacy';
  String get getDirections =>
      locale.languageCode == 'fr' ? 'Itinéraire' : 'Get directions';

  // ============================================================
  // Recherche
  // ============================================================
  String get search => locale.languageCode == 'fr' ? 'Rechercher' : 'Search';
  String get searchHint => locale.languageCode == 'fr'
      ? 'Que recherchez-vous ?'
      : 'What are you looking for?';
  String get recentSearches =>
      locale.languageCode == 'fr' ? 'Recherches récentes' : 'Recent searches';
  String get clearHistory =>
      locale.languageCode == 'fr' ? 'Effacer l\'historique' : 'Clear history';
  String get noResults =>
      locale.languageCode == 'fr' ? 'Aucun résultat' : 'No results';
  String get tryDifferentSearch => locale.languageCode == 'fr'
      ? 'Essayez une recherche différente'
      : 'Try a different search';

  // ============================================================
  // Erreurs et validations
  // ============================================================
  String get fieldRequired => locale.languageCode == 'fr'
      ? 'Ce champ est requis'
      : 'This field is required';
  String get invalidPhone => locale.languageCode == 'fr'
      ? 'Numéro de téléphone invalide'
      : 'Invalid phone number';
  String get invalidEmail => locale.languageCode == 'fr'
      ? 'Adresse email invalide'
      : 'Invalid email address';
  String get networkError =>
      locale.languageCode == 'fr' ? 'Erreur de connexion' : 'Connection error';
  String get serverError =>
      locale.languageCode == 'fr' ? 'Erreur serveur' : 'Server error';
  String get sessionExpired =>
      locale.languageCode == 'fr' ? 'Session expirée' : 'Session expired';
  String get tryAgain =>
      locale.languageCode == 'fr' ? 'Veuillez réessayer' : 'Please try again';
  String get somethingWentWrong => locale.languageCode == 'fr'
      ? 'Une erreur est survenue'
      : 'Something went wrong';

  // ============================================================
  // Onboarding
  // ============================================================
  String get skip => locale.languageCode == 'fr' ? 'Passer' : 'Skip';
  String get next => locale.languageCode == 'fr' ? 'Suivant' : 'Next';
  String get getStarted =>
      locale.languageCode == 'fr' ? 'Commencer' : 'Get started';
  String get welcomeTitle => locale.languageCode == 'fr'
      ? 'Bienvenue sur DR-PHARMA'
      : 'Welcome to DR-PHARMA';
  String get welcomeSubtitle => locale.languageCode == 'fr'
      ? 'Vos médicaments livrés à domicile'
      : 'Your medications delivered to your door';

  // ============================================================
  // Livraison
  // ============================================================
  String get delivery => locale.languageCode == 'fr' ? 'Livraison' : 'Delivery';
  String get deliveryAddress =>
      locale.languageCode == 'fr' ? 'Adresse de livraison' : 'Delivery address';
  String get deliveryTime =>
      locale.languageCode == 'fr' ? 'Heure de livraison' : 'Delivery time';
  String get standardDelivery =>
      locale.languageCode == 'fr' ? 'Livraison standard' : 'Standard delivery';
  String get expressDelivery =>
      locale.languageCode == 'fr' ? 'Livraison express' : 'Express delivery';
  String get courierOnTheWay => locale.languageCode == 'fr'
      ? 'Le livreur est en route'
      : 'Courier is on the way';
  String get courierArrived => locale.languageCode == 'fr'
      ? 'Le livreur est arrivé'
      : 'Courier has arrived';
  String get deliveryCompleted => locale.languageCode == 'fr'
      ? 'Livraison effectuée'
      : 'Delivery completed';
  String get contactCourier =>
      locale.languageCode == 'fr' ? 'Contacter le livreur' : 'Contact courier';

  // ============================================================
  // KYC et vérification
  // ============================================================
  String get verifyIdentity => locale.languageCode == 'fr'
      ? 'Vérifier mon identité'
      : 'Verify my identity';
  String get kycPending => locale.languageCode == 'fr'
      ? 'Vérification en cours'
      : 'Verification pending';
  String get kycApproved =>
      locale.languageCode == 'fr' ? 'Identité vérifiée' : 'Identity verified';
  String get kycRejected => locale.languageCode == 'fr'
      ? 'Vérification rejetée'
      : 'Verification rejected';
  String get uploadIdCard => locale.languageCode == 'fr'
      ? 'Télécharger la carte d\'identité'
      : 'Upload ID card';
  String get takeSelfie =>
      locale.languageCode == 'fr' ? 'Prendre un selfie' : 'Take a selfie';

  // ============================================================
  // Favoris
  // ============================================================
  String get favorites => locale.languageCode == 'fr' ? 'Favoris' : 'Favorites';
  String get addToFavorites =>
      locale.languageCode == 'fr' ? 'Ajouter aux favoris' : 'Add to favorites';
  String get removeFromFavorites => locale.languageCode == 'fr'
      ? 'Retirer des favoris'
      : 'Remove from favorites';
  String get noFavorites =>
      locale.languageCode == 'fr' ? 'Aucun favori' : 'No favorites';

  // ============================================================
  // Temps et dates
  // ============================================================
  String get today => locale.languageCode == 'fr' ? 'Aujourd\'hui' : 'Today';
  String get yesterday => locale.languageCode == 'fr' ? 'Hier' : 'Yesterday';
  String get tomorrow => locale.languageCode == 'fr' ? 'Demain' : 'Tomorrow';
  String get minutes => locale.languageCode == 'fr' ? 'min' : 'min';
  String get hours => locale.languageCode == 'fr' ? 'h' : 'h';

  // ============================================================
  // Méthodes avec paramètres
  // ============================================================
  String itemsInCart(int count) => locale.languageCode == 'fr'
      ? '$count article${count > 1 ? 's' : ''} dans le panier'
      : '$count item${count > 1 ? 's' : ''} in cart';

  String orderNumber(String id) =>
      locale.languageCode == 'fr' ? 'Commande n°$id' : 'Order #$id';

  String distanceAway(String distance) =>
      locale.languageCode == 'fr' ? 'À $distance' : '$distance away';

  String estimatedDelivery(String time) => locale.languageCode == 'fr'
      ? 'Livraison estimée: $time'
      : 'Estimated delivery: $time';

  String priceFormat(int amount) => '$amount FCFA';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
