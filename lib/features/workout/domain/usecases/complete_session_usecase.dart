import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Persists a finished session, computes Fitcoins, merges PRs on the server.
class CompleteSessionUseCase {
  CompleteSessionUseCase(this._repository);

  final WorkoutRepository _repository;

  /// [baseFitcoins] optional override; default uses duration tiers + PR bonus.
  Future<Either<Failure, WorkoutLog>> call(
    WorkoutLog draft, {
    int? baseFitcoins,
  }) async {
    final int fitcoins = baseFitcoins ?? _computeFitcoins(draft);
    final WorkoutLog enriched = draft.copyWith(fitcoinsEarned: fitcoins);
    return _repository.saveWorkoutLog(enriched);
  }

  /// Under 20 min → 5 FTC; 20–45 min → 15 FTC; 45+ min → 25 FTC; +10 if any new PR.
  int _computeFitcoins(WorkoutLog log) {
    final int durationMin = log.endTime
        .difference(log.startTime)
        .inMinutes
        .clamp(0, 600);
    int base;
    if (durationMin < 20) {
      base = 5;
    } else if (durationMin < 45) {
      base = 15;
    } else {
      base = 25;
    }
    final bool anyPr =
        log.completedSets.any((CompletedSet s) => s.isPersonalRecord);
    if (anyPr) {
      base += 10;
    }
    return base;
  }
}
