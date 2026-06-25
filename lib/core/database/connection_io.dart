import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Opens SQLite on Android / iOS / desktop.
QueryExecutor openDriftConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'fitup.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
