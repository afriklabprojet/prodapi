import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de confidentialité',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Dernière mise à jour : Juin 2025',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              '1. Collecte des données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'DR Pharma collecte les données personnelles nécessaires au bon fonctionnement du service : nom, prénom, adresse e-mail, numéro de téléphone, adresse de livraison et historique de commandes.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Utilisation des données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Vos données sont utilisées pour traiter vos commandes, gérer votre compte, améliorer nos services et vous envoyer des notifications relatives à vos commandes.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Protection des données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos données personnelles contre tout accès non autorisé, modification, divulgation ou destruction.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Partage des données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Vos données peuvent être partagées avec nos partenaires pharmacies et coursiers uniquement dans le cadre du traitement de vos commandes. Nous ne vendons pas vos données à des tiers.',
            ),
            SizedBox(height: 16),
            Text(
              '5. Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Pour toute question relative à vos données personnelles, contactez-nous à : support@drpharma.ci',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
