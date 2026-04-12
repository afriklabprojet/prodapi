/// Constantes d'accessibilité pour l'application DR-PHARMA
/// Labels sémantiques pour les lecteurs d'écran (VoiceOver/TalkBack)
class A11yLabels {
  A11yLabels._();

  // Navigation
  static const String homeTab = 'Onglet Accueil';
  static const String ordersTab = 'Onglet Mes commandes';
  static const String walletTab = 'Onglet Portefeuille';
  static const String profileTab = 'Onglet Mon profil';
  static const String backButton = 'Retour';
  static const String closeButton = 'Fermer';
  static const String menuButton = 'Menu';

  // Authentification
  static const String phoneInput = 'Champ numéro de téléphone';
  static const String passwordInput = 'Champ mot de passe';
  static const String emailInput = 'Champ adresse email';
  static const String otpInput = 'Champ code de vérification';
  static const String loginButton = 'Bouton connexion';
  static const String registerButton = 'Bouton inscription';
  static const String forgotPasswordButton = 'Mot de passe oublié';

  // Recherche
  static const String searchField = 'Champ de recherche';
  static const String searchButton = 'Lancer la recherche';
  static const String clearSearch = 'Effacer la recherche';

  // Produits
  static String productCard(String name) => 'Produit: $name';
  static String productPrice(String price) => 'Prix: $price francs CFA';
  static String addToCart(String product) => 'Ajouter $product au panier';
  static String removeFromCart(String product) => 'Retirer $product du panier';
  static const String favoriteButton = 'Ajouter aux favoris';
  static const String unfavoriteButton = 'Retirer des favoris';

  // Panier
  static const String cartBadge = 'Articles dans le panier';
  static String cartItem(String name, int quantity) =>
      '$name, quantité: $quantity';
  static const String increaseQuantity = 'Augmenter la quantité';
  static const String decreaseQuantity = 'Diminuer la quantité';
  static const String checkoutButton = 'Valider la commande';
  static String cartTotal(String total) => 'Total du panier: $total francs CFA';

  // Pharmacies
  static String pharmacyCard(String name) => 'Pharmacie: $name';
  static String pharmacyDistance(String distance) => 'Distance: $distance';
  static const String pharmacyOpen = 'Pharmacie ouverte';
  static const String pharmacyClosed = 'Pharmacie fermée';
  static const String onDutyPharmacy = 'Pharmacie de garde';
  static const String viewOnMap = 'Voir sur la carte';
  static const String callPharmacy = 'Appeler la pharmacie';

  // Commandes
  static String orderStatus(String status) => 'Statut de la commande: $status';
  static const String trackOrder = 'Suivre ma commande';
  static const String reorder = 'Commander à nouveau';
  static const String cancelOrder = 'Annuler la commande';
  static const String chatWithCourier = 'Discuter avec le livreur';

  // Ordonnances
  static const String uploadPrescription = 'Télécharger une ordonnance';
  static const String scanPrescription = 'Scanner une ordonnance';
  static const String takePrescriptionPhoto =
      'Prendre une photo de l\'ordonnance';
  static const String selectFromGallery = 'Sélectionner depuis la galerie';

  // Adresses
  static String addressCard(String label) => 'Adresse: $label';
  static const String addAddress = 'Ajouter une adresse';
  static const String editAddress = 'Modifier l\'adresse';
  static const String deleteAddress = 'Supprimer l\'adresse';
  static const String setDefaultAddress = 'Définir comme adresse par défaut';
  static const String currentLocationButton = 'Utiliser ma position actuelle';

  // Traitements
  static String treatmentCard(String name) => 'Traitement: $name';
  static const String addTreatment = 'Ajouter un traitement';
  static const String takeMedication = 'Marquer comme pris';
  static const String skipMedication = 'Passer cette prise';
  static String nextDose(String time) => 'Prochaine prise à $time';

  // Notifications
  static const String notificationBell = 'Notifications';
  static String unreadNotifications(int count) =>
      '$count notifications non lues';
  static const String markAllRead = 'Tout marquer comme lu';

  // Portefeuille
  static String walletBalance(String balance) => 'Solde: $balance francs CFA';
  static const String addFunds = 'Ajouter des fonds';
  static const String transactionHistory = 'Historique des transactions';

  // États
  static const String loading = 'Chargement en cours';
  static const String error = 'Une erreur s\'est produite';
  static const String retry = 'Réessayer';
  static const String empty = 'Aucun élément à afficher';
  static const String success = 'Opération réussie';

  // Formulaires
  static const String requiredField = 'Champ obligatoire';
  static const String invalidFormat = 'Format invalide';
  static const String submitButton = 'Valider';
  static const String cancelButton = 'Annuler';
  static const String saveButton = 'Enregistrer';

  // Images
  static String productImage(String name) => 'Image du produit $name';
  static String pharmacyImage(String name) => 'Photo de la pharmacie $name';
  static const String prescriptionImage = 'Image de l\'ordonnance';
  static const String userAvatar = 'Photo de profil';
}

/// Hints pour les actions (indications supplémentaires)
class A11yHints {
  A11yHints._();

  static const String doubleTapToActivate = 'Appuyez deux fois pour activer';
  static const String swipeToDelete = 'Glissez pour supprimer';
  static const String swipeForActions = 'Glissez pour voir les actions';
  static const String doubleTapAndHold =
      'Appuyez deux fois et maintenez pour les options';
  static const String pullToRefresh = 'Tirez vers le bas pour actualiser';
}

/// Rôles personnalisés pour améliorer la navigation
class A11yRoles {
  A11yRoles._();

  static const String header = 'en-tête';
  static const String button = 'bouton';
  static const String link = 'lien';
  static const String image = 'image';
  static const String slider = 'curseur';
  static const String checkbox = 'case à cocher';
  static const String radioButton = 'bouton radio';
  static const String textField = 'champ de texte';
  static const String alert = 'alerte';
  static const String dialog = 'dialogue';
}
