import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workout_model.dart';

/// Firestore paths for workout data.
class WorkoutRemoteDatasource {
  WorkoutRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _plans(String userId) =>
      _firestore.collection('users').doc(userId).collection('workout_plans');

  CollectionReference<Map<String, dynamic>> _logs(String userId) =>
      _firestore.collection('users').doc(userId).collection('workout_logs');

  CollectionReference<Map<String, dynamic>> _prs(String userId) =>
      _firestore.collection('users').doc(userId).collection('personal_records');

  Future<void> setWorkoutPlan(String planId, WorkoutPlanModel model) async {
    await _plans(model.userId).doc(planId).set(model.toJson());
  }

  Future<void> deleteWorkoutPlan(String userId, String planId) async {
    await _plans(userId).doc(planId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getWorkoutPlans(
    String userId,
  ) {
    return _plans(userId).orderBy('createdAt', descending: true).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getActiveWorkoutPlan(
    String userId,
  ) {
    return _plans(userId).where('isActive', isEqualTo: true).limit(1).get();
  }

  Future<void> setWorkoutLog(String logId, WorkoutLogModel model) async {
    await _logs(model.userId).doc(logId).set(model.toJson());
  }

  /// Fetches recent logs; [dateFrom]/[dateTo] applied in repository to avoid extra indexes.
  Future<QuerySnapshot<Map<String, dynamic>>> queryWorkoutLogs(
    String userId,
  ) {
    return _logs(userId)
        .orderBy('startTime', descending: true)
        .limit(500)
        .get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchWorkoutLogs(String userId) {
    return _logs(userId).orderBy('startTime', descending: true).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPersonalRecords(
    String userId,
  ) {
    return _prs(userId).get();
  }

  Future<void> setPersonalRecord(
    String userId,
    String exerciseId,
    PersonalRecordModel model,
  ) async {
    await _prs(userId).doc(exerciseId).set(model.toJson());
  }
}
