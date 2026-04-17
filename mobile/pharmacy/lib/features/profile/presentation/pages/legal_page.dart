import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  final String type; // 'terms' or 'privacy'

  const LegalPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == 'terms';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Conditions d\'utilisation' : 'Politique de confidentialité'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isTerms ? _buildTermsContent(context) : _buildPrivacyContent(context),
        ),
      ),
    );
  }

  List<Widget> _buildTermsContent(BuildContext context) {
    return [
      _buildLastUpdated('27 janvier 2026'),
      const SizedBox(height: 24),
      
      _buildSectionTitle('1. Acceptation des conditions'),
      _buildParagraph(
        'En utilisant l\'application DR-PHARMA, vous acceptez d\'être lié par les présentes conditions d\'utilisation. '
        'Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
      ),
      
      _buildSectionTitle('2. Description du service'),
      _buildParagraph(
        'DR-PHARMA est une plateforme de gestion pharmaceutique permettant aux pharmacies de :\n'
        '• Gérer leur inventaire de produits\n'
        '• Recevoir et traiter les commandes clients\n'
        '• Gérer les ordonnances\n'
        '• Suivre leurs performances commerciales\n'
        '• Communiquer avec leurs clients',
      ),
      
      _buildSectionTitle('3. Inscription et compte'),
      _buildParagraph(
        'Pour utiliser DR-PHARMA, vous devez créer un compte professionnel. Vous êtes responsable de :\n'
        '• La véracité des informations fournies\n'
        '• La confidentialité de vos identifiants\n'
        '• Toute activité réalisée depuis votre compte',
      ),
      
      _buildSectionTitle('4. Obligations de l\'utilisateur'),
      _buildParagraph(
        'En tant qu\'utilisateur, vous vous engagez à :\n'
        '• Respecter la réglementation pharmaceutique en vigueur\n'
        '• Fournir des informations exactes sur vos produits\n'
        '• Traiter les commandes dans les délais raisonnables\n'
        '• Respecter la confidentialité des données clients',
      ),
      
      _buildSectionTitle('5. Propriété intellectuelle'),
      _buildParagraph(
        'Tous les éléments de l\'application (logos, textes, images, code) sont protégés par le droit de la propriété intellectuelle. '
        'Toute reproduction non autorisée est strictement interdite.',
      ),
      
      _buildSectionTitle('6. Limitation de responsabilité'),
      _buildParagraph(
        'DR-PHARMA ne peut être tenu responsable des :\n'
        '• Erreurs dans les informations produits saisies par les pharmacies\n'
        '• Problèmes de livraison entre pharmacies et clients\n'
        '• Pertes de données dues à des facteurs externes',
      ),
      
      _buildSectionTitle('7. Modification des conditions'),
      _buildParagraph(
        'Nous nous réservons le droit de modifier ces conditions à tout moment. '
        'Les utilisateurs seront informés des modifications importantes par notification.',
      ),
      
      _buildSectionTitle('8. Contact'),
      _buildParagraph(
        'Pour toute question concernant ces conditions :\n'
        'Email : legal@drlpharma.com\n'
        'Adresse : COCODY ANGRE terminus 81/82, en face de la banque UBA – Abidjan, Côte d\'Ivoire',
      ),
    ];
  }

  List<Widget> _buildPrivacyContent(BuildContext context) {
    return [
      _buildLastUpdated('27 janvier 2026'),
      const SizedBox(height: 24),
      
      _buildSectionTitle('1. Introduction'),
      _buildParagraph(
        'Chez DR-PHARMA, nous accordons une grande importance à la protection de vos données personnelles. '
        'Cette politique explique comment nous collectons, utilisons et protégeons vos informations.',
      ),
      
      _buildSectionTitle('2. Données collectées'),
      _buildParagraph(
        'Nous collectons les données suivantes :\n'
        '• Informations d\'identification (nom, email, téléphone)\n'
        '• Informations de la pharmacie (nom, adresse, numéro d\'agrément)\n'
        '• Données de transaction (commandes, ventes)\n'
        '• Données techniques (type d\'appareil, adresse IP)',
      ),
      
      _buildSectionTitle('3. Utilisation des données'),
      _buildParagraph(
        'Vos données sont utilisées pour :\n'
        '• Fournir et améliorer nos services\n'
        '• Traiter vos commandes\n'
        '• Vous envoyer des notifications importantes\n'
        '• Générer des rapports et statistiques\n'
        '• Assurer la sécurité de la plateforme',
      ),
      
      _buildSectionTitle('4. Partage des données'),
      _buildParagraph(
        'Nous ne vendons pas vos données. Elles peuvent être partagées avec :\n'
        '• Les clients (informations de la pharmacie uniquement)\n'
        '• Les prestataires de paiement (données de transaction)\n'
        '• Les autorités (si requis par la loi)',
      ),
      
      _buildSectionTitle('5. Sécurité'),
      _buildParagraph(
        'Nous mettons en œuvre des mesures de sécurité avancées :\n'
        '• Chiffrement des données en transit et au repos\n'
        '• Authentification sécurisée\n'
        '• Surveillance continue des accès\n'
        '• Sauvegardes régulières',
      ),
      
      _buildSectionTitle('6. Vos droits'),
      _buildParagraph(
        'Conformément à la réglementation, vous avez le droit de :\n'
        '• Accéder à vos données\n'
        '• Rectifier vos informations\n'
        '• Supprimer votre compte\n'
        '• Exporter vos données\n'
        '• Vous opposer au traitement',
      ),
      
      _buildSectionTitle('7. Conservation'),
      _buildParagraph(
        'Vos données sont conservées pendant la durée de votre utilisation du service, '
        'puis archivées pendant la durée légale requise (généralement 5 ans).',
      ),
      
      _buildSectionTitle('8. Cookies'),
      _buildParagraph(
        'L\'application utilise des cookies techniques nécessaires au fonctionnement. '
        'Aucun cookie publicitaire n\'est utilisé.',
      ),
      
      _buildSectionTitle('9. Contact DPO'),
      _buildParagraph(
        'Pour exercer vos droits ou poser des questions :\n'
        'Email : privacy@drlpharma.com\n'
        'Délégué à la Protection des Données\n'
        'DR-PHARMA, COCODY ANGRE terminus 81/82 – Abidjan, Côte d\'Ivoire',
      ),
    ];
  }

  Widget _buildLastUpdated(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Dernière mise à jour : $date',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
