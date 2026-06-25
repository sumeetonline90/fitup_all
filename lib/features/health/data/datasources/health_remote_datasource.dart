import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vital_entry_model.dart';

class HealthRemoteDatasource {
  HealthRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _vitals(String userId) =>
      _firestore.collection('users').doc(userId).collection('vitals');

  CollectionReference<Map<String, dynamic>> _labs(String userId) =>
      _firestore.collection('users').doc(userId).collection('labReports');

  CollectionReference<Map<String, dynamic>> _meds(String userId) =>
      _firestore.collection('users').doc(userId).collection('medications');

  CollectionReference<Map<String, dynamic>> _menstrual(String userId) =>
      _firestore.collection('users').doc(userId).collection('menstrualCycles');

  Future<void> setVital(String userId, VitalEntryModel model) =>
      _vitals(userId).doc(model.id).set(model.toFirestore());

  Future<void> deleteVital(String userId, String id) =>
      _vitals(userId).doc(id).delete();

  Future<QuerySnapshot<Map<String, dynamic>>> queryVitalsForType(
    String userId,
    String typeName,
    int limit,
  ) {
    return _vitals(userId)
        .where('type', isEqualTo: typeName)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryAllVitals(
    String userId,
    int limit,
  ) {
    return _vitals(
      userId,
    ).orderBy('recordedAt', descending: true).limit(limit).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentVitals(
    String userId,
    int limit,
  ) {
    return _vitals(
      userId,
    ).orderBy('recordedAt', descending: true).limit(limit).snapshots();
  }

  Future<void> setLabReport(
    String userId,
    String id,
    Map<String, dynamic> data,
  ) => _labs(userId).doc(id).set(data);

  Future<QuerySnapshot<Map<String, dynamic>>> queryLabReports(String userId) {
    return _labs(userId).orderBy('scannedAt', descending: true).limit(50).get();
  }

  Future<void> setMedication(
    String userId,
    String id,
    Map<String, dynamic> data,
  ) => _meds(userId).doc(id).set(data);

  Future<void> deleteMedication(String userId, String id) =>
      _meds(userId).doc(id).delete();

  Future<QuerySnapshot<Map<String, dynamic>>> queryActiveMedications(
    String userId,
  ) {
    return _meds(userId).where('isActive', isEqualTo: true).limit(100).get();
  }

  Future<void> setMenstrual(
    String userId,
    String id,
    Map<String, dynamic> data,
  ) => _menstrual(userId).doc(id).set(data);

  Future<QuerySnapshot<Map<String, dynamic>>> queryMenstrual(
    String userId,
    int limit,
  ) {
    return _menstrual(
      userId,
    ).orderBy('cycleStart', descending: true).limit(limit).get();
  }
}
