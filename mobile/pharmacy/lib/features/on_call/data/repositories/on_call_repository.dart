import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/on_call_model.dart';
import '../datasources/on_call_remote_datasource.dart';

class OnCallRepository {
  final OnCallRemoteDataSource _dataSource;

  OnCallRepository(this._dataSource);

  Future<Either<Failure, List<OnCallModel>>> getOnCalls() async {
    try {
      final result = await _dataSource.getOnCalls();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, OnCallModel>> createOnCall(Map<String, dynamic> data) async {
    try {
      final result = await _dataSource.createOnCall(data);
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.errors, originalError: e));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, originalError: e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, originalError: e));
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', ''), originalError: e));
    }
  }

  Future<Either<Failure, void>> deleteOnCall(int id) async {
    try {
      await _dataSource.deleteOnCall(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

final onCallRepositoryProvider = Provider<OnCallRepository>((ref) {
  final dataSource = ref.watch(onCallRemoteDataSourceProvider);
  return OnCallRepository(dataSource);
});
