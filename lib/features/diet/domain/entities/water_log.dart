import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_log.freezed.dart';

@freezed
abstract class WaterLog with _$WaterLog {
  const factory WaterLog({
    required String id,
    required String userId,
    required double amountMl,
    required DateTime dateTime,
  }) = _WaterLog;
}
