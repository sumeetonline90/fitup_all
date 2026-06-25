/// Health goals shown in onboarding & profile.
enum HealthGoal {
  loseWeight,
  buildMuscle,
  improveOverallHealth,
  mentalWellbeing,
  improveFitness,
  manageHealthCondition,
}

extension HealthGoalX on HealthGoal {
  String get key => name;

  String get title => switch (this) {
        HealthGoal.loseWeight => 'Lose Weight',
        HealthGoal.buildMuscle => 'Build Muscle',
        HealthGoal.improveOverallHealth => 'Improve Overall Health',
        HealthGoal.mentalWellbeing => 'Mental Wellbeing',
        HealthGoal.improveFitness => 'Improve Fitness',
        HealthGoal.manageHealthCondition => 'Manage a Health Condition',
      };

  String get subtitle => switch (this) {
        HealthGoal.loseWeight => 'Burn fat, track calories',
        HealthGoal.buildMuscle => 'Strength training & protein goals',
        HealthGoal.improveOverallHealth => 'Vitals, sleep, nutrition balance',
        HealthGoal.mentalWellbeing => 'Stress, mood & mindfulness',
        HealthGoal.improveFitness => 'Endurance, VO₂ max, stamina',
        HealthGoal.manageHealthCondition => 'Diabetes, BP, thyroid, etc.',
      };
}

enum ProfileGender { male, female, other }

enum DietType {
  vegetarian,
  vegan,
  nonVeg,
  keto,
  pescatarian,
}

extension DietTypeX on DietType {
  String get label => switch (this) {
        DietType.vegetarian => 'Vegetarian',
        DietType.vegan => 'Vegan',
        DietType.nonVeg => 'Non-veg',
        DietType.keto => 'Keto',
        DietType.pescatarian => 'Pescatarian',
      };
}

enum FitnessLevel { beginner, intermediate, advanced }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

extension ActivityLevelX on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.lightlyActive => 'Lightly Active',
        ActivityLevel.moderatelyActive => 'Moderately Active',
        ActivityLevel.veryActive => 'Very Active',
        ActivityLevel.extraActive => 'Extra Active',
      };
}

enum SubscriptionTier { free, pro }

enum FitupThemePreference { light, dark, system }
