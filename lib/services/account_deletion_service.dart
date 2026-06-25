import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/services/logger_service.dart';

/// Client-side cascade before Firebase Auth delete. Server-side
/// `auth.user().onDelete` Cloud Function should mirror this for any paths the client misses.
class AccountDeletionService {
  AccountDeletionService(
    this._firestore,
    this._storage, {
    FitupDatabase? database,
  }) : _db = database;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FitupDatabase? _db;

  static const String _users = 'users';

  /// Deletes Firestore user subtree, Storage files, and local Drift rows for [userId].
  /// Does **not** delete the Auth user — caller must call [User.delete] after this succeeds.
  Future<Either<Failure, Unit>> deleteAllUserData(String userId) async {
    try {
      final DocumentReference<Map<String, dynamic>> root =
          _firestore.collection(_users).doc(userId);

      for (final String sub in _userSubcollections) {
        await _deleteCollection(root.collection(sub));
      }
      await root.delete();
      await _deleteStorageTree(userId);
      final FitupDatabase? db = _db;
      if (db != null) {
        await db.clearAllUserData(userId);
      }
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('deleteAllUserData', e, st);
      return Left<Failure, Unit>(ServerFailure(e.toString()));
    }
  }

  /// Known first-level subcollections under `users/{uid}` used by the app.
  static const List<String> _userSubcollections = <String>[
    'settings',
    'following',
    'followers',
    'feed_inbox',
    'blocked_users',
    'fitcoin_wallet',
    'fitcoin_transactions',
    'fitcoin_awards',
    'activities',
    'sleepLogs',
    'meals',
    'water_logs',
    'workout_plans',
    'workout_logs',
    'personal_records',
    'custom_exercises',
    'custom_foods',
    'vitals',
    'labReports',
    'medications',
    'menstrualCycles',
    'moods',
    'surveys',
    'breathingSessions',
    'meditationSessions',
    'stressScores',
    'dailyBriefings',
    'weeklyReports',
    'correlationAlerts',
    'chatHistory',
    'goalAdjustments',
  ];

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snap =
          await col.limit(500).get();
      if (snap.docs.isEmpty) {
        return;
      }
      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteStorageTree(String userId) async {
    final Reference root = _storage.ref().child('users').child(userId);
    await _deleteRefRecursive(root);
  }

  Future<void> _deleteRefRecursive(Reference ref) async {
    final ListResult list = await ref.listAll();
    for (final Reference item in list.items) {
      try {
        await item.delete();
      } catch (e, st) {
        LoggerService.w('Storage delete item', e, st);
      }
    }
    for (final Reference prefix in list.prefixes) {
      await _deleteRefRecursive(prefix);
    }
  }
}
