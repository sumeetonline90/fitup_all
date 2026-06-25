import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/activity.dart';
import '../entities/activity_stats.dart';
import '../entities/sleep_log.dart';

/// Activity + sleep persistence (remote + local sync).
abstract class ActivityRepository {
  Future<Either<Failure, Activity>> saveActivity(Activity activity);

  Future<Either<Failure, List<Activity>>> getActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  });

  Stream<List<Activity>> watchTodayActivities(String userId);

  Future<Either<Failure, ActivityStats>> getStats(
    String userId,
    DateTime from,
    DateTime to,
  );

  Future<Either<Failure, void>> deleteActivity(String activityId);

  Future<Either<Failure, SleepLog>> saveSleepLog(SleepLog log);

  Future<Either<Failure, List<SleepLog>>> getSleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  });
}
