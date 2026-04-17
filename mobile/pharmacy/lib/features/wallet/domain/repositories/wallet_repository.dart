import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/wallet_entity.dart';

/// Interface pour le repository du portefeuille
abstract class WalletRepositoryInterface {
  /// Récupère les données du portefeuille
  Future<Either<Failure, WalletEntity>> getWalletData();

  /// Récupère les statistiques par période (today, week, month, year)
  Future<Either<Failure, WalletStatsEntity>> getStatsByPeriod(String period);

  /// Demande de retrait
  Future<Either<Failure, WithdrawResultEntity>> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    String? accountDetails,
    String? phone,
    String? pin,
  });

  /// Enregistrer les informations bancaires
  Future<Either<Failure, void>> saveBankInfo({
    required String bankName,
    required String holderName,
    required String accountNumber,
    String? iban,
  });

  /// Enregistrer les informations Mobile Money
  Future<Either<Failure, void>> saveMobileMoneyInfo({
    required String operator,
    required String phoneNumber,
    required String accountName,
    bool isPrimary = true,
  });

  /// Récupérer les paramètres de seuil de retrait
  Future<Either<Failure, WithdrawalSettingsEntity>> getWithdrawalSettings();

  /// Configurer le seuil de retrait automatique
  Future<Either<Failure, WithdrawalSettingsEntity>> setWithdrawalThreshold({
    required double threshold,
    required bool autoWithdraw,
  });

  /// Exporter les transactions
  Future<Either<Failure, String>> exportTransactions({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  });
}
