import 'package:fitup/features/workout/domain/entities/workout_user_profile.dart';
import 'ai_input_sanitizer.dart';

/// Non-identifying fitness context for Gemini (never include Firebase UID).
String workoutProfilePromptSegment(WorkoutUserProfile p) {
  final List<String> parts = <String>['Fitness profile (no user identifiers)'];
  if (p.age != null) {
    parts.add('age: ${p.age}');
  }
  if (p.weightKg != null) {
    parts.add('weightKg: ${p.weightKg}');
  }
  if (p.heightCm != null) {
    parts.add('heightCm: ${p.heightCm}');
  }
  if (p.notes != null && p.notes!.isNotEmpty) {
    parts.add('notes: ${AiInputSanitizer.sanitizeProfileText(p.notes!)}');
  }
  for (final String c in p.healthConditions) {
    parts.add(AiInputSanitizer.sanitizeContextSnippet(c, maxLength: 200));
  }
  return parts.join('; ');
}
