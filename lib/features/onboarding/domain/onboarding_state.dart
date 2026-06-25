import '../../profile/domain/entities/emergency_contact.dart';
import '../../profile/domain/entities/profile_enums.dart';
import '../../profile/domain/entities/user_profile.dart';

/// Wizard UI state — persisted to Drift between steps (Phase 8.1).
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.goals = const <HealthGoal>{
      HealthGoal.improveOverallHealth,
    },
    this.gender,
    this.dateOfBirth,
    this.heightCm = 170,
    this.weightKg = 70,
    this.targetWeightKg,
    this.useMetricUnits = true,
    this.dietType = DietType.vegetarian,
    this.cuisines = const <String>[],
    this.allergies = const <String>[],
    this.fitnessLevel = FitnessLevel.beginner,
    this.activityLevel = ActivityLevel.lightlyActive,
    this.healthConditions = const <String>[],
    this.medicationsNote = '',
    this.emergencyContacts = const <EmergencyContact>[],
  });

  final int currentStep;
  final Set<HealthGoal> goals;
  final ProfileGender? gender;
  final DateTime? dateOfBirth;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final bool useMetricUnits;
  final DietType dietType;
  final List<String> cuisines;
  final List<String> allergies;
  final FitnessLevel fitnessLevel;
  final ActivityLevel activityLevel;
  final List<String> healthConditions;
  final String medicationsNote;
  final List<EmergencyContact> emergencyContacts;

  OnboardingState copyWith({
    int? currentStep,
    Set<HealthGoal>? goals,
    ProfileGender? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
    DietType? dietType,
    List<String>? cuisines,
    List<String>? allergies,
    FitnessLevel? fitnessLevel,
    ActivityLevel? activityLevel,
    List<String>? healthConditions,
    String? medicationsNote,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      goals: goals ?? this.goals,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      dietType: dietType ?? this.dietType,
      cuisines: cuisines ?? this.cuisines,
      allergies: allergies ?? this.allergies,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      medicationsNote: medicationsNote ?? this.medicationsNote,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  UserProfile toUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? phone,
    bool isOnboarded = true,
  }) {
    return UserProfile(
      userId: userId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      phone: phone,
      isOnboarded: isOnboarded,
      goals: goals.toList(),
      gender: gender,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      useMetricUnits: useMetricUnits,
      dietType: dietType,
      cuisines: cuisines,
      allergies: allergies,
      fitnessLevel: fitnessLevel,
      activityLevel: activityLevel,
      healthConditions: healthConditions,
      medicationsNote: medicationsNote,
      emergencyContacts: emergencyContacts,
      updatedAt: DateTime.now(),
    );
  }
}
