import 'package:drift/drift.dart';

/// Web: local Drift is not opened — use [InMemoryActivityLocalDataSource].
QueryExecutor openDriftConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError('FitupDatabase is not used on web; use in-memory cache.');
  });
}
