import 'package:fitup/features/workout/domain/entities/workout_user_profile.dart';
import 'package:fitup/services/workout_ai_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateWorkoutPlan profile segment does not contain userId string', () {
    const String uid = 'firebase_uid_ABC123_should_not_leak';
    const WorkoutUserProfile profile = WorkoutUserProfile(
      userId: uid,
      age: 30,
      notes: 'prefers mornings',
    );
    final String segment = workoutProfilePromptSegment(profile);
    expect(segment.contains(uid), isFalse);
    expect(segment.toLowerCase().contains('firebase'), isFalse);
  });
}
