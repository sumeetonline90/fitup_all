import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/fitcoins/data/repositories/firebase_fitcoin_repository.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_transaction.dart';
import 'package:fitup/features/fitcoins/domain/repositories/fitcoin_repository.dart';
import 'package:fitup/features/fitcoins/domain/services/fitcoin_award_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements FitcoinRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUpAll(() {
    registerFallbackValue(EarnSource.dailyLogin);
    registerFallbackValue('');
  });

  late _MockRepo repo;
  late FitcoinAwardService service;

  final FitcoinTransaction sampleTx = FitcoinTransaction(
    id: 't1',
    userId: 'u1',
    type: TransactionType.earned,
    source: EarnSource.dailyLogin,
    amount: 5,
    description: 'Daily login bonus',
    createdAt: DateTime.utc(2025, 3, 22),
  );

  setUp(() {
    repo = _MockRepo();
    service = FitcoinAwardService(repo);
  });

  test('onDailyLogin calls awardCoins with expected amount and idempotency key',
      () async {
    when(
      () => repo.awardCoins(
        userId: any(named: 'userId'),
        source: any(named: 'source'),
        amount: any(named: 'amount'),
        description: any(named: 'description'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => Right<Failure, FitcoinTransaction>(sampleTx));

    await service.onDailyLogin('u1');

    verify(
      () => repo.awardCoins(
        userId: 'u1',
        source: EarnSource.dailyLogin,
        amount: 5,
        description: 'Daily login bonus',
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
  });

  test('duplicate daily login still invokes repo; idempotency handled in repo',
      () async {
    when(
      () => repo.awardCoins(
        userId: any(named: 'userId'),
        source: any(named: 'source'),
        amount: any(named: 'amount'),
        description: any(named: 'description'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => Right<Failure, FitcoinTransaction>(sampleTx));

    await service.onDailyLogin('u1');
    await service.onDailyLogin('u1');

    verify(
      () => repo.awardCoins(
        userId: 'u1',
        source: EarnSource.dailyLogin,
        amount: 5,
        description: 'Daily login bonus',
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(2);
  });

  test('Left from awardCoins does not throw', () async {
    when(
      () => repo.awardCoins(
        userId: any(named: 'userId'),
        source: any(named: 'source'),
        amount: any(named: 'amount'),
        description: any(named: 'description'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer(
      (_) async => Left<Failure, FitcoinTransaction>(
        ServerFailure('offline'),
      ),
    );

    await expectLater(service.onDailyLogin('u1'), completes);
  });

  group('FirebaseFitcoinRepository redeemCoins', () {
    test('returns Left(InsufficientBalanceFailure) when balance is insufficient', () async {
      final FakeFirebaseFirestore fs = FakeFirebaseFirestore();
      final FirebaseFitcoinRepository fr = FirebaseFitcoinRepository(fs);
      await fs
          .collection('users')
          .doc('u')
          .collection('fitcoin_wallet')
          .doc('wallet')
          .set(<String, dynamic>{
        'userId': 'u',
        'balance': 4,
        'totalEarned': 10,
        'totalSpent': 6,
        'updatedAt': Timestamp.now(),
      });

      final Either<Failure, FitcoinTransaction> r = await fr.redeemCoins(
        userId: 'u',
        amount: 50,
        description: 'shop item',
      );
      expect(r.isLeft(), isTrue);
      r.fold(
        (Failure f) {
          expect(f, isA<InsufficientBalanceFailure>());
          final InsufficientBalanceFailure ib = f as InsufficientBalanceFailure;
          expect(ib.currentBalance, 4);
          expect(ib.required, 50);
        },
        (_) => fail('expected Left'),
      );
    });
  });
}
