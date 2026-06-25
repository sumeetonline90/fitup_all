import 'package:flutter/foundation.dart';

import 'emergency_contact.dart';
import 'profile_enums.dart';

/// Extended user profile (Firestore `users/{uid}` + domain).
@immutable
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.isOnboarded = false,
    this.goals = const <HealthGoal>[],
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.targetWeightDate,
    this.useMetricUnits = true,
    this.dietType = DietType.vegetarian,
    this.cuisines = const <String>[],
    this.allergies = const <String>[],
    this.fitnessLevel = FitnessLevel.beginner,
    this.activityLevel = ActivityLevel.lightlyActive,
    this.healthConditions = const <String>[],
    this.medicationsNote = '',
    this.emergencyContacts = const <EmergencyContact>[],
    this.progressPhotoUrls = const <String, String>{},
    this.currentStreakDays = 0,
    this.dailyStepGoal,
    this.dailyCalorieGoal,
    this.dailySleepGoalMinutes,
    this.dailyWaterGoalMl,
    this.dailyWorkoutGoalMinutes,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionRenewal,
    this.updatedAt,
    this.onboardingCompletedAt,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final bool isOnboarded;
  final List<HealthGoal> goals;
  final ProfileGender? gender;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final DateTime? targetWeightDate;
  final bool useMetricUnits;
  final DietType dietType;
  final List<String> cuisines;
  final List<String> allergies;
  final FitnessLevel fitnessLevel;
  final ActivityLevel activityLevel;
  final List<String> healthConditions;
  final String medicationsNote;
  final List<EmergencyContact> emergencyContacts;
  /// Slot key: `front` | `side` | `back` → download URL.
  final Map<String, String> progressPhotoUrls;
  final int currentStreakDays;
  final int? dailyStepGoal;
  final int? dailyCalorieGoal;
  final int? dailySleepGoalMinutes;
  final int? dailyWaterGoalMl;
  final int? dailyWorkoutGoalMinutes;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionRenewal;
  final DateTime? updatedAt;
  final DateTime? onboardingCompletedAt;

  /// Gate for shell routes (same as Firestore `isOnboarded` / `onboardingComplete`).
  bool get onboardingComplete => isOnboarded;

  /// BMI from height/weight when both set; else null.
  double? get bmi {
    final double? h = heightCm;
    final double? w = weightKg;
    if (h == null || w == null || h <= 0) {
      return null;
    }
    final double m = h / 100;
    return w / (m * m);
  }

  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isOnboarded,
    List<HealthGoal>? goals,
    ProfileGender? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    DateTime? targetWeightDate,
    bool? useMetricUnits,
    DietType? dietType,
    List<String>? cuisines,
    List<String>? allergies,
    FitnessLevel? fitnessLevel,
    ActivityLevel? activityLevel,
    List<String>? healthConditions,
    String? medicationsNote,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String>? progressPhotoUrls,
    int? currentStreakDays,
    int? dailyStepGoal,
    int? dailyCalorieGoal,
    int? dailySleepGoalMinutes,
    int? dailyWaterGoalMl,
    int? dailyWorkoutGoalMinutes,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionRenewal,
    DateTime? updatedAt,
    DateTime? onboardingCompletedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      goals: goals ?? this.goals,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetWeightDate: targetWeightDate ?? this.targetWeightDate,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      dietType: dietType ?? this.dietType,
      cuisines: cuisines ?? this.cuisines,
      allergies: allergies ?? this.allergies,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      medicationsNote: medicationsNote ?? this.medicationsNote,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      progressPhotoUrls: progressPhotoUrls ?? this.progressPhotoUrls,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailySleepGoalMinutes:
          dailySleepGoalMinutes ?? this.dailySleepGoalMinutes,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      dailyWorkoutGoalMinutes:
          dailyWorkoutGoalMinutes ?? this.dailyWorkoutGoalMinutes,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionRenewal: subscriptionRenewal ?? this.subscriptionRenewal,
      updatedAt: updatedAt ?? this.updatedAt,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }
}
