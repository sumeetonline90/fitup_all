import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/profile_enums.dart';
import '../../domain/entities/user_profile.dart';

/// Maps Firestore `users/{uid}` extended fields to [UserProfile].
class UserProfileModel {
  UserProfileModel._();

  static UserProfile fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> d = doc.data() ?? <String, dynamic>{};
    final Timestamp? updated = d['profileUpdatedAt'] as Timestamp?;
    final Timestamp? renewal = d['subscriptionRenewal'] as Timestamp?;
    final Timestamp? dob = d['dateOfBirth'] as Timestamp?;
    final Timestamp? targetWeightDate = d['targetWeightDate'] as Timestamp?;

    return UserProfile(
      userId: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      phone: d['phone'] as String?,
      isOnboarded: d['isOnboarded'] as bool? ??
          d['onboardingComplete'] as bool? ??
          false,
      goals: _parseGoals(d['goals']),
      gender: _parseGender(d['gender'] as String?),
      dateOfBirth: dob?.toDate(),
      heightCm: (d['heightCm'] as num?)?.toDouble(),
      weightKg: (d['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (d['targetWeightKg'] as num?)?.toDouble(),
      targetWeightDate: targetWeightDate?.toDate(),
      useMetricUnits: d['useMetricUnits'] as bool? ?? true,
      dietType: _parseDiet(d['dietType'] as String?),
      cuisines: _stringList(d['cuisines']),
      allergies: _stringList(d['allergies']),
      fitnessLevel: _parseFitness(d['fitnessLevel'] as String?),
      activityLevel: _parseActivity(d['activityLevel'] as String?),
      healthConditions: _stringList(d['healthConditions']),
      medicationsNote: d['medicationsNote'] as String? ?? '',
      emergencyContacts: _parseContacts(d['emergencyContacts']),
      progressPhotoUrls: _parseUrlMap(d['progressPhotoUrls']),
      currentStreakDays: (d['currentStreakDays'] as num?)?.toInt() ?? 0,
      dailyStepGoal: (d['dailyStepGoal'] as num?)?.toInt(),
      dailyCalorieGoal: (d['dailyCalorieGoal'] as num?)?.toInt(),
      dailySleepGoalMinutes: (d['dailySleepGoalMinutes'] as num?)?.toInt(),
      dailyWaterGoalMl: (d['dailyWaterGoalMl'] as num?)?.toInt(),
      dailyWorkoutGoalMinutes:
          (d['dailyWorkoutGoalMinutes'] as num?)?.toInt(),
      subscriptionTier: _parseTier(d['subscriptionTier'] as String?),
      subscriptionRenewal: renewal?.toDate(),
      updatedAt: updated?.toDate(),
      onboardingCompletedAt:
          (d['onboardingCompletedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Drift / JSON cache (JSON-safe only).
  static String toCacheJson(UserProfile p) {
    return jsonEncode(toPlainMap(p));
  }

  static Map<String, dynamic> toPlainMap(UserProfile p) {
    return <String, dynamic>{
      'userId': p.userId,
      'email': p.email,
      'displayName': p.displayName,
      'photoUrl': p.photoUrl,
      'phone': p.phone,
      'isOnboarded': p.isOnboarded,
      'goals': p.goals.map((HealthGoal e) => e.name).toList(),
      'gender': p.gender?.name,
      'dateOfBirth': p.dateOfBirth?.toIso8601String(),
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'targetWeightKg': p.targetWeightKg,
      'targetWeightDate': p.targetWeightDate?.toIso8601String(),
      'useMetricUnits': p.useMetricUnits,
      'dietType': p.dietType.name,
      'cuisines': p.cuisines,
      'allergies': p.allergies,
      'fitnessLevel': p.fitnessLevel.name,
      'activityLevel': p.activityLevel.name,
      'healthConditions': p.healthConditions,
      'medicationsNote': p.medicationsNote,
      'emergencyContacts': p.emergencyContacts
          .map(
            (EmergencyContact c) => <String, String>{
              'name': c.name,
              'phone': c.phone,
              'relationship': c.relationship,
            },
          )
          .toList(),
      'progressPhotoUrls': p.progressPhotoUrls,
      'currentStreakDays': p.currentStreakDays,
      'dailyStepGoal': p.dailyStepGoal,
      'dailyCalorieGoal': p.dailyCalorieGoal,
      'dailySleepGoalMinutes': p.dailySleepGoalMinutes,
      'dailyWaterGoalMl': p.dailyWaterGoalMl,
      'dailyWorkoutGoalMinutes': p.dailyWorkoutGoalMinutes,
      'subscriptionTier': p.subscriptionTier.name,
      'subscriptionRenewal': p.subscriptionRenewal?.toIso8601String(),
      'onboardingCompletedAt': p.onboardingCompletedAt?.toIso8601String(),
      'onboardingComplete': p.isOnboarded,
      'profileUpdatedAt': p.updatedAt?.toIso8601String(),
    };
  }

  static UserProfile fromCacheJson(String raw) {
    final Map<String, dynamic> m =
        jsonDecode(raw) as Map<String, dynamic>;
    return fromPlainMap(m);
  }

  static UserProfile fromPlainMap(Map<String, dynamic> d) {
    final String userId = d['userId'] as String? ?? '';
    return UserProfile(
      userId: userId,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      phone: d['phone'] as String?,
      isOnboarded: d['isOnboarded'] as bool? ??
          d['onboardingComplete'] as bool? ??
          false,
      goals: _parseGoals(d['goals']),
      gender: _parseGender(d['gender'] as String?),
      dateOfBirth: _parseIso(d['dateOfBirth'] as String?),
      heightCm: (d['heightCm'] as num?)?.toDouble(),
      weightKg: (d['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (d['targetWeightKg'] as num?)?.toDouble(),
      targetWeightDate: _parseIso(d['targetWeightDate'] as String?),
      useMetricUnits: d['useMetricUnits'] as bool? ?? true,
      dietType: _parseDiet(d['dietType'] as String?),
      cuisines: _stringList(d['cuisines']),
      allergies: _stringList(d['allergies']),
      fitnessLevel: _parseFitness(d['fitnessLevel'] as String?),
      activityLevel: _parseActivity(d['activityLevel'] as String?),
      healthConditions: _stringList(d['healthConditions']),
      medicationsNote: d['medicationsNote'] as String? ?? '',
      emergencyContacts: _parseContacts(d['emergencyContacts']),
      progressPhotoUrls: _parseUrlMap(d['progressPhotoUrls']),
      currentStreakDays: (d['currentStreakDays'] as num?)?.toInt() ?? 0,
      dailyStepGoal: (d['dailyStepGoal'] as num?)?.toInt(),
      dailyCalorieGoal: (d['dailyCalorieGoal'] as num?)?.toInt(),
      dailySleepGoalMinutes: (d['dailySleepGoalMinutes'] as num?)?.toInt(),
      dailyWaterGoalMl: (d['dailyWaterGoalMl'] as num?)?.toInt(),
      dailyWorkoutGoalMinutes:
          (d['dailyWorkoutGoalMinutes'] as num?)?.toInt(),
      subscriptionTier: _parseTier(d['subscriptionTier'] as String?),
      subscriptionRenewal: _parseIso(d['subscriptionRenewal'] as String?),
      updatedAt: _parseIso(d['profileUpdatedAt'] as String?),
      onboardingCompletedAt: _parseIso(d['onboardingCompletedAt'] as String?),
    );
  }

  static DateTime? _parseIso(String? s) {
    if (s == null) {
      return null;
    }
    return DateTime.tryParse(s);
  }

  static Map<String, dynamic> toFirestore(UserProfile p) {
    return <String, dynamic>{
      'email': p.email,
      'displayName': p.displayName,
      'photoUrl': p.photoUrl,
      'phone': p.phone,
      'isOnboarded': p.isOnboarded,
      'goals': p.goals.map((HealthGoal e) => e.name).toList(),
      'gender': p.gender?.name,
      'dateOfBirth': p.dateOfBirth != null
          ? Timestamp.fromDate(p.dateOfBirth!)
          : null,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'targetWeightKg': p.targetWeightKg,
      'targetWeightDate': p.targetWeightDate != null
          ? Timestamp.fromDate(p.targetWeightDate!)
          : null,
      'useMetricUnits': p.useMetricUnits,
      'dietType': p.dietType.name,
      'cuisines': p.cuisines,
      'allergies': p.allergies,
      'fitnessLevel': p.fitnessLevel.name,
      'activityLevel': p.activityLevel.name,
      'healthConditions': p.healthConditions,
      'medicationsNote': p.medicationsNote,
      'emergencyContacts': p.emergencyContacts
          .map(
            (EmergencyContact c) => <String, String>{
              'name': c.name,
              'phone': c.phone,
              'relationship': c.relationship,
            },
          )
          .toList(),
      'progressPhotoUrls': p.progressPhotoUrls,
      'currentStreakDays': p.currentStreakDays,
      'dailyStepGoal': p.dailyStepGoal,
      'dailyCalorieGoal': p.dailyCalorieGoal,
      'dailySleepGoalMinutes': p.dailySleepGoalMinutes,
      'dailyWaterGoalMl': p.dailyWaterGoalMl,
      'dailyWorkoutGoalMinutes': p.dailyWorkoutGoalMinutes,
      'subscriptionTier': p.subscriptionTier.name,
      'subscriptionRenewal': p.subscriptionRenewal != null
          ? Timestamp.fromDate(p.subscriptionRenewal!)
          : null,
      'onboardingCompletedAt': p.onboardingCompletedAt != null
          ? Timestamp.fromDate(p.onboardingCompletedAt!)
          : null,
      'onboardingComplete': p.isOnboarded,
      'profileUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<HealthGoal> _parseGoals(dynamic raw) {
    if (raw is! List) {
      return <HealthGoal>[];
    }
    final List<HealthGoal> out = <HealthGoal>[];
    for (final Object? o in raw) {
      if (o is! String) {
        continue;
      }
      for (final HealthGoal g in HealthGoal.values) {
        if (g.name == o) {
          out.add(g);
          break;
        }
      }
    }
    return out;
  }

  static ProfileGender? _parseGender(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final ProfileGender g in ProfileGender.values) {
      if (g.name == raw) {
        return g;
      }
    }
    return null;
  }

  static DietType _parseDiet(String? raw) {
    if (raw == null) {
      return DietType.vegetarian;
    }
    for (final DietType t in DietType.values) {
      if (t.name == raw) {
        return t;
      }
    }
    return DietType.vegetarian;
  }

  static FitnessLevel _parseFitness(String? raw) {
    if (raw == null) {
      return FitnessLevel.beginner;
    }
    for (final FitnessLevel f in FitnessLevel.values) {
      if (f.name == raw) {
        return f;
      }
    }
    return FitnessLevel.beginner;
  }

  static ActivityLevel _parseActivity(String? raw) {
    if (raw == null) {
      return ActivityLevel.lightlyActive;
    }
    for (final ActivityLevel a in ActivityLevel.values) {
      if (a.name == raw) {
        return a;
      }
    }
    return ActivityLevel.lightlyActive;
  }

  static SubscriptionTier _parseTier(String? raw) {
    if (raw == 'pro') {
      return SubscriptionTier.pro;
    }
    return SubscriptionTier.free;
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return <String>[];
    }
    return raw.map((Object? e) => '$e').toList();
  }

  static List<EmergencyContact> _parseContacts(dynamic raw) {
    if (raw is! List) {
      return <EmergencyContact>[];
    }
    final List<EmergencyContact> out = <EmergencyContact>[];
    for (final Object? o in raw) {
      if (o is Map<String, dynamic>) {
        out.add(
          EmergencyContact(
            name: o['name'] as String? ?? '',
            phone: o['phone'] as String? ?? '',
            relationship: o['relationship'] as String? ?? '',
          ),
        );
      }
    }
    return out;
  }

  static Map<String, String> _parseUrlMap(dynamic raw) {
    if (raw is! Map) {
      return <String, String>{};
    }
    return raw.map((Object? k, Object? v) => MapEntry('$k', '$v'));
  }
}
