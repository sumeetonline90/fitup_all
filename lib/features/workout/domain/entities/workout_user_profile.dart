/// Minimal profile context for AI workout generation (no Profile module yet).
class WorkoutUserProfile {
  const WorkoutUserProfile({
    required this.userId,
    this.age,
    this.weightKg,
    this.heightCm,
    this.notes,
    this.healthConditions = const <String>[],
  });

  final String userId;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? notes;
  final List<String> healthConditions;
}
