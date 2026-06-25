import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_model.dart';
import '../models/water_log_model.dart';

/// Firestore access for diet collections.
class DietRemoteDatasource {
  DietRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _meals(String userId) =>
      _firestore.collection('users').doc(userId).collection('meals');

  CollectionReference<Map<String, dynamic>> _water(String userId) =>
      _firestore.collection('users').doc(userId).collection('water_logs');

  Future<void> setMeal(String mealId, MealModel model) async {
    await _meals(model.userId).doc(mealId).set(model.toFirestore());
  }

  Future<void> deleteMeal(String userId, String mealId) async {
    await _meals(userId).doc(mealId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryMealsInRange(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    return _meals(userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMealsInRange(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    return _meals(userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dateTime', isLessThan: Timestamp.fromDate(to))
        .snapshots();
  }

  Future<void> setWaterLog(String logId, WaterLogModel model) async {
    await _water(model.userId).doc(logId).set(model.toFirestore());
  }

  Future<void> deleteWaterLog(String userId, String logId) async {
    await _water(userId).doc(logId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryWaterForDay(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _water(userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThan: Timestamp.fromDate(end))
        .get();
  }
}
