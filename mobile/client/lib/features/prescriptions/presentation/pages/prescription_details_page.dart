import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescriptions_provider.dart';
import '../../../../core/constants/api_constants.dart';

class PrescriptionDetailsPage extends ConsumerStatefulWidget {
  final int prescriptionId;

  const PrescriptionDetailsPage({super.key, required this.prescriptionId});

  @override
  ConsumerState<PrescriptionDetailsPage> createState() => _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState extends ConsumerState<PrescriptionDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
       ref.read(prescriptionsProvider.notifier).getPrescriptionDetails(widget.prescriptionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find prescription in state
    final state = ref.watch(prescriptionsProvider);
    final prescription = state.prescriptions.firstWhere(
      (p) => p.id == widget.prescriptionId,
      orElse: () => PrescriptionEntity(
        id: widget.prescriptionId,
        status: 'loading',
        imageUrls: [],
        createdAt: DateTime.now(),
      ),
    );

    if (prescription.status == 'loading') {
       // Try trigger fetch if not found (though initState handles it)
       return Scaffold(appBar: AppBar(title: const Text('Chargement...')), body: const Center(child: CircularProgressIndicator()));
    }

    final baseUrl = ApiConstants.storageBaseUrl; 

    return Scaffold(
      appBar: AppBar(title: Text('Ordonnance #${prescription.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(prescription),
            const SizedBox(height: 24),
            if (prescription.imageUrls.isNotEmpty) ...[
               const Text('Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               SizedBox(
                 height: 300,
                 child: PageView.builder(
                   itemCount: prescription.imageUrls.length,
                   itemBuilder: (context, index) {
                      var path = prescription.imageUrls[index];
                      if (path.startsWith('public/')) {
                        path = path.replaceFirst('public/', '');
                      }
                      final url = '$baseUrl/$path';
                      return CachedNetworkImage(
                        imageUrl: url, 
                        fit: BoxFit.cover,
                        errorWidget: (c,u,e) => const Center(child: Icon(Icons.broken_image)),
                      );
                   },
                 ),
               ),
            ],
            const SizedBox(height: 24),
            if (prescription.status == 'quoted')
              _buildQuoteSection(prescription),
            
            if (prescription.pharmacyNotes != null) ...[
              const SizedBox(height: 16),
              const Text('Note de la pharmacie:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(prescription.pharmacyNotes!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: prescription.status == 'quoted' 
          ? Padding(
             padding: const EdgeInsets.all(16),
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
               onPressed: () {
                 _showPaymentConfirmation(context, prescription);
               },
               child: Text('Payer ${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(prescription.quoteAmount ?? 0)}', style: const TextStyle(fontSize: 18)),
             ),
          )
          : null,
    );
  }

  void _showPaymentConfirmation(BuildContext context, PrescriptionEntity p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmer le paiement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Mode de paiement:'),
              const ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
                title: Text('Jèko (Wave, Orange, MTN, Moov)'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(prescriptionsProvider.notifier).payPrescription(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement en cours...')));
                  },
                  child: const Text('Confirmer et Payer'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(PrescriptionEntity p) {
    Color color;
    String text;
    IconData icon;

    switch (p.status) {
       case 'pending': 
         color = Colors.orange; text = 'En attente de traitement'; icon = Icons.timer;
         break;
       case 'quoted':
         color = Colors.blue; text = 'Devis Disponible'; icon = Icons.monetization_on;
         break;
       case 'paid':
         color = Colors.teal; text = 'Payé - En préparation'; icon = Icons.receipt_long;
         break;
       case 'validated':
         color = Colors.green; text = 'Commande Validée'; icon = Icons.check_circle;
         break;
       case 'rejected':
         color = Colors.red; text = 'Refusée'; icon = Icons.cancel;
         break;
       default:
         color = Colors.grey; text = p.status; icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildQuoteSection(PrescriptionEntity p) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Proposition de Prix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(p.quoteAmount ?? 0),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text('Veuillez procéder au paiement pour valider la commande.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
