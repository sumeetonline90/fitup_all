import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class GetPersonalRecordsUseCase {
  GetPersonalRecordsUseCase(this._repository);

  final WorkoutRepository _repository;

  Future<Either<Failure, List<PersonalRecord>>> call(String userId) =>
      _repository.getPersonalRecords(userId);
}
