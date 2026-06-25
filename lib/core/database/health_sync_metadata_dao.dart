import 'package:drift/drift.dart';

import 'fitup_database.dart';

/// Local persistence for Health Connect / HealthKit sync timestamps.
///
/// Used to backfill missed step days after app absence.
class HealthSyncMetadataDao {
  HealthSyncMetadataDao(this._db);

  final FitupDatabase _db;

  Future<HealthSyncMetadataData?> get() async {
    return (_db.select(_db.healthSyncMetadata)
          ..where(($HealthSyncMetadataTable t) => t.id.equals('singleton')))
        .getSingleOrNull();
  }

  /// Upsert by updating only the provided fields.
  Future<void> upsert({
    DateTime? lastStepSyncAt,
    DateTime? lastSleepSyncAt,
    DateTime? lastCalorieSyncAt,
    DateTime? lastHeartRateSyncAt,
  }) async {
    await _db.into(_db.healthSyncMetadata).insertOnConflictUpdate(
          HealthSyncMetadataCompanion.insert(
            id: const Value('singleton'),
            lastStepSyncAt: lastStepSyncAt != null
                ? Value<DateTime?>(lastStepSyncAt)
                : const Value.absent(),
            lastSleepSyncAt: lastSleepSyncAt != null
                ? Value<DateTime?>(lastSleepSyncAt)
                : const Value.absent(),
            lastCalorieSyncAt: lastCalorieSyncAt != null
                ? Value<DateTime?>(lastCalorieSyncAt)
                : const Value.absent(),
            lastHeartRateSyncAt: lastHeartRateSyncAt != null
                ? Value<DateTime?>(lastHeartRateSyncAt)
                : const Value.absent(),
          ),
        );
  }
}

