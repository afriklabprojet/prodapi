import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository repository;
  GetWalletUseCase(this.repository);

  Future<Either<Failure, WalletEntity>> call() {
    return repository.getWallet();
  }
}

class GetTransactionsUseCase {
  final WalletRepository repository;
  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<WalletTransactionEntity>>> call({
    int limit = 50,
    String? category,
  }) {
    return repository.getTransactions(limit: limit, category: category);
  }
}

class InitiateTopUpUseCase {
  final WalletRepository repository;
  InitiateTopUpUseCase(this.repository);

  Future<Either<Failure, PaymentInitResult>> call({
    required double amount,
    required String paymentMethod,
  }) {
    return repository.initiateTopUp(
      amount: amount,
      paymentMethod: paymentMethod,
    );
  }
}

class CheckPaymentStatusUseCase {
  final WalletRepository repository;
  CheckPaymentStatusUseCase(this.repository);

  Future<Either<Failure, PaymentStatusResult>> call(String reference) {
    return repository.checkPaymentStatus(reference);
  }
}

class TopUpWalletUseCase {
  final WalletRepository repository;
  TopUpWalletUseCase(this.repository);

  Future<Either<Failure, WalletTransactionEntity>> call({
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) {
    return repository.topUp(
      amount: amount,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
    );
  }
}

class WithdrawWalletUseCase {
  final WalletRepository repository;
  WithdrawWalletUseCase(this.repository);

  Future<Either<Failure, WalletTransactionEntity>> call({
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) {
    return repository.withdraw(
      amount: amount,
      paymentMethod: paymentMethod,
      phoneNumber: phoneNumber,
    );
  }
}

class PayOrderUseCase {
  final WalletRepository repository;
  PayOrderUseCase(this.repository);

  Future<Either<Failure, WalletTransactionEntity>> call({
    required double amount,
    required String orderReference,
  }) {
    return repository.payOrder(amount: amount, orderReference: orderReference);
  }
}
