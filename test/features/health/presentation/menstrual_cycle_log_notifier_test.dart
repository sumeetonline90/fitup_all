import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/auth/domain/entities/fitup_user.dart';
import 'package:fitup/features/auth/presentation/providers/auth_providers.dart';
import 'package:fitup/features/health/domain/entities/flow_intensity.dart';
import 'package:fitup/features/health/domain/entities/health_summary.dart';
import 'package:fitup/features/health/domain/entities/medication_log.dart';
import 'package:fitup/features/health/domain/entities/menstrual_cycle.dart';
import 'package:fitup/features/health/domain/entities/vital_entry.dart';
import 'package:fitup/features/health/domain/entities/vital_type.dart';
import 'package:fitup/features/health/domain/repositories/health_repository.dart';
import 'package:fitup/features/health/presentation/providers/health_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late _MockHealthRepository repo;

  setUpAll(() {
    registerFallbackValue(36);
    registerFallbackValue(
      MenstrualCycle(
        id: 'fb',
        userId: 'u',
        cycleStart: DateTime(2020),
        flowIntensity: FlowIntensity.medium,
      ),
    );
  });

  setUp(() {
    repo = _MockHealthRepository();
  });

  test('saveCycleLog invokes saveMenstrualCycle with expected entity', () async {
    final FitupUser user = FitupUser(
      id: 'u1',
      email: 'a@b.com',
      createdAt: DateTime(2025),
    );
    MenstrualCycle? seen;
    when(() => repo.saveMenstrualCycle(any())).thenAnswer((Invocation i) async {
      seen = i.positionalArguments[0] as MenstrualCycle;
      return Right<Failure, MenstrualCycle>(seen!);
    });
    when(() => repo.getMenstrualHistory(any(), limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => const Right<Failure, List<MenstrualCycle>>(<MenstrualCycle>[]),
    );
    when(() => repo.getHealthSummary(any())).thenAnswer(
      (_) async => Right<Failure, HealthSummary>(
        HealthSummary(
          latestVitals: <VitalType, VitalEntry?>{
            for (final VitalType t in VitalType.values) t: null,
          },
          trends: <VitalType, List<VitalEntry>>{
            for (final VitalType t in VitalType.values) t: <VitalEntry>[],
          },
          activeMedications: const <MedicationLog>[],
          vitalsInNormalRange: 0,
          vitalsNeedingAttention: 0,
        ),
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith(
          (Ref ref) => Stream<FitupUser?>.value(user),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.listen(authStateProvider, (_, __) {}, fireImmediately: true);
    await Future<void>.delayed(Duration.zero);

    final Either<Failure, MenstrualCycle> r = await container
        .read(menstrualCycleLogProvider.notifier)
        .saveCycleLog(
          startDate: DateTime(2025, 3, 15),
          flowIntensityLabel: 'Heavy',
          symptoms: const <String>['Cramps'],
          notes: 'test',
        );

    expect(r.isRight(), isTrue);
    verify(() => repo.saveMenstrualCycle(any())).called(1);
    expect(seen, isNotNull);
    expect(seen!.userId, user.id);
    expect(seen!.cycleStart, DateTime(2025, 3, 15));
    expect(seen!.flowIntensity, FlowIntensity.heavy);
    expect(seen!.symptoms, const <String>['Cramps']);
    expect(seen!.notes, 'test');
  });
}
