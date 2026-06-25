import '../features/activity/domain/entities/sleep_log.dart';

/// Web stub — Health Connect / HealthKit are not available in the browser.
class HealthConnectService {
  /// Web: no-op constructor (keeps same DI registration as mobile).
  HealthConnectService();

  Future<bool> requestPermissions() async => false;

  Future<int> getTodaySteps() async => 0;

  Future<bool> hasPermissions() async => false;

  Future<Map<DateTime, int>> getStepsForDateRange(
    DateTime from,
    DateTime to,
  ) async =>
      <DateTime, int>{};

  Future<void> syncHistoricalSteps({
    required String userId,
    required Object localDs,
    required Object fitcoinService,
    required Object metadataDao,
    Object? activityRepository,
    bool force = false,
  }) async =>
      {};

  Future<List<SleepLog>> getSleepData(DateTime from, DateTime to) async =>
      <SleepLog>[];

  Future<int?> getCurrentHeartRate() async => null;

  Future<double> getTodayCalories() async => 0;

  /// HRV (ms) when Health Connect exposes it; web always null.
  Future<double?> getLatestHrvMs() async => null;
}
