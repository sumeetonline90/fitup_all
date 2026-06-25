import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../entities/survey_result.dart';
import '../entities/survey_severity.dart';
import '../entities/survey_type.dart';
import '../repositories/mental_wellbeing_repository.dart';
import '../survey_scoring.dart';

class CompleteSurveyUseCase {
  CompleteSurveyUseCase(this._repository, this._ai);

  final MentalWellbeingRepository _repository;
  final AiService _ai;

  Future<Either<Failure, SurveyResult>> call({
    required String userId,
    required SurveyType type,
    required List<int> answers,
  }) async {
    try {
      final ({int total, SurveySeverity severity}) scored =
          SurveyScoring.scoreSurvey(type, answers);
      final Either<Failure, String> insight = await _ai.getSurveyInsight(
        type: type,
        severity: scored.severity,
      );
      final String? guidance = insight.fold((_) => null, (String s) => s);
      final SurveyResult result = SurveyResult(
        id: 'srv-$userId-${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        type: type,
        answers: List<int>.from(answers),
        totalScore: scored.total,
        severity: scored.severity,
        completedAt: DateTime.now(),
        aiGuidance: guidance,
      );
      return _repository.saveSurveyResult(result);
    } on ArgumentError catch (e) {
      return Left<Failure, SurveyResult>(ValidationFailure(e.message));
    }
  }
}
