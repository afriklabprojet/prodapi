import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/app_logger.dart';
import '../models/treatment_model.dart';

/// Source de données locale pour les traitements (Hive)
/// Utilise un singleton pattern pour garantir une instance unique initialisée
class TreatmentsLocalDatasource {
  static const String _boxName = 'treatments';
  static TreatmentsLocalDatasource? _instance;
  static bool _isInitialized = false;

  Box<TreatmentModel>? _box;

  /// Constructeur privé pour le singleton
  TreatmentsLocalDatasource._();

  /// Obtient l'instance unique du datasource
  factory TreatmentsLocalDatasource() {
    _instance ??= TreatmentsLocalDatasource._();
    return _instance!;
  }

  /// Initialise le box Hive (doit être appelé au démarrage de l'app)
  Future<void> init() async {
    if (_isInitialized && _box != null && _box!.isOpen) {
      AppLogger.info('TreatmentsLocalDatasource already initialized');
      return;
    }

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TreatmentModelAdapter());
    }
    _box = await Hive.openBox<TreatmentModel>(_boxName);
    _isInitialized = true;
    AppLogger.info(
      'TreatmentsLocalDatasource initialized with ${_box?.length ?? 0} treatments',
    );
  }

  /// Vérifie que le box est initialisé, l'initialise automatiquement si nécessaire
  Future<Box<TreatmentModel>> get box async {
    if (_box == null || !_box!.isOpen) {
      AppLogger.warning(
        'TreatmentsLocalDatasource not initialized, auto-initializing...',
      );
      await init();
    }
    return _box!;
  }

  /// Récupère tous les traitements
  Future<List<TreatmentModel>> getAllTreatments() async {
    final b = await box;
    return b.values.where((t) => t.isActive).toList()..sort(
      (a, b) => (a.nextRenewalDate ?? DateTime(2100)).compareTo(
        b.nextRenewalDate ?? DateTime(2100),
      ),
    );
  }

  /// Récupère les traitements qui ont besoin d'un renouvellement dans les X jours
  Future<List<TreatmentModel>> getTreatmentsNeedingRenewal() async {
    final now = DateTime.now();
    final b = await box;
    return b.values.where((t) {
        if (!t.isActive || t.nextRenewalDate == null) return false;
        final daysUntil = t.nextRenewalDate!.difference(now).inDays;
        return daysUntil <= t.reminderDaysBefore;
      }).toList()
      ..sort((a, b) => a.nextRenewalDate!.compareTo(b.nextRenewalDate!));
  }

  /// Récupère un traitement par ID
  Future<TreatmentModel?> getTreatmentById(String id) async {
    final b = await box;
    return b.get(id);
  }

  /// Ajoute un nouveau traitement
  Future<TreatmentModel> addTreatment(TreatmentModel treatment) async {
    final b = await box;
    // Générer un ID si nécessaire
    final id = treatment.id.isEmpty ? const Uuid().v4() : treatment.id;
    final newTreatment = TreatmentModel(
      id: id,
      productId: treatment.productId,
      productName: treatment.productName,
      productImage: treatment.productImage,
      dosage: treatment.dosage,
      frequency: treatment.frequency,
      quantityPerRenewal: treatment.quantityPerRenewal,
      renewalPeriodDays: treatment.renewalPeriodDays,
      nextRenewalDate:
          treatment.nextRenewalDate ??
          DateTime.now().add(Duration(days: treatment.renewalPeriodDays)),
      lastOrderedAt: treatment.lastOrderedAt,
      reminderEnabled: treatment.reminderEnabled,
      reminderDaysBefore: treatment.reminderDaysBefore,
      notes: treatment.notes,
      isActive: treatment.isActive,
      createdAt: treatment.createdAt,
    );

    await b.put(id, newTreatment);
    AppLogger.info('Treatment added: ${newTreatment.productName} (ID: $id)');
    return newTreatment;
  }

  /// Met à jour un traitement existant
  Future<TreatmentModel> updateTreatment(TreatmentModel treatment) async {
    final b = await box;
    await b.put(treatment.id, treatment);
    AppLogger.info('Treatment updated: ${treatment.productName}');
    return treatment;
  }

  /// Supprime un traitement (soft delete)
  Future<void> deleteTreatment(String id) async {
    final b = await box;
    final treatment = b.get(id);
    if (treatment != null) {
      final updated = TreatmentModel(
        id: treatment.id,
        productId: treatment.productId,
        productName: treatment.productName,
        productImage: treatment.productImage,
        dosage: treatment.dosage,
        frequency: treatment.frequency,
        quantityPerRenewal: treatment.quantityPerRenewal,
        renewalPeriodDays: treatment.renewalPeriodDays,
        nextRenewalDate: treatment.nextRenewalDate,
        lastOrderedAt: treatment.lastOrderedAt,
        reminderEnabled: treatment.reminderEnabled,
        reminderDaysBefore: treatment.reminderDaysBefore,
        notes: treatment.notes,
        isActive: false, // Soft delete
        createdAt: treatment.createdAt,
      );
      await b.put(id, updated);
      AppLogger.info('Treatment deleted (soft): ${treatment.productName}');
    }
  }

  /// Supprime définitivement un traitement
  Future<void> hardDeleteTreatment(String id) async {
    final b = await box;
    await b.delete(id);
    AppLogger.info('Treatment hard deleted: $id');
  }

  /// Marque un traitement comme commandé
  Future<TreatmentModel> markAsOrdered(String id) async {
    final b = await box;
    final treatment = b.get(id);
    if (treatment == null) {
      throw Exception('Treatment not found: $id');
    }

    final now = DateTime.now();
    final updated = TreatmentModel(
      id: treatment.id,
      productId: treatment.productId,
      productName: treatment.productName,
      productImage: treatment.productImage,
      dosage: treatment.dosage,
      frequency: treatment.frequency,
      quantityPerRenewal: treatment.quantityPerRenewal,
      renewalPeriodDays: treatment.renewalPeriodDays,
      nextRenewalDate: now.add(Duration(days: treatment.renewalPeriodDays)),
      lastOrderedAt: now,
      reminderEnabled: treatment.reminderEnabled,
      reminderDaysBefore: treatment.reminderDaysBefore,
      notes: treatment.notes,
      isActive: treatment.isActive,
      createdAt: treatment.createdAt,
    );

    await b.put(id, updated);
    AppLogger.info(
      'Treatment marked as ordered: ${treatment.productName}, next renewal: ${updated.nextRenewalDate}',
    );
    return updated;
  }

  /// Active/désactive les rappels
  Future<TreatmentModel> toggleReminder(String id, bool enabled) async {
    final b = await box;
    final treatment = b.get(id);
    if (treatment == null) {
      throw Exception('Treatment not found: $id');
    }

    final updated = TreatmentModel(
      id: treatment.id,
      productId: treatment.productId,
      productName: treatment.productName,
      productImage: treatment.productImage,
      dosage: treatment.dosage,
      frequency: treatment.frequency,
      quantityPerRenewal: treatment.quantityPerRenewal,
      renewalPeriodDays: treatment.renewalPeriodDays,
      nextRenewalDate: treatment.nextRenewalDate,
      lastOrderedAt: treatment.lastOrderedAt,
      reminderEnabled: enabled,
      reminderDaysBefore: treatment.reminderDaysBefore,
      notes: treatment.notes,
      isActive: treatment.isActive,
      createdAt: treatment.createdAt,
    );

    await b.put(id, updated);
    AppLogger.info(
      'Treatment reminder ${enabled ? 'enabled' : 'disabled'}: ${treatment.productName}',
    );
    return updated;
  }

  /// Ferme le box
  Future<void> close() async {
    await _box?.close();
  }
}
