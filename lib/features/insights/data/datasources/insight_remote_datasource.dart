import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore paths under `users/{uid}/…`.
class InsightRemoteDatasource {
  InsightRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _daily(String userId) =>
      _firestore.collection('users').doc(userId).collection('dailyBriefings');

  CollectionReference<Map<String, dynamic>> _weekly(String userId) =>
      _firestore.collection('users').doc(userId).collection('weeklyReports');

  CollectionReference<Map<String, dynamic>> _alerts(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('correlationAlerts');

  CollectionReference<Map<String, dynamic>> _chat(String userId) =>
      _firestore.collection('users').doc(userId).collection('chatHistory');

  CollectionReference<Map<String, dynamic>> _goals(String userId) =>
      _firestore.collection('users').doc(userId).collection('goalAdjustments');

  Future<void> setDailyBriefing(
    String userId,
    String dateKey,
    Map<String, dynamic> data,
  ) => _daily(userId).doc(dateKey).set(data);

  Future<void> setWeeklyReport(
    String userId,
    String weekKey,
    Map<String, dynamic> data,
  ) => _weekly(userId).doc(weekKey).set(data);

  Future<void> setAlert(String userId, String id, Map<String, dynamic> data) =>
      _alerts(userId).doc(id).set(data);

  Future<void> dismissAlert(String userId, String alertId) => _alerts(
    userId,
  ).doc(alertId).update(<String, dynamic>{'isDismissed': true});

  Future<QuerySnapshot<Map<String, dynamic>>> queryActiveAlerts(String userId) {
    return _alerts(
      userId,
    ).where('isDismissed', isEqualTo: false).limit(50).get();
  }

  Future<void> setChatMessage(
    String userId,
    String msgId,
    Map<String, dynamic> data,
  ) => _chat(userId).doc(msgId).set(data);

  Future<QuerySnapshot<Map<String, dynamic>>> queryChatHistory(
    String userId,
    int limit,
  ) {
    return _chat(
      userId,
    ).orderBy('timestamp', descending: true).limit(limit).get();
  }

  Future<void> setGoalAdjustment(
    String userId,
    String id,
    Map<String, dynamic> data,
  ) => _goals(userId).doc(id).set(data);

  Future<QuerySnapshot<Map<String, dynamic>>> queryLatestGoalAdjustment(
    String userId,
  ) {
    return _goals(
      userId,
    ).orderBy('generatedAt', descending: true).limit(1).get();
  }
}
