import 'package:dartz/dartz.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/domain/entities/fitup_user.dart';
import '../../../../features/insights/domain/entities/holistic_context.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';
import '../../../../features/insights/domain/repositories/holistic_plan_repository.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/services/holistic_context_builder.dart';

/// Generates a new holistic plan (resets dates) and syncs
/// `UserProfile` daily targets from the resulting plan.
Future<Either<Failure, HolisticPlan>> generateHolisticPlanAndSyncProfile({
  required FitupUser user,
  required DateTime startDate,
  required int durationDays,
  String? userPlanInput,
}) async {
  final HolisticPlanRepository planRepo = getIt<HolisticPlanRepository>();
  final AiService ai = getIt<AiService>();
  final ProfileRepository profileRepo = getIt<ProfileRepository>();
  final HolisticContextBuilder ctxBuilder = getIt<HolisticContextBuilder>();

  final int safeDays = durationDays.clamp(7, 90);
  final DateTime endDate = startDate.add(Duration(days: safeDays));

  final HolisticContext ctx = await ctxBuilder.buildFor(user.id);

  final Either<Failure, HolisticPlanDraft> draftEither =
      await ai.generateHolisticPlan(
        ctx: ctx,
        startDate: startDate,
        endDate: endDate,
        userPlanInput: userPlanInput,
      );

  return await draftEither.fold(
    (Failure f) async => Left<Failure, HolisticPlan>(f),
    (HolisticPlanDraft draft) async {
      final Either<Failure, HolisticPlan> saved =
          await planRepo.saveNewActivePlan(
        userId: user.id,
        draft: draft,
        generatedAt: DateTime.now(),
      );

      return await saved.fold(
        (Failure f) async => Left<Failure, HolisticPlan>(f),
        (HolisticPlan plan) async {
          final Either<Failure, UserProfile> profileEither =
              await profileRepo.getProfile(user.id);
          return await profileEither.fold(
            (Failure f) async {
              LoggerService.e(
                'generateHolisticPlanAndSyncProfile profile fetch',
                f,
                StackTrace.current,
              );
              // Plan creation succeeded; profile sync can retry later.
              return Right<Failure, HolisticPlan>(plan);
            },
            (UserProfile current) async {
              final UserProfile updated = current.copyWith(
                dailyStepGoal: plan.dailyTargets.dailyStepGoal,
                dailyCalorieGoal: plan.dailyTargets.dailyCalorieGoal,
                dailySleepGoalMinutes: plan.dailyTargets.dailySleepGoalMinutes,
                dailyWaterGoalMl: plan.dailyTargets.dailyWaterGoalMl,
                dailyWorkoutGoalMinutes:
                    plan.dailyTargets.dailyWorkoutGoalMinutes,
                updatedAt: DateTime.now(),
              );
              final Either<Failure, Unit> updatedResult =
                  await profileRepo.updateProfile(updated);
              return updatedResult.fold(
                (Failure f) {
                  LoggerService.e(
                    'generateHolisticPlanAndSyncProfile profile update',
                    f,
                    StackTrace.current,
                  );
                  // Keep successful plan even if profile sync fails.
                  return Right<Failure, HolisticPlan>(plan);
                },
                (_) => Right<Failure, HolisticPlan>(plan),
              );
            },
          );
        },
      );
    },
  );
}

/// Updates the currently active plan modules (keeps existing dates)
/// and syncs `UserProfile` daily targets from the updated plan.
Future<Either<Failure, HolisticPlan>> amendActivePlanModuleAndSyncProfile({
  required FitupUser user,
  required HolisticPlan activePlan,
  required PlanModuleKey moduleKey,
  required String moduleAmendment,
}) async {
  final HolisticPlanRepository planRepo = getIt<HolisticPlanRepository>();
  final AiService ai = getIt<AiService>();
  final ProfileRepository profileRepo = getIt<ProfileRepository>();
  final HolisticContextBuilder ctxBuilder = getIt<HolisticContextBuilder>();

  final HolisticContext ctx = await ctxBuilder.buildFor(user.id);

  final Either<Failure, HolisticPlanDraft> updatedDraftEither =
      await ai.updateHolisticPlanFromModule(
        ctx: ctx,
        activePlan: activePlan,
        moduleKey: moduleKey,
        moduleAmendment: moduleAmendment,
  );

  return await updatedDraftEither.fold(
    (Failure f) async => Left<Failure, HolisticPlan>(f),
    (HolisticPlanDraft updatedDraft) async {
      final Either<Failure, HolisticPlan> updatedPlanEither =
          await planRepo.updateActivePlanModules(
        userId: user.id,
        activePlan: activePlan,
        updatedDraft: updatedDraft,
        updatedAt: DateTime.now(),
      );

      return await updatedPlanEither.fold(
        (Failure f) async => Left<Failure, HolisticPlan>(f),
        (HolisticPlan updatedPlan) async {
          final Either<Failure, UserProfile> profileEither =
              await profileRepo.getProfile(user.id);
          return await profileEither.fold(
            (Failure f) async {
              LoggerService.e(
                'amendActivePlanModuleAndSyncProfile profile fetch',
                f,
                StackTrace.current,
              );
              return Right<Failure, HolisticPlan>(updatedPlan);
            },
            (UserProfile current) async {
              final UserProfile updated = current.copyWith(
                dailyStepGoal: updatedPlan.dailyTargets.dailyStepGoal,
                dailyCalorieGoal: updatedPlan.dailyTargets.dailyCalorieGoal,
                dailySleepGoalMinutes: updatedPlan.dailyTargets.dailySleepGoalMinutes,
                dailyWaterGoalMl: updatedPlan.dailyTargets.dailyWaterGoalMl,
                dailyWorkoutGoalMinutes:
                    updatedPlan.dailyTargets.dailyWorkoutGoalMinutes,
                updatedAt: DateTime.now(),
              );
              final Either<Failure, Unit> updatedResult =
                  await profileRepo.updateProfile(updated);
              return updatedResult.fold(
                (Failure f) {
                  LoggerService.e(
                    'amendActivePlanModuleAndSyncProfile profile update',
                    f,
                    StackTrace.current,
                  );
                  return Right<Failure, HolisticPlan>(updatedPlan);
                },
                (_) => Right<Failure, HolisticPlan>(updatedPlan),
              );
            },
          );
        },
      );
    },
  );
}

/// Algorithmic duration in days based on availability/intensity + target shift.
///
/// - `availabilityIdx`: 0=Low, 1=Medium, 2=High
/// - `intensityIdx`: 0=Easy, 1=Balanced, 2=Push
/// - `targetRatio`: newTarget / currentTarget (for the specific module target)
int computeHolisticPlanDurationDays({
  required int availabilityIdx,
  required int intensityIdx,
  required double targetRatio,
}) {
  final List<int> availabilityBase = <int>[14, 30, 45];
  final List<double> intensityFactor = <double>[1.0, 0.95, 0.85];

  final int baseDays = availabilityBase[availabilityIdx.clamp(0, 2)];
  final double iFactor = intensityFactor[intensityIdx.clamp(0, 2)];

  final double ratio = targetRatio.isFinite && targetRatio > 0 ? targetRatio : 1.0;
  final double targetFactor = ratio >= 1.3
      ? 1.15
      : ratio >= 1.1
          ? 1.05
          : ratio <= 0.7
              ? 0.85
              : ratio <= 0.9
                  ? 0.95
                  : 1.0;

  final int days = (baseDays * iFactor * targetFactor).round();
  return days.clamp(7, 90);
}

