import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/prescription_remote_datasource.dart';
import '../../data/models/prescription_model.dart';
import 'prescription_details_page.dart';

/// Provider pour charger les détails d'une ordonnance par ID
final prescriptionDetailsWrapperProvider =
    FutureProvider.family<PrescriptionModel?, int>((ref, prescriptionId) async {
  final dataSource = ref.watch(prescriptionRemoteDataSourceProvider);
  try {
    final result = await dataSource.getPrescription(prescriptionId);
    return result;
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
          '❌ [PrescriptionDetails] Erreur lors du chargement de l\'ordonnance #$prescriptionId: $e');
    }
    throw Exception(e.toString());
  }
});

/// Page wrapper qui charge une ordonnance par son ID et affiche PrescriptionDetailsPage
class PrescriptionDetailsWrapperPage extends ConsumerWidget {
  final int prescriptionId;

  const PrescriptionDetailsWrapperPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionAsync =
        ref.watch(prescriptionDetailsWrapperProvider(prescriptionId));
    final isDark = AppColors.isDark(context);

    return prescriptionAsync.when(
      data: (prescription) {
        if (prescription == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Ordonnance introuvable'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
                tooltip: 'Retour',
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ordonnance #$prescriptionId introuvable',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }

        return PrescriptionDetailsPage(prescription: prescription);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Retour',
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'ordonnance...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Retour',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(
                        prescriptionDetailsWrapperProvider(prescriptionId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
