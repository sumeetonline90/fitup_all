import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_log.freezed.dart';

/// Sleep session from manual entry or Health Connect / HealthKit.
@freezed
abstract class SleepLog with _$SleepLog {
  const factory SleepLog({
    required String id,
    required String userId,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMinutes,
    double? quality,
    required String source,
  }) = _SleepLog;
}
