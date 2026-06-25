import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/database/fitup_database.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../app_settings_codec.dart';

Failure _map(Object e) {
  if (e is FirebaseException) {
    return ProfileFailure(e.message ?? e.code);
  }
  return ProfileFailure(e.toString());
}

/// `users/{userId}/settings/preferences` + Drift cache.
class FirebaseAppSettingsRepository implements AppSettingsRepository {
  FirebaseAppSettingsRepository(
    this._firestore, {
    FitupDatabase? database,
  }) : _db = database;

  final FirebaseFirestore _firestore;
  final FitupDatabase? _db;

  DocumentReference<Map<String, dynamic>> _prefsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('settings').doc('preferences');

  Future<void> _writeCache(String userId, AppSettings s) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    await db.into(db.appSettingsCache).insertOnConflictUpdate(
          AppSettingsCacheCompanion.insert(
            userId: userId,
            payloadJson: AppSettingsCodec.toJsonString(s),
            syncedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Either<Failure, AppSettings>> getSettings(String userId) async {
    try {
      final FitupDatabase? db = _db;
      if (db != null) {
        final AppSettingsCacheRow? row =
            await (db.select(db.appSettingsCache)
                  ..where((AppSettingsCache tbl) => tbl.userId.equals(userId)))
                .getSingleOrNull();
        if (row != null) {
          return Right<Failure, AppSettings>(
            AppSettingsCodec.fromJsonString(row.payloadJson),
          );
        }
      }
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _prefsRef(userId).get();
      if (!doc.exists) {
        final AppSettings def = AppSettings.defaults();
        await _prefsRef(userId).set(AppSettingsCodec.toFirestore(def));
        await _writeCache(userId, def);
        return Right<Failure, AppSettings>(def);
      }
      final AppSettings s = AppSettingsCodec.fromFirestore(doc);
      await _writeCache(userId, s);
      return Right<Failure, AppSettings>(s);
    } catch (e, _) {
      return Left<Failure, AppSettings>(_map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(
    String userId,
    AppSettings settings,
  ) async {
    try {
      await _writeCache(userId, settings);
    } catch (e) {
      return Left<Failure, Unit>(_map(e));
    }
    try {
      await _prefsRef(userId).set(
        AppSettingsCodec.toFirestore(settings),
        SetOptions(merge: true),
      );
      await _writeCache(userId, settings);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      if (kDebugMode) {
        // Firestore failed — cache remains source of truth.
      }
      try {
        await _writeCache(userId, settings);
      } catch (_) {}
      return const Right<Failure, Unit>(unit);
    }
  }

  @override
  Stream<AppSettings> watchSettings(String userId) {
    return _prefsRef(userId).snapshots().asyncMap(
      (DocumentSnapshot<Map<String, dynamic>> doc) async {
        if (!doc.exists) {
          final AppSettings def = AppSettings.defaults();
          await _prefsRef(userId).set(AppSettingsCodec.toFirestore(def));
          await _writeCache(userId, def);
          return def;
        }
        final AppSettings s = AppSettingsCodec.fromFirestore(doc);
        await _writeCache(userId, s);
        return s;
      },
    );
  }
}
