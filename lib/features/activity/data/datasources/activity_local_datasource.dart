import '../../domain/entities/activity.dart';
import '../../domain/entities/sleep_log.dart';

/// Offline activity + sleep cache (Drift or in-memory on web).
abstract class ActivityLocalDataSource {
  Future<void> saveActivityLocal(Activity activity, {required bool synced});

  /// Inserts or updates a synthetic passive-steps record for the given day.
  ///
  /// This is used by health backfill logic so step-goal checks see wearable
  /// steps even if the user was away for multiple days.
  Future<void> upsertPassiveStepsForDate({
    required DateTime date,
    required int steps,
    required String userId,
  });

  Future<void> deleteActivityLocal(String activityId);

  Future<List<Activity>> queryActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  });

  Stream<List<Activity>> watchTodayActivities(String userId);

  Future<List<SleepLog>> querySleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  });

  Future<void> saveSleepLogLocal(SleepLog log, {required bool synced});

  Future<void> enqueueSync({
    required String id,
    required String userId,
    required String resourceType,
    required String payloadJson,
  });

  Future<void> dequeueSync(String id);

  Future<void> markActivitySynced(String activityId);

  Future<void> markSleepSynced(String sleepId);
}
