import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_input_sanitizer.dart';
import '../entities/mood_entry.dart';
import '../repositories/mental_wellbeing_repository.dart';

class LogMoodUseCase {
  LogMoodUseCase(this._repository);

  final MentalWellbeingRepository _repository;

  Future<Either<Failure, MoodEntry>> call(MoodEntry entry) {
    if (entry.journal != null && entry.journal!.length > 500) {
      return Future<Either<Failure, MoodEntry>>.value(
        const Left<Failure, MoodEntry>(
          ValidationFailure('Journal must be 500 characters or less'),
        ),
      );
    }
    final List<String> safeTags = entry.tags
        .map(
          (String t) =>
              AiInputSanitizer.sanitizeContextSnippet(t, maxLength: 40),
        )
        .where((String t) => t.isNotEmpty)
        .toList();
    final String? j = entry.journal != null
        ? AiInputSanitizer.sanitizeContextSnippet(
            entry.journal!,
            maxLength: 500,
          )
        : null;
    return _repository.saveMoodEntry(
      MoodEntry(
        id: entry.id,
        userId: entry.userId,
        mood: entry.mood,
        journal: j,
        recordedAt: entry.recordedAt,
        tags: safeTags,
      ),
    );
  }
}
