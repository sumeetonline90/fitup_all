import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings(String userId);

  Future<Either<Failure, Unit>> saveSettings(
    String userId,
    AppSettings settings,
  );

  Stream<AppSettings> watchSettings(String userId);
}
