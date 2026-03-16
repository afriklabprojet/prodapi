import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../datasources/prescription_remote_datasource.dart';
import '../models/prescription_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart' as domain;

/// Implémentation concrète du repository de prescriptions
class PrescriptionRepositoryImpl implements domain.PrescriptionRepository {
  final PrescriptionRemoteDataSource _dataSource;

  PrescriptionRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getPrescriptions() async {
    try {
      final result = await _dataSource.getPrescriptions();
      return Right(result.map(_mapToEntity).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> getPrescription(int id) async {
    try {
      final result = await _dataSource.getPrescription(id);
      return Right(_mapToEntity(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> updateStatus(
    int id,
    String status, {
    String? notes,
    double? quoteAmount,
  }) async {
    try {
      final result = await _dataSource.updateStatus(id, status, notes: notes, quoteAmount: quoteAmount);
      return Right(_mapToEntity(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, domain.PrescriptionAnalysisResult>> analyzePrescription(int id, {bool force = false}) async {
    try {
      final result = await _dataSource.analyzePrescription(id, force: force);
      return Right(_mapAnalysisResult(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Convertit un PrescriptionModel en PrescriptionEntity
  PrescriptionEntity _mapToEntity(PrescriptionModel model) {
    return PrescriptionEntity(
      id: model.id,
      customerId: model.customerId,
      status: model.status,
      notes: model.notes,
      images: model.images ?? [],
      adminNotes: model.adminNotes,
      pharmacyNotes: model.pharmacyNotes,
      quoteAmount: model.quoteAmount,
      createdAt: DateTime.tryParse(model.createdAt) ?? DateTime.now(),
      customer: model.customer != null ? _mapCustomer(model.customer!) : null,
      extractedMedications: model.extractedMedications,
      matchedProducts: model.matchedProducts,
      unmatchedMedications: model.unmatchedMedications,
      ocrConfidence: model.ocrConfidence,
      analyzedAt: model.analyzedAt != null ? DateTime.tryParse(model.analyzedAt!) : null,
      analysisStatus: model.analysisStatus.toAnalysisStatus(),
      analysisError: model.analysisError,
    );
  }

  CustomerInfo _mapCustomer(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Client inconnu',
      phone: json['phone'],
      email: json['email'],
    );
  }

  domain.PrescriptionAnalysisResult _mapAnalysisResult(AnalysisResult result) {
    return domain.PrescriptionAnalysisResult(
      extractedMedications: result.extractedMedications.map((m) {
        return domain.ExtractedMedication(
          name: m['name'] ?? '',
          dosage: m['dosage'],
          frequency: m['frequency'],
          quantity: m['quantity'],
          confidence: (m['confidence'] ?? 0.0).toDouble(),
        );
      }).toList(),
      matchedProducts: result.matchedProducts.map((p) {
        return domain.MatchedProduct(
          productId: p['product_id'] ?? 0,
          productName: p['product_name'] ?? '',
          medicationName: p['medication_name'] ?? '',
          price: (p['price'] ?? 0).toDouble(),
          stockQuantity: p['stock_quantity'] ?? 0,
          matchScore: (p['match_score'] ?? 0.0).toDouble(),
        );
      }).toList(),
      unmatchedMedications: result.unmatchedMedications.map((e) => e.toString()).toList(),
      confidence: result.confidence,
      status: 'completed',
    );
  }
}

final prescriptionRepositoryProvider = Provider<domain.PrescriptionRepository>((ref) {
  final dataSource = ref.watch(prescriptionRemoteDataSourceProvider);
  return PrescriptionRepositoryImpl(dataSource);
});
