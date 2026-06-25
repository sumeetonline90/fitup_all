import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fitcoin_transaction.dart';
import '../entities/fitcoin_wallet.dart';

abstract interface class FitcoinRepository {
  Future<Either<Failure, FitcoinWallet>> getWallet(String userId);

  Future<Either<Failure, List<FitcoinTransaction>>> getTransactions(
    String userId, {
    int limit = 30,
  });

  /// [idempotencyKey] when set must be unique per logical award (duplicate → skip).
  Future<Either<Failure, FitcoinTransaction>> awardCoins({
    required String userId,
    required EarnSource source,
    required int amount,
    required String description,
    String? idempotencyKey,
  });

  /// Redeem/spend coins. On insufficient balance returns [InsufficientBalanceFailure]
  /// (not [ValidationFailure]) so UI can show "need X more FC" messaging.
  Future<Either<Failure, FitcoinTransaction>> redeemCoins({
    required String userId,
    required int amount,
    required String description,
  });

  Stream<FitcoinWallet> watchWallet(String userId);

  Stream<List<FitcoinTransaction>> watchTransactions(
    String userId, {
    int limit = 40,
  });
}
