import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meditation_session.dart';
import '../repositories/mental_wellbeing_repository.dart';

class CompleteMeditationUseCase {
  CompleteMeditationUseCase(this._repository);

  final MentalWellbeingRepository _repository;

  Future<Either<Failure, MeditationSession>> call(MeditationSession session) {
    return _repository.saveMeditationSession(session);
  }
}
