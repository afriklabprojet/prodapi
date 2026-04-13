import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescriptions_provider.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';

class PrescriptionDetailsPage extends ConsumerStatefulWidget {
  final int prescriptionId;

  const PrescriptionDetailsPage({super.key, required this.prescriptionId});

  @override
  ConsumerState<PrescriptionDetailsPage> createState() =>
      _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState
    extends ConsumerState<PrescriptionDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(prescriptionsProvider.notifier)
          .getPrescriptionDetails(widget.prescriptionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find prescription in state
    final state = ref.watch(prescriptionsProvider);
    final prescription = state.prescriptions
        .cast<PrescriptionEntity?>()
        .firstWhere((p) => p!.id == widget.prescriptionId, orElse: () => null);

    if (prescription == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final apiClient = ref.watch(apiClientProvider);
    final authHeaders = apiClient.currentToken != null
        ? {'Authorization': 'Bearer ${apiClient.currentToken}'}
        : <String, String>{};

    return Scaffold(
      appBar: AppBar(title: Text('Ordonnance #${prescription.id}')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(prescriptionsProvider.notifier)
              .getPrescriptionDetails(widget.prescriptionId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(prescription),
              const SizedBox(height: 24),
              if (prescription.imageUrls.isNotEmpty) ...[
                const Text(
                  'Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: prescription.imageUrls.length,
                    itemBuilder: (context, index) {
                      final url = prescription.imageUrls[index];
                      return CachedNetworkImage(
                        imageUrl: url,
                        httpHeaders: authHeaders,
                        fit: BoxFit.contain,
                        placeholder: (c, u) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (c, u, e) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Erreur de chargement',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                const Text(
                  'Note de la pharmacie:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(prescription.pharmacyNotes!),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: prescription.status == 'quoted'
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showPaymentConfirmation(context, prescription);
                },
                child: Text(
                  'Payer ${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(prescription.quoteAmount ?? 0)}',
                  style: const TextStyle(fontSize: 18),
                ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirmer le paiement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Mode de paiement:'),
              const ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
                title: Text('Jèko (Wave, Orange, MTN, Moov)'),
                trailing: Icon(Icons.check_circle, color: AppColors.success),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref
                        .read(prescriptionsProvider.notifier)
                        .payPrescription(p.id);
                    AppSnackbar.info(context, 'Paiement en cours...');
                  },
                  child: const Text('Confirmer et Payer'),
                ),
              ),
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
        color = AppColors.warning;
        text = 'En attente de traitement';
        icon = Icons.timer;
        break;
      case 'quoted':
        color = AppColors.info;
        text = 'Devis Disponible';
        icon = Icons.monetization_on;
        break;
      case 'paid':
        color = AppColors.secondary;
        text = 'Payé - En préparation';
        icon = Icons.receipt_long;
        break;
      case 'validated':
        color = AppColors.success;
        text = 'Commande Validée';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Refusée';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = p.status;
        icon = Icons.info;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (p.fulfillmentStatus != 'none') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: p.isFullyDispensed
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: p.isFullyDispensed
                    ? AppColors.success
                    : AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  p.isFullyDispensed ? Icons.check_circle : Icons.timelapse,
                  color: p.isFullyDispensed
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.isFullyDispensed
                        ? 'Médicaments entièrement délivrés (${p.dispensingCount} dispensation(s))'
                        : 'Médicaments partiellement délivrés (${p.dispensingCount} dispensation(s))',
                    style: TextStyle(
                      color: p.isFullyDispensed
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuoteSection(PrescriptionEntity p) {
    return Card(
      elevation: 4,
      color: AppColors.info.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Proposition de Prix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                symbol: 'FCFA',
                decimalDigits: 0,
              ).format(p.quoteAmount ?? 0),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez procéder au paiement pour valider la commande.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
