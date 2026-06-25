import 'package:cloud_firestore/cloud_firestore.dart';

class MentalWellbeingRemoteDatasource {
  MentalWellbeingRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _moods(String userId) =>
      _firestore.collection('users').doc(userId).collection('moods');

  CollectionReference<Map<String, dynamic>> _surveys(String userId) =>
      _firestore.collection('users').doc(userId).collection('surveys');

  CollectionReference<Map<String, dynamic>> _breathing(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('breathingSessions');

  CollectionReference<Map<String, dynamic>> _meditation(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('meditationSessions');

  CollectionReference<Map<String, dynamic>> _stress(String userId) =>
      _firestore.collection('users').doc(userId).collection('stressScores');

  Future<void> setMood(String userId, String id, Map<String, dynamic> data) =>
      _moods(userId).doc(id).set(data);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentMoods(String userId) {
    return _moods(
      userId,
    ).orderBy('recordedAt', descending: true).limit(24).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryMoodHistory(
    String userId,
    DateTime from,
  ) {
    return _moods(userId)
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('recordedAt', descending: true)
        .limit(200)
        .get();
  }

  Future<void> setSurvey(String userId, String id, Map<String, dynamic> data) =>
      _surveys(userId).doc(id).set(data);

  Future<QuerySnapshot<Map<String, dynamic>>> querySurveys(
    String userId,
    String typeName,
    int limit,
  ) {
    return _surveys(userId)
        .where('type', isEqualTo: typeName)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
  }

  Future<void> setBreathing(String userId, String id, Map<String, dynamic> d) =>
      _breathing(userId).doc(id).set(d);

  Future<void> setMeditation(
    String userId,
    String id,
    Map<String, dynamic> d,
  ) => _meditation(userId).doc(id).set(d);

  Future<QuerySnapshot<Map<String, dynamic>>> queryBreathingSince(
    String userId,
    DateTime from,
  ) {
    return _breathing(userId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .limit(200)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryMeditationSince(
    String userId,
    DateTime from,
  ) {
    return _meditation(userId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .limit(200)
        .get();
  }

  Future<void> setStress(String userId, String id, Map<String, dynamic> d) =>
      _stress(userId).doc(id).set(d);

  Future<QuerySnapshot<Map<String, dynamic>>> queryLatestStress(String userId) {
    return _stress(
      userId,
    ).orderBy('calculatedAt', descending: true).limit(1).get();
  }
}
