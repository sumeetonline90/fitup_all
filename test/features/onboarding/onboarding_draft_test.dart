import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:fitup/features/onboarding/domain/onboarding_state.dart';
import 'package:fitup/features/profile/domain/entities/profile_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FitupDatabase db;
  late OnboardingDraftRepository repo;

  setUp(() {
    db = FitupDatabase(NativeDatabase.memory());
    repo = OnboardingDraftRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saveDraft and loadDraft restore step and goals', () async {
    const String uid = 'user_x';
    final OnboardingState state = OnboardingState(
      currentStep: 3,
      goals: <HealthGoal>{
        HealthGoal.improveOverallHealth,
        HealthGoal.loseWeight,
      },
    );
    final Either<Failure, Unit> save = await repo.saveDraft(uid, state);
    expect(save.isRight(), isTrue);
    final Either<Failure, OnboardingState?> load = await repo.loadDraft(uid);
    expect(load.isRight(), isTrue);
    load.fold(
      (_) => fail('unexpected Left'),
      (OnboardingState? s) {
        expect(s, isNotNull);
        expect(s!.currentStep, 3);
        expect(s.goals.length, 2);
      },
    );
  });

  test('clearDraft removes row', () async {
    const String uid = 'user_y';
    await repo.saveDraft(
      uid,
      const OnboardingState(currentStep: 1),
    );
    await repo.clearDraft(uid);
    final Either<Failure, OnboardingState?> load = await repo.loadDraft(uid);
    load.fold(
      (_) => fail('unexpected'),
      (OnboardingState? s) => expect(s, isNull),
    );
  });
}
