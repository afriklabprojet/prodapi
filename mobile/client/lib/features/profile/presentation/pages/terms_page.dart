import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conditions Générales d\'Utilisation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Dernière mise à jour : Juin 2025',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              '1. Objet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Les présentes conditions générales d\'utilisation régissent l\'utilisation de l\'application DR Pharma, service de livraison de médicaments à domicile en Côte d\'Ivoire.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Inscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'L\'utilisation de l\'application nécessite la création d\'un compte avec des informations exactes et à jour. L\'utilisateur est responsable de la confidentialité de ses identifiants.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Commandes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Les commandes sont traitées sous réserve de disponibilité des produits. Certains médicaments nécessitent une ordonnance valide. DR Pharma se réserve le droit de refuser toute commande.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Livraison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Les délais de livraison sont donnés à titre indicatif. DR Pharma s\'efforce de respecter les délais mais ne peut être tenu responsable des retards indépendants de sa volonté.',
            ),
            SizedBox(height: 16),
            Text(
              '5. Paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Le paiement peut être effectué par mobile money, paiement à la livraison ou tout autre moyen de paiement proposé dans l\'application.',
            ),
            SizedBox(height: 16),
            Text(
              '6. Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Pour toute question, contactez-nous à : support@drpharma.ci',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
