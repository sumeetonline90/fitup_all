import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/fitup_database.dart';
import '../../../core/error/failures.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_draft_codec.dart';

/// Persists onboarding wizard drafts to [OnboardingDraftCache].
class OnboardingDraftRepository {
  OnboardingDraftRepository(this._db);

  final FitupDatabase? _db;

  Future<Either<Failure, OnboardingState?>> loadDraft(String userId) async {
    final FitupDatabase? db = _db;
    if (db == null || kIsWeb) {
      return const Right<Failure, OnboardingState?>(null);
    }
    try {
      final OnboardingDraftCacheRow? row =
          await (db.select(db.onboardingDraftCache)
                ..where((OnboardingDraftCache t) => t.userId.equals(userId)))
              .getSingleOrNull();
      if (row == null || row.payloadJson.isEmpty) {
        return const Right<Failure, OnboardingState?>(null);
      }
      return Right<Failure, OnboardingState?>(
        OnboardingDraftCodec.decode(row.payloadJson),
      );
    } catch (e) {
      return Left<Failure, OnboardingState?>(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> saveDraft(String userId, OnboardingState state) async {
    final FitupDatabase? db = _db;
    if (db == null || kIsWeb) {
      return const Right<Failure, Unit>(unit);
    }
    try {
      await db.into(db.onboardingDraftCache).insertOnConflictUpdate(
            OnboardingDraftCacheCompanion.insert(
              userId: userId,
              payloadJson: OnboardingDraftCodec.encode(state),
              updatedAt: DateTime.now(),
            ),
          );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> clearDraft(String userId) async {
    final FitupDatabase? db = _db;
    if (db == null || kIsWeb) {
      return const Right<Failure, Unit>(unit);
    }
    try {
      await (db.delete(db.onboardingDraftCache)
            ..where((OnboardingDraftCache t) => t.userId.equals(userId)))
          .go();
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(CacheFailure(e.toString()));
    }
  }
}
