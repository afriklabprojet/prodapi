import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/on_call_entity.dart';

/// Interface abstraite du repository de gardes
abstract class OnCallRepositoryInterface {
  /// Récupère toutes les gardes de la pharmacie
  Future<Either<Failure, List<OnCallEntity>>> getOnCalls();
  
  /// Crée une nouvelle garde
  Future<Either<Failure, OnCallEntity>> createOnCall({
    required int dutyZoneId,
    required DateTime startAt,
    required DateTime endAt,
    required OnCallType type,
  });
  
  /// Supprime une garde
  Future<Either<Failure, void>> deleteOnCall(int id);
  
  /// Met à jour une garde existante
  Future<Either<Failure, OnCallEntity>> updateOnCall(
    int id, {
    DateTime? startAt,
    DateTime? endAt,
    OnCallType? type,
    bool? isActive,
  });
}
