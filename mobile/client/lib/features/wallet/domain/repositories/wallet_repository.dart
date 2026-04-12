import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();

  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions({
    int limit = 50,
    String? category,
  });

  /// Initier un rechargement via Jeko - retourne {reference, redirect_url}
  Future<Either<Failure, PaymentInitResult>> initiateTopUp({
    required double amount,
    required String paymentMethod,
  });

  /// Vérifier le statut d'un paiement
  Future<Either<Failure, PaymentStatusResult>> checkPaymentStatus(String reference);

  Future<Either<Failure, WalletTransactionEntity>> topUp({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  });

  Future<Either<Failure, WalletTransactionEntity>> withdraw({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  });

  Future<Either<Failure, WalletTransactionEntity>> payOrder({
    required double amount,
    required String orderReference,
  });
}
