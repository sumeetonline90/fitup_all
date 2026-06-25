import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart' show Either;

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/domain/entities/fitup_user.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';
import '../../../../features/insights/domain/repositories/holistic_plan_repository.dart';

/// Active holistic plan for the currently signed-in user (offline-first read).
final activeHolisticPlanProvider = FutureProvider<HolisticPlan?>(
  (final Ref ref) async {
    final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
    final FitupUser? user = switch (auth) {
      AsyncData<FitupUser?>(:final value) => value,
      _ => null,
    };

    if (user == null) {
      return null;
    }

    final HolisticPlanRepository repo = getIt<HolisticPlanRepository>();
    final Either<Failure, HolisticPlan?> result = await repo.getActivePlan(user.id);
    return result.fold((_) => null, (HolisticPlan? p) => p);
  },
);

