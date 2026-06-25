import 'package:flutter/foundation.dart';

/// Keys for module-level plan snapshots stored under an active holistic plan.
enum PlanModuleKey {
  activity,
  diet,
  workout,
  mental,
  health,
  community,
}

extension PlanModuleKeyX on PlanModuleKey {
  /// Stable string key for persistence.
  String get key => name;
}

@immutable
class PlanTargets {
  const PlanTargets({
    required this.dailyStepGoal,
    required this.dailyCalorieGoal,
    required this.dailySleepGoalMinutes,
    required this.dailyWaterGoalMl,
    required this.dailyWorkoutGoalMinutes,
  });

  final int dailyStepGoal;
  final int dailyCalorieGoal;
  final int dailySleepGoalMinutes;
  final int dailyWaterGoalMl;
  final int dailyWorkoutGoalMinutes;

  PlanTargets copyWith({
    int? dailyStepGoal,
    int? dailyCalorieGoal,
    int? dailySleepGoalMinutes,
    int? dailyWaterGoalMl,
    int? dailyWorkoutGoalMinutes,
  }) {
    return PlanTargets(
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailySleepGoalMinutes: dailySleepGoalMinutes ?? this.dailySleepGoalMinutes,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      dailyWorkoutGoalMinutes:
          dailyWorkoutGoalMinutes ?? this.dailyWorkoutGoalMinutes,
    );
  }
}

/// AI output / editable snapshot for a module within a holistic plan.
///
/// We keep this as a generic JSON payload so the UI can evolve without
/// repeated migrations.
@immutable
class ModulePlan {
  const ModulePlan({
    required this.moduleKey,
    required this.payload,
  });

  final PlanModuleKey moduleKey;
  final Map<String, dynamic> payload;
}

/// Container for AI-generated output used to create or update a plan.
@immutable
class HolisticPlanDraft {
  const HolisticPlanDraft({
    required this.startDate,
    required this.endDate,
    required this.dailyTargets,
    required this.majorGoals,
    required this.modulePlans,
  });

  final DateTime startDate;
  final DateTime endDate;
  final PlanTargets dailyTargets;
  final List<String> majorGoals;
  final Map<PlanModuleKey, ModulePlan> modulePlans;
}

@immutable
class HolisticPlan {
  const HolisticPlan({
    required this.id,
    required this.userId,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.dailyTargets,
    required this.majorGoals,
    required this.modulePlans,
    required this.generatedAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final PlanTargets dailyTargets;
  final List<String> majorGoals;
  final Map<PlanModuleKey, ModulePlan> modulePlans;
  final DateTime generatedAt;
  final DateTime updatedAt;

  HolisticPlan copyWith({
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    PlanTargets? dailyTargets,
    List<String>? majorGoals,
    Map<PlanModuleKey, ModulePlan>? modulePlans,
    DateTime? updatedAt,
  }) {
    return HolisticPlan(
      id: id,
      userId: userId,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyTargets: dailyTargets ?? this.dailyTargets,
      majorGoals: majorGoals ?? this.majorGoals,
      modulePlans: modulePlans ?? this.modulePlans,
      generatedAt: generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class PlanDailyCheck {
  const PlanDailyCheck({
    required this.id,
    required this.userId,
    required this.holisticPlanId,
    required this.dateKey,
    required this.stepsCompleted,
    required this.caloriesCompleted,
    required this.sleepCompleted,
    required this.waterCompleted,
    required this.workoutCompleted,
    required this.nudgeText,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String holisticPlanId;
  final String dateKey;
  final bool stepsCompleted;
  final bool caloriesCompleted;
  final bool sleepCompleted;
  final bool waterCompleted;
  final bool workoutCompleted;
  final String nudgeText;
  final DateTime updatedAt;

  bool get onTrack =>
      stepsCompleted &&
      caloriesCompleted &&
      sleepCompleted &&
      waterCompleted &&
      workoutCompleted;
}

