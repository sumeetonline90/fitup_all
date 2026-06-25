import 'package:drift/drift.dart';

import 'connection_io.dart' if (dart.library.html) 'connection_web.dart' as impl;

QueryExecutor openDriftConnection() => impl.openDriftConnection();
