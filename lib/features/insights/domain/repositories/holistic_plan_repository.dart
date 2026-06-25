import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/holistic_plan.dart';

/// Offline-first holistic plan persistence (Drift) + best-effort sync
/// (Firestore) for UI to work without internet.
abstract class HolisticPlanRepository {
  Future<Either<Failure, HolisticPlan?>> getActivePlan(String userId);

  Future<Either<Failure, HolisticPlan>> saveNewActivePlan({
    required String userId,
    required HolisticPlanDraft draft,
    required DateTime generatedAt,
  });

  /// Updates the currently active plan content while preserving
  /// the plan's `startDate`/`endDate` (holistic plan reset happens only
  /// when the user explicitly regenerates the holistic plan).
  Future<Either<Failure, HolisticPlan>> updateActivePlanModules({
    required String userId,
    required HolisticPlan activePlan,
    required HolisticPlanDraft updatedDraft,
    required DateTime updatedAt,
  });

  Future<Either<Failure, PlanDailyCheck?>> getDailyCheck({
    required String userId,
    required String holisticPlanId,
    required String dateKey,
  });

  Future<Either<Failure, Unit>> upsertDailyCheck({
    required String userId,
    required PlanDailyCheck check,
  });

  /// Called by [SyncService] when connectivity returns.
  Future<Either<Failure, Unit>> flushPendingPlansToRemote({
    required String userId,
  });
}

