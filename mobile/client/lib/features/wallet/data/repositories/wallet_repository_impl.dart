import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async {
    try {
      final wallet = await remoteDataSource.getWallet();
      return Right(wallet.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions({
    int limit = 50,
    String? category,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactions(
        limit: limit,
        category: category,
      );
      return Right(transactions.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, PaymentInitResult>> initiateTopUp({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final data = await remoteDataSource.initiateTopUp(
        amount: amount,
        paymentMethod: paymentMethod,
      );
      return Right(PaymentInitResult.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on ValidationException catch (e) {
      final msg = e.errors.values.expand((v) => v).join('\n');
      return Left(ValidationFailure(message: msg, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, PaymentStatusResult>> checkPaymentStatus(String reference) async {
    try {
      final data = await remoteDataSource.checkPaymentStatus(reference);
      return Right(PaymentStatusResult.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, WalletTransactionEntity>> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      final data = await remoteDataSource.topUp(
        amount: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );
      final txJson = data['transaction'] as Map<String, dynamic>;
      return Right(WalletTransactionModel.fromJson(txJson).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on ValidationException catch (e) {
      final msg = e.errors.values.expand((v) => v).join('\n');
      return Left(ValidationFailure(message: msg, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, WalletTransactionEntity>> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    try {
      final data = await remoteDataSource.withdraw(
        amount: amount,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
      );
      final txJson = data['transaction'] as Map<String, dynamic>;
      return Right(WalletTransactionModel.fromJson(txJson).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on ValidationException catch (e) {
      final msg = e.errors.values.expand((v) => v).join('\n');
      return Left(ValidationFailure(message: msg, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, WalletTransactionEntity>> payOrder({
    required double amount,
    required String orderReference,
  }) async {
    try {
      final data = await remoteDataSource.payOrder(
        amount: amount,
        orderReference: orderReference,
      );
      final txJson = data['transaction'] as Map<String, dynamic>;
      return Right(WalletTransactionModel.fromJson(txJson).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue'));
    }
  }
}
