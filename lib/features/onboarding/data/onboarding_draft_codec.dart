import 'dart:convert';

import '../../profile/domain/entities/emergency_contact.dart';
import '../../profile/domain/entities/profile_enums.dart';
import '../domain/onboarding_state.dart';

/// JSON persistence for [OnboardingState] ↔ `onboarding_draft_cache.payloadJson`.
class OnboardingDraftCodec {
  OnboardingDraftCodec._();

  static String encode(OnboardingState s) {
    return jsonEncode(toMap(s));
  }

  static Map<String, dynamic> toMap(OnboardingState s) {
    return <String, dynamic>{
      'currentStep': s.currentStep,
      'goals': s.goals.map((HealthGoal g) => g.name).toList(),
      'gender': s.gender?.name,
      'dateOfBirthIso': s.dateOfBirth?.toIso8601String(),
      'heightCm': s.heightCm,
      'weightKg': s.weightKg,
      'targetWeightKg': s.targetWeightKg,
      'useMetricUnits': s.useMetricUnits,
      'dietType': s.dietType.name,
      'cuisines': s.cuisines,
      'allergies': s.allergies,
      'fitnessLevel': s.fitnessLevel.name,
      'activityLevel': s.activityLevel.name,
      'healthConditions': s.healthConditions,
      'medicationsNote': s.medicationsNote,
      'emergencyContacts': s.emergencyContacts
          .map(
            (EmergencyContact e) => <String, dynamic>{
              'name': e.name,
              'phone': e.phone,
              'relationship': e.relationship,
            },
          )
          .toList(),
    };
  }

  static OnboardingState decode(String raw) {
    final Map<String, dynamic> m =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic>? goalsRaw = m['goals'] as List<dynamic>?;
    final Set<HealthGoal> goals = <HealthGoal>{};
    if (goalsRaw != null) {
      for (final Object? g in goalsRaw) {
        final String name = g?.toString() ?? '';
        for (final HealthGoal h in HealthGoal.values) {
          if (h.name == name) {
            goals.add(h);
            break;
          }
        }
      }
    }
    if (goals.isEmpty) {
      goals.add(HealthGoal.improveOverallHealth);
    }
    ProfileGender? gender;
    final String? gn = m['gender'] as String?;
    if (gn != null) {
      for (final ProfileGender pg in ProfileGender.values) {
        if (pg.name == gn) {
          gender = pg;
          break;
        }
      }
    }
    DateTime? dob;
    final String? iso = m['dateOfBirthIso'] as String?;
    if (iso != null && iso.isNotEmpty) {
      dob = DateTime.tryParse(iso);
    }
    DietType dietType = DietType.vegetarian;
    final String? dt = m['dietType'] as String?;
    if (dt != null) {
      dietType = DietType.values.firstWhere(
        (DietType e) => e.name == dt,
        orElse: () => DietType.vegetarian,
      );
    }
    FitnessLevel fl = FitnessLevel.beginner;
    final String? fls = m['fitnessLevel'] as String?;
    if (fls != null) {
      fl = FitnessLevel.values.firstWhere(
        (FitnessLevel e) => e.name == fls,
        orElse: () => FitnessLevel.beginner,
      );
    }
    ActivityLevel al = ActivityLevel.lightlyActive;
    final String? als = m['activityLevel'] as String?;
    if (als != null) {
      al = ActivityLevel.values.firstWhere(
        (ActivityLevel e) => e.name == als,
        orElse: () => ActivityLevel.lightlyActive,
      );
    }
    final List<EmergencyContact> contacts = <EmergencyContact>[];
    final List<dynamic>? ec = m['emergencyContacts'] as List<dynamic>?;
    if (ec != null) {
      for (final Object? o in ec) {
        if (o is Map<String, dynamic>) {
          contacts.add(
            EmergencyContact(
              name: o['name'] as String? ?? '',
              phone: o['phone'] as String? ?? '',
              relationship: o['relationship'] as String? ?? '',
            ),
          );
        }
      }
    }
    return OnboardingState(
      currentStep: (m['currentStep'] as num?)?.toInt() ?? 0,
      goals: goals,
      gender: gender,
      dateOfBirth: dob,
      heightCm: (m['heightCm'] as num?)?.toDouble() ?? 170,
      weightKg: (m['weightKg'] as num?)?.toDouble() ?? 70,
      targetWeightKg: (m['targetWeightKg'] as num?)?.toDouble(),
      useMetricUnits: m['useMetricUnits'] as bool? ?? true,
      dietType: dietType,
      cuisines: (m['cuisines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      allergies: (m['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      fitnessLevel: fl,
      activityLevel: al,
      healthConditions: (m['healthConditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      medicationsNote: m['medicationsNote'] as String? ?? '',
      emergencyContacts: contacts,
    );
  }
}
