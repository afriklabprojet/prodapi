import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LegalNoticesPage extends StatelessWidget {
  const LegalNoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentions Légales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Mentions Légales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Éditeur\n'
              'L\'application DR-PHARMA est éditée par la société AFRIK LAB, société à responsabilité limitée.\n\n'
              'Siège social\n'
              'Abidjan, Côte d\'Ivoire\n\n'
              'Contact\n'
              'Email : contact@drlpharma.com\n'
              'Téléphone : +225 07 XX XX XX XX\n\n'
              'Hébergement\n'
              'L\'infrastructure technique est hébergée sur des serveurs sécurisés.\n\n'
              'Propriété intellectuelle\n'
              'Tous les contenus de l\'application (textes, images, logos) sont protégés par le droit d\'auteur.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
